# AI Workspace Web 对齐 XWorkmate Desktop 的实施计划

## 目标

Portal 保持现有 Web 信息架构，但逐步消费与 XWorkmate Desktop 相同的 Bridge 共享会话数据：`sessionId + namespaceId + event cursor`。不复制 Desktop 视觉，不用浏览器 local state 作为会话真相。

## 已完成：数据层第一步

- Portal 已增加同域 `/api/ai-workspace/sessions/*` proxy。
- proxy 将已登录 Portal 的 Accounts session 转给 Bridge；浏览器不直接持有 Bridge 地址或 token。
- 客户端已定义 create、snapshot、event replay、message command 合同。

## 对齐顺序

| 阶段 | Desktop 功能语义 | Portal 交付 | 依赖 |
| --- | --- | --- | --- |
| W1 | TaskThread 列表/新对话/继续会话 | 默认 namespace session 列表；创建后以 cloud `sessionId` 选中 | Bridge list/create API |
| W2 | 任务上下文会话 | 按 event replay 渲染用户消息、助手消息、运行状态 | snapshot/events API |
| W3 | 对话执行与恢复 | composer 调用 `POST /messages`，显示 queued/running/terminal | Bridge scheduler/callback |
| W4 | 任务路径与执行目标 | 只显示服务端安全的 workspace display/ref 与 bridge target；不泄漏本地绝对路径 | snapshot context |
| W5 | 文件/制品面板 | 依据 `taskRunId + bridgeTaskRef` 查询 Bridge 制品域 | Bridge artifacts API |
| W6 | 取消、归档、恢复 | queued cancel、terminal task reopen、断线后 replay | cancel/SSE |
| W7 | Desktop 已有模型/技能/附件语义 | 逐项复用同一 command/API 合同 | 基础链路稳定 |

## Web 状态规则

```text
Portal task row id     = cloud sessionId
Portal active session  = cloud sessionId + namespaceId
Portal cached cursor   = lastEventSeq
Portal local draft     = only unsent composer content
```

`TaskItem.id = makeId(...)` 只能作为组件暂态；W1 完成后不再用于服务端会话、Bridge thread 或跨端恢复。

## UI 边界

- 可保留 Web 的工作台、专项目录和右侧洞察布局。
- 功能语义以 Desktop 为准：列表、继续、消息、运行、文件、取消、恢复。
- namespace 在 MVP 可以由当前 workspace/默认 personal 解析，不要求 Desktop 新增 namespace UI；Web 的 namespace 管理仅在单独管理入口提供。
- 文件内容不进入 Portal session cache 或 PG；Portal 仅展示 Bridge 可访问的制品引用。

## 每阶段验收

- W1：Web 创建后 Desktop 能打开相同 `sessionId`。
- W2：Web reload 后消息不重复，cursor 单调增加。
- W3：Web 发送消息只创建一个 event/run，Desktop 可看到状态。
- W4/W5：跨端显示同一运行引用，但不显示另一台设备的绝对本地路径。
- W6：断线恢复后无漏 event；非所有者无法读取或取消。

