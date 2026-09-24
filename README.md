# Nova Laravel Starter

投放广告的英文内容站起始模板：Laravel 12 + PHP 8.2 + MySQL 5.7 + `inova/nova-admin`。
本地用 Sail，生产用 PHP-FPM + Nginx + Supervisor。

后台、广告、站点设置、SEO、静态页、前台缓存等通用能力都在 `inova/nova-admin` 包里，
**所有站点通用的改动改包、发版，项目 `composer update` 即得**。本 Starter 只放每站都要改的前台骨架。

**开发约定见 [AGENTS.md](AGENTS.md)**（`CLAUDE.md` 是它的软链），动模板和配置前先读。

## 开新项目

```bash
composer create-project inova/nova-laravel-starter myhub
cd myhub
./init.sh myhub        # 依赖 + .env + 前端构建 + 起容器 + migrate + seed
```

结尾会打印访问地址；后台 `/admin`，本地账号固定 `nova` / `nova`。然后：

1. **先定广告位**：通用位由包提供，本站专属位在 `config/nova-admin.php` 追加，改完跑
   `sail artisan nova-admin:doctor`。
2. **写页面**：照 `resources/views/home.blade.php` 抄，页面只写 `@section('title', ...)` 和内容，
   SEO 与布局级广告由布局统一输出。`sail artisan ad:seed` 填测试广告看排版，`--off` 关掉。
3. **后台「站点设置」**填站点名、副标题、SEO、Favicon / Logo，前台即时生效；「静态页面」填法务页。
4. **上线前**导入广告代码与 ads.txt：`sail artisan ads:import-site-ad-config <webdeploy下发的.json>`。

## 本地开发（Sail）

```bash
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'   # 建议加进 ~/.bashrc

sail up -d / sail down          # 启停（down -v 连数据卷一起删）
sail artisan test               # 测试
sail npm run dev                # Vite 热更新
sail --profile queue up -d      # 需要时加队列 worker（scheduled 同理）
```

**init.sh**：`./init.sh [项目名] [--reset]`，项目名默认取目录名，`--reset` 会删数据卷重来。

- `.env` 由 `.env.example` 生成并补上 Sail 专属键（端口、`DB_HOST=mysql`、账号等），**绝不静默覆盖**：
  已有 `.env` 不含 `APP_PORT` 时先备份成 `.env.bak.*` 再生成（`create-project` 的新项目走这条，正常）；
  含 `APP_PORT` 则保留。
- 端口自动避让：`APP_PORT` / `VITE_PORT` / `FORWARD_DB_PORT` 被别的进程或项目占用就往后挪，
  `APP_URL` 同步。要手工指定改 `.env`，改 `compose.yaml` 无效。端口只绑 `127.0.0.1`。

**数据库**：容器内 `mysql:3306`；宿主机 `mysql -h 127.0.0.1 -P ${FORWARD_DB_PORT} -u sail -psail ${DB_DATABASE}`。

**排障**：`.env` 含空格的值要加引号，否则容器反复重启、返回 503；改 `.env` 后 `sail restart laravel.test`；
卡在「等待 MySQL 就绪」且容器 PORTS 列没有 `127.0.0.1:xxxx->` 映射，`sail down -v` 后重跑 `init.sh`。

## 生产部署（LNMP）

不使用 `compose.yaml` 与 `init.sh`：

```bash
composer install --no-dev --optimize-autoloader
cp .env.example .env    # 填域名、APP_KEY、数据库等；APP_ENV=production、APP_DEBUG=false
php artisan key:generate
php artisan migrate --force
php artisan nova-admin:create-admin    # 用 NOVA_ADMIN_NAME / EMAIL / PASSWORD 覆盖默认凭据
php artisan optimize
```

Supervisor 跑 `php artisan queue:work`，crontab 或 Supervisor 跑 `php artisan schedule:work`。

## 维护 Starter

- **来源**：`laravel new` + `composer require inova/nova-admin` + `php artisan nova-admin:install` + 前台骨架
  （`resources/`、`routes/public.php`、`bootstrap/app.php` 的 nova.public 路由组、`.env.example`、`init.sh`、`AGENTS.md`）。
  Laravel 升大版本时按此重新生成，再把前台骨架拷回来。
- **发版**：`composer create-project` 取 Packagist 最新 tag，Starter 有改动就打 tag（主版本号与 nova-admin 对齐），记入 `CHANGELOG.md`。
- **联调 nova-admin**：`composer dev:link` 把依赖切到同级 `../nova-admin` 的软链（本地包声明为 `2.99.99` 以满足 `^2.x`），
  改包即时生效；包发版后 `composer dev:unlink` 切回，**提交前必须 unlink**。软链在 Sail 容器内不可见，联调用宿主机 `php artisan test`。
