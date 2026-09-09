<?php

namespace Tests\Feature;

use Tests\TestCase;

class AdTemplateContractTest extends TestCase
{
    /**
     * 模板侧的广告契约。AdContractTest 守的是配置侧（协议映射 → 启用的位），
     * 这里守的是模板侧：后台填了代码、协议也下发了，模板漏投一半照样不展示。
     *
     * 判定按单个 blade 文件做：布局里 anchor / interstitial / global_head 的
     * head 与 body 本来就同文件；页面则是 @push('ad-head') 与 @section('content')
     * 同文件。所以「同文件内成对」就等价于「同页面内成对」，不必去解析
     * @extends / @push 的跨文件关系。
     */
    private const HEAD = 'ad-head';

    private const BODY = 'ad-body';

    public function test_each_template_pairs_ad_head_with_ad_body(): void
    {
        $positions = config('nova-admin.ad_positions');

        foreach ($this->bladeFiles() as $file) {
            $source = file_get_contents($file);
            $name = $this->relative($file);

            // position 必须是字面量，否则静态检查形同虚设，契约也就无从保证。
            $this->assertDoesNotMatchRegularExpression(
                '/<x-ad-(?:head|body)\b[^>]*:position=/',
                $source,
                "{$name} 用了动态 :position，广告位必须写成字面量 position=\"...\""
            );

            $head = $this->positionsOf($source, self::HEAD);
            $body = $this->positionsOf($source, self::BODY);

            foreach (array_diff($head, $body) as $missing) {
                $this->fail("{$name} 投了 <x-ad-head position=\"{$missing}\"> 却没有对应的 <x-ad-body>，后台填的 body 代码永远不会渲染");
            }

            foreach (array_diff($body, $head) as $missing) {
                $this->fail("{$name} 投了 <x-ad-body position=\"{$missing}\"> 却没有对应的 <x-ad-head>，head 代码不加载则该位不出广告");
            }

            foreach ($head as $position) {
                $this->assertArrayHasKey($position, $positions, "{$name} 引用的广告位 {$position} 未在 ad_positions 中启用");
            }
        }
    }

    /** @return list<string> */
    private function positionsOf(string $source, string $component): array
    {
        preg_match_all('/<x-'.$component.'\b[^>]*\bposition="([^"]+)"/', $source, $matches);

        return array_values(array_unique($matches[1]));
    }

    /** @return list<string> */
    private function bladeFiles(): array
    {
        $files = [];

        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator(resource_path('views'), \FilesystemIterator::SKIP_DOTS)
        );

        foreach ($iterator as $file) {
            if (str_ends_with($file->getFilename(), '.blade.php')) {
                $files[] = $file->getPathname();
            }
        }

        $this->assertNotEmpty($files, 'resources/views 下没有找到任何 blade 模板');

        return $files;
    }

    private function relative(string $path): string
    {
        return ltrim(str_replace(base_path(), '', $path), DIRECTORY_SEPARATOR);
    }
}
