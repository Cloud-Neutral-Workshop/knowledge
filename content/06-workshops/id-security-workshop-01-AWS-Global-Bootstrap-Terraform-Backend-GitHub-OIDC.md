# AWS × GitHub 一次性 Bootstrap（Root AccessKey 仅初始化使用）

> 目标：只用一次 root AccessKey，把“无密钥体系”搭起来（OIDC / IAM / Terraform Backend）。  
> 完成后彻底删除所有长期凭证，后续全部改用 **GitHub Actions OIDC + IAM Role** 获取 **AWS 临时凭证**。

---

## 1️⃣ AWS 侧：root 用户一次性 Bootstrap 准备（仅此一次）

**仅此一次**使用 AWS 账号 **root 用户**创建 AccessKey，用于初始化全局基础设施（OIDC / IAM / Backend）。

### 步骤要点
- 进入 **IAM → 安全凭证**
- 创建 **访问密钥（AccessKey：AK / SK）**
- **仅用于 bootstrap**, 完成后立即删除

### 目的（为什么需要 root AK/SK）

用于创建/初始化以下全局基础设施：

- 创建 **GitHub Actions OIDC Provider**
- 创建 **IAM Role**（支持 `AssumeRoleWithWebIdentity`）
- 初始化 **Terraform backend**（S3 / DynamoDB）

---

## 2️⃣ GitHub 侧：配置临时 Secrets（仅 Bootstrap 使用）

在 GitHub **Organization/Repo** 中配置一次性 Secrets（仅供 bootstrap workflow 使用）：

- `AWS_BOOTSTRAP_ACCESS_KEY_ID`
- `AWS_BOOTSTRAP_SECRET_ACCESS_KEY`

---

## 3️⃣ 运行 Bootstrap Pipeline

执行仓库中的 workflow：
    - `.github/workflows/iac-pipeline-aws-global-bootstrap.yaml`

该流程会完成以下事项：

- 初始化 Terraform backend（**S3 / DynamoDB**）
- 创建 GitHub Actions **OIDC Provider**
- 创建 IAM Role（**AssumeRoleWithWebIdentity**）
- 建立后续 CI/CD 的 **最小权限边界**

### 依赖仓库

- `https://github.com/cloud-neutral-workshop/gitops.git`
- `https://github.com/cloud-neutral-workshop/iac_modules.git`

---

## 4️⃣ Bootstrap 完成后的正确姿势（关键）

### ✅ 必须立刻做

- ✅ 删除 root 用户的 **AK / SK**
- ✅ 后续所有 workflow 使用 **OIDC + IAM Role**
