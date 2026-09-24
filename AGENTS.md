# AGENTS.md

面向本项目（及由本 Starter 衍生的新项目）的工作约定。人和 AI 都按这份来。

本项目是**投放广告的英文内容站**底座：Laravel 12 + Filament 5 + `inova/nova-admin`。
广告收入是站点存在的理由，所以下面「广告契约」一节的优先级高于代码整洁、高于视觉美观。

---

## 一、广告契约（最高优先级）

通用广告位由 `inova/nova-admin` 包枚举，本站专属位在 `config/nova-admin.php` 的 `ad_positions`
里追加；代码由后台或 webdeploy 协议下发，模板只负责**留出渲染点**。

广告位分两类：
- **布局级位**（anchor / interstitial 等浮层、脚本类，加上 `global_head`）：由布局里的
  `<x-ad-layout-head />` 与 `<x-ad-layout-body />` 统一输出，包新增此类位后升级即生效，不用改模板。
- **内容位**（banner）：各页面模板自行放置。

四条硬约定：

1. **head 与 body 必须成对，position 写字面量**
   每个投了 `<x-ad-head position="X">` 的页面，必须有对应的 `<x-ad-body position="X">`。
   缺一半不会报错，只是广告永远不展示。`nova-admin:doctor`（`AdTemplateContractTest` 调用它）守着这条。

2. **`global_head` 排在所有广告位之后**
   GPT 要求 slot 定义早于 `enableServices`，顺序错了整页广告失效。
   布局组件已保证 `global_head` 最后；布局里 `@stack('ad-head')` 必须写在 `<x-ad-layout-head />` 之前。

3. **浮层位交给布局组件，不要在页面里手写**
   它们自己 `position:fixed`，布局组件输出时不套居中容器；手写容易套上容器破坏布局。

4. **不要靠删模板来关广告**
   没填代码的位不产生任何 DOM（`shouldRender()` 返回 false）。渲染点一律保留，
   展示与否由后台和下发协议决定。要整支关广告用下面的 `$section` 机制。

### 关广告的正确做法

布局里是鸭子类型判断，**不需要任何特定模型**：

```blade
<x-ad-layout-head :enabled="($section ?? null)?->ads_enabled ?? true" />
<x-ad-layout-body :enabled="($section ?? null)?->ads_enabled ?? true" />
```

任何带 `ads_enabled` 属性的对象都能接入：栏目模型加个字段即可；一次性场景直接
`(object) ['ads_enabled' => false]`（静态页和 404 页由 nova-admin 按 `ad_disabled_views` 注入）。

`enabled=false` 时组件仍输出 `global_head` —— 统计、站点验证这类站点级脚本任何页面都要加载。

### 哪些页面不投广告

| 页面 | 浮层位 | 内容位 | `global_head` |
|---|---|---|---|
| 首页 / 内容页 | ✅ | ✅ | ✅ |
| 静态页（法务五件套等） | ❌ | ❌ | ✅ |
| 404 | ❌ | ❌ | ✅ |
| 500 | ❌ | ❌ | ❌（模板不继承布局，见下） |

法务页和错误页内容稀薄，投放踩 AdSense 政策线，收益也约等于零。

### 页面投放样板

```blade
@extends('layouts.app')

@push('ad-head')
    <x-ad-head position="detail_banner1" />
    <x-ad-head position="detail_banner2" />
@endpush

@section('content')
    <x-ad-body position="detail_banner1" />
    {{-- 正文 --}}
    <x-ad-body position="detail_banner2" />
@endsection
```

`resources/views/home.blade.php` 是可运行的参照。改广告位枚举时，
`ad_positions` 与 `ads_protocol.position_map` 必须同步增删，`nova-admin:doctor` 守着这条。

---

## 二、前台约定

- **面向英文用户**：所有前台可见文案一律英文（`APP_LOCALE=en`）。代码注释用中文。
  后台是中文，别混淆两者。
- **布局** `resources/views/layouts/app.blade.php` 是所有前台页的唯一骨架，页眉页脚在此。
  页脚法务链接用包注入的 `$footerPages`（按启用状态），不要硬编码 slug。
- **SEO 由 `<x-nova-seo />` 统一输出**（title / description / keywords / canonical / favicon / OG），
  数据来自后台「站点设置」。页面只写 `@section('title', '页面标题')`，站点名由标题模板拼上，
  不要在页面里手写 `<title>` 或 meta；需要时再写 `@section('description' | 'canonical' | 'og_image')`。
  首页不写 title，自动取「站点名 - 副标题」。
- **读站点设置用 `site_setting('key')`**（未保存时回退默认值），媒体用 `site_media_url('logo_path')`。
- **页眉不用 `sticky`**：顶部 anchor 广告同样固定在视口顶端，两者会互相遮挡。
- **移动端页眉高度控制在 56–64px**，别把首屏广告挤出视口。
- **500 页不继承布局**（`resources/views/errors/500.blade.php`）：
  布局要查 `static_pages` 和 `ad_spots`，而 500 最常见的成因就是数据库不可用，
  继承会导致二次异常、用户看到白屏。这页零依赖、内联样式，改动时保持这条。
- **后台入口 `/admin` 不要挂在前台页面上**，`robots.txt` 已 Disallow。

---

## 三、环境与配置

- **env 模板只有 `.env.example` 一份，生产直接 `cp` 使用**：主体按生产（LNMP）写，新增应用配置键加在主体。
  Sail 专属键加在末尾「Docker（Sail）本地开发」区且保持注释，由 `init.sh` 在 `.env` 里取消注释并填写。
- **`config/nova-admin.php` 只写与包默认不同的部分**（合并规则见文件头），包新增配置升级后自动继承。
- **业务代码不直接用 `env()`**，一律走 `config()`。
- 本地后台账号固定 `nova` / `nova`，这是开发环境约定，不用另建管理员。

---

## 四、改动前后

- `sail artisan test` 必须全绿：`AdTemplateContractTest` 跑 `nova-admin:doctor`（广告配置与模板契约），
  `FrontendSmokeTest` 渲染首页与 404。**变红是设计意图，不是障碍** —— 不要为了让测试通过而放宽断言。
- 改了 Blade 或 Tailwind 类名后需要 `npm run build`（或 `sail npm run dev`），否则样式不生效。
- 验广告位排布：`sail artisan ad:seed` 填测试广告，看完 `sail artisan ad:seed --off` 关掉。
- 配置一致性与模板渲染点自检：`sail artisan nova-admin:doctor`（CI 可加 `--strict`，未放置的内容位也判失败）。
- 所有站点通用的逻辑改 nova-admin 包、发版后 `composer update`，不要在项目里复制；联调用 `composer dev:link`。

---

## 五、别做这些

- 不要为了「页面太朴素」重写 `layouts/app.blade.php` 的广告渲染点或调整其顺序。
- 不要去掉暂时没用上的位（如详情页位），留着备用：去掉后平台一勾到它，整批导入失败。
  真要去掉，在 `ad_positions` 与 `position_map` 里都写 `false`。
- 不要给静态页、错误页加广告位。
- 不要在前台文案里写中文。
- 不要提交 `.env`、密钥或测试数据。
