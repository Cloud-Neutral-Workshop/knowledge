# 添加产品与服务矩阵宣传页面及优化 AI 工作区布局

> **Status**: ⏳ 代码已推送到 PR #93 并创建 PR，待合并
> **Date**: 2026-07-12
> **Related PRs**: PR #93 (portal)
> **组件**: `src/app/products/*`, `src/app/ai-workspace/*`, `src/components/marketing/*`, `src/components/ai-workspace/*`

## 目标

1. 新增三个公开的产品与服务宣传路由页面：`/products/xstream`、`/products/xworkmate` 和 `/products/open-platform`，移除 deprecate 的助手对话框。
2. 合并 SaaS 前端与加速域展示为 Xstream Platform。
3. 建立 `/ai-workspace` 新路由实现 Web 版 of XWorkmate-app（对接 `xworkmate-bridge`），并精简样式，使其字体和风格与主控制台保持一致，避免文字被极度挤压折行。
4. 首页中去除 placeholder，以轮播卡片形式展示 Open-platform 相关的连线拓扑图与架构图，调整文案突出产品服务矩阵与开源平台解决方案。

## 实现

- **路由与页面添加**：
  - 新建 `/products/xstream/page.tsx`、`/products/xworkmate/page.tsx`、`/products/open-platform/page.tsx` 页面。
  - 同步 open-platform 相关图片 `unified-open-control-plane.png`、`four-trusted-foundations.png` 和 `secure-delivery-lifecycle.png` 并用 Carousel 在页面及首页卡片中展示。
- **AI 工作区与代理**：
  - 创建 `/ai-workspace` 页面与布局。
  - 新建 `/api/ai-workspace/bridge/route.ts` 作为代理，调用用户的 `${ACCOUNT_API_BASE}/xworkmate/profile` 自动提取 `bridgeUrl` 和 `bridgeToken`，中转 RPC 请求以规避 CORS 与敏感 Token 暴露。
  - 对 `/ai-workspace` 的 UI 样式进行缩放，统一为控制台标准的 `text-sm`/`text-xs`、紧凑的间距、`w-64` 的侧边栏，优化任务列表布局为 Flex 适应响应式宽度，移除了 Mock 数据（无数据时显示“暂无任务”）。
- **首页文案调整**：
  - 更新 `src/components/marketing/content.ts` 头部文案，突出产品矩阵与开源解决方案。

## 验证

- `npm run build`：全量构建成功，没有 TypeScript 类型与 Next.js 构建错误。
- 本地静态编译及路由映射完整无误。
