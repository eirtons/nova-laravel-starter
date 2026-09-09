{{--
    404 页。继承站点布局，让失效链接与爬虫命中也落在正常骨架里（页脚法务链接可达）。

    不投任何广告位：错误页没有实质内容，AdSense 明令禁止在此类页面投放。
    浮层位由 AppServiceProvider 注入的 $section->ads_enabled=false 关掉，
    内容位这里根本不写。500 页不同——见 500.blade.php 的说明。
--}}
@extends('layouts.app')

@section('title', 'Page Not Found - '.site_config('site_name', config('app.name')))

@section('content')
    <section class="max-w-xl py-8">
        <p class="text-sm font-medium text-neutral-400">404</p>
        <h1 class="mt-2 text-2xl font-semibold tracking-tight text-neutral-900 sm:text-3xl">Page not found</h1>
        <p class="mt-4 text-base leading-7 text-neutral-600">
            The page you are looking for does not exist or has been moved.
        </p>
        <a href="{{ route('home') }}"
           class="mt-6 inline-block rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-700">
            Back to home
        </a>
    </section>
@endsection
