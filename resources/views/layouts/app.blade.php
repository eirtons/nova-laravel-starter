{{--
    前台基础布局 —— 同时是 nova-admin 广告契约的参照样板。

    契约（详见 vendor/inova/nova-admin/README.md）：
      1. 布局级位（anchor / interstitial 等浮层、脚本类，以及 global_head）由
         <x-ad-layout-head /> 与 <x-ad-layout-body /> 统一输出：global_head 固定最后、
         浮层不套容器，nova-admin 新增此类位后升级即生效，不用改这里。
      2. 页面的 @stack('ad-head') 必须写在 <x-ad-layout-head /> 之前：
         GPT 要求 slot 定义早于 global_head 里的 enableServices。
      3. 内容位（banner）由页面模板放置，<x-ad-head> 与 <x-ad-body> 必须成对。
      4. 没填代码的位不产生任何 DOM，渲染点全都留着，展示与否交给后台 / 下发协议决定，
         不要靠删模板来关广告。
    AdTemplateContractTest 与 php artisan nova-admin:doctor 守着第 3 条。

    SEO：<x-nova-seo /> 按后台「站点设置」输出 title / description / canonical / favicon / OG，
    页面只写 @section('title', '页面标题')，站点名由标题模板拼上；description、canonical、og_image 同理可覆盖。

    禁广告的栏目（如医疗急救类）用 $section->ads_enabled 整支关掉；
    $section 缺失的页面（首页、工具页）默认允许。注意 starter 未自带 Section 模型，
    有栏目级开关需求的项目要自己建模并向视图传 $section。
--}}
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" class="scroll-smooth">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <x-nova-seo />

    @vite(['resources/css/app.css', 'resources/js/app.js'])

    {{-- 各页面用 @push('ad-head') 追加自己的广告位（如 home_banner1、detail_banner1） --}}
    @stack('ad-head')
    {{-- enabled=false 时只输出 global_head：统计、站点验证这类站点级脚本任何页面都要加载 --}}
    <x-ad-layout-head :enabled="($section ?? null)?->ads_enabled ?? true" />
    @stack('head')
</head>
<body class="flex min-h-screen flex-col bg-white font-sans text-neutral-900 antialiased">
    <x-ad-layout-body :enabled="($section ?? null)?->ads_enabled ?? true" />

    {{-- 页眉：移动端高度控制在 56~64px，别把首屏广告挤出视口。
         刻意不用 sticky —— 顶部 anchor 广告同样固定在视口顶端，两者会互相遮挡。 --}}
    <header class="border-b border-neutral-200">
        <div class="mx-auto flex h-14 max-w-5xl items-center justify-between px-4 sm:h-16 sm:px-6">
            <a href="{{ url('/') }}" class="text-base font-semibold tracking-tight text-neutral-900 hover:text-neutral-600">
                @if ($logo = site_media_url('logo_path'))
                    <img src="{{ $logo }}" alt="{{ site_setting('site_name') }}" class="h-8 w-auto">
                @else
                    {{ site_setting('site_name') }}
                @endif
            </a>
            {{-- 栏目导航：新项目在此加自己的入口 --}}
            <nav class="flex items-center gap-5 text-sm text-neutral-600"></nav>
        </div>
    </header>

    <main class="mx-auto w-full max-w-5xl flex-1 px-4 py-8 sm:px-6 sm:py-12">
        @yield('content')
    </main>

    {{-- 页脚：法务五件套链接（隐私政策 / 服务条款 / 关于 / 联系 / Cookie）必须可达 --}}
    <footer class="mt-8 border-t border-neutral-200 bg-neutral-50">
        <div class="mx-auto max-w-5xl px-4 py-8 sm:px-6">
            @if (($footerPages ?? collect())->isNotEmpty())
                <nav class="flex flex-wrap gap-x-5 gap-y-2 text-sm text-neutral-600">
                    @foreach ($footerPages as $page)
                        <a href="{{ url('/'.$page->slug) }}" class="hover:text-neutral-900 hover:underline">{{ $page->title }}</a>
                    @endforeach
                </nav>
            @endif
            <p class="mt-6 text-xs text-neutral-500">{{ site_setting('copyright') }}</p>
        </div>
    </footer>
</body>
</html>
