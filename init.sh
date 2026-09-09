#!/usr/bin/env bash

set -e

PROJECT_NAME="${1:-$(basename "$(pwd)")}"
DOCKER_PROJECT_NAME="$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"
ENV_TEMPLATE=".env.docker.example"

echo "🚀 正在初始化项目: $PROJECT_NAME"
echo ""

# 如需清理已有容器与数据卷，必须显式传入 --reset
if [ "${2:-}" = "--reset" ] && [ -x "vendor/bin/sail" ]; then
    echo "🧹 正在清理容器和数据卷..."
    ./vendor/bin/sail down -v
    echo "✅ 清理完成"
    echo ""
fi

# 在一次性容器里执行命令，避免宿主机必须装 PHP / Node
run_in() {
    local image="$1"; shift
    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$(pwd):/srv/$(basename "$(pwd)")" \
        -w "/srv/$(basename "$(pwd)")" \
        "$image" "$@"
}

# 1. 安装 Composer 依赖
if [ ! -x "vendor/bin/sail" ]; then
    echo "📦 安装 Composer 依赖..."
    run_in laravelsail/php82-composer:latest composer install --ignore-platform-reqs
    echo "✅ Composer 依赖安装完成"
else
    echo "⏭️  vendor/ 已存在，跳过 composer install"
fi

# 2. 安装 Node 依赖
if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
    echo ""
    echo "📦 安装 Node 依赖..."
    run_in node:24-bookworm-slim npm install
    echo "✅ Node 依赖安装完成"
else
    echo "⏭️  跳过 npm install"
fi

# 2.1 构建前端资源（缺少产物会导致页面 500）
# Vite 项目看 public/build/manifest.json，Laravel Mix 项目看 public/mix-manifest.json
if [ -f "package.json" ]; then
    if grep -q '"build"' package.json; then
        BUILD_SCRIPT=build
        BUILD_MANIFEST=public/build/manifest.json
    elif grep -q '"production"' package.json; then
        BUILD_SCRIPT=production
        BUILD_MANIFEST=public/mix-manifest.json
    else
        BUILD_SCRIPT=""
    fi

    if [ -n "$BUILD_SCRIPT" ] && [ ! -f "$BUILD_MANIFEST" ]; then
        echo ""
        echo "🎨 构建前端资源（npm run $BUILD_SCRIPT）..."
        run_in node:24-bookworm-slim npm run "$BUILD_SCRIPT"
        echo "✅ 前端资源构建完成"
    else
        echo "⏭️  跳过前端构建"
    fi
fi

# 端口占用探测。多个 Starter 项目并存时端口最容易撞，而 compose 撞了以后仍会把容器
# 建出来（只是没有宿主映射、网络也是半成品），随后卡在「等待 MySQL 就绪」空转 30 次，
# 报错完全指不到真正的原因。所以在 up 之前就要判掉。
SS_BIN="$(command -v ss || true)"

if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(-i '')
else
    SED_INPLACE=(-i)
fi

# 优先读监听表：瞬时返回。WSL2 下对未监听端口的 connect 会被丢包而不是 RST，
# 纯 /dev/tcp 探测每个空闲端口都要挂到超时，所以 /dev/tcp 只作兜底且必须带 timeout。
port_in_use() {
    if [ -n "$SS_BIN" ]; then
        "$SS_BIN" -ltn 2>/dev/null | grep -qE "[:.]$1[[:space:]]"
        return $?
    fi
    timeout 1 bash -c "(exec 3<>/dev/tcp/127.0.0.1/$1)" 2>/dev/null
}

# 端口被本项目自己的容器占着是正常的（重复执行 init.sh），只有被别人占才算冲突。
port_taken_by_others() {
    port_in_use "$1" || return 1
    docker ps --format '{{.Names}} {{.Ports}}' 2>/dev/null \
        | grep -F "127.0.0.1:$1->" \
        | grep -q "^${DOCKER_PROJECT_NAME}-" && return 1
    return 0
}

next_free_port() {
    local port="$1"
    while port_in_use "$port"; do
        port=$((port + 1))
    done
    echo "$port"
}

# 3. 生成 .env 文件（绝不静默覆盖已有配置）
generate_env() {
    cp "$ENV_TEMPLATE" .env

    DB_NAME="$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]-' '[:lower:]_')"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SED_INPLACE=(-i '')
    else
        SED_INPLACE=(-i)
    fi
    sed "${SED_INPLACE[@]}" "s/^COMPOSE_PROJECT_NAME=.*/COMPOSE_PROJECT_NAME=$DOCKER_PROJECT_NAME/" .env
    sed "${SED_INPLACE[@]}" "s/^APP_NAME=.*/APP_NAME=$PROJECT_NAME/" .env
    sed "${SED_INPLACE[@]}" "s/^DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env

    # 新项目直接挑空闲端口，免得跟已在跑的其他 Starter 项目撞。
    NEW_APP_PORT="$(next_free_port "$(grep -E '^APP_PORT=' .env | tail -1 | cut -d= -f2)")"
    NEW_VITE_PORT="$(next_free_port "$(grep -E '^VITE_PORT=' .env | tail -1 | cut -d= -f2)")"
    NEW_DB_PORT="$(next_free_port "$(grep -E '^FORWARD_DB_PORT=' .env | tail -1 | cut -d= -f2)")"

    sed "${SED_INPLACE[@]}" "s/^APP_PORT=.*/APP_PORT=$NEW_APP_PORT/" .env
    sed "${SED_INPLACE[@]}" "s/^VITE_PORT=.*/VITE_PORT=$NEW_VITE_PORT/" .env
    sed "${SED_INPLACE[@]}" "s/^FORWARD_DB_PORT=.*/FORWARD_DB_PORT=$NEW_DB_PORT/" .env
    # APP_URL 必须跟着 APP_PORT 走，否则站内生成的链接全指向旧端口。
    sed "${SED_INPLACE[@]}" "s#^APP_URL=.*#APP_URL=http://127.0.0.1:$NEW_APP_PORT#" .env

    echo "✅ .env 文件已生成（项目名: $PROJECT_NAME，端口: $NEW_APP_PORT / $NEW_VITE_PORT / $NEW_DB_PORT）"
}

if [ ! -f ".env" ]; then
    echo ""
    echo "📝 使用 Docker 模板生成 .env..."
    generate_env
elif ! grep -q '^APP_PORT=' .env; then
    ENV_BACKUP=".env.bak.$(date +%Y%m%d%H%M%S)"
    echo ""
    echo "📝 现有 .env 不含 Docker 端口配置，切换为 Docker 模板..."
    cp .env "$ENV_BACKUP"
    generate_env
    echo "⚠️  原 .env 已备份为 $ENV_BACKUP，请自行迁移其中的自定义配置"
else
    echo "⏭️  已存在 Docker .env，保留现有配置"
fi

# 读取端口配置，供后续提示使用
APP_PORT="$(grep -E '^APP_PORT=' .env | tail -1 | cut -d= -f2)"
VITE_PORT="$(grep -E '^VITE_PORT=' .env | tail -1 | cut -d= -f2)"
DB_PORT_HOST="$(grep -E '^FORWARD_DB_PORT=' .env | tail -1 | cut -d= -f2)"
DB_DATABASE="$(grep -E '^DB_DATABASE=' .env | tail -1 | cut -d= -f2)"

# 3.1 起容器前先判端口。沿用现有 .env 的项目（如从别的项目复制过来的）最容易在这里
# 撞车：.env 里有 APP_PORT，上面的分支就判定「保留现有配置」，端口冲突被原样留着。
CONFLICTS=()
for pair in "APP_PORT:$APP_PORT" "VITE_PORT:$VITE_PORT" "FORWARD_DB_PORT:$DB_PORT_HOST"; do
    if port_taken_by_others "${pair#*:}"; then
        CONFLICTS+=("$pair")
    fi
done

if [ ${#CONFLICTS[@]} -gt 0 ]; then
    echo ""
    echo "🔌 检测到端口冲突，自动改用空闲端口："
    for pair in "${CONFLICTS[@]}"; do
        KEY="${pair%%:*}"
        PORT="${pair#*:}"
        OWNER="$(docker ps --format '{{.Names}} {{.Ports}}' 2>/dev/null | grep -F "127.0.0.1:$PORT->" | cut -d' ' -f1)"
        FREE="$(next_free_port "$PORT")"

        sed "${SED_INPLACE[@]}" "s/^$KEY=.*/$KEY=$FREE/" .env
        echo "   $KEY: $PORT → $FREE（原端口被 ${OWNER:-非容器进程} 占用）"

        # APP_URL 必须跟着 APP_PORT 走，否则站内生成的链接全指向旧端口。
        if [ "$KEY" = "APP_PORT" ]; then
            sed "${SED_INPLACE[@]}" "s#^APP_URL=.*#APP_URL=http://127.0.0.1:$FREE#" .env
            echo "   APP_URL 已同步为 http://127.0.0.1:$FREE"
            APP_PORT="$FREE"
        fi
        # 同步 shell 变量，后面的连接提示才不会打印出已被改掉的旧端口。
        if [ "$KEY" = "VITE_PORT" ]; then
            VITE_PORT="$FREE"
        elif [ "$KEY" = "FORWARD_DB_PORT" ]; then
            DB_PORT_HOST="$FREE"
        fi
    done
    echo "   （端口只在 .env 里配；compose.yaml 的 \${APP_PORT:-8014} 只是兜底默认值，改它无效）"
fi

# 4. 启动 Docker 容器
echo ""
echo "🐳 启动 Docker 容器..."
./vendor/bin/sail up -d

# 等待 MySQL 就绪
echo ""
echo "⏳ 等待 MySQL 就绪..."
# 冷启动建数据目录通常十几秒，超过 5 次（10 秒）多半不是「还没起来」而是真出了问题，
# 这时候把诊断信息摆出来，别让人对着计数器干等到 30。
MAX_ATTEMPTS=15
HINT_AT=5
ATTEMPT=0
until ./vendor/bin/sail artisan db:show >/dev/null 2>&1 || [ $ATTEMPT -eq $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "   MySQL 尚未就绪，等待中... ($ATTEMPT/$MAX_ATTEMPTS)"

    if [ $ATTEMPT -eq $HINT_AT ]; then
        echo ""
        echo "   ⚠️  已等待 $((HINT_AT * 2)) 秒仍未连上，先看一眼容器端口映射："
        docker ps --format '      {{.Names}}  {{.Status}}  {{.Ports}}' 2>/dev/null \
            | grep -F "${DOCKER_PROJECT_NAME}-" || echo "      （没有本项目的容器在跑）"
        echo ""
        echo "      若 PORTS 一列没有 127.0.0.1:xxxx-> 映射，说明端口绑定失败、"
        echo "      容器是半成品：./vendor/bin/sail down -v 后重跑本脚本即可。"
        echo "      其他情况看日志：./vendor/bin/sail logs mysql"
        echo ""
    fi

    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "❌ MySQL 启动超时（已等 $((MAX_ATTEMPTS * 2)) 秒）。按上面的提示排查，"
    echo "   最常见的是端口冲突导致容器网络没配好：./vendor/bin/sail down -v 后重跑。"
    exit 1
fi
echo "✅ MySQL 已就绪"

# 5. 生成 APP_KEY
echo ""
if grep -qE '^APP_KEY=.+$' .env; then
    echo "⏭️  APP_KEY 已存在，跳过生成"
else
    echo "🔑 生成应用密钥..."
    ./vendor/bin/sail artisan key:generate
fi

# 6. 迁移与填充（seeder 多不幂等，重复初始化时失败不阻断）
echo ""
echo "🗄️  初始化数据库..."
./vendor/bin/sail artisan migrate --force
./vendor/bin/sail artisan db:seed --force || echo "⚠️  seeder 执行失败（通常是已初始化过），已跳过"

echo ""
echo "✨ 初始化完成！"
echo ""
echo "🌐 访问地址: http://127.0.0.1:${APP_PORT}"
echo ""
echo "🗄️  MySQL 连接（宿主机）:"
echo "   mysql -h 127.0.0.1 -P ${DB_PORT_HOST} -u sail -psail ${DB_DATABASE}"
echo ""
echo "📋 常用命令:"
echo "   ./vendor/bin/sail up -d                       # 启动"
echo "   ./vendor/bin/sail down                        # 停止"
echo "   ./vendor/bin/sail artisan <cmd>               # Artisan"
echo "   ./vendor/bin/sail npm run dev                 # 前端热更新"
echo "   ./vendor/bin/sail logs -f                     # 日志"
echo "   ./vendor/bin/sail --profile queue up -d       # 附带队列 worker"
echo "   ./vendor/bin/sail --profile scheduled up -d   # 附带调度器"
