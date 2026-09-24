<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FrontendSmokeTest extends TestCase
{
    // 布局要查 site_configs、static_pages、ad_spots
    use RefreshDatabase;

    public function test_home_page_renders_with_site_seo(): void
    {
        $this->get('/')
            ->assertOk()
            ->assertSee('<title>'.e(site_setting('site_name')), false)
            ->assertSee('<link rel="canonical"', false);
    }

    public function test_missing_page_renders_the_404_template(): void
    {
        $this->get('/definitely-missing')
            ->assertNotFound()
            ->assertSee('Page not found');
    }
}
