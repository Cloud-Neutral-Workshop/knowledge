## 十四、推荐落地顺序

### Phase 0：Micro SaaS 服务注册

- [ ] 为新 SaaS 建立域交付清单和服务边界；
- [ ] 为每个服务选择 S0–S4 运行档位；
- [ ] 声明主路由、Cloud Run fallback、数据库/队列/对象存储依赖；
- [ ] 声明资源下限、并发、连接池、健康检查和观测字段；
- [ ] 生成对应 Vault 路径、Gateway service key、镜像仓库和回滚合同；
- [ ] 通过静态配置校验后，才允许进入部署流水线。

### Phase 1：身份和制品

- [ ] 为每个环境建立独立 Vault JWT Role 和 Policy；
- [ ] 建立 GCP WIF；
- [ ] 删除长期 GCP Service Account JSON；
- [ ] 固化镜像仓库和不可变 tag 合同；
- [ ] 为每个服务生成 digest 和 release manifest。

### Phase 2：VPS 主链路和数据库

- [ ] 按领域交付清单确认 VPS 主服务边界；
- [ ] 记录当前 `console-uat` 本地 PostgreSQL 的数据量、备份和恢复点；
- [ ] 将同环境数据库逐步迁移到 Supabase；
- [ ] 迁移完成前不启用本地 PostgreSQL/Supabase 双写；
- [ ] 校验 VPS 端口、启动命令和必需环境变量；
- [ ] 配置 Pooler 连接和连接池上限；
- [ ] 完成 migration/seed 和数据恢复演练；
- [ ] 验证 VPS `/healthz` 和 `/readyz`。

### Phase 3：Cloud Run 弹性链路

- [ ] 部署 accounts、billing、content Cloud Run 服务，默认 `min=0`；
- [ ] 校验 Cloud Run 端口、启动命令和必需环境变量；
- [ ] 配置 Cloud Run revision 与 runtime identity；
- [ ] 动态生成三个服务的 Cloud Run fallback upstream；
- [ ] 验证 `/healthz`、`/readyz` 和冷启动行为。

### Phase 4：Gateway 与 Portal

- [ ] 建立当前环境独立 Worker environment；
- [ ] 实现 VPS primary → Cloud Run fallback 的服务级路由；
- [ ] 显式注入 Worker Secret；
- [ ] 完成 Portal Pages/Cloud Run 选型；
- [ ] 验证域名、CORS、JWT 和关键 API。

### Phase 5：观测、故障转移和运营

- [ ] 建立 smoke test；
- [ ] 接入 VPS、Cloud Run、Worker 的日志、指标和 Trace；
- [ ] 完成 VPS 故障、Cloud Run 冷启动和回切演练；
- [ ] 建立 revision 回滚流程；
- [ ] 建立预算、日志、指标和追踪告警；
- [ ] 建立 keepalive、备份和恢复演练。

### Phase 6：扩展多云

- [ ] AWS IAM OIDC/STS；
- [ ] Azure Entra Federated Credential；
- [ ] 统一各云环境的 Role/Policy 命名；
- [ ] 统一部署摘要、审计和回滚合同。

---

## 十五、上线验收标准

只有满足以下条件，才允许把该方案标记为“可用”：

- [ ] GitHub Secrets 中不存储长期云凭据；不支持 OIDC 的供应商凭据必须限定在 Vault 的环境基础设施路径，并由独立 Role 读取；
- [ ] SIT、UAT、PROD 及其他环境身份和 Secret 路径完全隔离；
- [ ] 所有部署都使用不可变 tag 或 digest；
- [ ] VPS 三个主服务和 Cloud Run 三个备用服务能够独立启动和健康检查；
- [ ] Gateway 能正确执行三个服务的 primary/fallback 路由；
- [ ] 幂等写请求不会因故障转移产生重复副作用；
- [ ] Portal 构建和运行模式已验证；
- [ ] migration、seed、keepalive、备份和恢复已演练；
- [ ] smoke test 失败会使 workflow 失败；
- [ ] cleanup 不会误删生产资源或可回滚制品；
- [ ] 能根据 revision/digest 完成一次回滚；
- [ ] GitHub Actions、Vault、云厂商审计日志能够关联同一 `DEPLOYMENT_ID`。

最终原则：

> **GitHub OIDC 负责工作负载身份，Vault 负责应用密钥，云厂商 WIF 负责云控制面权限，VPS 负责稳定流量，Cloud Run 负责按需弹性和故障兜底，Supabase 负责持久数据，所有发布必须可追踪、可验证、可回滚。**
