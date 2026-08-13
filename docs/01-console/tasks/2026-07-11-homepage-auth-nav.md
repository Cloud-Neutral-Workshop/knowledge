# 主页导航登录态显示

> **Status**: ⏳ 代码完成 + 本地验证,待合并部署
> **Date**: 2026-07-11
> **Related PRs**: 本 PR(portal)
> **组件**: `src/components/marketing/MarketingNav.tsx` + `src/components/marketing/content.ts`

## 目标

console.svc.plus 主页导航固定显示"登录",即使用户已登录也不变。改为按登录态渲染:**已登录就不显示"登录",改显示用户态并支持退出切换**。

## 实现

- 接入现有 `useUserStore`(zustand,与 panel `Navbar.tsx` 同一 store,含 `user`/`isLoading`/`logout`)
- 导航右上角三分支(桌面 + 移动端):
  - **加载中** → 骨架圆点(避免"登录"闪现后消失)
  - **未登录** → `登录` + `进入控制台`(原样)
  - **已登录** → 账户 chip(头像首字母 + 用户名,下拉含"退出登录")+ `进入控制台`,**隐藏"登录"**
- `content.ts` nav 增 `logout` 文案(zh "退出登录" / en "Sign out")
- 账户下拉接入原有点击外部关闭 + Esc 逻辑

## 验证

- `tsc --noEmit`:全量 0 error
- 本地 `next dev` HTTP 200,首页渲染正常
- 未登录态实测截图:显示 `登录` + `进入控制台`,无 console 错误
- 三分支逻辑(skeleton/login/chip)浏览器内断言:全对(chip → 首字母、用户名)
- 已登录态本地无真实 session,用逻辑断言 + 与 `Navbar.tsx` 相同 null-safe 字段用法确认

## 遗留待办

- [ ] 合并部署到 console.svc.plus(portal pipeline → `ghcr.io/ai-workspace-services/console` → `portal-dashboard` 容器)
- [ ] 部署后线上实测已登录态(用真实 session 确认 chip + 退出)
