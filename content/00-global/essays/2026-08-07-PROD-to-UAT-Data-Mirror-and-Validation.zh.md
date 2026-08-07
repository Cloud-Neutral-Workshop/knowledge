# 🚀 实践验证：PROD 数据如何安全“倒灌”？——防呆熔断、Schema 契约与 UAT 自动化验证闭环

**——从 Daily Tag 到 4 层数据隔离屏障，让生产数据在不越界的前提下驱动新版本对账**

![SAFE DATA MIRRORING & UAT PARITY](/assets/images/data-parity-architecture.png)

---

**作者信息**

- 作者：Haitao Pan
- 职位：平台工程师（Platform Engineer）
- 所在项目：XWorkmate · XConnect · Open Platform
- 开源组织：ai-workspace-infra（https://github.com/ai-workspace-infra）
- 一句话自述：Bring AI into real work, not just chat——从想法到工作流，再到可控制的落地。

---

## 导读

在前两篇文章中，我们论证了[《平台工程的核心命题：开发环境 ≠ 构建环境 ≠ 运行环境，隔离与收敛》](https://console-uat.onwalk.net/blogs/00-global/essays/2026-07-31-Platform-Engineering-Environment-Isolation-and-Convergence.zh)，并落地了[《🚀 实践验证：Docker 单机也能玩 GitOps》](https://console-uat.onwalk.net/blogs/00-global/essays/2026-07-31-Docker-Single-Node-GitOps.zh)。

然而当镜像制品与基础设施实现不可变之后，团队很快会撞上**环境一致性（Environment Parity）的最后一个隐形巨坑：数据环境脱节**。
UAT 环境里跑着最新的代码，数据库里却只有三两条脏数据，复杂的历史边界条件与真实业务场景根本测不出来；而如果直接把生产数据库 Dump 到预发环境，又极易引发**数据误覆盖、写穿线上、敏感数据泄漏**的毁灭性灾难。

本文结合 `platform-ops-toolkit` 工具链中的 `daily-main-snapshot.yaml`、`platform-ops.yaml` 与 `data-migration.yaml` 三条核心流水线，分享我们如何通过 **Schema 哈希契约、四层防呆熔断屏障与自动化增量合并**，实现从 PROD 到 UAT 的安全数据镜像，构建新版本交付的完整验证闭环。

---

## 一、痛点：代码一致了，数据“假干净”怎么办？

在持续交付链路中，我们经常遇到这样的困境：

1. **“空库测试”的虚假安全感**：
   开发者在 UAT 环境测试通过，一上线就报主键冲突、外键约束失败或长文本截断。原因很简单——UAT 的测试数据是人工手填的“理想数据”，而生产环境充满了历史遗留的边缘 Case。
2. **“手动 SQL 导入”的悬崖走丝**：
   运维为了配合测试，手动导出一个 `prod.sql` 执行 `psql -h uat_db < prod.sql`。某天把 `-h uat_db` 错写成 `-h prod_db`，或者连接串混淆，生产环境数据瞬间被摧毁。
3. **Schema 漂移与字段不兼容**：
   PROD 还在跑 `v1.2` 的数据库 Schema，UAT 已经升级到了 `v1.3` 添加了新字段。粗暴的全量 `pg_dump` 直接擦除了 UAT 新版本的 DDL 变更，导致应用启动崩溃。

**核心问题**：如何让 UAT 环境**安全地使用真实/生成数据**来验证新版本，同时**绝对物理隔离生产写入风险**？

---

## 二、总体架构：制品快照 + 部署编排 + 数据镜像三位一体

在 `platform-ops-toolkit` 中，我们将“UAT 新版本数据验证”解耦为三个标准化阶段：

```text
 ┌────────────────────────┐
 │ daily-main-snapshot    │  1. 每日午夜触发：跨仓固化 daily-build-YYYY.MM.DD 镜像 Tag
 └───────────┬────────────┘
             │
             ▼
 ┌────────────────────────┐
 │ platform-ops.yaml      │  2. IaC 环境拉起 & GitOps 自动反写 Tag -> doco-cd 自动对账
 └───────────┬────────────┘
             │
             ▼
 ┌────────────────────────┐
 │ data-migration.yaml    │  3. 触发现场防呆断言 -> PROD 导出 -> UAT Dry-Run 预览 -> 增量合并
 └────────────────────────┘
```

### 2.1 每日不可变快照 (`daily-main-snapshot.yaml`)
- 每日午夜由 cron 触发，利用 Vault OIDC 签发的 GitHub App 动态 Token，对多组织（`ai-workspace-infra`, `ai-workspace-services` 等）仓库代码进行集成测试，并打上 `daily-build-YYYY.MM.DD` 标签。
- 确保 UAT 验证所使用的**镜像制品是经过检验的唯一事实来源**。

### 2.2 多云部署与 GitOps 联动 (`platform-ops.yaml`)
- 负责 VPS 资源 Provision 与基础配置（Ansible）。
- 部署成功后自动更新 `gitops` 仓库的清单文件，触发单节点 GitOps 引擎（如 `doco-cd`）拉取新镜像，完成代码面的收敛。

### 2.3 数据安全镜像与迁移 (`data-migration.yaml`)
- 专为 `PROD -> UAT` 数据倒灌设计的自动化工作流，内置 `migratectl` 逻辑层增量合并引擎与**四层防呆屏障**。

---

## 三、核心防护：四层防呆屏障（Safeguard Architecture）

为了做到“数据可以安全镜像，但写入绝对无法反噬生产”，我们在内核、系统、脚本与凭据四个层级建立了**硬性断路熔断**：

| 防呆层级 | 防御手段 | 物理效果 |
| :--- | :--- | :--- |
| **1. PROD 内核级只读** | PostgreSQL 角色配置为 `NOSUPERUSER NOCREATEDB NOCREATEROLE`，且仅赋予 `SELECT, USAGE` | 任何 `INSERT/UPDATE/DELETE` 将被 Postgres 引擎层直接拒绝 (`permission denied`) |
| **2. 系统账号隔离** | Linux `readonly` 账号禁止加入 `sudo` / `docker` 提权组 | 无法通过宿主机 `docker exec` 或容器挂载卷修改数据库配置与底层文件 |
| **3. 脚本字符串熔断** | `accounts_data_migration.sh` 硬性断言字符串 | 若 `TARGET_DSN` 包含生产域名 (`svc.plus`)、不含 UAT (`onwalk.net`/回环)、或与源 DSN 相同，**在接触任何数据库前立即 `exit 1`** |
| **4. Vault 凭据隔离** | 生产只读凭据存放在 Vault 的 `kv/data/uat/accounts-migration` 路径 | 迁移流水线获取的凭据天然只读，PROD 管理员写口令**永远不会进入**该流水线 |

```bash
# 流量与安全边界断言逻辑（截取自安全测试基线）：
if [[ "$MIGRATION_TARGET_DSN" == *"svc.plus"* ]]; then
    echo "::error::CRITICAL: Target DSN contains PROD domain! Aborting to prevent disaster."
    exit 1
fi
```

---

## 四、技术细节：Single Binary 与双模式传输

### 4.1 Schema 契约与单二进制约束 (`migratectl`)
传统数据迁移最容易毁在“版本不匹配”。为了保证导出（Export）与导入（Import）两端的 Schema 强一致：

- 业务服务内置 Go 语言编写的 `migratectl` CLI；
- 编译时将当前版本的 `schema.sql` 嵌入二进制中，并计算得到全局唯一的 `schemaHash`；
- `migratectl export` 导出的快照文件必须携带该 Hash；
- `migratectl import` 在读取快照时，**会校验快照 Hash 与当前二进制 Hash 是否完全一致**，若不一致则直接拒绝导入。
- **CI 规则**：流水线必须由 `data-migration_accounts_build-migratectl.sh` **统一构建出一个二进制文件**同时作用于导出与导入两端，从根源消除版本漂移。

### 4.2 双传输模式：`direct` vs `ssh`

```text
 模式 A: direct（Runner 直连模式）
 [Runner (migratectl)] ──(SELECT DSN)──► [PROD DB:5432]
                       ──(WRITE DSN)───► [UAT DB:5432]

 模式 B: ssh（容器 NetNS 模式，零暴露端点）
 [Runner] ──(SSH readonly)──► [PROD Host] ──(docker exec)──► [PROD DB (loopback)]
          ──(SSH deploy)────► [UAT Host]  ──(docker exec)──► [UAT DB (loopback)]
```

1. **`direct` 模式**：
   适用于 Runner 能直连两端 PostgreSQL 的场景。结合 Vault 动态读取 `MIGRATION_SOURCE_DSN`（只读）与 `MIGRATION_TARGET_DSN`（写入），流水线全程无驻留。
2. **`ssh` 模式**：
   生产环境往往不允许数据库端口公网暴露（仅开通 5433 Stunnel TLS 握手）。`ssh` 模式下，流水线通过专用只读 SSH Key 登录宿主机，在 `web-saas-postgresql` 容器的网络命名空间（NetNS）内部直接调起 `migratectl`，利用 `trust` 本地回环免密完成操作。

---

## 五、自动化演练：从 Dry-Run 预览到二次收敛校验

自动化数据迁移最忌讳“流水线显示绿色，但实际上数据没落库”。`data-migration.yaml` 引入了完整的演练与校验闭环：

### 5.1 预览阶段 (`accounts_dry_run = true`)
```bash
migratectl import \
  --dsn "$MIGRATION_TARGET_DSN" \
  --file /tmp/account-prod-snapshot.yaml \
  --dry-run \
  --merge \
  --merge-strategy timestamp
```
在 Postgres 事务内模拟合并并立即 `ROLLBACK`，输出新增、更新、冲突跳过的详细变更报告。

### 5.2 增量合并阶段 (`accounts_dry_run = false`)
采用 `timestamp` 优先合并策略：
- PROD 新增用户：增量写入 UAT；
- 记录冲突：保留 `updated_at` 时间戳最新的那份，跳过旧记录；
- UAT 独有的测试账号：**保留不删除**，避免破坏其他测试人员的预设环境。

### 5.3 二次收敛校验 (Convergence Assertion)
合并完成后，脚本用**同一份 PROD 快照**再次对 UAT 执行一次 `--dry-run` 预览：

$$\text{Assert: } \text{inserted}_{\text{users}} = 0 \quad \land \quad \text{inserted}_{\text{identities}} = 0 \quad \land \quad \text{inserted}_{\text{sessions}} = 0$$

若发现新增行数不为 0，说明数据未能完全收敛，流水线直接抛出 `exit 1` 报警。

---

## 六、总结与工程范式

从构建环境隔离（LFS/Docker），到声明式状态管理（GitOps），再到数据的安全倒灌（Data Parity），平台工程的底层逻辑一脉相承：

1. **隔离是稳定的前提**：无论是环境、凭据，还是数据库权限，必须做到默认隔离、按契约通信。
2. **防呆高于规范**：不要相信人的操作自觉，把安全寄托在凭据隔离与内核级只读（Postgres `NOSUPERUSER` + 脚本断言）上。
3. **过程转化为产品**：数据迁移不是一次性“偷懒的手工命令”，而是一条**可复现、可演练、可对账的自动化流水线**。

通过这套机制，我们的团队能够在每天午夜自动完成最新代码与真实数据镜像的组装，让 UAT 环境真正成为生产发布前最坚固的“安全演练场”。

---

### **开放讨论**
1. 你们团队在 UAT / 预发环境测试时，数据主要来源于手动构造、Mock 数据，还是生产数据脱敏倒灌？
2. 跨环境数据同步时，针对敏感数据（如用户手机号、支付凭证）的脱敏（Sanitization），你们倾向于在导出端处理还是导入中间层处理？
3. 在自动化 CI/CD 流水线中，还有哪些“防呆（Anti-Foolishness）”机制曾救过你们的生产环境？

*欢迎在评论区分享你的工程实践与踩坑经验！*
