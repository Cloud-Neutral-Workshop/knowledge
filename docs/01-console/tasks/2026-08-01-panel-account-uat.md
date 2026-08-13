# `/panel/account` UAT 页面补全

> **Status**: ⏳ 代码完成 + 定向验证,PR #132 待审阅与认证浏览器视觉复核
> **Date**: 2026-08-01
> **Related PRs**: [#132 OPEN](https://github.com/ai-workspace-services/portal/pull/132)
> **组件**: `src/modules/extensions/builtin/user-center/routes/account.tsx` + account panel components

## 目标

参考 XStream Dashboard 截图补全 `/panel/account` 的信息层级，覆盖订阅/配额、VLESS 连接/节点、策略与安全；严格保留现有功能与 API，不伪造后端未提供的数据。

## 实现

- 增加账户页分区骨架：账户概览、订阅与配额、VLESS 连接与节点、策略与安全。
- 将 VLESS QR 从账户资料卡中移至连接区，旁边展示 agent API 返回的节点配置。
- 节点区只显示 `name`、`address`、`server_name`、端口、协议和真实数量；不显示未由 API 提供的在线、延迟、负载或审计数据。
- 将现有 usage、billing ledger、subscription record 的展示分成明确的配额、流水、订阅记录层级，保留 Stripe 客户门户与取消订阅行为。
- 增加策略快照和 MFA 状态卡；MFA/service readiness 原有绑定流程未改动。

## Decision Log

- 组件边界：用 `AccountSection` 负责稳定分区骨架，连接与策略分别拆成独立展示组件，避免继续扩大 `UserOverview` 职责。
- 状态位置：节点刷新/加载沿用 SWR key `user-center-agent-nodes`；策略沿用 `account-policy`；不新增可推导业务状态。
- 兼容性：保留原 API、SWR key、VLESS QR 生成、Stripe 和 MFA 入口；`UserOverview.hideVless` 仅用于账户页组合，并保留只读角色不可修改 MFA 的边界。
- 风险/回滚：主要风险是新分区的真实浏览器视觉差异；可整体回滚本 PR，不涉及后端或部署配置。

## 验证

- `vitest` 定向测试：4 个测试文件、4 个测试通过。
- 目标文件 ESLint：通过。
- `tsc --noEmit`：被仓库既有 contentlayer 生成文件缺失阻塞（`docs-home/open-platform/xstream/xworkmate`），未出现本次改动文件的错误。
- `design-qa.md`：已记录源截图；因当前环境无可用认证浏览器，implementation screenshot 无法获取，`final result: blocked`。

## 遗留待办

- [ ] 使用认证浏览器在相同 desktop viewport 打开 `/panel/account`，完成全视图与连接/配额/安全焦点对照。
- [ ] 复核主要交互、console errors 与真实 API 数据态。
- [ ] PR 审阅通过后再由维护者合并；本任务不合并、不部署。
