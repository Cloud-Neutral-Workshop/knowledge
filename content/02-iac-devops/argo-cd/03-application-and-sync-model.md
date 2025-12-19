
这一篇解决的核心问题

Argo CD 是如何“接管交付控制权”的？

它不关心 Helm、Helmfile、Chart 细节，
它关心的是：状态是如何被声明、比较、收敛的。

从原文中“归位”到第 03 篇的内容
✅ 1. Application 的基本模型

来自你原文中所有 Application 示例的共同结构：

apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
  destination:
  syncPolicy:


在第 03 篇里，这部分要被抽象为：

Application ≠ 一个应用

Application = 一个期望状态的声明

source / destination / syncPolicy 是控制权三要素

✅ 2. automated sync / selfHeal 的语义

来自原文：

syncPolicy:
  automated:
    prune: true
    selfHeal: true


在第 03 篇中，它不再是“配置说明”，而是：

automated sync = 持续对齐机制

selfHeal = 系统拥有修复权

prune = 声明以外的资源视为异常

👉 这一篇里只讲：
“Argo CD 在什么时候会动手”

✅ 3. 禁止在这里讨论 Helm / Helmfile

在第 03 篇中：

❌ 不解释 Helm

❌ 不解释 Helmfile

❌ 不解释 Chart 来源

因为此时还没进入“渲染层”。

第 03 篇内容边界总结

这一篇结束时，读者应该明白：

Argo CD 的核心不是“部署”，
而是持续判断：现实是否等于声明
