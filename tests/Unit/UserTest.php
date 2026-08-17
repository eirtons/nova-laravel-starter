<?php

namespace Tests\Unit;

use App\Models\User;
use Filament\Panel;
use Mockery;
use PHPUnit\Framework\TestCase;

class UserTest extends TestCase
{
    protected function tearDown(): void
    {
        Mockery::close();

        parent::tearDown();
    }

    public function test_only_administrators_can_access_the_admin_panel(): void
    {
        $panel = Mockery::mock(Panel::class);
        $panel->shouldReceive('getId')->andReturn('admin');

        $administrator = new User();
        $administrator->is_admin = true;

        $user = new User();
        $user->is_admin = false;

        $this->assertTrue($administrator->canAccessPanel($panel));
        $this->assertFalse($user->canAccessPanel($panel));
    }
}
