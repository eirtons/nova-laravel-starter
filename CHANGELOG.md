# Changelog

本文件记录 Starter 每个版本的变更。`composer create-project` 取 Packagist 上最新 tag，
Starter 有改动就要打 tag，否则新项目拿不到。版本主号与 `inova/nova-admin` 对齐。

## [2.1.1] - 2026-09-23

- `.env.example` 末尾以注释列出 Sail 专属键及默认值，说明由 `init.sh` 自动生成（只看模板找不到 Docker 配置）

## [2.1.0] - 2026-09-23

- 依赖升至 `inova/nova-admin` ^2.2；布局改用 `<x-nova-seo />`，后台「站点设置」的标题模板、描述、关键词、
  Favicon、Logo、副标题、版权在前台生效（此前只用了站点名）；页面只写 `@section('title', '页面标题')`
- env 模板合并为 `.env.example` 一份，`init.sh` 生成 `.env` 时补 Sail 专属键；删除 `.env.docker.example` 与 `EnvTemplateContractTest`
- 前端去掉未使用的 axios、`resources/js/bootstrap.js`、concurrently 与未加载的 Instrument Sans 字体声明
- 去掉与 `init.sh` 重复且假设宿主机环境的 composer `setup` / `dev` 脚本，以及 inspire 示例命令
- `ExampleTest` 改为 `FrontendSmokeTest`：首页 SEO 与 404 模板
- README 与 AGENTS.md 去重：README 讲启动与部署，AGENTS.md 讲约定

## [2.0.0] - 2026-09-23

Starter 收敛为「Laravel + nova-admin + 前台薄骨架」，通用逻辑全部由 `inova/nova-admin` ^2.1 提供。

- 依赖升至 `inova/nova-admin` ^2.1；`config/nova-admin.php` 改为差异写法，包新增配置升级即得
- 删除前台缓存、HSTS 中间件与 `config/page-cache.php`，public 路由改挂包提供的 `nova.public`
- 删除 `is_admin` 迁移与手写的 `canAccessPanel`，User 改用包的 `HasNovaAdminAccess`
- `AppServiceProvider` 清空：`$footerPages` 与静态页 / 404 关广告由包注入
- 布局改用 `<x-ad-layout-head/body />`，包新增浮层位升级即生效
- `AdminPanelProvider` 去掉被插件覆盖的主色与 `login()`
- 测试收敛：广告契约改为断言 `nova-admin:doctor` 通过；删去与包重复或无实际断言的用例
- 新增 `composer dev:link` / `dev:unlink` 联调同级 nova-admin
- env 模板去掉 `NOVA_STATIC_FRONTEND`（包默认已开启）
