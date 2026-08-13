# Release Process (ZH)

> English: `../../governance/release-process.md`

本页用于记录公开控制台在 `www.svc.plus` 与 `console.svc.plus` 下发布版本的说明与变更摘要。

## 当前版本

### v0.2

发布标签：`v0.2`  
发布分支：`release/v0.2`  
发布提交：`0fab89e`

#### 亮点

- 引入新的 XWorkmate 工作区，助手布局更紧凑，工作区外壳更统一，入口流程也更顺滑。
- 新增 OpenClaw assistant workspace 与 pairing bridge，支持可配置的 origin override，并改进了配对失败时的回退行为。
- 统一导航与 AI 入口，加入持久化 assistant sidebar，并梳理 panel 路由。
- 首页增加最新博客快捷入口，同时优化游客模式与注册引导文案。
- 双语文档结构继续补齐，OIDC 接入文档和安装说明也更完整。
- 修复构建稳定性问题，包括 `next-mdx-remote` 相关的漏洞拦截构建错误，以及 Yarn 依赖元数据对齐问题。

#### 新特性

- 上线 XWorkmate 工作区，并完善其入口与界面布局。
- 增加 OpenClaw assistant 集成、pairing bridge、integration probe API，以及 integration defaults 处理能力。
- 在服务页加入 XScopeHub MCP 服务可见性。
- 首页快捷区展示最新 7 篇博客文章标题。

#### 体验改进

- 将 observability 工作区拆分为 tri-view，并优化 panel 助手路由。
- 统一导航结构与持久化 AI sidebar 行为。
- 登录与注册流程改为使用服务端解析后的 account service URL。
- 体验与演示模式不得在公开 UI 或会话载荷中暴露其后端承载账号身份。
- 为集成配置增加基于 vault 的 token 查询能力。

#### 文档与安装

- 增补双语文档覆盖，并整理文档入口结构。
- 重写 OIDC 认证接入文档，补充更完整的配置说明。
- 更新安装指导并精简 README 结构。

#### 构建与依赖修复

- 对齐并升级 `next-mdx-remote` 使用方式，确保构建安全。
- 移除冲突的 npm 锁文件状态，并整理 Yarn 依赖元数据，提升构建可复现性。

## 备注

- GitHub Release：`https://github.com/x-evor/console.svc.plus/releases/tag/v0.2`
- 发布校验必须同时验证 `www.svc.plus` 与 `console.svc.plus` 的 `releaseImageRef`、`releaseImageTag`、`releaseCommit` 完全一致。
- `www.svc.plus` 是 metadata、sitemap、`dashboardUrl` 与公开分享链接的首选域名。
- 相关文档：`docs/README.md`、`docs/en/README.md`、`docs/zh/README.md`
