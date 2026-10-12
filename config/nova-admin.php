<?php

/*
|--------------------------------------------------------------------------
| nova-admin 站点差异配置
|--------------------------------------------------------------------------
| 包内 config/nova-admin.php 是出厂底座，这里只写本站与之不同的部分：
| 升级 inova/nova-admin 后，包新增的广告位、协议映射等配置自动继承。
|
| 合并规则：
| - 关联数组逐键合并：写一行就覆盖/追加一项；
| - 列表（如 sitemap.urls、favicon.accepted_types）整体替换；
| - 空数组等于没写；
| - 写 false 删除包内的键（包里是布尔值的键除外，那就是普通的关闭）。
|
| 完整配置项见 vendor/inova/nova-admin/config/nova-admin.php，
| 或 php artisan vendor:publish --tag=nova-admin-config 导出查看（导出后请改回差异写法）。
| 改完跑 php artisan nova-admin:doctor 自检。
*/

return [

    /*
    | 建站预设：首次 seed 会随机分配领域 / 主题等的项目，登记后 webdeploy 发起建站时可下拉预选。
    | Provider 实现 Inova\NovaAdmin\SitePresets\SitePresetProvider；seeder 写 site_preset('theme') ?? 原随机。
    | 改了清单后运行 php artisan nova-admin:export-site-presets 并提交 site-presets.json（doctor 守一致）。
    */
    'site_presets' => [
        // 'theme' => [
        //     'label'    => '主题',
        //     'provider' => App\Support\SitePresets\ThemePresetProvider::class,
        //     'initial'  => env('NOVA_PRESET_THEME'),
        // ],
    ],

    /*
    | 本站专属广告位：追加一行；去掉包内的位写 false，
    | 并同步处理 ads_protocol.position_map 里指向它的键。
    */
    'ad_positions' => [
        // 'custom_spot'  => '专属广告位',
        // 'interstitial' => false,
    ],

    'ads_protocol' => [
        'position_map' => [
            // 'custom_spot'  => 'custom_spot',
            // 'interstitial' => false,
        ],
    ],

    /*
    | 布局级（浮层 / 脚本类）广告位，由 <x-ad-layout-head/body /> 自动输出。
    */
    'ad_layout_positions' => [
        // 'custom_float' => true,
    ],

    /*
    | 静态页用项目模板替代包内兜底模板，使法务五件套与主站共用 layouts/app.blade.php 页眉页脚。
    */
    'static_pages' => [
        'frontend' => [
            'view' => 'pages.show',
        ],
    ],

];
