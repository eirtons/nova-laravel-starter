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

多个项目并存不用手工分配端口：`init.sh` 起容器前会探测宿主机监听表，
`APP_PORT` / `VITE_PORT` / `FORWARD_DB_PORT` 撞上别人就自动往后挪，并同步改写 `APP_URL`。

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

## 本地 Docker 开发（Laravel Sail）

要求：Docker Desktop（WSL2）或 Docker Engine 与 Docker Compose。

把 alias 加进 shell 配置文件（如 `~/.bashrc`）会方便很多：

```bash
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
```

### init.sh 做了什么

```bash
./init.sh                  # 项目名取当前目录名
./init.sh MyNewSite        # 显式指定：容器前缀 mynewsite，数据库 mynewsite
./init.sh myhub --reset    # 推倒重来（会删除数据卷！）
```

依次完成：装依赖 → 生成 `.env` → 前端构建 → 探测端口 → 起容器 → 迁移 + 填充。

关于 `.env`，它**绝不静默覆盖已有配置**，三条分支：

| `.env` 状态 | 行为 |
| --- | --- |
| 不存在 | 用 `.env.docker.example` 生成 |
| 存在但不含 `APP_PORT` | 备份为 `.env.bak.<时间戳>` 后重新生成，并提示自行迁移自定义配置 |
| 存在且含 `APP_PORT` | 保留，只在端口冲突时改写端口相关键 |

`composer create-project` 会先用 `.env.example` 造一个 `.env`，它不含 Docker 端口键，
所以新项目走的是中间那条分支——留下一个 `.env.bak.*` 是正常的，已在 `.gitignore` 里。

项目名参数影响 `COMPOSE_PROJECT_NAME`（转小写）、`APP_NAME`、`DB_DATABASE`（转小写，`-` 换 `_`），
且只在生成 `.env` 时写入。`--reset` 是第二个位置参数，单独传 `./init.sh --reset` 会被当成项目名。

### 端口

`.env.docker.example` 的默认值是 HTTP `8014`、Vite `5187`、MySQL `33075`，
但本机多个 Starter 项目并存时几乎必然撞车，所以 `init.sh` 在 `sail up` **之前**先探测：

- 端口被别的进程或别的项目容器占着 → 自动往后找空闲端口，改写 `.env`，`APP_URL` 跟着同步
- 端口被本项目自己的容器占着 → 视为正常，重复执行 `init.sh` 不会导致端口漂移

所有端口只绑定 `127.0.0.1`，不对外暴露。要手工指定就改 `.env` 里的
`APP_PORT` / `VITE_PORT` / `FORWARD_DB_PORT`——**改 `compose.yaml` 无效**，
里面的 `${APP_PORT:-8014}` 只是 `.env` 缺键时的兜底默认值。

实际地址以 `init.sh` 结尾打印的为准：应用 `http://127.0.0.1:${APP_PORT}`，
后台入口 `http://127.0.0.1:${APP_PORT}/admin/login`。
本地后台账号固定 `nova` / `nova`，这是开发环境约定，不需要另建管理员。

### 常用命令

```bash
sail up -d          # 启动
sail down           # 停止（保留数据）
sail down -v        # 停止并删除数据卷
sail ps             # 查看容器
sail logs -f        # 跟踪日志
sail artisan migrate
sail artisan test
sail artisan tinker
sail npm run dev    # Vite 热更新（需与 .env 的 VITE_PORT 一致）
```

### 可选服务（profile）

默认只起 `laravel.test` + `mysql`。队列和调度器按需启动：

```bash
sail --profile queue up -d       # 加 queue:work
sail --profile scheduled up -d   # 加 schedule:work
```

### 连接数据库

容器内用 `mysql:3306`；宿主机 GUI 工具或命令行用 `127.0.0.1:${FORWARD_DB_PORT}`：

```bash
mysql -h 127.0.0.1 -P ${FORWARD_DB_PORT} -u sail -psail ${DB_DATABASE}
```

### 注意

- `.env` 中含空格的值必须加引号（例如 `APP_NAME="Nova Starter"`），
  否则容器会因 dotenv 解析失败反复重启并返回 503。
- 改完 `.env` 后需 `sail restart laravel.test` 才生效。
- 若卡在「等待 MySQL 就绪」，先看容器的 PORTS 一列有没有 `127.0.0.1:xxxx->` 映射；
  没有说明端口绑定失败、容器是半成品，`sail down -v` 后重跑 `init.sh` 即可。

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
