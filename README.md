# Nova Laravel Starter

基于 Laravel 12、PHP 8.2、MySQL 5.7、Laravel Sail 和 `inova/nova-admin` 的项目起始模板。

本地开发使用 Sail；生产环境继续使用 PHP-FPM、Nginx 与 Supervisor，不使用 Docker Compose。

**项目约定见 [AGENTS.md](AGENTS.md)**（`CLAUDE.md` 是它的软链）。广告契约、前台文案语言、
env 双模板同步等规则都在那里，动模板和配置前先读。

## 基于 Starter 开新项目

```bash
composer create-project inova/nova-laravel-starter myhub
cd myhub
./init.sh myhub        # 依赖 + .env + 前端构建 + 起容器 + migrate + seed
```

多个项目并存时改 `.env` 的 `APP_PORT` 与 `FORWARD_DB_PORT`，避免端口冲突。

起来之后按这个顺序做：

1. **先定广告位，再写业务。** 广告位是站点的结构性决定，页面按它排版，不是最后往页面上贴。
   按站点实际裁剪 `config/nova-admin.php` 的 `ad_positions`，**同步删 `ads_protocol.position_map`
   里对应的行**（两者必须一致）。改完跑：

   ```bash
   sail artisan nova-admin:doctor    # 配置一致性自检
   sail artisan test                 # 三个契约测试必须全绿
   ```

2. **写页面时照 `resources/views/home.blade.php` 抄。** head/body 成对、`global_head` 排最后、
   浮层位 `:wrapper="false"` —— 细节见 AGENTS.md 的广告契约一节。
   `sail artisan ad:seed` 可填测试广告肉眼验证排版，看完 `--off` 关掉。

3. **栏目级关广告**按需接入：布局判断的是 `$section->ads_enabled`，鸭子类型，
   自己的栏目模型加个 `ads_enabled` 字段即可，Starter 不预设栏目结构。

4. **上线前**导入广告代码与 ads.txt：

   ```bash
   sail artisan ads:import-site-ad-config <webdeploy下发的.json>
   ```

   静态页（法务五件套）在后台「静态页面」填，页脚链接自动按启用状态展示。

## 本地 Docker 开发

要求：Docker Desktop（WSL2）或 Docker Engine 与 Docker Compose。

若本机尚未配置 `sail` 命令，先将下面的 alias 加入 shell 配置文件（如 `~/.bashrc`）：

```bash
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
```

使用 Composer 创建项目：

```bash
composer create-project inova/nova-laravel-starter myhub
cd myhub
```

创建命令会安装依赖、生成 `.env` 与应用密钥；不会连接或迁移数据库。

默认访问地址为 <http://127.0.0.1:8000>，后台登录入口为 <http://127.0.0.1:8000/admin/login>。
本地初始化后的后台账号固定为 `nova`，密码固定为 `nova`；这是 Starter 的开发环境约定，不需要另建管理员。

使用 Sail 初始化本地环境：

```bash
cp .env.docker.example .env
# 修改 COMPOSE_PROJECT_NAME、APP_NAME、APP_URL、APP_PORT、FORWARD_DB_PORT、DB_DATABASE 等本地参数
sail up -d
sail artisan key:generate
sail artisan migrate --seed
```

`sail up -d` 默认启动 Laravel 与 MySQL。需要异步任务时启动 queue profile；需要定时任务时启动 scheduled profile：

```bash
sail --profile queue up -d
sail --profile scheduled up -d
```

常用命令：

```bash
sail artisan migrate
sail artisan test
sail logs -f
sail down
```

MySQL 在容器内使用 `mysql:3306`，宿主机访问 `127.0.0.1:${FORWARD_DB_PORT}`，默认端口为 `33061`。
`COMPOSE_PROJECT_NAME` 决定 Docker 容器、网络和数据卷的名称前缀；使用小写项目标识，例如 `myhub`。

## 传统 LNMP 部署

生产服务器不要使用 `.env.docker.example` 或 `compose.yaml`：

```bash
composer install --no-dev --optimize-autoloader
cp .env.example .env
# 填写生产域名、APP_KEY、数据库、缓存、邮件和队列配置
php artisan key:generate
php artisan migrate --force
php artisan nova-admin:create-admin
php artisan optimize
```

生产 `.env` 应设置 `APP_ENV=production`、`APP_DEBUG=false`，将 `DB_HOST` 配置为实际数据库地址，并通过 `NOVA_ADMIN_NAME`、`NOVA_ADMIN_EMAIL`、`NOVA_ADMIN_PASSWORD` 覆盖默认管理员凭据。由 Supervisor 运行 `php artisan queue:work`，由 crontab 或 Supervisor 运行 `php artisan schedule:work`。

## 环境文件约定

- `.env.example`：非 Docker 的本地开发配置模板；生产部署时以实际生产参数覆盖。
- `.env.docker.example`：Sail 本地 Docker 配置模板。
- `.env`：当前运行环境配置，不提交。

不要在应用业务代码中直接使用 `env()`；配置值应通过 `config()` 读取。
