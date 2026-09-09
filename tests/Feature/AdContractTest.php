<?php

namespace Tests\Feature;

use Tests\TestCase;

class AdContractTest extends TestCase
{
    /**
     * 协议下发的每个广告位都必须是本站启用的位，否则平台一勾到没启用的位，
     * ads:import-site-ad-config 就整体失败——而且报错只在部署时才看得到。
     *
     * 裁剪 config/nova-admin.php 的 ad_positions 是这条最常见的破坏方式；
     * 整块删掉 ads_protocol 更隐蔽：mergeConfigFrom 是浅合并，该键会回落到
     * 包默认值，配置文件里看不见，运行时却在生效。
     */
    public function test_every_ad_protocol_target_is_an_enabled_position(): void
    {
        $positions = config('nova-admin.ad_positions');

        foreach (config('nova-admin.ads_protocol.position_map') as $key => $target) {
            $this->assertArrayHasKey($target, $positions, "协议键 {$key} 映射的广告位 {$target} 未在 ad_positions 中启用");
        }
    }
}
