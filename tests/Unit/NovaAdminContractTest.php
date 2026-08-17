<?php

namespace Tests\Unit;

use Tests\TestCase;

class NovaAdminContractTest extends TestCase
{
    public function test_starter_keeps_the_documented_local_admin_credentials(): void
    {
        $this->assertSame('nova', config('nova-admin.admin.default_name'));
        $this->assertSame('nova', config('nova-admin.admin.default_password'));
    }
}
