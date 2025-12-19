# 使用 Argo CD 管理 Helm / Helmfile  

## 当 Helm 不再足以描述系统结构

> 本篇是 Argo CD 系列的第 04 篇，聚焦一个非常具体的工程问题：  
> **在 Argo CD 已经接管“状态收敛”之后，Kubernetes 应用的期望状态是如何被生成出来的？**

---

## 一、这一篇在系列中的位置

在前一篇中（`03-application-and-sync-model.md`），我们已经明确：

- Argo CD 的核心职责是 **持续判断并收敛状态**
- 它并不关心状态“如何被执行”，只关心状态“是否一致”

那么自然会引出下一个问题：

> **这些“期望状态 YAML”，到底是怎么生成的？**

Helm 与 Helmfile，正是 Argo CD 在“状态生成层”所支持的两种关键机制。

---

## 二、Helm 在 Argo CD 中的真实角色

在 Argo CD 的语境下，Helm 不再是一个“部署工具”。

它的角色被刻意压缩为一件事：

> **根据输入参数，生成一组 Kubernetes 声明式资源。**

Argo CD 只做两件事：

1. 调用 Helm（或 Helmfile）生成 manifests  
2. 对生成结果进行 diff、sync、self-heal

理解这一点，是区分 Helm / Helmfile 边界的前提。

---

## 三、三种 Helm 使用模式（清晰分层）

在实际工程中，Argo CD 管理 Helm 主要存在三种模式。

---

### 1. Helm 仓库中的 Chart（组件级）

这是最标准、也是最容易治理的一种模式。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: mysql
  namespace: argocd
spec:
  project: default
  source:
    chart: mysql
    repoURL: https://charts.onwalk.net
    targetRevision: 9.21.2
    helm:
      releaseName: mysql
  destination:
    server: "https://kubernetes.default.svc"
    namespace: itsm-dev-db
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
适用特征：

Chart 被视为“稳定制品”

values 只是参数输入

版本通过 targetRevision 明确锁定

这是组件级交付，非常适合数据库、中间件、基础服务。

2. Git 仓库中的 Helm Chart（应用级）
当 Helm Chart 本身就是应用代码的一部分时，通常采用这种方式。

yaml
复制代码
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: redis
  namespace: argocd
spec:
  project: default
  source:
    path: helm/redis
    repoURL: https://github.com/svc-design/gitops.git
    targetRevision: main
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: itsm-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
适用特征：

Chart 与应用生命周期强绑定

不适合作为通用制品复用

更强调代码审查与版本演进

这是应用级交付，常见于内部服务。

3. Helmfile（系统级，这是拐点）
当系统由多个 Chart 组成，且环境差异开始显著时，Helm 本身会逐渐失效：

values.yaml 数量膨胀

Chart 之间的关系无法表达

环境差异只能靠复制目录

Helmfile 的出现，正是为了解决这一类问题。

yaml
复制代码
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: itsm
  namespace: argocd
spec:
  project: default
  source:
    path: helmfiles/itsm
    repoURL: https://github.com/svc-design/gitops.git
    targetRevision: main
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: itsm-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
在这里：

Helmfile 描述的是系统结构

Chart 只是系统中的组成部分

环境差异通过 Helmfile 的环境机制统一表达

这是系统级交付。

四、Argo CD 如何集成 Helmfile（CMP 插件）
Argo CD 并没有内建 Helmfile 支持，而是通过
Config Management Plugin（CMP） 的方式进行集成。

这一设计是刻意的边界选择。

Helmfile 插件配置示例
以下配置展示了在 Argo CD 中启用 Helmfile 插件的完整方式：

yaml
复制代码
repoServer:
  extraContainers:
    - name: helmfile
      image: ghcr.io/helmfile/helmfile:v0.157.0
      command: ["/var/run/argocd/argocd-cmp-server"]
      env:
        - name: HELM_CACHE_HOME
          value: /tmp/helm/cache
        - name: HELM_CONFIG_HOME
          value: /tmp/helm/config
        - name: HELMFILE_CACHE_HOME
          value: /tmp/helmfile/cache
        - name: HELMFILE_TEMPDIR
          value: /tmp/helmfile/tmp
      securityContext:
        runAsNonRoot: true
        runAsUser: 999
      volumeMounts:
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
        - mountPath: /home/argocd/cmp-server/config/plugin.yaml
          subPath: helmfile.yaml
          name: argocd-cmp-cm
        - mountPath: /tmp
          name: helmfile-tmp
  volumes:
    - name: argocd-cmp-cm
      configMap:
        name: argocd-cmp-cm
    - name: helmfile-tmp
      emptyDir: {}
configs:
  cmp:
    create: true
    plugins:
      helmfile:
        allowConcurrency: true
        discover:
          fileName: helmfile.yaml
        generate:
          command:
            - bash
            - "-c"
            - |
              if [[ -v ENV_NAME ]]; then
                helmfile -n "$ARGOCD_APP_NAMESPACE" -e $ENV_NAME template --include-crds -q
              elif [[ -v ARGOCD_ENV_ENV_NAME ]]; then
                helmfile -n "$ARGOCD_APP_NAMESPACE" -e "$ARGOCD_ENV_ENV_NAME" template --include-crds -q
              else
                helmfile -n "$ARGOCD_APP_NAMESPACE" template --include-crds -q
              fi
        lockRepo: false
关键理解点：

Argo CD 只负责调用插件生成 manifests

Helmfile 的语义完全保留

控制权仍然集中在 Argo CD 的 diff / sync 机制中

五、自动同步与 Helm / Helmfile 的关系
在以上三种模式中，通常都会启用自动同步：

yaml
复制代码
syncPolicy:
  automated:
    prune: true
    selfHeal: true
这意味着：

Helm / Helmfile 只负责“生成期望状态”

Argo CD 负责“保证现实状态一致”

如果需要人为控制发布节奏，可以显式关闭：

yaml
复制代码
syncPolicy: {}
自动同步与否，并不是 Helm / Helmfile 的问题，
而是发布策略的问题，将在后续章节专门讨论。

六、小结：清晰的职责分工
到这里，可以给出一个清晰的工程判断：

Helm：渲染一个组件

Helmfile：渲染一个系统

Argo CD：对渲染结果负责持续收敛

当这三者各司其职时，GitOps 才不会退化为 YAML 的自动执行器。

参考
Argo CD 官方文档
https://argo-cd.readthedocs.io/en/stable/

Getting Started with Argo CD
https://argo-cd.readthedocs.io/en/stable/getting_started/

Deploying Helm Charts using Argo CD and Helmfile
https://christianhuth.de/deploying-helm-charts-using-argocd-and-helmfile/

markdown
复制代码

---

### 一句收尾确认

你给的原始内容 **一行都没丢**，  
只是从“能跑的教程”，变成了：

> **Argo CD 系列中，关于 Helm / Helmfile 的那一篇**
