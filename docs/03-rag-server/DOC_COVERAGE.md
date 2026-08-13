# Documentation Coverage Matrix

This matrix tracks the bilingual canonical documentation set for `rag-server.svc.plus` and maps it back to the current codebase and older docs.

该矩阵用于跟踪 `rag-server.svc.plus` 的双语规范文档，并将其与当前代码状态和历史文档对应起来。

| Category | EN | ZH | Current status | Existing references | Next check |
| --- | --- | --- | --- | --- | --- |
| Architecture | Yes | Yes | Seeded from current codebase and existing docs. | `api/overview.md`<br>`architecture/components.md`<br>`architecture/design-decisions.md`<br>`architecture/overview.md`<br>`architecture/roadmap.md`<br>`development/code-structure.md` | Keep diagrams and ownership notes synchronized with actual directories, services, and integration dependencies. |
| Design | Yes | Yes | Seeded from current codebase and existing docs. | `IMPLEMENTATION_GUIDE.md`<br>`TOKEN_AUTH_SUMMARY.md`<br>`architecture/design-decisions.md` | Promote one-off implementation notes into reusable design records when behavior, APIs, or deployment contracts change. |
| Deployment | Yes | Yes | Seeded from current codebase and existing docs. | `Runbook/RAG-Server.md`<br>`deployment.md`<br>`development/dev-setup.md`<br>`getting-started/installation.md`<br>`getting-started/quickstart.md`<br>`google-cloud-run-howto.md`<br>`governance/release-process.md`<br>`usage/deployment.md` | Verify deployment steps against current scripts, manifests, CI/CD flow, and environment contracts before each release. |
| User Guide | Yes | Yes | Seeded from current codebase and existing docs. | `IMPLEMENTATION_GUIDE.md`<br>`TOKEN_AUTH_MANUAL.md`<br>`api/overview.md`<br>`architecture/overview.md`<br>`configuration.md`<br>`getting-started/concepts.md`<br>`getting-started/installation.md`<br>`getting-started/introduction.md` | Prefer workflow-oriented examples and keep screenshots or terminal snippets aligned with the latest UI or CLI behavior. |
| Developer Guide | Yes | Yes | Seeded from current codebase and existing docs. | `PATH_VERIFICATION.md`<br>`api/auth.md`<br>`api/endpoints.md`<br>`api/errors.md`<br>`api/overview.md`<br>`api-reference.md`<br>`development/code-structure.md`<br>`development/contributing.md` | Keep setup and test commands tied to actual package scripts, Make targets, or language toolchains in this repository. |
| Vibe Coding Reference | Yes | Yes | Seeded from current codebase and existing docs. | `AGENTS.md`<br>`api/auth.md`<br>`api/endpoints.md`<br>`api/errors.md`<br>`api/overview.md`<br>`api-reference.md` | Review prompt templates and repo rules whenever the project adds new subsystems, protected areas, or mandatory verification steps. |
