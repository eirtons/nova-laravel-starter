<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| 前台公开路由
|--------------------------------------------------------------------------
| 这些路由刻意不挂 web 中间件组：不启会话、不下发 XSRF Cookie。
| 带 Cookie 的响应 Cloudflare 一律按 DYNAMIC 处理、每次回源，
| 去掉会话后配合 CacheablePage 的 Cache-Control，边缘才能真正命中。
|
| 只读的前台页面都写在这里。以下情况必须留在 routes/web.php：
|   - 页面里有 @csrf 表单（CSRF token 存在 session 里）
|   - 依赖 auth() 判断登录态
|   - 用到 session() 写入或 flash 消息
|   - 用 request()->validate()（失败时要重定向 + 闪存错误，无会话会 500）
*/

Route::get('/', function () {
    return view('home');
})->name('home');
