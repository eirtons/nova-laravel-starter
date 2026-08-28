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

    echo "✅ .env 文件已生成（项目名: $PROJECT_NAME）"
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
DB_PORT_HOST="$(grep -E '^FORWARD_DB_PORT=' .env | tail -1 | cut -d= -f2)"
DB_DATABASE="$(grep -E '^DB_DATABASE=' .env | tail -1 | cut -d= -f2)"

# 4. 启动 Docker 容器
echo ""
echo "🐳 启动 Docker 容器..."
./vendor/bin/sail up -d

# 等待 MySQL 就绪
echo ""
echo "⏳ 等待 MySQL 就绪..."
MAX_ATTEMPTS=30
ATTEMPT=0
until ./vendor/bin/sail artisan db:show >/dev/null 2>&1 || [ $ATTEMPT -eq $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "   MySQL 尚未就绪，等待中... ($ATTEMPT/$MAX_ATTEMPTS)"
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "❌ MySQL 启动超时，请检查 ./vendor/bin/sail logs mysql"
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
