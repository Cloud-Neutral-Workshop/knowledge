# 开发手册

该仓库是 Go 服务，文档需要覆盖 API、配置、运行时操作与部署职责。

本页用于记录本地开发环境、项目结构、测试面与贴合当前代码库的贡献约定。

## 与当前代码对齐的说明

- 文档目标仓库: `rag-server.svc.plus`
- 仓库类型: `go-service`
- 构建与运行依据: go.mod (`rag-server`)
- 主要实现与运维目录: `cmd/`, `internal/`, `api/`, `deploy/`, `ansible/`, `scripts/`, `tests/`, `example/`, `migrations/`, `sql/`
- `package.json` 脚本快照: No package.json scripts were detected.

## 需要继续归并的现有文档

- `PATH_VERIFICATION.md`
- `api/auth.md`
- `api/endpoints.md`
- `api/errors.md`
- `api/overview.md`
- `api-reference.md`
- `development/code-structure.md`
- `development/contributing.md`

## 本页下一步应补充的内容

- 先描述当前已落地实现，再补充未来规划，避免只写愿景不写现状。
- 术语需要与仓库根 README、构建清单和实际目录保持一致。
- 将上方列出的历史 runbook、spec、子系统说明逐步链接并归并到本页。
- 持续让环境搭建与测试命令对应真实存在的脚本、Make 目标或语言工具链。
