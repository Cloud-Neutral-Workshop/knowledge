
# Cloud-Neutral 资讯雷达｜交付与变更控制 · Terraform / OpenTofu

# Terraform / OpenTofu


**Terraform / OpenTofu** 是 Cloud-Neutral Tool Map 中 交付与变更控制（IaC & DevOps) 这一层的基础设施级核心工具，用于解决一个最根本的问题：

> **基础设施的变化，能否被清晰描述、审计，并可重复执行。**

它们不是部署工具，也不是运维脚本，而是把“云资源”抽象成一种可推理、可验证的状态机。
---

## 项目主要特性

- 声明式 IaC 模型：用代码描述期望状态，而非操作步骤  
- Plan / Apply 分离：变更在执行前即可被完整审阅  
- Provider 生态：统一管理多云与本地资源  
- 状态文件（State）**：显式记录现实世界的资源映射  
- 跨云一致性：AWS / GCP / 阿里云 / 私有环境通用

**OpenTofu** 作为 Terraform 的开源分支， 在保持生态兼容的同时，强调 **社区治理与中立性**。

---


## 优缺点

| 优点 | 局限 |
|---|---|
| IaC 事实标准，生态极其成熟 | 学习成本与心智模型较重 |
| 变更可审计、可回滚、可复现 | State 管理需要工程纪律 |
| 天然适配多云与混合环境 | 不适合高频、细粒度变更 |
| 与 CI/CD、GitOps 高度互补 | 不负责运行态配置 |

---

## 适用场景

| 适合 | 不适合 |
|---|---|
| 云资源创建与生命周期管理 | 应用级配置与发布 |
| 多云 / 混合云统一管理 | 高频、即时操作 |
| 需要严格变更审计的团队 | 纯命令式运维 |
| 与 Ansible / Argo CD 配合 | 作为应用配置管理 |
---

## 工程判断

Terraform / OpenTofu 并不关心系统“如何运行”，  而是坚定地站在 **“资源定义与变更控制”** 这一工程责任边界上：

> **让基础设施的每一次变化，都先在代码中发生。**

在成熟的体系中，它们的位置非常清晰：

- Terraform / OpenTofu 定义资源边界，  
- Ansible 落地系统配置，  
- Ansible 落地系统配置，  

---

## 项目地址

- Terraform：https://github.com/hashicorp/terraform  
- OpenTofu：https://github.com/opentofu/opentofu  
- 官网：https://developer.hashicorp.com/terraform  
- OpenTofu 文档：https://opentofu.org/docs  

---

> **如果说脚本是在“直接操作世界”，那 Terraform / OpenTofu，是在先定义世界应该长什么样。**

更多工程判断，见「**云原生工坊 · 工程技术雷达**」。
