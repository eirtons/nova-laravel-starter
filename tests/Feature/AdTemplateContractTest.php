<?php

namespace Tests\Feature;

use Tests\TestCase;

class AdTemplateContractTest extends TestCase
{
    /**
     * 广告契约由 nova-admin:doctor 统一检查（配置侧 + 模板侧）：
     * 协议映射目标必须启用；内容位 head/body 成对；position 必须是字面量且已启用。
     * 后台填了代码、协议也下发了，模板漏投一半照样不展示，这类漏配没有任何报错。
     */
    public function test_nova_admin_doctor_passes(): void
    {
        $this->artisan('nova-admin:doctor')->assertExitCode(0);
    }
}
