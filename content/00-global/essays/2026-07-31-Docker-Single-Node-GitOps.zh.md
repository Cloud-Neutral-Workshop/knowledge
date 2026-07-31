# 🚀 实践验证：Docker 单机也能玩 GitOps

**——零信任凭证 + 声明式状态 + AI 加速的多环境交付实录**

![Multi-Cloud Delivery](/assets/images/multi-cloud-delivery.png)

---

**作者信息**

- 作者：Haitao Pan
- 职位：平台工程师（Platform Engineer）
- 所在项目：XWorkmate · XConnect · Open Platform
- 开源组织：ai-workspace-infra（https://github.com/ai-workspace-infra）
- 一句话自述：Bring AI into real work, not just chat——从想法到工作流，再到可控制的落地。

---

## 摘要

2024 年，我在某新能源车企担任 SRE，负责产线工控机的部署维护。这些工控机清一色是单机 Docker，更新靠手撸半自动化工具硬怼。4 个月不到，我在裁员潮中离开了团队，但那个问题一直卡在心里：**单机的 Docker，凭什么不能拥有 K8s 级别的声明式、可追溯、自动化的部署体验？**

答案是：能。本文用一套经过实践验证的方案回答这个问题——以 **doco-cd**（Git 仓库声明 docker-compose，提交即部署、回滚即 `git revert`）为核心，叠加 **Vault OIDC 零信任动态凭证** 与 **AI Agent 结对编程**，把“单机 GitOps”从口号变成了每天在跑的流水线。文章拆解了支撑这套体系的 4 个核心工作流（GitOps 状态反写、每日不可变快照、Vault ACME 证书轮换、多云编排中枢），并分享了 AI 将 2–3 个月基建工作量压缩到数周的真实经验。

---

## 一、缘起：产线工控机教会我的事

2024 年，我以 SRE 身份加入一家新能源车企，负责产线边缘的工业控制机。它们有几个共同点：**单机部署、Docker 运行时、无集群**。没有 K8s，没有 Service Mesh，更新靠什么？靠运维手撸的半自动化脚本：

- 构建镜像 → 手动 scp 到目标机 → 手动 `docker compose up -d` → 祈祷没问题。

这套流程有三个致命伤，相信做过传统运维的人都懂：

1. **不可追溯**：服务器上跑的是什么版本，只有登录进去 `docker ps` 才知道；Git 仓库对生产环境一无所知。
2. **不可回滚**：出问题想回滚？先翻聊天记录找上一个镜像 Tag，再手工操作一遍，期间服务持续不可用。
3. **配置漂移**：每台机器的 `docker-compose.yml` 都可能是历史某个时刻手工改出来的副本，环境之间差异越滚越大。

4 个月后，我在裁员潮中离开了。但“单机 Docker 的部署体验问题”一直没放下。它本质上是一个工程尊严问题：**为什么只有 K8s 用户能享受“声明式、可追溯、自动化”的部署体验，单机 Docker 用户就只能回到 2015 年？**

后来的答案是：可以，而且不需要引入 K8s。这套方案我们内部叫它“轻量 GitOps”——核心是 doco-cd 这个单节点 GitOps 引擎。

---

## 二、总体架构：四件套与三条原则

### 2.1 技术栈

整套交付栈由四个组件加一个“大脑”组成：

| 组件 | 角色 | 一句话职责 |
| --- | --- | --- |
| Docker | 执行（Execution） | 不可变容器制品，镜像 Tag = 版本身份证 |
| GitOps（doco-cd / ArgoCD） | 状态（State） | 声明式对账，Git 是唯一事实来源 |
| HashiCorp Vault | 安全（Security） | 动态凭证、集中存储、细粒度访问控制 |
| GitHub Actions | 编排（Orchestration） | CI/CD 流水线中枢与安全门禁 |
| AI Agent | 大脑（Engineering Brain） | 架构推导、排障、脚本调试 |

### 2.2 三条架构原则

1. **单一事实来源**：任何环境、任何应用的精确版本与状态，100% 以声明式形式体现在 Git 中。
2. **零信任与集中式密钥**：放弃静态长效令牌，改用 Vault + OIDC 分发动态、短时凭证。
3. **不可变基础设施**：同一份镜像 Tag 原样流经所有环境，杜绝环境间差异。

### 2.3 两级 GitOps：单机用 doco-cd，集群用 ArgoCD

一个常被忽略的事实是：GitOps 不是 K8s 的专利。我们的实践是**按节点规模分两级**：

- **单节点（工控机、边缘机、临时压测机）**：用 **doco-cd**——一个轻量 GitOps 引擎，以 Git 仓库声明 `docker-compose` 为目标状态，定期（或 webhook 触发）拉取并 reconcile 本地容器；
- **多节点 / 集群**：用 **ArgoCD**——面向多集群的声明式状态生成与对账。

底层逻辑可以压缩成一句话：**镜像 Tag 是不可变身份证，Git Commit 是部署指令，Vault 是动态密盾，AI 是工程加速器。**

> 配图建议 ①：多云交付架构拓扑图（四色环形能力图：GitOps / Vault / Docker / GitHub Actions + 可观测性开源套件）。

---

## 三、核心工作流（上）：状态反写与每日快照

### 3.1 `auto-gitops-tags-update`：让 Git 替你“反写”状态

**痛点**：传统 CI 构建完镜像直接 push 到服务器，Git 仓库对生产环境“睁眼瞎”——想回滚时根本不知道当前滚到哪个版本。

**做法**：这里践行的是纯 GitOps。镜像构建成功后，流水线不 SSH 进任何服务器，而是**程序化更新基础设施清单仓库（infra manifest repo）中的 Image Tag 并提交**：

```text
镜像构建成功
  └─▶ 自动修改 infra 仓库中的 Image Tag
        └─▶ 发起 Git Commit
              └─▶ doco-cd 感知变更 → 自动拉取 → 自动 reconcile
```

**结果**：

- 每一次升级 = 一行 `git log`，任何时刻都知道“什么版本跑在什么地方”；
- 回滚 = `git revert`，简单到可以交给值班机器人；
- 部署依赖 **Pull** 而非 Push，服务器侧不开放任何入站通道，攻击面最小化。

### 3.2 `daily-main-snapshot.yaml`：每天凌晨的一枚“定心丸”

**痛点**：代码“合久必冲突，放久必炸裂”。发版前夜构建崩溃，是运维的至暗时刻。

**做法**：该工作流每日午夜运行——

```text
🕛 每天午夜（cron）
  └─▶ 拉取 main 分支
        └─▶ 运行完整集成测试
              └─▶ 强制构建 snapshot-YYYYMMDD 不可变镜像 Tag
```

**结果**：

- UAT、临时压测、紧急救火，随手拉一个当日快照，**100% 可信**；
- 保证每个云节点拉取的是**同一个经过集成测试验证的制品**，从根上消除“这台机器版本不一样”的环境漂移。

---

## 四、核心工作流（中）：Vault ACME 证书轮换（DevSecOps）

**痛点**：多云边缘节点的 HTTPS 证书管理是运维噩梦——人工申请、邮件传递、半夜过期、线上暴毙。证书轮换几乎是每个平台的“定时炸弹”。

**做法**：我们用 HashiCorp Vault 自动化了 90 天 Let's Encrypt 通配符证书的完整生命周期，分三步：

1. **OIDC / JWT 认证（零信任入口）**：彻底移除明文 Vault Token。GitHub Actions 利用自身原生 OIDC 身份向 Vault 认证，Vault 严格校验 JWT claim（**仅允许 main 分支**触发），签发短时令牌。
2. **自动化签发与安全存储**：流水线在**临时容器**内通过 **Cloudflare DNS API** 完成域名验证并签发 Let's Encrypt 证书，随后立即用 `vault kv put` 将新证书写入集中式 Vault 集群（`kv/CICD/domains` 路径）。
3. **边缘节点零接触热加载**：CI runner 不留任何痕迹、从不触碰生产边缘节点；各边缘网关只需**监听 Vault 对应路径**，检测到新证书即无缝热重载。

**安全细节**（这是与“一把密钥走天下”最本质的区别）：

- 动态 Token 的权限被收敛到**只能读证书相关路径**；
- Token 生命周期短，**流水线一结束立即消亡**——即便 runner 日志泄漏，泄漏的也只是一枚已失效的凭证；
- 整个轮换过程无人值守、全程可审计。

**结果**：证书轮换从“高危手工操作”变成“日常自动化任务”，HTTPS 过期事故归零。

---

## 五、核心工作流（下）：`platform-ops.yaml` 编排中枢与一体化可观测性

### 5.1 多云指挥大脑

`platform-ops.yaml` 是交付链的**总编排器与中央总线**。它不编译任何业务代码，只串联基础设施操作：

- 分析上游 GitOps 标签（构建产物的状态）；
- 引导 Remote Host Monitor Agent（可观测性代理）；
- 触发数据库迁移脚本；
- 执行**加权 DNS 流量切换**（Blue-Green 部署的流量灰度）。

**安全门禁（Supply Chain Gating）**：我们引入了严格的 CI 门禁——自定义校验脚本**禁止 `run:` 块中出现未经审计的内联 shell 脚本**。所有脚本必须先入库、走评审、被打包为可复用的 action/脚本文件后才能执行。这从供应链源头掐断了“流水线里埋雷”的投毒路径。

### 5.2 一体化可观测性：业务在哪，监控跟到哪

通过 `platform-ops.yaml`，我们不只是部署应用，而是把**基础设施监控生命周期捆绑进同一个部署工作流**：

- 每当新节点加入或环境初始化，流水线利用 **Ansible Matrix** 自动引导 **Node Exporter、Process Exporter** 与日志采集代理；
- 这种**同构部署（Isomorphic Deployment）**策略保证：业务服务跑在哪里，监控网格就跟随到哪里；
- 配合 `observability.svc.plus` 的 OpenTelemetry 埋点、Prometheus 指标、Loki 日志与 Grafana 可视化，**彻底消除环境漂移造成的监控盲区**——不存在“业务上线了但没人知道它在哪”的黑洞。

> 配图建议 ②：GitHub Actions `platform-ops` 工作流拓扑图；  
> 配图建议 ③：UAT 统一监控控制台截图；  
> 配图建议 ④：Node Exporter 全局资源监控视图。

---

## 六、AI Agent 加速与多仓库生态

### 6.1 从 2–3 个月到 4 周：AI 到底干了什么

坦率地说，这套跨越 10+ 仓库、涉及 Ansible / Terraform / GitHub Actions / Vault / TLS / OpenTelemetry 的基础设施生态，按传统方式需要资深 DevOps 工程师全职投入 **2–3 个月**。而在本次重构中，通过与 Agentic AI 的深度结对编程，整个里程碑被压缩到**几周**，部分复杂组件甚至数天完成。

AI 的贡献不是“帮忙写 YAML”，而是四件实打实的事：

1. **架构推演与 IaC 模块化重构**：从需求直接推导仓库拆分与模块边界；
2. **TLS 证书轮转与 Vault 零信任对接**：打通跨系统认证链路；
3. **Bash / Python 供应链门禁脚本的调试**：这类脚本的边界条件极其刁钻，AI 显著缩短了排错周期；
4. **YAML 语法纠错与 CI/CD 疑难杂症排查**：面对晦涩报错（如**跨云 OIDC claim 被拒、权限作用域问题**），AI Agent 能自主分析日志、追踪执行路径，直接给出可提 PR 的修复方案。

我们的经验是：AI 的价值密度与“问题能否被精确描述”成正比。把「目标状态 + 约束 + 失败日志」喂给 Agent，比让它自由发挥高效一个数量级。

### 6.2 背后的“积木”生态：ai-workspace-infra

这套方案能成立，底层是 `ai-workspace-infra` 组织下**高内聚、低耦合的多仓库策略**——不是单体仓库，而是一个专门化的仓库生态：

| 仓库 | 职责 |
| --- | --- |
| `platform-ops-toolkit` | AI 驱动的平台运维大脑（迁移与平台操作） |
| `gitops` / `playbooks` / `iac_modules` | GitOps 三驾马车：环境清单（状态）/ Ansible（配置）/ Terraform（多云 IaC） |
| `observability.svc.plus` | 端到端可观测性栈：OpenTelemetry + Prometheus + Loki |
| `postgresql.svc.plus` | 生产级 PG 集群：向量搜索、TLS 隧道、高可用 |
| `artifacts` / `diagram-generator` | 制品托管、架构图生成等辅助工具 |

搭积木式的多仓库策略，让 IaC、基础组件与业务代码完美解耦——任何一层都可以独立演进、独立回滚。

### 6.3 未来路线图：向高级 SRE 能力演进

得益于 `platform-ops.yaml` 的模块化设计，基础设施已为以下能力做好准备：

| 能力 | 实现路径 |
| --- | --- |
| 无缝多云迁移 | 加权 DNS 灰度发布 + 跨云编排，云厂商间零停机热迁移 |
| 发布前自动压测 | 在动态开通的临时节点上集成 K6 / JMeter |
| 自动化容灾演练 | Vault active/standby 复制 + GitHub Actions 定期模拟跨区域故障切换 |
| 混沌工程 | Chaos Mesh 注入故障（网络延迟、Pod 崩溃），利用密集监控探针验证自愈能力 |

---

## 总结

这套改造的实质，是把几件事彻底分开、又严丝合缝地拼在一起：

- **Docker** 负责执行——不可变制品；
- **GitOps（doco-cd / ArgoCD）** 负责状态——声明式对账；
- **Vault** 负责安全——零信任动态凭证；
- **GitHub Actions** 负责编排——流水线中枢与门禁；
- **AI Agent** 负责脑力——架构推导与排障。

我们不再把敏感配置散落在零散的 GitHub Secrets 里，而是集中到 Vault 中，以细粒度、短时 OIDC 凭证进行分发。单机 Docker 终于拥有了 K8s 级别的部署体验——**而你，只差一个 `git push`。**

**开放问题（欢迎讨论）**：

1. 单机 / 边缘场景的 GitOps，你们用的是什么方案？doco-cd 之外还有哪些值得关注的工具？
2. OIDC 动态凭证落地时，跨云 claim 校验和权限作用域是最大的坑吗？你们怎么处理的？
3. 平台工程团队如何系统性引入 Agentic AI，而不只是“让它写点 YAML”？

**参考链接**：https://github.com/ai-workspace-infra

---

## 附：配图清单（供编辑部排版）

1. 多云交付架构拓扑图（四色环形能力图：GitOps / Vault / Docker / GitHub Actions + 可观测性开源套件）
2. `platform-ops` GitHub Actions 工作流拓扑截图
3. UAT 统一监控控制台截图
4. Node Exporter 全局资源监控视图

---

*本文基于作者在多环境交付改造中的真实工程实践撰写。*
