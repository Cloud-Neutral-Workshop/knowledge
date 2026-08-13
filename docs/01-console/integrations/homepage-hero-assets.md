# Homepage hero assets

## TL;DR

首页结构与本地回退内容保持在代码中，主视觉图片、卡片标题和说明可以从公开的 S3 或 CDN 动态加载。部署时配置：

```dotenv
NEXT_PUBLIC_HOME_HERO_CONTENT_URL=https://assets.svc.plus/marketing/home-hero/content.json
NEXT_PUBLIC_HOME_HERO_MEDIA_BASE_URL=https://assets.svc.plus
NEXT_PUBLIC_HOME_HERO_ASSET_VERSION=2026-07-11.1
```

修改 S3 上的 JSON 或图片后，更新 `NEXT_PUBLIC_HOME_HERO_ASSET_VERSION` 并重新构建前端，即可让浏览器请求带上新的 `?v=` 参数。远程请求失败、JSON 无效或变量留空时，首页会自动回退到仓库内置文案和插画占位符，不影响现有布局。

## Variables

| Variable                               | Purpose                        | Example                                                    |
| -------------------------------------- | ------------------------------ | ---------------------------------------------------------- |
| `NEXT_PUBLIC_HOME_HERO_CONTENT_URL`    | 公开的多语言 JSON 配置完整 URL | `https://assets.svc.plus/marketing/home-hero/content.json` |
| `NEXT_PUBLIC_HOME_HERO_MEDIA_BASE_URL` | 公开图片资源根 URL             | `https://assets.svc.plus`                                  |
| `NEXT_PUBLIC_HOME_HERO_ASSET_VERSION`  | JSON 和图片的缓存破坏/发布版本 | `2026-07-11.1`                                             |

这些变量会进入浏览器构建产物。只允许填写公开 URL 和非敏感版本号，不要放 AWS Access Key、Secret Key、私有 bucket 地址或长期签名 URL。

## Content JSON example

`NEXT_PUBLIC_HOME_HERO_CONTENT_URL` 返回的 JSON 按语言提供可选覆盖字段：

```json
{
  "zh": {
    "eyebrow": "XWorkmate / AI Workspace",
    "title": "统一云原生与网络运维，化繁为简，安全可控",
    "subtitle": "在单一平台上观测、调度与保护您的基础设施与应用，跨云跨地域一致体验，开放兼容，按需扩展。",
    "imageUrl": "https://assets.svc.plus/marketing/home-hero-2026-07-11.png",
    "version": "2026-07-11.1"
  },
  "en": {
    "eyebrow": "XWorkmate / AI Workspace",
    "title": "Unified cloud-native and network operations",
    "subtitle": "Observe, orchestrate, and protect infrastructure and applications from one platform.",
    "imageUrl": "https://assets.svc.plus/marketing/home-hero-2026-07-11.png",
    "version": "2026-07-11.1"
  }
}
```

所有字段均可选。`imageUrl` 存在时优先使用它；省略时，页面会按以下规则构造图片地址：

```text
${NEXT_PUBLIC_HOME_HERO_MEDIA_BASE_URL}/marketing/home-hero.png?v=${version}
```

JSON 内语言项的 `version` 优先用于图片 URL；没有该字段时回退到 `NEXT_PUBLIC_HOME_HERO_ASSET_VERSION`。

## Minimal S3 layout example

```text
s3://svc-plus-public-assets/
└── marketing/
    ├── home-hero.png
    └── home-hero/
        └── content.json
```

若直接从 S3 或 CloudFront 在浏览器加载，需允许 `console.svc.plus` 和本地开发源发起 `GET` 请求。最小 S3 CORS 示例：

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["https://console.svc.plus", "http://localhost:3000"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

建议通过 CloudFront 或其他 CDN 公开只读资源，并为 JSON 使用较短缓存、图片使用长缓存和版本化文件名。

## Version rollout example

1. 上传新图片，例如 `marketing/home-hero-2026-07-18.png`。
2. 更新 `content.json` 中的 `imageUrl` 和 `version`。
3. 将部署变量 `NEXT_PUBLIC_HOME_HERO_ASSET_VERSION` 更新为 `2026-07-18.1`。
4. 重新构建并发布前端；`NEXT_PUBLIC_*` 值在 Next.js 构建时写入浏览器包。
5. 验证中英文首页；如远端资源不可用，页面应显示本地回退内容。

仅更新 JSON 中的文案或 `imageUrl` 时，当前实现使用 `cache: no-store` 获取 JSON，因此无需修改页面代码。更新部署变量本身仍需重新构建前端。
