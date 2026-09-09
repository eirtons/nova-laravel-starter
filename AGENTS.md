# AGENTS.md

面向本项目（及由本 Starter 衍生的新项目）的工作约定。人和 AI 都按这份来。

本项目是**投放广告的英文内容站**底座：Laravel 12 + Filament 5 + `inova/nova-admin`。
广告收入是站点存在的理由，所以下面「广告契约」一节的优先级高于代码整洁、高于视觉美观。

---

## 一、广告契约（最高优先级）

广告位在 `config/nova-admin.php` 的 `ad_positions` 中枚举，代码由后台或 webdeploy 协议下发，
模板只负责**留出渲染点**。四条硬约定：

1. **head 与 body 必须成对**
   每个投了 `<x-ad-head position="X">` 的页面，必须有对应的 `<x-ad-body position="X">`。
   缺一半不会报错，只是广告永远不展示。`AdTemplateContractTest` 守着这条。

2. **`global_head` 排在所有广告位之后**
   GPT 要求 slot 定义早于 `enableServices`，顺序错了整页广告失效。

3. **浮层位（`anchor` / `interstitial`）必须 `:wrapper="false"`**
   它们自己 `position:fixed`，套上居中容器会破坏布局。

4. **不要靠删模板来关广告**
   没填代码的位不产生任何 DOM（`shouldRender()` 返回 false）。渲染点一律保留，
   展示与否由后台和下发协议决定。要整支关广告用下面的 `$section` 机制。

### 关广告的正确做法

布局里是鸭子类型判断，**不需要任何特定模型**：

```blade
@if (($section ?? null)?->ads_enabled ?? true)
    <x-ad-head position="anchor" />
    <x-ad-body position="anchor" :wrapper="false" />
@endif
<x-ad-head position="global_head" />   {{-- 不受开关影响，始终加载 --}}
```

任何带 `ads_enabled` 属性的对象都能接入：栏目模型加个字段即可；一次性场景直接
`(object) ['ads_enabled' => false]`（静态页和 404 页就是这么做的，见 `AppServiceProvider`）。

`global_head` 刻意放在 `@if` 之外 —— 统计、站点验证这类站点级脚本任何页面都要加载。

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
`ad_positions` 与 `ads_protocol.position_map` 必须同步增删，`AdContractTest` 守着这条。

---

## 二、前台约定

- **面向英文用户**：所有前台可见文案一律英文（`APP_LOCALE=en`）。代码注释用中文。
  后台是中文，别混淆两者。
- **布局** `resources/views/layouts/app.blade.php` 是所有前台页的唯一骨架，
  页眉页脚在此。页脚法务链接按 `is_active` 从库里取，不要硬编码 slug。
- **页眉不用 `sticky`**：顶部 anchor 广告同样固定在视口顶端，两者会互相遮挡。
- **移动端页眉高度控制在 56–64px**，别把首屏广告挤出视口。
- **500 页不继承布局**（`resources/views/errors/500.blade.php`）：
  布局要查 `static_pages` 和 `ad_spots`，而 500 最常见的成因就是数据库不可用，
  继承会导致二次异常、用户看到白屏。这页零依赖、内联样式，改动时保持这条。
- **后台入口 `/admin` 不要挂在前台页面上**，`robots.txt` 已 Disallow。

---

## 三、环境与配置

- **两份 env 模板必须同步**：`.env.example`（LNMP/生产）与 `.env.docker.example`（Sail）。
  `init.sh` 用的是后者，只改前者等于没改。`EnvTemplateContractTest` 比对键集合，
  值可以不同（端口、库名、主机名本就该不同）。Docker 专属键写进该测试的白名单。
- **业务代码不直接用 `env()`**，一律走 `config()`。
- 新项目起步：`./init.sh <项目名>`，它会处理依赖、`.env`、前端构建、起容器、迁移与填充。
- 本地后台账号固定 `nova` / `nova`，这是开发环境约定，不用另建管理员。

---

## 四、改动前后

- 动模板、配置或 env 之前，先看 `tests/Feature/` 下的三个契约测试守着什么：
  `AdContractTest`（配置侧）、`AdTemplateContractTest`（模板侧）、`EnvTemplateContractTest`（env 侧）。
  **它们变红是设计意图，不是障碍** —— 不要为了让测试通过而放宽断言。
- 改了 Blade 或 Tailwind 类名后需要 `npm run build`（或 `sail npm run dev`），否则样式不生效。
- 验广告位排布：`sail artisan ad:seed` 填测试广告，看完 `sail artisan ad:seed --off` 关掉。
- 配置一致性自检：`sail artisan nova-admin:doctor`。

---

## 五、别做这些

- 不要为了「页面太朴素」重写 `layouts/app.blade.php` 的广告渲染点或调整其顺序。
- 不要删 `ad_positions` 里暂时没用上的位（如详情页位），留着备用；
  真要删必须同步删 `position_map`。
- 不要给静态页、错误页加广告位。
- 不要在前台文案里写中文。
- 不要提交 `.env`、密钥或测试数据。
