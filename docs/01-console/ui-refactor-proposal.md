# UI 主题与风格重构方案

作为资深 Web UI 设计师和前端工程师，针对我们 SaaS 控制台当前的 Next.js + Tailwind CSS 架构，结合 WCAG 可访问性标准和跨端响应式需求，特制定此 UI 重构方案。方案旨在提升整体视觉一致性、深色模式的可访问性，并优化桌面与移动端的用户体验（特别是 iOS/Android 浏览器的触控和渲染差异）。

---

## 1. 审查现有界面

在审查当前的界面代码（如 `tailwind.config.js`, `src/app/globals.css`, `src/components/theme/` 及 `Navbar.tsx`）后，我发现了以下改进点：

*   **色彩硬编码与对比度**：在部分文件（如 `designTokens.ts` 和 `Navbar.tsx` 的内联类名）中仍然存在类似 `#3467e9`, `bg-[#f6f7f9]` 的硬编码颜色，这破坏了主题切换的完整性。同时，深色模式下的次级文本（如 `text-muted` `#cbd5f5`）在深色背景（`#0f172a`）上的对比度可能无法满足 WCAG AA 级 4.5:1 的标准。
*   **语义化不足**：`Navbar.tsx` 中的菜单项过度使用了 `<div>` 和普通的 `<a>` 标签，缺少 `<nav>`, `<ul>`, `<li>` 结构，并且缺乏管理下拉/折叠状态的 `aria-expanded` 属性。
*   **触控目标尺寸**：移动端的某些交互元素（如链接和图标按钮）没有保证至少 44px × 44px 的物理点击区域，这在 iOS/Android 设备上容易造成误触。
*   **深色模式层级**：深色模式主要依赖背景色区分层级（如 `surface-muted`），缺乏细微的边框（Border）或发光阴影（Glow/Shadow）来凸显浮动面板（如 Dropdown 菜单）。

---

## 2. 定义设计系统 Token

我们需要收敛硬编码颜色，改用语义化的 CSS 变量（Token），并对深/浅色模式设定严格的对比度要求。

### 颜色 Token 规划

*   **背景色**：
    *   浅色：纯白 `#ffffff` (Surface) 或极浅灰 `#f8fafc` (Background)。
    *   深色：避免纯黑，使用 `#0f172a` (Background) 和微亮的暗灰 `#1e293b` (Surface)，减轻视觉疲劳。
*   **文本色**：
    *   主要文本 (`--color-text`)：浅色模式 `#0f172a`，深色模式 `#f8fafc`。
    *   次要文本 (`--color-text-muted`)：确保在深浅背景下对比度均大于 4.5:1。浅色推荐 `#475569`，深色推荐 `#94a3b8`。
*   **主色与交互色**：
    *   `--color-primary`：统一使用高对比度的主题蓝（如 `#2563eb`），确保按钮上的白色文字（`--color-primary-foreground`）对比度达标。

### Tailwind / CSS 变量伪代码

```css
/* src/app/globals.css 补充与覆盖 */
:root {
  /* 基础结构色 */
  --bg-color: #f8fafc;
  --surface-color: #ffffff;
  /* 文本色 */
  --text-color: #0f172a;
  --secondary-color: #475569;
  /* 主色调 */
  --primary: #2563eb;
  --primary-foreground: #ffffff;
  /* 边框与分隔线 */
  --border-color: #e2e8f0;
}

:root[data-theme="dark"],
.dark {
  --bg-color: #0f172a;
  --surface-color: #1e293b;
  --text-color: #f8fafc;
  --secondary-color: #94a3b8; /* 保证对比度 > 4.5:1 */
  --primary: #3b82f6; /* 在深色背景下稍微提亮主色 */
  --primary-foreground: #ffffff;
  --border-color: #334155;
  /* 深色模式下的特殊视觉补偿 */
  --shadow-elevation: 0 4px 6px -1px rgba(0, 0, 0, 0.5), 0 2px 4px -2px rgba(0, 0, 0, 0.5);
}
```

---

## 3. 设计排版体系

排版需兼顾多语言（中英文混合）和多端阅读体验。

*   **字体选择**：保留现有的 `Geist`，同时后备配置 `Inter` 或 `Noto Sans SC` 以优化中文显示：
    `font-family: var(--font-geist-sans), 'Inter', 'Noto Sans SC', sans-serif;`
*   **字号范围 (Fluid Typography / 断点响应)**：
    *   **移动端**：基础字号 16px（防止 iOS Safari 输入框自动缩放），正文 `16px - 18px`，大标题约 `24px - 28px`。
    *   **桌面端**：正文 `16px - 20px`，大标题可达 `32px - 48px`。
*   **行高与间距**：正文行高 `1.5` 至 `1.6`（150%-160%），段落间距使用 `margin-bottom: 1.5em`。标题行高缩紧至 `1.2`。

---

## 4. 构建全局样式与主题切换

当前系统已通过 Zustand (`store.ts`) 和 `ThemeProvider.tsx` 实现了基于 `localStorage` 和 `data-theme` 的切换。

*   **优化防闪烁 (FOUC)**：由于在 Next.js 中客户端 Hydration 会有延迟，需要确保在 `<head>` 中注入一个同步脚本读取 `localStorage` 和 `prefers-color-scheme`，在 React 渲染前就应用 `dark` 类或 `data-theme`。
*   **深色模式下的层级分离**：避免仅仅改变背景色。对于弹窗、Dropdown 等元素，在深色模式下增加一个极细的亮色边框：
    ```css
    .dark .surface-elevated {
      border: 1px solid rgba(255,255,255,0.1);
      box-shadow: var(--shadow-elevation);
    }
    ```

---

## 5. 响应式布局策略

*   **断点定义**：
    *   移动端：`< 768px` (Tailwind 默认 `md` 以下)。
    *   平板/桌面端：`>= 768px` (`md` 及以上)。
*   **移动端 (iOS/Android) 策略**：
    *   隐藏复杂的侧边栏（Sidebar），顶部导航精简为 Logo 和汉堡菜单。
    *   所有的按钮 (`button`, `a`) 必须拥有至少 `min-h-[44px] min-w-[44px]` 的触控区域（可以使用 padding 撑开）。
*   **桌面端策略**：
    *   最大化利用横向空间，采用 Sidebar + Main Content 或全宽 Header 的多列布局。

---

## 6. 重构导航菜单 (示例)

当前 `Navbar.tsx` 使用了平铺的链接。我们需要使用语义化标签，并通过 `aria-expanded` 增强可访问性，并分离移动端的汉堡菜单和桌面端菜单。

### 菜单组件伪代码

```tsx
'use client'
import { useState } from 'react';

export default function SemanticNavbar() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);

  return (
    <header className="sticky top-0 z-50 w-full bg-surface border-b border-border">
      <nav className="max-w-7xl mx-auto px-4 min-h-[64px] flex items-center justify-between" aria-label="Main Navigation">
        {/* Logo */}
        <div className="flex-shrink-0">
          <a href="/" className="font-bold text-text-color text-lg flex items-center min-h-[44px]">Logo</a>
        </div>

        {/* Desktop Menu */}
        <ul className="hidden md:flex items-center gap-6">
          <li>
            <a href="/dashboard" className="text-secondary-color hover:text-text-color transition-colors py-2">
              控制台
            </a>
          </li>
          <li className="relative group">
            {/* 父菜单如果是功能性展开按钮，使用 button */}
            <button
              aria-expanded={isDropdownOpen}
              aria-controls="services-dropdown"
              onClick={() => setIsDropdownOpen(!isDropdownOpen)}
              className="flex items-center gap-1 text-secondary-color hover:text-text-color py-2"
            >
              服务 <ChevronDownIcon />
            </button>
            {/* Dropdown 弹窗 */}
            <ul
              id="services-dropdown"
              className={`absolute top-full left-0 mt-2 w-48 bg-surface-elevated border border-border rounded-md shadow-md ${isDropdownOpen ? 'block' : 'hidden'}`}
            >
              <li>
                {/* 保证键盘 Tab 键能聚焦到这里 */}
                <a href="/service/1" className="block px-4 py-3 text-text-color hover:bg-surface-hover">服务一</a>
              </li>
            </ul>
          </li>
        </ul>

        {/* Mobile Hamburger Button */}
        <div className="md:hidden">
          <button
            aria-controls="mobile-menu"
            aria-expanded={isMobileMenuOpen}
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="p-2 min-w-[44px] min-h-[44px] text-text-color"
            aria-label="Toggle navigation"
          >
            <HamburgerIcon />
          </button>
        </div>
      </nav>

      {/* Mobile Menu Panel */}
      <div
        id="mobile-menu"
        className={`md:hidden overflow-hidden transition-[max-height] duration-300 ease-in-out ${isMobileMenuOpen ? 'max-h-screen' : 'max-h-0'}`}
      >
        <ul className="px-4 pb-4 space-y-2 bg-surface">
          <li>
            <a href="/dashboard" className="block py-3 text-text-color">控制台</a>
          </li>
          {/* 移动端子菜单可以直接平铺或使用手风琴折叠 */}
          <li>
            <span className="block py-3 text-secondary-color font-semibold">服务</span>
            <ul className="pl-4 space-y-2 border-l-2 border-border ml-2">
              <li><a href="/service/1" className="block py-3 text-text-color">服务一</a></li>
            </ul>
          </li>
        </ul>
      </div>
    </header>
  );
}
```

---

## 7. 针对移动端和桌面端的优化差异

*   **iOS/Android 浏览器差异处理**：
    *   **iOS Safari 底部安全区**：在主内容区底部增加 `padding-bottom: env(safe-area-inset-bottom);`，避免按钮被 Home Indicator 遮挡。
    *   **字体抗锯齿 (Anti-aliasing)**：在 `globals.css` 中的 `body` 标签已设置 `-webkit-font-smoothing: antialiased;`，在深色模式下这能让细小的亮色文字边缘更加平滑，没有晕影。
    *   **长文本限制**：在博客或文档页面，容器设置 `max-w-prose` (相当于 `max-width: 65ch`)，确保每行不超过 60 个字符，提升阅读体验。
*   **桌面端强化**：
    *   可利用 Hover 状态提供丰富的反馈（如背景变色、细微的 `transform: translateY(-1px)`）。
    *   在宽屏上显示侧边栏和次要信息列（多列网格布局）。

---

## 8. 可访问性测试与迭代流程

为确保重构后的界面符合标准，开发团队应在提交代码前进行以下检查：

1.  **对比度扫描**：使用 Chrome DevTools 的 Lighthouse 或 WebAIM 对比度检查器，确保所有的正文/背景对比度 >= 4.5:1，大号文本 >= 3.0:1。
2.  **重排与缩放测试**：使用浏览器的缩放功能放大页面到 `200%` 和 `400%`。确保在 `400%` 下页面自动转为单列移动端布局，且文字不出现截断或相互重叠（开启 CSS 文本重排 `text-wrap: balance` 或避免固定高度）。
3.  **键盘导航测试**：不使用鼠标，仅用 `Tab` 和 `Enter` 遍历界面。确保所有交互元素有明显的 `:focus-visible` 外框线（Tailwind `focus-visible:ring-2 focus-visible:ring-primary`）。二级菜单不能在 Tab 聚焦到父元素时自动弹出（除非是用按钮触发），以避免用户被迫穿过无数个子菜单才能到达下一个主栏目。
4.  **屏幕阅读器体验**：开启 VoiceOver (Mac/iOS) 或 TalkBack (Android)，验证 `aria-expanded`, `aria-controls` 等状态是否能被正确播报。
