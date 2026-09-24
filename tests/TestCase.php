<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // 测试不依赖前端构建产物：create-project 后或 CI 里没跑 npm run build 时，
        // 布局里的 @vite 会因找不到 manifest 直接 500。
        $this->withoutVite();
    }
}
