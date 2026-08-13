# 补充 Admin 管理控制台选择与进入

> **Status**: ⏳ 代码已推送到 PR #94 并创建 PR，待合并
> **Date**: 2026-07-12
> **Related PRs**: PR #94 (portal)
> **组件**: `src/components/marketing/MarketingNav.tsx`

## 目标

为管理员 (Admin) 和运营者 (Operator) 提供可选的“管理控制台”入口。
- Admin/Operator 用户在登录后，可以在市场页导航栏的账户下拉菜单中切换要进入的控制台（如：Admin 管理面、Operator 运营面、用户中心）。
- 订阅用户（普通用户）保持原样，点击“进入控制台”只能前往默认的用户中心。
- 导航主体 UI 布局基本保持不变。

## 实现

- **状态管理与切换**：
  - 在 `MarketingNav.tsx` 中增加 `activeConsole` 状态，类型为 `"user" | "admin" | "operator"`。
  - 根据登录用户的角色初始化默认控制台：如果是 `isAdmin`，默认为 `"admin"`；如果是 `isOperator`，默认为 `"operator"`；普通用户或未登录默认为 `"user"`。
  - 按钮文字与触发：头像右侧的文字信息如果匹配管理员或运营者，会展示当前选中的控制台模式（如 "Admin"、"Operator"、"用户中心"），点击可以展开下拉选择面板。
- **动态跳转路径**：
  - “进入控制台”按钮的路径根据所选的控制台动态计算（Admin/Operator 管理面指向 `/panel/management`，用户中心指向 `/panel`）。
  - 该逻辑同时应用在桌面端导航及移动端抽屉菜单中。

## 验证

- `npm run build`：构建检查通过，TypeScript 编译零错误，所有动态/静态路由成功生成。
- 登录态与控制台目标解析正常。
