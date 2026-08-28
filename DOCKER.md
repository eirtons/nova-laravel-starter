# 本地 Docker 开发（Laravel Sail）

## 一键初始化

```bash
./init.sh                 # 首次初始化：装依赖 → 生成 .env → 起容器 → 迁移 + 填充
./init.sh nova-laravel-starter --reset   # 推倒重来（会删除数据卷！）
```

`init.sh` 只在 `.env` 不存在（或不含 `COMPOSE_PROJECT_NAME`）时才从 `.env.docker.example` 生成，
已有配置不会被覆盖。

作为项目模板，`init.sh` 接受项目名参数，会自动改写 `.env` 里的
`COMPOSE_PROJECT_NAME` / `APP_NAME` / `DB_DATABASE`：

```bash
./init.sh MyNewSite     # 容器前缀 mynewsite，数据库 mynewsite
```

## 端口分配

本机多个 Laravel 项目并存，本项目占用：

| 用途 | 宿主机端口 |
| --- | --- |
| 应用 HTTP | 8014 |
| Vite | 5187 |
| MySQL | 33075 |

改端口只需编辑 `.env` 里的 `APP_PORT` / `VITE_PORT` / `FORWARD_DB_PORT`，然后 `sail up -d`。
所有端口都只绑定 `127.0.0.1`，不对外暴露。

## 常用命令

```bash
./vendor/bin/sail up -d          # 启动
./vendor/bin/sail down           # 停止（保留数据）
./vendor/bin/sail down -v        # 停止并删除数据卷
./vendor/bin/sail ps             # 查看容器
./vendor/bin/sail logs -f        # 跟踪日志
./vendor/bin/sail artisan tinker
./vendor/bin/sail composer install
./vendor/bin/sail npm run dev    # Vite 热更新（需 .env 中 VITE_PORT 一致）
./vendor/bin/sail test           # 跑测试
```

把 `alias sail='./vendor/bin/sail'` 加进 shell 配置会方便很多。

## 可选服务（profile）

默认只起 `laravel.test` + `mysql`。队列和调度器按需启动：

```bash
./vendor/bin/sail --profile queue up -d       # 加 queue:work
./vendor/bin/sail --profile scheduled up -d   # 加 schedule:work
```

## 连接数据库

```bash
mysql -h 127.0.0.1 -P 33075 -u sail -psail nova_laravel_starter
```

容器内 `DB_HOST=mysql`；宿主机 GUI 工具用 `127.0.0.1:33075`。

## 注意

- `.env` 中含空格的值必须加引号（例如 `APP_NAME="Nova Starter"`），否则容器会因
  dotenv 解析失败反复重启并返回 503。
- 改完 `.env` 后需 `./vendor/bin/sail restart laravel.test` 才生效。
