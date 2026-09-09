<?php

namespace Tests\Feature;

use Tests\TestCase;

class EnvTemplateContractTest extends TestCase
{
    /**
     * 两份 env 模板必须保持同步。
     *
     * init.sh（新项目的主初始化路径）用的是 .env.docker.example，而人改配置时
     * 往往只改 .env.example，漏的那半要到部署或排查线上问题时才发现。已经中过两次：
     * NOVA_STATIC_FRONTEND 漏配导致静态页前台路由不开、页脚法务链接全 404；
     * LOG_CHANNEL 漏改导致日志没按天切割。
     *
     * 只比键，不比值——两份模板的端口、库名、主机名本来就该不同。
     */
    private const DOCKER_ONLY = [
        'COMPOSE_PROJECT_NAME',
        'APP_PORT',
        'VITE_PORT',
        'FORWARD_DB_PORT',
        'DB_ROOT_PASSWORD',
        'WWWUSER',
        'WWWGROUP',
    ];

    public function test_env_templates_declare_the_same_keys(): void
    {
        $plain = $this->keysOf('.env.example');
        $docker = $this->keysOf('.env.docker.example');

        $missingInDocker = array_diff($plain, $docker);
        $this->assertSame([], array_values($missingInDocker),
            '.env.docker.example 缺少这些键，init.sh 起的新项目会拿不到：'.implode(', ', $missingInDocker));

        $extraInDocker = array_diff($docker, $plain, self::DOCKER_ONLY);
        $this->assertSame([], array_values($extraInDocker),
            '.env.example 缺少这些键（若确属 Docker 专用，加进 DOCKER_ONLY）：'.implode(', ', $extraInDocker));
    }

    /** @return list<string> */
    private function keysOf(string $file): array
    {
        $path = base_path($file);
        $this->assertFileExists($path);

        preg_match_all('/^([A-Z_][A-Z0-9_]*)=/m', file_get_contents($path), $matches);

        return $matches[1];
    }
}
