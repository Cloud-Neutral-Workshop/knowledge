# Cloud-Neutral 资讯雷达｜平台基础设施底座 · KVM / QEMU

# KVM / QEMU

**KVM / QEMU** 是 Cloud-Neutral Tool Map 中 **⑥ 平台基础设施底座（Platform Foundation）** 这一层最关键、也最容易被忽视的一块能力。如果说容器与 Kubernetes 定义了“应用如何运行”，  那么 **KVM / QEMU** 解决的则是一个更底层的问题：

> **计算资源，究竟如何被切分、隔离与抽象。**

---


## 项目主要特性

- **KVM** ：（Kernel-based Virtual Machine）Linux 内核原生虚拟化能力，将内核直接作为 Hypervisor
- **QEMU** ：通用虚拟化与硬件模拟器，为虚拟机提供完整的设备模型
- **软硬件解耦** ： 把 CPU / 内存 / 网络 / 存储抽象为可编排资源
- **云厂商 IaaS 的技术根基** ：大多数公有云与私有云计算节点，均构建于 KVM / QEMU 之上,KVM 提供性能与隔离， QEMU 提供完整性与可移植性。


---


## 优缺点


| 优点 | 局限 |
|---|---|
| Linux 原生能力，成熟稳定 | 运维复杂度较高 |
| 高性能，接近裸金属 | 学习曲线陡峭 |
| 广泛支撑公有云与私有云 | 不适合应用级管理 |
| 不绑定任何云厂商 | 通常需配套平台 |

---


## 适用场景


| 适合 | 不适合 |
|---|---|
| 私有云 / 自建 IaaS 平台 | 直接应用交付 |
| 云厂商计算节点 | 小规模、手工运维 |
| 对隔离与安全要求高 | 仅容器即可满足的场景 |
| OpenStack / Harvester 等 |企业自建虚拟化管理平台的场景 |

---


## 工程判断


KVM / QEMU 并不直接服务于应用， 而是明确站在“计算资源抽象”这一工程责任边界上: **所有云计算的弹性，本质都来自虚拟化。** 

容器不是虚拟化的替代品，而是寄生其上的优化层。在绝大多数公有云里：
```
物理机
 └── KVM / Hypervisor
     └── VM
         └── Container Runtime
             └── Pod / Container
```
在 Cloud-Neutral 体系中，它们的位置非常清晰：

- KVM / QEMU 提供算力抽象，  
- OpenStack / Harvester 管理资源池，  
- Kubernetes 承载工作负载。

---


## 项目地址

- KVM：https://www.linux-kvm.org  
- QEMU：https://www.qemu.org  
- 文档：https://www.qemu.org/documentation/  
---

> **如果说 Kubernetes 是“应用调度器”，  那 KVM / QEMU，就是云计算世界真正的物理引擎。**更多工程判断，见「**云原生工坊 · 工程技术雷达**」。

