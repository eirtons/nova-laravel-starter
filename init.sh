#!/usr/bin/env bash

set -e

PROJECT_NAME="${1:-$(basename "$(pwd)")}"
DOCKER_PROJECT_NAME="$(printf '%s' "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"

echo "🚀 正在初始化项目: $PROJECT_NAME"
echo ""

# 如需清理已有容器与数据卷，必须显式传入 --reset。
if [ "${2:-}" = "--reset" ] && [ -d "vendor" ]; then
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
        -v "$(pwd):/opt" \
        -w /opt \
        laravelsail/php82-composer:latest \
        composer install --ignore-platform-reqs
    echo "✅ Composer 依赖安装完成"
else
    echo "⏭️  vendor/ 已存在，跳过 composer install"
fi

# 1.5. 安装 Node 依赖并构建前端资源
if [ ! -d "node_modules" ]; then
    echo ""
    echo "📦 安装 Node 依赖..."
    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$(pwd):/opt" \
        -w /opt \
        node:24-bookworm-slim \
        npm ci
    echo "✅ Node 依赖安装完成"

    echo ""
    echo "🎨 构建前端资源..."
    docker run --rm \
        -u "$(id -u):$(id -g)" \
        -v "$(pwd):/opt" \
        -w /opt \
        node:24-bookworm-slim \
        npm run build
    echo "✅ 前端资源构建完成"
else
    echo "⏭️  node_modules/ 已存在，跳过 npm install"
fi

# 2. 生成 .env 文件
if [ ! -f ".env" ] || ! grep -q '^COMPOSE_PROJECT_NAME=' .env; then
    echo ""
    echo "📝 使用 Docker 模板生成 .env..."
    cp .env.docker.example .env

    # 自动替换项目名
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/COMPOSE_PROJECT_NAME=.*/COMPOSE_PROJECT_NAME=$DOCKER_PROJECT_NAME/" .env
        sed -i '' "s/APP_NAME=.*/APP_NAME=$PROJECT_NAME/" .env
        sed -i '' "s/DB_DATABASE=.*/DB_DATABASE=$PROJECT_NAME/" .env
    else
        # Linux
        sed -i "s/COMPOSE_PROJECT_NAME=.*/COMPOSE_PROJECT_NAME=$DOCKER_PROJECT_NAME/" .env
        sed -i "s/APP_NAME=.*/APP_NAME=$PROJECT_NAME/" .env
        sed -i "s/DB_DATABASE=.*/DB_DATABASE=$PROJECT_NAME/" .env
    fi

    echo "✅ .env 文件已生成（项目名: $PROJECT_NAME）"
else
    echo "⏭️  已存在 Docker .env，保留现有配置"
fi

# 3. 启动 Docker 容器
echo ""
echo "🐳 启动 Docker 容器..."
./vendor/bin/sail up -d

# 等待 MySQL 就绪
echo ""
echo "⏳ 等待 MySQL 就绪..."
MAX_ATTEMPTS=30
ATTEMPT=0
until ./vendor/bin/sail artisan db:show 2>/dev/null | grep -q "mysql" || [ $ATTEMPT -eq $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "   MySQL 尚未就绪，等待中... ($ATTEMPT/$MAX_ATTEMPTS)"
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "❌ MySQL 启动超时，请检查 Docker 容器状态"
    exit 1
fi
echo "✅ MySQL 已就绪"

# 4. 生成 APP_KEY
echo ""
if grep -qE '^APP_KEY=.+$' .env; then
    echo "⏭️  APP_KEY 已存在，跳过生成"
else
    echo "🔑 生成应用密钥..."
    ./vendor/bin/sail artisan key:generate
fi

# 5. 运行数据库迁移和填充
echo ""
echo "🗄️  初始化数据库..."
./vendor/bin/sail artisan migrate --seed

echo ""
echo "✨ 初始化完成！"
echo ""
echo "🌐 访问地址:"
echo "   应用首页: http://127.0.0.1:8000"
echo "   后台管理: http://127.0.0.1:8000/admin"
echo ""
echo "🗄️  MySQL 连接信息（宿主机）:"
echo "   主机: 127.0.0.1"
echo "   端口: 33061"
echo "   数据库: $PROJECT_NAME"
echo "   用户名: sail"
echo "   密码: sail"
echo ""
echo "   连接命令: mysql -h 127.0.0.1 -P 33061 -u sail -psail $PROJECT_NAME"
echo ""
echo "📋 常用命令:"
echo "   ./vendor/bin/sail up -d      # 启动容器"
echo "   ./vendor/bin/sail down       # 停止容器"
echo "   ./vendor/bin/sail artisan    # 运行 Artisan 命令"
echo "   ./vendor/bin/sail logs -f    # 查看日志"
