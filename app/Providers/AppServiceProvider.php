<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

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
        // 页脚法务链接（$footerPages）与静态页 / 404 关广告由 nova-admin 注入，
        // 见 nova-admin.static_pages.footer_views 与 nova-admin.ad_disabled_views。
    }
}
