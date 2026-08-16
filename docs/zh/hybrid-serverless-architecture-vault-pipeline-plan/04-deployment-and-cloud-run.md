## 七、混合部署流水线

```text
Prepare
  ↓
Resolve environment + deploy_tag / digest
  ↓
GitHub OIDC 登录 Vault
  ↓
GitHub OIDC 登录 GCP WIF
  ↓
读取并校验最小权限 Secret
  ↓
校验镜像存在、digest 和服务配置
  ↓
部署或更新 VPS 主服务
  ↓
部署或更新 Cloud Run 备用服务（min=0）
  ↓
获取 VPS 健康地址、Cloud Run URL 和 revision
  ↓
生成当前环境的服务级 upstream map
  ↓
部署 Worker 当前 environment
  ↓
构建并部署 Portal
  ↓
执行 migration / seed
  ↓
执行全链路 smoke test
  ↓
输出部署摘要、revision、digest 和回滚命令
```

### 失败处理

所有关键步骤必须 fail closed：

- Vault 认证失败：停止；
- 必需 Secret 缺失：停止；
- 镜像不存在或 digest 不匹配：停止；
- VPS 或任一 Cloud Run 服务部署失败：停止后续流量切换；
- Worker/Portal 部署失败：不得报告成功；
- smoke test 失败：标记发布失败并保留现场。

禁止使用以下方式隐藏失败：

```bash
|| true
failed_when: false
```

### 触发策略

| GitHub 事件 | 行为 | 凭据范围 |
|---|---|---|
| Pull Request | SIT 验证和制品检查，可选按策略部署 SIT | SIT |
| `main` / `release/*` | 按交付规则生成或消费环境快照 | 由环境规则决定 |
| `vMAJOR.MINOR.PATCH` | 生产候选/生产发布 | PROD |
| `workflow_dispatch` | 必须显式指定环境和不可变 `deploy_tag` | 用户选择环境 |
| 定时任务 | 仅执行 keepalive、观测和成本检查 | 指定环境 |
| 清理任务 | 只清理带环境标签的候选 revision/镜像 | 指定环境 |

环境路由必须遵守：PR → SIT，`main`/`release/*` → UAT，`vMAJOR.MINOR.PATCH` → PROD。快照必须使用 `<env>-daily-build-*`，生产版本必须使用 `v*`，两者不能混用。

---

## 八、Cloud Run 生命周期与成本控制

默认策略：

```text
Cloud Run service 保留
min-instances=0
max-instances=2
```

夜间不强制删除服务。保留服务可以保留 revision、服务地址和回滚能力。

如果确实需要销毁候选资源：

- 只删除具有明确 `environment=<env>` 和 `managed-by=platform-ops-toolkit` 标签的资源；
- 不删除未过保留期的镜像；
- 不删除当前 revision 或最近可回滚 revision；
- 部署与清理使用同一个 concurrency group；
- 清理前检查是否存在 active deployment lease。

Artifact Registry 清理应按照明确的仓库、tag 前缀和保留窗口执行，禁止对整个仓库进行“创建时间早于两天”的粗粒度删除。

---
