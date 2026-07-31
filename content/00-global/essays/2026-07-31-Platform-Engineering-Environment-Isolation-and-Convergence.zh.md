# 平台工程的核心命题：开发环境 ≠ 构建环境 ≠ 运行环境，隔离与收敛

> **导读**：很多团队「每次全新构建、全新部署，线上依然出玄学问题」。本文从 LFS → chroot → mock 的构建环境演进出发，论证平台工程的核心不是 Kubernetes、不是 IaC、不是 CI/CD，而是持续缩小「开发环境、构建环境、运行环境」之间的差异，同时保持三者隔离。所有平台能力——IaC、CI/CD、Artifact Registry、Config、Observability——都只是这件事的支撑。

---

## 一、问题：为什么「每次全新构建」还是不稳定？

很多团队处于这样一种状态：

- 没有环境区分
- 每次构建都是「全新」的
- 每次部署都是「全新」的
- 线上总出现「我本地可以」「上次可以」的玄学问题

表面上看，每次都全新构建似乎很「干净」。但实际上，这是典型的 **假干净（Fake Clean）**：

| 假干净来源 | 问题 |
|---|---|
| 宿主机器 | 依赖来自开发者电脑、PATH、brew |
| CI runner | 缓存、镜像 tag 漂移 |
| 网络 | `latest` tag、apt 源随时间变化 |
| 无 artifact 追踪 | 构建不可复现，没人知道线上跑的是什么 |

**根本症结**：构建不是「一个产品」，而是一个「不可控的过程」。

> 🔴 关键认知：**干净 ≠ 可控**
> - 每次都变（依赖、环境、时间）→ 假干净
> - 每次都一样 → 真正的工程净室（Clean Room Build）

---

## 二、核心命题：三个环境的隔离与收敛

平台工程真正要解决的一件事：

> **开发环境 ≠ 构建环境 ≠ 运行环境，但最终输出必须行为一致。**

三者的职责完全不同，混在一起是所有环境类事故的根源。

```
 写代码                    Commit / PR                    运行
   │                          │                            │
   ▼                          ▼                            ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Development │ →  │    Build     │ →  │   Runtime    │
│   开发环境    │    │   构建环境    │    │   运行环境    │
└──────────────┘    └──────────────┘    └──────────────┘
    追求：快             追求：确定             追求：稳
    IDE / Debug          唯一 Artifact         CPU / Memory
    Hot Reload / Mock    可复现 / 可重放        Secret / Config
    天然是「脏」的        Hermetic / Immutable  Scaling / Rollback
```

### 2.1 开发环境：追求效率

- IDE、Debug、Hot Reload、Mock、本地数据库、Docker Compose
- 开发者可以安装任何东西：brew、Node、Python、各种缓存
- **这里是「快」优先，不是「一致」优先**

### 2.2 构建环境：追求确定性

- 只关心一件事：**能否稳定地产出唯一一个 Artifact**
- 固定 Ubuntu 24.04、固定 gcc、固定 Go、固定 Python、固定 OpenSSL、固定所有依赖版本
- 任何两次 Build，结果都应该一致
- 不依赖开发者电脑、PATH、brew、apt latest、系统缓存

### 2.3 运行环境：追求稳定

- CPU、Memory、Network、Secret、Config、Storage、Scaling、Rolling Update
- 完全不关心 gcc / cmake / make——因为已经编译完了

### 2.4 为什么不能混：两个真实案例

**案例 A：Python 版本漂移**

```
开发环境：Python 3.13   →  OK
CI：      Python 3.11   →  Fail
生产：     Python 3.9   →  Crash
```

不是代码的问题，是环境的问题。

**案例 B：OpenSSL 来源漂移**

```
开发：brew install openssl
CI：  Ubuntu 自带 OpenSSL
线上： RHEL 自带 OpenSSL

→ SSL 握手失败，所有人去查业务代码
→ 实际是运行环境不同
```

---

## 三、构建环境隔离的演进史：从 LFS 到 mock

平台工程里「净室构建」的思想，在 Linux 发行版工程里早就存在。

### 3.1 LFS（Linux From Scratch）：终极净室

> 从 0 构建一个完全可控的系统环境：不依赖宿主、工具链（gcc/glibc）自己编译、完全确定性。

LFS 是「没有污染来源」的终极净室——代价是极致的繁琐。

### 3.2 chroot：弱净室

> 「我不信任宿主系统，但我又懒得全重建。」

- 文件系统隔离 ✅
- 进程 / kernel 共享 ❌

本质是**半隔离**的弱净室。

### 3.3 mock / rpm build：标准化构建

> 每一次构建，都在干净的、可重复的环境里发生。

- 每次 build 都是 fresh chroot
- 依赖由 spec 明确声明
- 无隐藏依赖

**这是整个方法论的关键理念：构建必须可重放（reproducible）。**

### 3.4 演进轴

| 阶段 | 方法 | 隔离强度 |
|---|---|---|
| L0 | 本机 build | ❌ |
| L1 | chroot | 弱 |
| L2 | Docker build（固定 base image） | 中 |
| L3 | Nix / Bazel / hermetic build | 强 |

推荐路径：**最低 Docker build（固定 base image）**，进阶 Nix（真正可复现）。

---

## 四、工程净室四层方法论

### Layer 1：构建环境隔离（Build Isolation）

构建必须发生在标准化环境中，与开发者电脑、宿主系统完全隔离。

### Layer 2：依赖锁定（Dependency Closure）

> 所有依赖必须被声明，而不是隐式存在。

典型反模式：

- `pip install xxx` 不带版本
- `FROM ubuntu:latest`
- apt 源随时间变化

解决方案：

- lock file（requirements.txt / poetry.lock / package-lock.json）
- base image 用 **digest** 而不是 tag
- 私有镜像仓库（freeze 所有上游）

### Layer 3：构建产物优先（Artifact First）

> ❌ 每次部署时重新构建
> ✅ 构建一次 → 到处部署

```
build → artifact（immutable）→ deploy
```

典型实现：

- Docker image（tag = commit SHA）
- RPM / DEB 包
- 二进制 release

核心原则：

> 🔥 **运行的不是代码，而是 artifact。**

### Layer 4：环境一致性（Environment Parity）

- dev 可以、prod 不行 → 环境是代码的一部分
- IaC（Terraform）、Config-as-Code、多环境（SIT / UAT / PROD）
- 关键一刀：**不同环境部署同一个 artifact**

---

## 五、从发行版打包到 DevOps：软件的三层结构

把「Linux 发行版维护 → 软件开发 → DevOps」串起来看，它们解决的是同一个问题：

> **软件如何在不同环境中稳定存在并运行？**

软件本质上由三部分组成：

```
[ Binary / Code ] + [ Dependencies ] + [ Runtime Config ]
       代码              静态 lib / 动态 lib        config / env
```

### 5.1 静态链接 vs 动态链接：不是技术选择，是分发策略选择

| | 静态链接 | 动态链接 |
|---|---|---|
| 特点 | 依赖打进一个 binary，运行时零依赖 | 运行时加载 `.so`，依赖系统环境 |
| 优点 | 可移植、copy 即跑、不依赖系统版本 | 体积小、共享依赖、安全更新方便 |
| 缺点 | 体积大、安全更新需全量重编 | 版本冲突地狱（glibc / openssl）、依赖宿主 |
| 典型 | Go / Rust binary、CLI、Agent | 系统级服务 |

| 场景 | 推荐 |
|---|---|
| CLI / 工具 / Agent | 静态 |
| 系统级服务 | 动态 |
| 容器 | 两者皆可 |

### 5.2 config / env：真正的隐形炸弹

同一个 binary + 同一个依赖，因为 config/env 不同，行为完全不同。80% 的「玄学问题」出在这里。

**演进：**

- 发行版时代：`/etc/*.conf`、`/usr/lib/systemd`——配置 = 文件，强绑定系统
- DevOps 时代（12-Factor）：**Config should be in ENV**——env vars、configmap/secret、runtime injection

**反模式**：`.env` 写死、config 埋在代码里、build 时注入环境 → 构建不可复现 + 行为不可预测。

### 5.3 演进轴：系统为中心 → 应用为中心 → 系统解耦 → 工程系统化

| 阶段 | 模式 | 特点 |
|---|---|---|
| 1. 发行版模式 | 代码 + 动态库 + config → 打包 → 安装 | 强依赖系统，yum/apt 管理，系统为中心 |
| 2. 容器模式 | 代码 + 依赖 → image；config → runtime env | 环境一起打包，应用为中心 |
| 3. Cloud Native | build → artifact；deploy → inject config；run → immutable infra | build/run 分离，系统解耦 |
| 4. 平台工程 | 标准化 build system / artifact / runtime contract / config schema | 工程系统化 |

---

## 六、Runtime Contract：运行时契约

「代码依赖不确定、config 混乱、env 不规范」的本质是**缺少运行时契约**。

定义一个标准：

```yaml
app:
  binary: xworkmate
  runtime:
    required_env:
      - DATABASE_URL
      - API_KEY
    optional_env:
      - LOG_LEVEL
  dependencies:
    type: static / dynamic
  config:
    source: env / configmap
```

这就是「软件运行契约」：环境之间只能通过契约通信——

- Build 输出：Image / RPM / DEB / Binary
- Runtime 不重新编译
- Deployment 不修改代码
- Config 不重新打包

每一层都有明确边界。

---

## 七、平台工程 = 环境工程

> 平台工程不是在管理 Kubernetes，也不是在维护流水线，而是在管理**环境的生命周期**：开发环境如何快速且可重复地创建；构建环境如何做到确定性、可复现；运行环境如何做到稳定、可观测、可回滚；最终通过标准化的 Artifact 和明确的 Runtime Contract，把三个本质不同的环境连接起来，让开发、构建、运行**既保持隔离，又最终收敛到一致的行为**。

平台工程一直在做四件事：

1. **隔离（Isolation）**：三个环境互不污染（Mac / Container / Kubernetes）
2. **标准化（Standardization）**：每次构建都一样（Go 1.25 / Ubuntu 24.04 / glibc / OpenSSL 全部固定）
3. **收敛（Convergence）**：环境不同，输出必须一致（dev 的 go test = CI 的 go test = 生产的同一个 binary）
4. **契约（Contract）**：环境之间只通过 artifact 与 config schema 通信

所有平台能力都围绕这一件事展开：

```
 Platform Engineering
        │
        ▼
 Development ≠ Build ≠ Runtime（隔离）
        │
        ▼
      行为一致（收敛）
        │
 ┌──────┬──────┬──────┬──────┬──────┐
 IaC   CI/CD  Artifact Config Observability
 Terraform GHA  Harbor  Vault  Prometheus
        │
        └──────── 都是支撑 ────────┘
```

工具会变化，但「开发环境 ≠ 构建环境 ≠ 运行环境」的隔离与收敛，是几十年来软件工程始终在解决的核心问题。

---

## 八、务实的最小升级路径

不要一上来就上 Nix / Bazel（那是大厂玩法），给出现实路径：

**Step 1：强制 Docker 化构建**
所有构建必须在 Docker 里完成，base image 固定版本。

**Step 2：Artifact 固化**
每次 build 输出 `image: <app>:<git-sha>`，禁止线上构建。构建一次，到处部署。

**Step 3：环境分层**
已有 sit / uat / prod？补上关键一刀：**不同环境部署同一个 artifact**。

**Step 4：依赖冻结**
- Python → requirements.txt（锁版本）
- Node → package-lock.json
- Docker → digest（不用 tag）

**Step 5（进阶）：引入运行时契约**
用一份 spec 声明 required/optional env、依赖类型、config 来源，启动时校验。

---

## 九、总结

从 LFS 到 mock，本质不是「更复杂」，而是：

> 🔥 **让构建从「过程」变成「可复现的产品」。**

从 Linux 发行版到 DevOps，本质变化是：

> 🔥 **从「系统决定软件如何运行」→「软件自己定义运行契约」。**

而平台工程的全部工作，可以收敛为一句话：

> **持续缩小开发环境、构建环境、运行环境之间的差异，同时保持它们彼此隔离——最终输出必须一致。**

这就是环境工程（Environment Engineering），也是平台工程超越具体工具的本质。

---

*（本文整理自工程实践讨论，围绕 LFS/chroot/mock 构建隔离、静态/动态链接、config/env、Runtime Contract 与平台工程展开。）*
