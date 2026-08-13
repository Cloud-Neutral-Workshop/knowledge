# Cloudflare Web Analytics 集成配置

本页说明首页统计接口 `/api/marketing/home-stats` 依赖的 3 个 Cloudflare 环境变量如何获取，以及应配置到哪里。

## 需要的环境变量

```bash
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ACCOUNT_ID=
CLOUDFLARE_WEB_ANALYTICS_SITE_TAG=
```

## 变量获取方式

### 1) `CLOUDFLARE_API_TOKEN`

用途：服务端调用 Cloudflare GraphQL API 读取访问量。

获取路径：

1. 打开 Cloudflare 控制台，右上角头像 -> **My Profile**
2. 进入 **API Tokens**
3. 点击 **Create Token**
4. 建议创建仅只读 token，至少包含：**Account Analytics:Read**（作用域限定到目标 Account）
5. 复制生成后的 token（只显示一次）

### 2) `CLOUDFLARE_ACCOUNT_ID`

用途：GraphQL 查询时定位账号。

获取方式（任选其一）：

- 在 Cloudflare 控制台 URL 中，账号路径段通常就是 account id。
- 在账号总览页面（Overview）侧边栏/页面信息中复制 Account ID。

### 3) `CLOUDFLARE_WEB_ANALYTICS_SITE_TAG`

用途：定位具体 Web Analytics 站点。

获取方式（任选其一）：

- 你当前这类链接中可直接看到：
  `.../web-analytics/overview?siteTag~in=<SITE_TAG>&excludeBots=Yes`
  其中 `<SITE_TAG>` 就是变量值。
- 在 Cloudflare Web Analytics 的站点设置/安装脚本中，`siteTag`（或 beacon token）即对应值。

## 配置写入位置

### 本地开发

写入当前前端仓库的 `.env.local`：

```bash
CLOUDFLARE_API_TOKEN=...
CLOUDFLARE_ACCOUNT_ID=...
CLOUDFLARE_WEB_ANALYTICS_SITE_TAG=...
```

### 线上部署

把同名变量写入前端部署环境。

> 注意：这些变量属于服务端密钥，不要暴露到 `NEXT_PUBLIC_*`。

## 联调验证

部署后访问：

```bash
curl -fsSL https://www.svc.plus/api/marketing/home-stats
```

期望返回中 `visits.daily/weekly/monthly` 为数字（非 `null`）。

如果是 `null`，优先检查：

1. token 权限是否包含 Analytics Read
2. Account ID 是否与 siteTag 属于同一账号
3. 环境变量是否已在当前运行实例生效（重启/重新部署后再测）
