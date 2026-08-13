# Installation (ZH)

> English: `../../getting-started/installation.md`

## 目的

- 为 `console.svc.plus` 准备本地运行环境。
- 用环境变量给 AI 助手和集成功能做默认值预填，而不是把网关配置写死在 UI 里。

## 环境准备

1. 复制示例文件：

```bash
cp .env.example .env
```

2. 如有联调环境，优先参考 `/Users/shenlan/workspaces/cloud-neutral-toolkit/openclaw-deploy-example/.env` 中对应值。

## AI 助手与集成变量

下面这些变量会由服务端读取，并用于以下场景的默认值预填：

- 首页 AI 助手
- 侧栏 AI 助手
- `/panel/api` 集成页

| 变量 | 用途 | 说明 |
|---|---|---|
| `OPENCLAW_GATEWAY_REMOTE_URL` | OpenClaw 助手 | 远端 WebSocket 地址，例如 `wss://openclaw.svc.plus:443` |
| `OPENCLAW_GATEWAY_TOKEN` | OpenClaw 助手 | 服务端桥接 OpenClaw gateway 时使用的令牌 |
| `VAULT_SERVER_URL` | Vault 集成 | Vault 服务地址，用于默认值和连通性探测 |
| `VAULT_NAMESPACE` | Vault 集成 | Vault Enterprise namespace，可选 |
| `VAULT_TOKEN` | Vault 集成 | Vault 探测请求使用的令牌 |
| `APISIX_AI_GATEWAY_URL` | APISIX AI Gateway 集成 | AI gateway 的 HTTP(S) 地址 |
| `AI_GATEWAY_ACCESS_TOKEN` | APISIX AI Gateway 集成 | AI gateway 探测请求使用的访问令牌 |

## 行为说明

- 这些变量不会被硬编码进前端 React 组件。
- 页面中的输入项仍然支持会话级覆盖。
- 变量留空只会取消默认值预填，不会影响现有布局。

## 相关文档

- `../README.md`
- `../usage/config.md`
