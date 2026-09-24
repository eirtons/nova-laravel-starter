# Changelog

本文件记录 Starter 每个版本的变更。`composer create-project` 取 Packagist 上最新 tag，
Starter 有改动就要打 tag，否则新项目拿不到。版本主号与 `inova/nova-admin` 对齐。

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
