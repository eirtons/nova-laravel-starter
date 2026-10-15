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

    public function test_static_page_without_meta_description_closes_its_output_buffers(): void
    {
        // DatabaseSeeder 用 WithoutModelEvents，seed 出来的静态页 meta_description 为 null。
        // @section('description', null) 会被 Blade 当成块级 section 开头，ob_start 永不关闭。
        $this->seed();
        \Inova\NovaAdmin\Models\StaticPage::query()->where('slug', 'about')->update(['meta_description' => null]);
        $level = ob_get_level();

        $this->get('/about')->assertOk();

        $this->assertSame($level, ob_get_level());
    }
}
