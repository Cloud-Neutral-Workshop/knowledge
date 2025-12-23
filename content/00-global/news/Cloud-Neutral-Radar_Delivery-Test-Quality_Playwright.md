
# Cloud-Neutral 资讯雷达｜交付与测试 · Playwright

## Playwright

Playwright 是 Cloud-Neutral Tool Map 中 **交付与测试（E2E & Frontend Validation）** 层的核心工具之一。它关注的不是系统极限，而是一个更基础、也更刚性的工程问题：

> **用户关键路径，在真实浏览器中还能不能稳定走通。**

Playwright 的设计目标非常克制： 不是“像人一样操作浏览器”，而是 **让浏览器每次都以同样方式被操作**。

---

## 项目主要特性

- 真多浏览器支持（Chromium / Firefox / WebKit）
- 高确定性的自动化模型
- Headless / Headful 双模式
- 原生等待与并发控制
- 与 CI 深度集成

Playwright 的核心价值并不是“自动化”，而是： **可复现性。**

---

## 优缺点

| 优点 | 局限 |
|---|---|
| 稳定性与确定性高 | 并发能力有限 |
| 浏览器行为真实 | 资源消耗较高 |
| 适合回归测试 | 不适合压测 |
| 结果可信 | 不擅长探索未知 |

---

## 适用场景

| 适合 | 不适合 |
|---|---|
| 核心业务 E2E | 大规模并发 |
| CI 回归测试 | 后端容量评估 |
| 前端性能基线 | 模糊探索测试 |
| 合规 / 稳定性要求高 | |

---

## 工程判断

Playwright 的工程角色非常清晰：

> **它不是探索工具，而是“事实固定器”。**

在现代交付体系中，更合理的分工是：

> DevTools MCP 探索路径，  
> **Playwright 固化路径**，  
> k6 在 API 层放大验证。

---

## 项目地址

- GitHub：https://github.com/microsoft/playwright
- 官网：https://playwright.dev
- 文档：https://playwright.dev/docs

---

> Playwright 的价值在于：> **它告诉你，系统在“已知正确路径”上，是否仍然可靠。**

