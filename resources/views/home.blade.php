{{--
    首页（路由 home）—— 同时是「页面级广告位怎么投放」的参照样板。

    投放方式：head 侧用 @push('ad-head') 追加，body 侧在内容里的实际展示位置写。
    两侧的 position 必须一一对应，AdTemplateContractTest 会守住这条。
    换成真实首页时改 content 里的内容即可，广告位保持原样。
--}}
@extends('layouts.app')

@section('description', site_config('site_description', config('nova-admin.static_pages.site_description')))

@section('content')
    <section class="max-w-2xl">
        <h1 class="text-3xl font-semibold tracking-tight text-neutral-900 sm:text-4xl">
            {{ site_config('site_name', config('app.name')) }}
        </h1>
        <p class="mt-4 text-base leading-7 text-neutral-600">
            {{ site_config('site_description', config('nova-admin.static_pages.site_description')) }}
        </p>
        <div class="mt-6 flex flex-wrap gap-3">
            <a href="{{ url('/admin') }}"
               class="rounded-md bg-neutral-900 px-4 py-2 text-sm font-medium text-white hover:bg-neutral-700">
                进入后台
            </a>
        </div>
    </section>

    {{-- 首屏 Banner：排在首屏内容之后，别把内容挤出视口 --}}
    <x-ad-body position="home_banner1" />

    <section class="mt-10 grid gap-4 sm:grid-cols-3">
        {{-- 内容卡片占位：新项目换成自己的列表 / 工具入口 --}}
        @foreach (range(1, 3) as $i)
            <article class="rounded-lg border border-neutral-200 p-5">
                <h2 class="text-sm font-medium text-neutral-900">内容位 {{ $i }}</h2>
                <p class="mt-2 text-sm leading-6 text-neutral-500">
                    替换为实际内容。布局与广告位的相对关系保持不变即可。
                </p>
            </article>
        @endforeach
    </section>

    <x-ad-body position="home_banner2" />
@endsection

@push('ad-head')
    <x-ad-head position="home_banner1" />
    <x-ad-head position="home_banner2" />
@endpush
