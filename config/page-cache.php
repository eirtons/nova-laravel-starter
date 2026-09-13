<?php

return [
    // 浏览器用 max-age，CDN 用 s-maxage；设为 0 可整体关闭。
    // 浏览器那份清不掉（副本在访客机器上）所以给 1 小时；
    // CDN 那份能用 webdeploy 的 cloudflare:purge 随时清，给满一天换命中率。
    'ttl' => (int) env('PAGE_CACHE_TTL', 3600),
    'cdn_ttl' => (int) env('PAGE_CACHE_CDN_TTL', 86400),
];
