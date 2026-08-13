# 首页“从对话到交付”重构实施计划

## 目标

将首页主体重构为结果导向的七段式叙事，同时保持顶部 `MarketingNav` 原样不动。完成后，访问者应能在一次滚动中理解 AI Workspace 如何计划工作、连接能力、推动交付并保持可控。

设计基线见 [首页设计语言：从对话到交付](../design/homepage-conversation-to-delivery.md)。

## 实施状态

- P1 已完成并合并：首屏价值主张、Plan / Connect / Deliver 三项核心能力。
- P2 已完成：Web / Desktop / Mobile 三端轮播与创建 → 连接 → 执行 → 交付工作流。
- P3 已完成：安全、权限、连接、部署控制能力，产品事实区和最终双 CTA。
- 文档侧栏预目录需求已撤回，本次不修改 `/docs` 左侧导航。

## 现状与改造边界

当前首页按 `HeroSection → StatsBar → ProductGrid → BenefitList → InviteBanner → PricingTeaser` 排列。它已具备语言状态、营销主题和轮播组件，但区块内容仍按产品/泛用卖点分散组织。

本次改造：

- 保留：`MarketingNav`、`Footer`、`LanguageProvider`、既有主/次 CTA 样式和当前六张轮播素材。
- 替换或迁移：首屏内容、产品网格、卖点列表、邀请横幅、定价引导的首页职责。
- 新增：核心能力、三端轮播、工作流、控制能力、产品事实与用户证明、最终 CTA 的独立区块。
- 不改：顶部导航信息架构、登录/退出、角色选择、语言切换、现有产品页和控制台路由。

## 目标页面结构

```text
MarketingNav（不变）
├── OutcomeHeroSection
├── CoreCapabilitiesSection（Plan / Connect / Deliver）
├── EditionsCarouselSection（中文三张 / 英文三张）
├── WorkflowSection（创建 → 连接 → 执行 → 交付）
├── ControlPlaneSection（安全 / 权限 / 连接 / 部署）
├── ProofSection（产品事实 / 客户证明）
├── FinalCtaSection（进入控制台 / 查看产品）
└── Footer（保留）
```

## 内容模型

将首页专属内容集中在 `src/data/content/home-marketing.ts`，并在 `HomeMarketingContent` 中补充下面的结构。组件只负责展示，不内嵌中英文文案。

```ts
homepage: {
  outcomeHero: { title: string[]; description: string; primaryCta; secondaryCta; visual }
  coreCapabilities: Array<{ key: "plan" | "connect" | "deliver"; title; description; evidence }>
  editions: { title; description; slides: Array<{ src; alt; label }> }
  workflow: { title; description; steps: Array<{ number; title; description; evidence }> }
  controls: Array<{ key: "security" | "permissions" | "connections" | "deployment"; title; description; evidence }>
  proof: { facts: Array<{ value; label; source? }>; testimonials: Array<{ quote; name; role; logo? }> }
  finalCta: { title; description; primaryCta; secondaryCta }
}
```

`proof` 中的事实和引言在没有可靠来源前应以空数据处理，组件不要渲染空状态卡片。上线前由产品/运营提供可公开引用的事实和授权文案。

## 实施步骤

### P1：内容与组件骨架

1. 在内容类型和中文/英文数据中加入目标页面结构。
2. 创建 `OutcomeHeroSection`，将当前 `HeroSection` 的主/次 CTA 迁移过去；首屏使用一张主视觉，不内嵌六图轮播。
3. 创建 `CoreCapabilitiesSection`，固定渲染 Plan、Connect、Deliver 三项；使用现有 Lucide 图标和营销主题令牌。
4. 更新 `src/app/page.tsx` 到目标区块顺序，不触碰 `MarketingNav`。

验收：中英文切换后所有标题、正文与 CTA 都成对出现；首页不再依赖产品名称来解释第一层价值。

### P2：三端体验与工作流

1. 将现有 `Carousel` 封装到 `EditionsCarouselSection`，添加区块标题、说明、显式轮播控制与语言切换重置。
2. 接入 `public/marketing/home-editions/` 的六张 1536×960 图片；首屏外图片采用延迟加载。
3. 创建 `WorkflowSection`，实现四步可顺序阅读的流程，并为每一步放入真实 UI 截图、任务状态或产品事实。
4. 移除首页对 `ProductGrid` 的引用；不删除组件，避免影响其他页面或快速回滚。

验收：轮播在键盘、指针与触屏下均可操作；中文不显示英文营销文案，英文不显示中文营销文案；窄屏无横向溢出。

### P3：控制与信任

1. 创建 `ControlPlaneSection`，呈现安全、权限、连接、部署四项控制能力；每项关联明确证据，不使用纯装饰占位符。
2. 创建 `ProofSection`，先支持产品事实；有通过审阅的客户证明后再开启引言模块。
3. 以新的 `FinalCtaSection` 替换首页 `InviteBanner` 和 `PricingTeaser`，保留“进入控制台 / 查看产品”双行动。
4. 迁移或下线 `StatsBar`、`BenefitList` 在首页的使用；保留源码直到发布稳定后再单独清理。

验收：无虚构指标、客户或引言；安全/权限描述与真实产品能力一致；最终 CTA 在桌面和移动端清晰可见。

### P4：质量、分析与发布

1. 为语言切换、轮播重置、CTA 链接、空 Proof 数据补充组件测试。
2. 检查键盘焦点、`prefers-reduced-motion`、图片 `alt`、标题层级、色彩对比与 44px 触控目标。
3. 通过 Lighthouse/浏览器检查首屏 LCP、图片懒加载、CLS 与移动端横向溢出。
4. 记录 CTA 点击与轮播交互事件（遵循现有分析/隐私策略），发布后对比“进入控制台”和“查看产品”的转化。

验收：`npm run typecheck`、`npm run lint` 通过；关键首页行为有测试；桌面、平板、移动端视觉审核通过。

## 组件边界与状态决策

| 组件 | 稳定职责 | 状态位置 |
| --- | --- | --- |
| `OutcomeHeroSection` | 价值承诺、CTA、单个主视觉 | 无本地业务状态，语言从 `useLanguage` 派生。 |
| `CoreCapabilitiesSection` | Plan/Connect/Deliver 内容呈现 | 无状态。 |
| `EditionsCarouselSection` | 三端区块标题与轮播内容选择 | 语言从 `useLanguage` 派生；页码状态留在 `Carousel`。 |
| `WorkflowSection` | 工作流叙事及证据 | 无状态；可选展开状态仅限组件内部。 |
| `ControlPlaneSection` | 控制能力和证据 | 无状态。 |
| `ProofSection` | 事实与授权证明 | 无状态；空数据不渲染。 |
| `FinalCtaSection` | 最后一次行动引导 | 无状态。 |

不创建首页级 Zustand 状态；语言已经是全局状态，轮播当前页是局部瞬态状态。

## 风险与回滚

| 风险 | 控制方式 | 回滚点 |
| --- | --- | --- |
| 未核验数据降低可信度 | Proof 数据仅来自已确认来源；缺失时隐藏。 | 在内容配置中清空 `proof`。 |
| 图片影响首屏性能 | 首屏只加载一张主视觉，轮播图片懒加载。 | 恢复当前 Hero 图片与轮播配置。 |
| 内容迁移造成双语缺字 | 内容类型要求双语成对，测试语言切换。 | 保留旧 `homeMarketingContent` 字段，逐块迁移。 |
| 重构影响导航 | 将导航排除在变更文件与验收清单外。 | 首页 `page.tsx` 可恢复原区块顺序，`MarketingNav` 不动。 |
| 现有区块被其他页面复用 | 只移除首页引用，稳定后另开清理任务。 | 恢复原组件引用。 |

## 完成定义

- 首页主体严格按目标七段式结构渲染，顶部导航未修改。
- 中英文内容、轮播图片、CTA 和无障碍文本完整对应。
- Web、Desktop、Mobile 六张图片作为独立的三端证据区展示。
- 工作流和控制能力均有真实产品证据。
- 产品事实与客户证明仅在有可靠来源时渲染。
- 测试、可访问性和性能检查均达到发布门槛。
