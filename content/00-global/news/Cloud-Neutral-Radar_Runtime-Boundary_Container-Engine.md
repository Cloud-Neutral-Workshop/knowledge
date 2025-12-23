# Cloud-Neutral 资讯雷达｜平台基础设施运行时 · 容器引擎

# 容器引擎（Container Engine）

**容器引擎** 是 Cloud-Neutral Tool Map 中 ** 应用运行时（Application Runtime）**这一层的核心能力。

如果说 **KVM / QEMU** 解决的是：**计算资源如何被切分与隔离** 那么 **容器引擎** 解决的则是：应用进程如何被打包、启动、隔离并持续运行**

它不是调度器，不是平台，也不是 PaaS，而是 应用从“镜像”到“进程”的那条最短、最关键路径。

---

## 项目主要特性

- **基于 Linux Kernel 的进程级隔离**
  - Namespace：进程 / 网络 / 文件系统 / 用户隔离
  - Cgroups：CPU / 内存 / IO 资源限制
  - Capabilities / Seccomp：最小权限控制

- **OCI 标准实现**
  - OCI Image：镜像格式标准
  - OCI Runtime：运行时接口标准
  - OCI Distribution：镜像分发标准

- **核心职责高度聚焦**
  - 拉取镜像
  - 创建容器
  - 启动进程
  - 管理生命周期

- **Kubernetes 的执行基石**
  - kubelet 并不直接运行容器
  - 一切 Pod，最终都要落到容器引擎执行

---


## 典型实现


- **Docker Engine**

  - 一体化体验

  - 强调开发者友好

  - 历史包袱较重


- **containerd**

  - CNCF 项目

  - Kubernetes 默认运行时

  - 专注、稳定、工业化


- **CRI-O**

  - 专为 Kubernetes 设计

  - Red Hat / OpenShift 体系常用

  - 接近 kubelet 的最小实现


---


## 优缺点


### 优点


- 启动速度快，资源开销小

- 与 Linux 深度融合

- 镜像可移植性强

- 云厂商与 Kubernetes 生态事实标准


### 局限


- 隔离强度弱于虚拟机

- 安全边界依赖内核正确性

- 生命周期管理粒度偏低

- 不具备资源池与多租户视角


---


## 适用场景


### 适合


- 云原生应用运行

- 微服务 / Web 服务

- CI / CD 执行环境

- Kubernetes 工作负载承载


### 不适合


- 强隔离多租户（需 VM 边界）

- 需要完整 OS 语义的传统系统

- 单机手工运维的应用管理


---


## 工程判断


**容器引擎不是平台，它是“进程启动器”。**


它的工程责任边界非常清晰：


- 不做调度

- 不做编排

- 不管理集群

- 不理解业务


它只关心一件事：


> **如何在受控环境中，把一个镜像，可靠地变成一组正在运行的进程**


在典型云原生架构中，层级关系如下：
```
物理机
└── KVM / Hypervisor
└── VM
└── Container Engine
└── Container / Pod
└── Application Process
```

在 Cloud-Neutral 体系中，它的位置同样明确：

- **KVM / QEMU**：提供算力与安全边界  
- **容器引擎**：提供应用进程隔离与启动  
- **Kubernetes**：负责编排与调度  
- **PaaS / 平台能力**：提供工程效率  

---

## 一个常见但危险的误解

**“容器比虚拟机更轻，所以可以替代虚拟机。”** 这是一个工程语境下的伪命题。

- 容器解决的是 **应用运行密度**
- 虚拟机解决的是 **安全与资源边界**

现实世界里的云，几乎全部是：**VM 上跑容器，而不是容器替代 VM**

---

## 项目地址

- Docker：https://www.docker.com  
- containerd：https://containerd.io  
- CRI-O：https://cri-o.io  

---

> **如果说 Kubernetes 是应用世界的“调度大脑”，那容器引擎，就是把每一次调度真正变成“正在运行”的那双手。**
