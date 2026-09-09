{{--
    500 页。刻意【不】继承 layouts.app —— 那份布局会查数据库：页脚法务链接要读
    static_pages，每个广告位要读 ad_spots。而 500 最常见的成因恰恰就是数据库不可用，
    此时渲染错误页会二次抛异常，用户看到的是白屏而不是这一页。

    所以这里零依赖：内联样式、不查库、不投广告、不读 site_config。
    改这页时保持这条——好看远不如「任何情况下都渲染得出来」重要。
--}}
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex">
    <title>Service Unavailable</title>
    <style>
        body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
               font-family: system-ui, -apple-system, "Segoe UI", sans-serif; color: #171717; background: #fff; }
        .box { max-width: 32rem; padding: 0 1.5rem; }
        .code { font-size: .875rem; font-weight: 500; color: #a3a3a3; margin: 0; }
        h1 { font-size: 1.5rem; line-height: 1.25; margin: .5rem 0 0; }
        p { font-size: 1rem; line-height: 1.75; color: #525252; margin: 1rem 0 0; }
        a { display: inline-block; margin-top: 1.5rem; padding: .5rem 1rem; border-radius: .375rem;
            background: #171717; color: #fff; font-size: .875rem; font-weight: 500; text-decoration: none; }
        a:hover { background: #404040; }
    </style>
</head>
<body>
    <div class="box">
        <p class="code">500</p>
        <h1>Service unavailable</h1>
        <p>Something went wrong on our end. Please try again later.</p>
        <a href="{{ url('/') }}">Back to home</a>
    </div>
</body>
</html>
