# Documentation Page Redesign Specification

## 1. Overview
Refactor the `/docs` section of `console.svc.plus` to strictly load content from `cloud-neutral-workshop/knowledge/docs`. The UI will be redesigned to match the [Pigsty Documentation](https://pigsty.cc/docs/) layout while maintaining the existing `console.svc.plus` visual identity (Tailwind tokens, fonts, and colors).

## 2. Layout Structure

The layout will consist of a fixed header and a three-column content area (on desktop).

### 2.1. Global Header (Modified)
- **Content**: Logo, Main Nav (Home, Docs, Blog, etc.), Search Bar, GitHub Link, User Profile.
- **Additions**: 
  - **Version Selector**: Dropdown to switch between documentation versions (if available).
  - **Search**: Integrated Algolia/Command-K search bar.

### 2.2. Left Sidebar (Navigation)
- **Behavior**: Sticky, independently scrollable.
- **Content**: 
  - Tree-view navigation structure matching the directory structure of `knowledge/docs`.
  - **Expandable/Collapsible**: Categories should be collapsible folders.
  - **Active State**: clear visual indicator for current page.

### 2.3. Main Content Area (Center)
- **Typography**: Optimized for long-form reading (prose, decent line-height).
- **Elements**:
  - Breadcrumbs at the top.
  - H1 Title.
  - Last updated timestamp.
  - Content rendered via MDX/Markdown.
  - **Feedback Section (Footer)**: "Is this page helpful?" (Yes/No buttons) similar to Pigsty.
  - Prev/Next page navigation links.

### 2.4. Right Sidebar (Table of Contents & Meta)
- **Behavior**: Sticky, hidden on mobile.
- **Content**:
  - **On this Page**: Auto-generated TOC from H2/H3 headers.
  - **Metadata**: 
    - "Module": Tags or categorization pills.
    - "Edit this page": Link to GitHub source.
    - "Contributors": List of contributors (optional).

## 3. Visual Style & Theming
- **Colors**: Use existing `brand-*` and `surface-*` tokens from `console.svc.plus`.
  - Sidebar Background: `bg-surface-muted` or `bg-background` with right border.
  - Active Link: `text-primary` with `bg-primary/10` background.
- **Responsiveness**:
  - **Mobile**: Hambergur menu to open Sidebar. TOC hidden or moved to top of content (Accordion).

## 4. Implementation Plan

### 4.1. Data Source
- Ensure `scripts/sync-doc-content.sh` pulls specifically from `knowledge/docs`.
- Update `contentlayer` or `next-mdx-remote` configuration to handle the nested structure of `docs/`.

### 4.2. Components
1. **`DocsLayout`**: Wrapper for the 3-column grid.
2. **`SidebarTree`**: Recursive component for navigation.
3. **`TOC`**: Component to parse headings and display right sidebar.
4. **`FeedbackWidget`**: Simple interactivity for user sentiment.

## 5. Reference
- **Inspiration**: [Pigsty Docs](https://pigsty.cc/docs/)
- **Theme**: Cloud-Neutral Toolkit (Dark/Light mode support).
