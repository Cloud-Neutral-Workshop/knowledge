# Multi-Device Shared Session & Task Indexing Architecture

This document defines the multi-service architecture, database schemas, and frontend implementation for multi-device shared sessions and real-time task indexing across the AI Workspace ecosystem.

---

## 1. Linked Repositories & Service Boundaries

| Service / Repository | Path & Link | Language / Stack | Core Responsibility |
| :--- | :--- | :--- | :--- |
| **Portal (Frontend)** | [`portal`](file:///Users/shenlan/workspaces/ai-workspace-service/portal) | Next.js 16, React 18, Tailwind CSS | **Pure Frontend UI**: Bottom-docked Chat Composer, dynamic Task list reactive state, collapsible sidebars, and API proxy routing (`/api/ai-workspace/[...path]`). |
| **XWorkmate Bridge** | [`xworkmate-bridge`](file:///Users/shenlan/workspaces/ai-workspace-lab/xworkmate-bridge) | Go | **Session & Task Indexing & Gateway**: Maintains lightweight session metadata DB, handles TaskThread execution, and bridges heavy binary artifacts to S3 / Object Storage. |
| **Accounts Service** | [`accounts`](file:///Users/shenlan/workspaces/ai-workspace-service/accounts) | Go, PostgreSQL | **Identity & Device Authority**: Manages user accounts, tenant memberships, and registered terminal devices (`workspace_devices`). |
| **XWorkmate Desktop (Reference App)** | [`xworkmate-app`](file:///Users/shenlan/workspaces/ai-workspace-lab/xworkmate-app) | Flutter (Dart) | **Desktop Client Reference**: Reference implementation for `AppShellDesktop`, `buildWorkbenchProjection`, and dual-sidebar collapse mechanics. |

---

## 2. Multi-Service Topology & Data Flow

```
+-------------------------------------------------------------------------------+
|                      portal (Next.js - Pure Frontend)                         |
|  - Route: /ai-workspace                                                       |
|  - Components: Sidebar, ChatInputArea, RightContextPanel, Dashboard           |
|  - Reactive Store: taskStore.ts                                               |
|  - API Proxy: /api/ai-workspace/[...path]                                     |
+-------------------------------------------------------------------------------+
                                       |
                   +-------------------+-------------------+
                   |                                       |
                   v                                       v
+------------------------------------+   +--------------------------------------+
| accounts (Go Service)              |   | xworkmate-bridge (Go Gateway Service) |
| Repository:                        |   | Repository:                          |
| ai-workspace-service/accounts      |   | ai-workspace-lab/xworkmate-bridge    |
|                                    |   |                                      |
| - User Authentication              |   | - Shared Session Indexing            |
| - Device / Terminal Registration   |   | - Message Index & SSE Stream         |
| - Session Token Issuance           |   | - TaskThread Execution               |
| - DB: workspace_users, devices     |   | - DB: session_index, message_index   |
+------------------------------------+   +--------------------------------------+
```

---

## 3. Database Schema Specification (DB 详细设计)

To support instant cross-terminal session synchronization without bloated database storage, **binary artifacts remain in S3 / Object Storage / Bridge disk**, while the database indexes **only lightweight text metadata**.

### A. `accounts` Database Schema

```sql
-- 1. Account / User Table
CREATE TABLE IF NOT EXISTS workspace_users (
    id VARCHAR(64) PRIMARY KEY,
    tenant_id VARCHAR(64) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Terminal Device Registry (Multi-Device Sync)
CREATE TABLE IF NOT EXISTS workspace_devices (
    device_id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES workspace_users(id) ON DELETE CASCADE,
    device_name VARCHAR(128) NOT NULL, -- e.g. "MacBook Pro 16", "iPhone 15", "Chrome Web"
    platform VARCHAR(32) NOT NULL,    -- "macos", "web", "ios", "android"
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_devices_user ON workspace_devices(user_id);
```

### B. `xworkmate-bridge` Database Schema

```sql
-- 3. Shared Session Metadata Index (多终端共享会话索引表)
CREATE TABLE IF NOT EXISTS workspace_session_index (
    session_key VARCHAR(128) PRIMARY KEY, -- e.g. "draft-178606227..."
    tenant_id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    title VARCHAR(255) NOT NULL,           -- e.g. "主页SEO优化"
    last_message_preview TEXT,             -- Truncated text preview
    execution_target VARCHAR(64) DEFAULT 'Gateway', -- 'Gateway' | 'OpenClaw'
    lifecycle_status VARCHAR(32) DEFAULT 'ready',    -- 'ready' | 'running' | 'completed' | 'blocked'
    progress_percentage INT DEFAULT 0,               -- 0 to 100
    artifact_count INT DEFAULT 0,                   -- Index of artifact count only
    message_count INT DEFAULT 0,
    created_device_id VARCHAR(64),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- High-performance query index for multi-device synchronization
CREATE INDEX idx_session_user_updated ON workspace_session_index(user_id, updated_at DESC);
CREATE INDEX idx_session_tenant ON workspace_session_index(tenant_id);

-- 4. Session Messages Index Table (会话消息纯文本索引表)
CREATE TABLE IF NOT EXISTS workspace_message_index (
    id VARCHAR(64) PRIMARY KEY,
    session_key VARCHAR(128) NOT NULL REFERENCES workspace_session_index(session_key) ON DELETE CASCADE,
    role VARCHAR(16) NOT NULL,             -- 'user' | 'assistant' | 'system'
    content_text TEXT NOT NULL,
    sender_device_id VARCHAR(64),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_message_session ON workspace_message_index(session_key, created_at ASC);
```

---

## 4. Frontend Architecture in `portal`

### Key Frontend Components & Modules

1. **`src/app/ai-workspace/layout.tsx`**:
   - Manages top-level workspace layout and collapsible left sidebar mechanics.
   - Renders a floating reveal rail button (`ChevronsRight` / `>>`) at top-left when the sidebar is hidden.

2. **`src/app/ai-workspace/conversation/[id]/page.tsx`**:
   - Docks `ChatInputArea` at the **bottom of the container**.
   - Handles the right context panel toggle button at top-right.

3. **`src/lib/xworkmate/taskStore.ts`**:
   - Client-side reactive task store.
   - When a user submits a prompt in `ChatInputArea`, `taskStore.addTask()` creates a new session and broadcasts it to both the left **Sidebar** and **Tasks Page (`/ai-workspace/tasks`)**.

4. **`src/lib/xworkmate/workbenchProjection.ts`**:
   - TypeScript port of Flutter Desktop's `buildWorkbenchProjection` algorithm.
   - Projects raw session threads into dynamic project groupings, 7-day workload trend line charts, and weekly progress statistics.

---

## 5. API Proxy & Security

All frontend API calls under `/ai-workspace` are routed through Next.js App Router API proxy at [`src/app/api/ai-workspace/[...path]/route.ts`](file:///Users/shenlan/workspaces/ai-workspace-service/portal/src/app/api/ai-workspace/[...path]/route.ts).

- **Target Origin**: `https://xworkmate-bridge.svc.plus`
- **Forwarded Headers**: `cookie`, `authorization`, `x-account-session`, `user-agent`
- **CORS Handling**: Server-to-server forwarding ensures browser CORS rules do not block requests and user tokens are seamlessly reused across sessions.
