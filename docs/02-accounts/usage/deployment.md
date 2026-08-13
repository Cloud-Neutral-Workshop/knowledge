# 部署方式

## 本地或 VM

推荐通过 Makefile 与脚本执行：

```bash
curl -fsSL "https://raw.githubusercontent.com/cloud-neutral-toolkit/accounts.svc.plus/main/scripts/setup.sh?$(date +%s)" \
  | bash -s -- accounts.svc.plus --mode process --deploy

make init-db
make build
make start
```

默认启动脚本 `scripts/start.sh` 使用 `config/account.yaml`。
单机部署脚本 `scripts/install-process.sh` 默认写入 Caddy 配置到 `/etc/caddy/conf.d/accounts.svc.plus.conf`。

## Docker

详见 `getting-started/installation.md`。

初始化命令：

```bash
curl -fsSL "https://raw.githubusercontent.com/cloud-neutral-toolkit/accounts.svc.plus/main/scripts/setup.sh?$(date +%s)" \
  | bash -s -- accounts.svc.plus --mode docker --deploy
```

## Cloud Run

仓库内的 Cloud Run 配置：
- `deploy/gcp/cloud-run/prod-service.yaml`
- `deploy/gcp/cloud-run/preview-service.yaml`
- `config/account.cloudrun.yaml`

初始化命令：

```bash
curl -fsSL "https://raw.githubusercontent.com/cloud-neutral-toolkit/accounts.svc.plus/main/scripts/setup.sh?$(date +%s)" \
  | bash -s -- accounts.svc.plus --mode cloudrun
```

特点：
- 通过 `entrypoint.sh` + `CONFIG_TEMPLATE` 注入配置
- 附带 stunnel sidecar，用于安全连接数据库
- SMTP 凭据通过 Secret 注入

## stunnel（数据库连接）

- 模板：`deploy/stunnel-account-db-client.conf` / `deploy/stunnel-account-db-server.conf`
- Cloud Run 示例：`deploy/gcp/cloud-run/stunnel.conf`

适合在数据库仅允许本地或专线访问的场景。
