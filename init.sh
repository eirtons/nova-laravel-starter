#!/usr/bin/env bash

set -e

PROJECT_NAME="${1:-$(basename "$(pwd)")}"
DOCKER_PROJECT_NAME="$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"

echo "🚀 正在初始化项目: $PROJECT_NAME"
echo ""

# 如需清理已有容器与数据卷，必须显式传入 --reset
if [ "${2:-}" = "--reset" ] && [ -x "vendor/bin/sail" ]; then
    echo "🧹 正在清理容器和数据卷..."
    ./vendor/bin/sail down -v
    echo "✅ 清理完成"
    echo ""
fi

# 1. 安装 Composer 依赖
if [ ! -x "vendor/bin/sail" ]; then
    echo "📦 安装 Composer 依赖..."
    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$(pwd):/srv/$(basename "$(pwd)")" \
        -w "/srv/$(basename "$(pwd)")" \
        laravelsail/php82-composer:latest \
        composer install --ignore-platform-reqs
    echo "✅ Composer 依赖安装完成"
else
    echo "⏭️  vendor/ 已存在，跳过 composer install"
fi

# 2. 安装 Node 依赖并构建前端资源
if [ ! -d "node_modules" ]; then
    echo ""
    echo "📦 安装 Node 依赖..."
    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$(pwd):/srv/$(basename "$(pwd)")" \
        -w "/srv/$(basename "$(pwd)")" \
        node:24-bookworm-slim \
        npm install
    echo "✅ Node 依赖安装完成"
else
    echo "⏭️  node_modules/ 已存在，跳过 npm install"
fi

# 2.1 构建前端资源（缺少 manifest 会导致页面 500）
if [ ! -f "public/build/manifest.json" ]; then
    echo ""
    echo "🎨 构建前端资源..."
    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$(pwd):/srv/$(basename "$(pwd)")" \
        -w "/srv/$(basename "$(pwd)")" \
        node:24-bookworm-slim \
        npm run build
    echo "✅ 前端资源构建完成"
else
    echo "⏭️  public/build/manifest.json 已存在，跳过前端构建"
fi

# 3. 生成 .env 文件（绝不静默覆盖已有配置）
generate_env() {
    cp .env.docker.example .env

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
APP_PORT="$(grep -E '^APP_PORT=' .env | cut -d= -f2)"
DB_PORT_HOST="$(grep -E '^FORWARD_DB_PORT=' .env | cut -d= -f2)"
DB_DATABASE="$(grep -E '^DB_DATABASE=' .env | cut -d= -f2)"

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

# 6. 运行数据库迁移和填充
echo ""
echo "🗄️  初始化数据库..."
./vendor/bin/sail artisan migrate --seed --force

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
echo "   ./vendor/bin/sail npm run dev                 # Vite 热更新"
echo "   ./vendor/bin/sail logs -f                     # 日志"
echo "   ./vendor/bin/sail --profile queue up -d       # 附带队列 worker"
echo "   ./vendor/bin/sail --profile scheduled up -d   # 附带调度器"
