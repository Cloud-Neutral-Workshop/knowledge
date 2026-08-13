# 审计：任何构建产物都会直连 PROD 服务

**结论：成立，且有两条互相独立的路径。** 修掉其中任何一条，另一条仍然会让
SIT / UAT / 本地开发的构建连上生产认证服务。

审计对象：`src/config/`、`src/server/runtime-loader.ts`、`Dockerfile`、
`.github/workflows/pipeline.yaml`。

---

## 路径一：环境检测永远落到 `prod`

`runtime-loader.ts` 解析环境的顺序是：`RUNTIME_ENV` 环境变量 → 四个候选配置
文件路径 → **默认值**。默认值是：

```ts
runtimeEnvSettingsCache = {
  environment: 'prod',        // ← src/server/runtime-loader.ts:359
  region: 'default',
  detectedBy: 'default',
}
```

而前面每一级都不会命中：

| 检测手段 | 实际情况 |
|---|---|
| `process.env.RUNTIME_ENV` | **CI 从不设置它。** CI 传的是 `NEXT_PUBLIC_RUNTIME_ENVIRONMENT` —— 两个不同的变量名，loader 不读后者 |
| `RUNTIME_ENV_CONFIG_PATH` | 未设置 |
| `dashboard/config/.runtime-env-config.yaml` | 不存在 |
| `src/config/.runtime-env-config.yaml` | 不存在 |
| `./.runtime-env-config.yaml` | 不存在 |

`.runtime-env-config.yaml` **被 `.gitignore` 排除（3 处），且 `Dockerfile` 完全
不生成它**。镜像里没有这个文件，四个候选路径全部落空。

于是**每一个构建出来的镜像，只要没人手工挂载那个文件，都以 `prod` 身份运行**。

雪上加霜的是 `pipeline.yaml:51` 在 workflow 顶层写死了
`NEXT_PUBLIC_RUNTIME_ENVIRONMENT: prod` —— 即使有人把 loader 改成读这个变量，
默认拿到的仍是 `prod`。

### 附带缺陷：`main` 被映射为 `prod`

```ts
const mapping: Record<string, RuntimeEnvironment> = {
  main: 'prod',              // ← runtime-loader.ts:237
  release: 'prod',
  ...
}
```

组织的环境路由规范是 **`main` push → UAT，生产只经 `v*` tag**
（`engineering-standards/multi-environment-delivery-and-release` §1）。这张表
把 `main` 判成 `prod`，与整条交付链的路由规则相反。

---

## 路径二：`base.yaml` 把生产地址写进了"所有环境共享"层

```yaml
# Base runtime configuration shared by all environments.
apiBaseUrl: https://rag-server-svc-plus-...run.app
authUrl: https://accounts.svc.plus        # ← 生产认证服务
dashboardUrl: https://www.svc.plus        # ← 生产站点
docsServiceUrl: https://docs.svc.plus     # ← 生产文档
```

配置是 `base` 与环境覆盖层做 merge。所以**任何没被环境层显式覆盖的键，都会
沿用 base 里的生产地址**。

`sit.yaml` 覆盖了什么、漏了什么：

| 键 | base（生产） | sit 覆盖 | 结果 |
|---|---|---|---|
| `apiBaseUrl` | run.app | `http://127.0.0.1:8080` | ✅ |
| `dashboardUrl` | `www.svc.plus` | `http://localhost:3000` | ✅ |
| **`authUrl`** | **`accounts.svc.plus`** | **未覆盖** | ❌ **SIT 连生产认证** |
| **`docsServiceUrl`** | **`docs.svc.plus`** | **未覆盖** | ❌ **SIT 连生产文档** |

**即使路径一被修好、环境被正确识别为 `sit`，认证请求仍然打到生产。**

### 附带缺陷：`uat` 和 `dev` 没有配置源

```ts
type RuntimeSourceKey = 'base' | 'prod' | 'sit'          // 3 个
export type RuntimeEnvironment = 'dev' | 'uat' | 'prod' | 'sit'   // 4 个

const source: RuntimeSourceKey = environment === 'prod' ? 'prod' : 'sit'
```

类型声明本身就暴露了不匹配。这个"非 prod 即 sit"的三元表达式意味着：

- `uat` → 用 SIT 的端点（`127.0.0.1:8080`，在 UAT 主机上根本不存在）
- `dev` → 同上

UAT 既连不上自己的服务，又通过 base 的漏项连着生产认证。

---

## 为什么这个问题能长期存在

三层失败全部是**静默的**：

1. 配置文件缺失 → `loadYamlSource` 只 `console.warn`，返回 `undefined`，继续跑
2. 环境检测落空 → 不报错，安静地选 `prod`
3. base 的键没被覆盖 → merge 的正常语义，看不出是"漏了"

没有任何一处会让构建失败或让启动报错。一个连着生产认证服务的 SIT 环境，
从日志上看和配置正确的 SIT 完全一样。

与 `platform-ops-toolkit` 交付链上那一批缺陷同源
（[陷阱清单](https://github.com/ai-workspace-infra/platform-ops-toolkit/blob/main/docs/tasks/2026-07-25-delivery-chain-workplan.md#0-陷阱清单必读)
#15/#16：Jinja 缺键渲染成空串、空口令不让任何东西崩溃）——
**默认值指向危险的方向，且失败不报错。**

---

## 路径三：Dockerfile 把 `RUNTIME_ENV=prod` 烧进镜像

```dockerfile
ENV NODE_ENV=production \
    RUNTIME_ENV=prod \        # ← Dockerfile:106
    REGION=cn \
```

`runtime-loader` 检测环境的**第一级**就是 `process.env.RUNTIME_ENV`，所以它在每次
容器启动时都命中。**路径一里那个默认值根本走不到。**

> 这同时更正本文档最初的一处判断：先前写"`RUNTIME_ENV` 从未被设置"是错的 ——
> 它被设置了，设成 `prod`，只是在当时检视的范围外一层。第一级分支已经命中时，
> 改兜底值没有任何作用。

已修（portal#114 移除，gitops#115 改为部署时注入）。

## 路径四：`NEXT_PUBLIC_*` 在 CI 顶层被硬编码为生产值

`.github/workflows/pipeline.yaml` 的 workflow 顶层 `env:`：

```yaml
NEXT_PUBLIC_APP_BASE_URL: https://console.xworkmate.com
NEXT_PUBLIC_SITE_URL: https://console.xworkmate.com
ACCOUNT_SERVICE_URL: https://accounts.svc.plus
RUNTIME_HOSTNAME: console.xworkmate.com
```

`NEXT_PUBLIC_*` 会被 **编译进客户端 bundle**，运行时无法更改。所以这条路径
不受路径一至三的修复影响。

`build` job 只覆盖了其中一个：

| 变量 | PR（SIT）构建里的实际值 | |
|---|---|---|
| `NEXT_PUBLIC_RUNTIME_ENVIRONMENT` | `sit` | ✅ 第 100 行按环境覆盖 |
| `NEXT_PUBLIC_APP_BASE_URL` | `https://console.xworkmate.com` | ❌ |
| `NEXT_PUBLIC_SITE_URL` | `https://console.xworkmate.com` | ❌ |
| `ACCOUNT_SERVICE_URL` | `https://accounts.svc.plus` | ❌ |

覆盖机制本身是可用的 —— `NEXT_PUBLIC_RUNTIME_ENVIRONMENT` 已经用它按环境取值。
缺的是把其余几个也纳入。

**未修，因为需要一个我无法从代码推断的事实**：SIT 环境对应的域名。UAT 的可以
从 provision 输出确定（`console-uat` / `accounts-uat` + `TARGET_DOMAIN_BASE`），
prod 已知，但 SIT 用什么域名（或是否根本不对外暴露）需要确认。填错域名比暂时
留着更糟：它会变成一个"看起来已经修好"的错误配置。

### 与 runtime config 的关系待厘清

`NEXT_PUBLIC_APP_BASE_URL` 与 `runtime-service-config.<env>.yaml` 的
`dashboardUrl`/`authUrl` 是两套并行的来源。修路径四之前需要先确定：应用代码在
两者都存在时以哪个为准。否则可能出现"改了一个、另一个仍然生效"的局面 ——
与本次审计发现的每一条都是同一种失败形态。

## 修复方向

按"改一处就能减少一条路径"排序：

1. **默认环境改为最不危险的方向。** 检测不出环境时应当是 `dev`（或直接抛错），
   绝不能是 `prod`。这一条单独就能挡住本地开发直连生产。
2. **`base.yaml` 移除所有环境特定的服务地址。** base 只放真正与环境无关的东西。
   任何服务端点都必须由环境层显式给出——缺失时应当让启动失败，而不是沿用一个
   "看起来能用"的生产地址。
3. **统一变量名。** loader 读 `RUNTIME_ENV`，CI 传 `NEXT_PUBLIC_RUNTIME_ENVIRONMENT`。
   二者取其一，并让 `Dockerfile` 把它写进 `.runtime-env-config.yaml`，
   或在运行时注入 `RUNTIME_ENV`。
4. **补 `runtime-service-config.uat.yaml` 与 `.dev.yaml`**，
   并把 `source` 的选择从三元表达式改成显式映射，让新增环境时缺文件会**报错**
   而不是静默落到 `sit`。
5. **`main: 'prod'` 改为 `main: 'uat'`**，与组织路由规范一致。

第 1、2 条是安全性的关键；第 3、4、5 条是让配置系统的行为与声明相符。
