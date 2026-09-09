{{--
    静态页前台模板（config nova-admin.static_pages.frontend.view 指向这里），
    替换包内兜底模板，让法务五件套与站点共用同一套页眉页脚。

    模板契约：$page->title / $page->body_html（已剥标题 H1）/ $page->meta_description。

    这类页面不投任何内容广告位：正文稀薄，投 banner 既无收益也踩政策线。
    浮层位（anchor / interstitial）由 AppServiceProvider 注入的 $section->ads_enabled=false
    关掉——插屏弹在隐私政策页上，体验和审核观感都差；global_head 不受该开关影响，
    站点级脚本（统计、站点验证）照常加载。
--}}
@extends('layouts.app')

@section('title', $page->title.' - '.site_config('site_name', config('app.name')))
@section('description', $page->meta_description)

@push('head')
    <link rel="canonical" href="{{ url('/'.$page->slug) }}">
@endpush

@section('content')
    <article class="max-w-2xl">
        <h1 class="text-2xl font-semibold tracking-tight text-neutral-900 sm:text-3xl">{{ $page->title }}</h1>

        {{-- 富文本正文：未引入 typography 插件，用任意变体给后台产出的标签配基础排版 --}}
        <div class="mt-6 text-base leading-7 text-neutral-700
                    [&_h2]:mt-8 [&_h2]:text-lg [&_h2]:font-semibold [&_h2]:text-neutral-900
                    [&_h3]:mt-6 [&_h3]:text-base [&_h3]:font-semibold [&_h3]:text-neutral-900
                    [&_p]:mt-4
                    [&_ul]:mt-4 [&_ul]:list-disc [&_ul]:pl-6
                    [&_ol]:mt-4 [&_ol]:list-decimal [&_ol]:pl-6
                    [&_li]:mt-1
                    [&_a]:text-blue-600 [&_a]:underline hover:[&_a]:text-blue-800
                    [&_img]:mt-4 [&_img]:h-auto [&_img]:max-w-full">
            {!! $page->body_html !!}
        </div>
    </article>
@endsection
