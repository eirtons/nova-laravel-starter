<?php

namespace App\Providers;

use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;
use Inova\NovaAdmin\Models\StaticPage;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // 页脚法务链接。硬编码 slug 会在后台停用某页后指向 404，所以按启用状态取，
        // 顺序由 static_pages.presets 决定（后台新增的页排在预置页之后）。
        View::composer('layouts.app', function ($view): void {
            $order = array_keys(config('nova-admin.static_pages.presets', []));

            $view->with('footerPages', StaticPage::query()
                ->where('is_active', true)
                ->get(['slug', 'title'])
                ->sortBy(fn (StaticPage $page) => array_search($page->slug, $order, true) === false
                    ? PHP_INT_MAX
                    : array_search($page->slug, $order, true))
                ->values());
        });

        // 静态页（法务五件套等）不出浮层广告：插屏弹在隐私政策页上，体验与审核观感都差。
        // 复用布局既有的 $section->ads_enabled 开关，global_head 不受影响。
        View::composer('pages.show', function ($view): void {
            $view->with('section', (object) ['ads_enabled' => false]);
        });
    }
}
