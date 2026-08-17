<?php

namespace Tests\Unit;

use Tests\TestCase;

class SiteConfigDefaultsTest extends TestCase
{
    public function test_site_settings_fields_have_defaults(): void
    {
        $defaults = config('nova-admin.site_defaults');

        foreach ([
            'site_name',
            'subtitle',
            'copyright',
            'contact_email',
            'meta_title_template',
            'meta_description',
            'meta_keywords',
            'favicon_path',
            'logo_path',
        ] as $key) {
            $this->assertArrayHasKey($key, $defaults);
        }
    }
}
