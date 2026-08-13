# 部署

## 生产基线

- 运行拓扑: `Caddy + Docker Compose`
- 目标主机: `root@jp-xhttp-contabo.svc.plus`
- 域名:
  - `www.svc.plus`
  - `console.svc.plus`
- 公开首选域名: `www.svc.plus`
- 前端独立发布流水线: `.github/workflows/pipeline.yaml`

## 运行方式

前端镜像在 GitHub Actions 中完成构建并推送到镜像仓库，目标主机只负责拉取镜像和启动容器，不在机器上本地构建。

`yarn prebuild` 现在只生成 console 自己的营销内容工件。`/docs` 与 `/blogs` 不再把 `knowledge/` 或 Markdown 文档打进前端镜像，而是在请求时通过服务端 `docsServiceClient` 从 `docs.svc.plus` 拉取渲染后的内容。

当前方案尽量以静态模式运行：

- Caddy 直接服务 `/_next/static/*` 与 `public/` 里的静态资源，并配合 `frontend_static` 共享卷。
- Next.js standalone 容器只承接动态页面、认证接口和代理接口，`frontend-assets` 任务会把所有静态文件（包括哈希后的 CSS/JS）拷贝到 `frontend_static`。
- `docs.svc.plus` 是 docs/blog 的运行时内容源，浏览器不会直接访问它。

发布由 `.github/workflows/pipeline.yaml` 驱动，CI 构建/推送镜像、渲染包含 `DOCS_SERVICE_URL` / `DOCS_SERVICE_INTERNAL_URL` 的 `.env.runtime`，然后将 `docker-compose.yml`、`Caddyfile` 与运行时环境文件发送到主机。随后控制平面 DNS 自动化会通过 `scripts/github-actions/update-release-dns.sh` 更新 Cloudflare DNS，使当前生产主机 `jp-xhttp-contabo.svc.plus` 承载更新后的环境。

这是针对弱 IO 单机主机 `root@jp-xhttp-contabo.svc.plus` 的部署权衡：主机不会在本地构建镜像，只需登录 GHCR、拉取 `dashboard` 镜像、解包静态资源到 `frontend_static`，再通过 `docker compose` 启动 `dashboard` 与 `caddy`。

`docs.svc.plus` 已经是前端 docs/blog 内容的独立服务。

当前发布合同要求：

- `CANONICAL_DOMAIN=www.svc.plus`
- `SERVED_DOMAINS=www.svc.plus,console.svc.plus`
- 流水线必须同时校验两个域名的首页静态资源与 `/api/ping` 版本元数据完全一致
- `dashboardUrl`、canonical、structured data 与 sitemap 默认统一输出 `https://www.svc.plus`

## 相关文档

- `usage/deployment.md`
- `governance/release-process.md`
- `development/dev-setup.md`
