{{--
    前台基础布局 —— 同时是 nova-admin 广告契约的参照样板。

    契约（详见 vendor/inova/nova-admin/README.md）：
      1. 每个广告位的 <x-ad-head> 与 <x-ad-body> 必须成对出现；协议下发时
         head_code 与 body_code 一起给，少一半就会被静默吞掉。
      2. global_head 必须排在所有广告位之后：GPT 要求 slot 定义早于 enableServices。
      3. 浮层位（anchor / interstitial）自己 position:fixed，body 侧必须 :wrapper="false"，
         套居中容器会破坏布局。
      4. 没填代码的位不产生任何 DOM（shouldRender() 返回 false），所以渲染点全都留着，
         展示与否交给后台 / 下发协议决定，不要靠删模板来关广告。

    禁广告的栏目（如医疗急救类）用 $section->ads_enabled 整支关掉；
    $section 缺失的页面（首页、工具页）默认允许。
--}}
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', config('app.name'))</title>

    @vite(['resources/css/app.css', 'resources/js/app.js'])

    @if (($section ?? null)?->ads_enabled ?? true)
        <x-ad-head position="anchor" />
        <x-ad-head position="interstitial" />
    @endif
    {{-- 各页面用 @push('ad-head') 追加自己的广告位（如 home_banner1、detail_banner1） --}}
    @stack('ad-head')
    <x-ad-head position="global_head" />
    @stack('head')
</head>
<body>
    @if (($section ?? null)?->ads_enabled ?? true)
        <x-ad-body position="anchor" :wrapper="false" />
        <x-ad-body position="interstitial" :wrapper="false" />
    @endif
    <x-ad-body position="global_head" :wrapper="false" />

    {{-- 页眉：移动端高度控制在 56~64px，别把首屏广告挤出视口 --}}

    <main>
        @yield('content')
    </main>

    {{-- 页脚：法务五件套链接（隐私政策 / 服务条款 / 关于 / 联系 / Cookie）必须可达 --}}
</body>
</html>
