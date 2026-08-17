<?php

namespace Tests\Unit;

use Inova\NovaAdmin\Database\Seeders\NovaAdminSeeder;
use PHPUnit\Framework\TestCase;

class NovaAdminSeederAutoloadTest extends TestCase
{
    public function test_nova_admin_seeder_is_autoloadable(): void
    {
        $this->assertTrue(class_exists(NovaAdminSeeder::class));
    }
}
