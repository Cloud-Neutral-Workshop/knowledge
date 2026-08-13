# Cloud-Neutral Toolkit - RAG Server Runbook

## 📚 文档概述

**文档类型**: 运维手册 (Runbook)  
**服务名称**: RAG Server (rag-server-svc-plus)  
**维护团队**: Cloud-Neutral Toolkit Team  
**最后更新**: 2026-01-25  
**版本**: 1.0

## 🎯 服务概述

### 服务信息
- **服务名称**: rag-server-svc-plus
- **部署平台**: Google Cloud Run
- **区域**: asia-northeast1
- **项目 ID**: xzerolab-480008
- **服务 URL**: https://rag-server-svc-plus-266500572462.asia-northeast1.run.app
- **代码仓库**: https://github.com/x-evor/rag-server.svc.plus

### 服务功能
RAG (Retrieval-Augmented Generation) 服务器提供以下功能：
1. **向量检索** (`/api/rag/query`) - 从知识库中检索相关文档
2. **AI 问答** (`/api/askai`) - 使用 LLM 生成答案
3. **文档索引** (`/api/rag/upsert`) - 向知识库添加文档

### 依赖服务
- **LLM Provider**: NVIDIA AI (integrate.api.nvidia.com)
- **向量数据库**: PostgreSQL with pgvector
- **认证服务**: accounts-svc-plus
- **前端服务**: console.svc.plus (Vercel)

## 🏗️ 架构说明

### 系统架构
```
用户 (https://www.svc.plus)
  ↓
Console Frontend (Vercel)
  ↓
Next.js API Routes (/api/askai, /api/rag/query)
  ↓
RAG Server (Cloud Run)
  ├─→ NVIDIA AI API (LLM)
  └─→ PostgreSQL (向量数据库)
```

### 配置文件结构
```
rag-server.svc.plus/
├── config/
│   └── rag-server.yaml          # 主配置文件
├── api/
│   ├── askai.go                 # AI 问答端点
│   ├── rag.go                   # RAG 检索端点
│   └── register.go              # 路由注册
├── cmd/
│   └── rag-server/
│       └── main.go              # 主程序入口
├── Dockerfile                   # Docker 镜像构建
└── entrypoint.sh               # 容器启动脚本
```

## 🚀 部署流程

### 标准部署流程

#### 1. 代码变更
```bash
# 克隆仓库
git clone https://github.com/x-evor/rag-server.svc.plus.git
cd rag-server.svc.plus

# 创建功能分支
git checkout -b feature/your-feature-name

# 进行代码修改
# ... 编辑文件 ...

# 提交变更
git add .
git commit -m "feat: your feature description"
git push -u origin feature/your-feature-name
```

#### 2. 创建 Pull Request
1. 访问 GitHub 仓库
2. 创建 PR: `feature/your-feature-name` → `main`
3. 等待 CI/CD 检查通过
4. 请求代码审查
5. 合并到 main 分支

#### 3. 部署到 Cloud Run

**方式 A: 使用 gcloud CLI (推荐用于紧急修复)**
```bash
cd /path/to/rag-server.svc.plus

# 部署到 Cloud Run
gcloud run deploy rag-server-svc-plus \
  --source . \
  --region asia-northeast1 \
  --project xzerolab-480008 \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars NVIDIA_API_KEY='your-api-key-here'

# 部署通常需要 3-5 分钟
```

**方式 B: 通过 Cloud Build (自动化)**
```bash
# 触发 Cloud Build
gcloud builds submit \
  --config cloudbuild.yaml \
  --project xzerolab-480008
```

### 环境变量配置

必需的环境变量：
```bash
NVIDIA_API_KEY=nvapi-xxx...        # NVIDIA AI API 密钥
DATABASE_URL=postgres://...        # PostgreSQL 连接字符串
POSTGRES_USER=postgres             # 数据库用户名
POSTGRES_PASSWORD=xxx              # 数据库密码
```

可选的环境变量：
```bash
PORT=8080                          # 服务端口（Cloud Run 自动设置）
LOG_LEVEL=info                     # 日志级别 (debug/info/warn/error)
CONFIG_PATH=/etc/rag-server/rag-server.yaml  # 配置文件路径
```

## 🔍 监控和日志

### 查看 Cloud Run 日志

**使用 Google Cloud Console**:
```
https://console.cloud.google.com/logs/query;query=resource.type%20%3D%20%22cloud_run_revision%22%0Aresource.labels.service_name%20%3D%20%22rag-server-svc-plus%22
```

**使用 gcloud CLI**:
```bash
# 查看最近 50 条日志
gcloud logging read \
  "resource.type=cloud_run_revision AND resource.labels.service_name=rag-server-svc-plus" \
  --limit 50 \
  --project xzerolab-480008 \
  --format json

# 实时查看日志
gcloud logging tail \
  "resource.type=cloud_run_revision AND resource.labels.service_name=rag-server-svc-plus" \
  --project xzerolab-480008
```

### 关键指标监控

1. **请求成功率**: 应该 > 95%
2. **响应时间**: P95 < 5s, P99 < 10s
3. **错误率**: < 5%
4. **实例数量**: 根据负载自动扩缩容

### 告警设置

建议设置以下告警：
- 错误率 > 10% 持续 5 分钟
- P99 延迟 > 15s 持续 5 分钟
- 实例启动失败
- 配置文件加载失败

## 🐛 故障排查

### 常见问题和解决方案

#### 问题 1: `/api/askai` 返回 500 错误

**症状**:
```json
{
  "error": "Post \"\": unsupported protocol scheme \"\"",
  "config": {"timeout": 30, "retries": 3}
}
```

**原因**: ConfigPath 配置错误，无法读取 LLM endpoint

**解决方案**:
1. 检查 `api/askai.go` 中的 `ConfigPath` 变量
2. 确保指向正确的配置文件: `config/rag-server.yaml`
3. 验证配置文件中的 `models.generator.endpoint` 不为空

**修复代码**:
```go
// api/askai.go
var ConfigPath = filepath.Join("config", "rag-server.yaml")
```

#### 问题 2: 数据库连接失败

**症状**:
```
postgres connect error: connection refused
```

**排查步骤**:
1. 检查 `DATABASE_URL` 环境变量是否正确
2. 验证 PostgreSQL 服务是否运行
3. 检查网络连接和防火墙规则
4. 如果使用 Stunnel，检查 TLS 隧道是否正常

**解决方案**:
```bash
# 测试数据库连接
psql "$DATABASE_URL"

# 检查 Stunnel 状态
ps aux | grep stunnel
netstat -an | grep 5432
```

#### 问题 3: NVIDIA API 调用失败

**症状**:
```
askai request failed: 401 Unauthorized
```

**排查步骤**:
1. 验证 `NVIDIA_API_KEY` 环境变量是否设置
2. 检查 API key 是否有效
3. 确认 API quota 未超限

**解决方案**:
```bash
# 测试 NVIDIA API
curl -X POST https://integrate.api.nvidia.com/v1/chat/completions \
  -H "Authorization: Bearer $NVIDIA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "minimaxai/minimax-m2", "messages": [{"role": "user", "content": "test"}]}'
```

#### 问题 4: 配置文件未找到

**症状**:
```
load config err: open config/rag-server.yaml: no such file or directory
```

**排查步骤**:
1. 检查 Dockerfile 是否正确复制配置文件
2. 验证 entrypoint.sh 是否正确设置配置路径
3. 检查容器内文件系统

**解决方案**:
```dockerfile
# Dockerfile
COPY config/rag-server.yaml /etc/rag-server/rag-server.yaml
```

```bash
# entrypoint.sh
CONFIG_FILE="${CONFIG_PATH:-/etc/rag-server/rag-server.yaml}"
```

### 调试命令

```bash
# 1. 检查服务状态
gcloud run services describe rag-server-svc-plus \
  --region asia-northeast1 \
  --project xzerolab-480008

# 2. 测试健康检查
curl https://rag-server-svc-plus-266500572462.asia-northeast1.run.app/health

# 3. 测试 RAG 查询
curl -X POST https://rag-server-svc-plus-266500572462.asia-northeast1.run.app/api/rag/query \
  -H "Content-Type: application/json" \
  -d '{"question": "test"}'

# 4. 测试 AI 问答
curl -X POST https://rag-server-svc-plus-266500572462.asia-northeast1.run.app/api/askai \
  -H "Content-Type: application/json" \
  -d '{"question": "Hello"}'

# 5. 查看最新部署版本
gcloud run revisions list \
  --service rag-server-svc-plus \
  --region asia-northeast1 \
  --project xzerolab-480008

# 6. 回滚到上一个版本
gcloud run services update-traffic rag-server-svc-plus \
  --to-revisions REVISION_NAME=100 \
  --region asia-northeast1 \
  --project xzerolab-480008
```

## 🔄 回滚流程

### 紧急回滚

如果新部署导致严重问题：

```bash
# 1. 列出所有版本
gcloud run revisions list \
  --service rag-server-svc-plus \
  --region asia-northeast1 \
  --project xzerolab-480008

# 2. 回滚到上一个稳定版本
gcloud run services update-traffic rag-server-svc-plus \
  --to-revisions PREVIOUS_REVISION=100 \
  --region asia-northeast1 \
  --project xzerolab-480008

# 3. 验证回滚成功
curl https://rag-server-svc-plus-266500572462.asia-northeast1.run.app/health
```

### Git 回滚

```bash
# 回滚到上一个提交
git revert HEAD
git push origin main

# 或者硬回滚（谨慎使用）
git reset --hard HEAD~1
git push -f origin main
```

## 📊 性能优化

### 配置优化建议

1. **调整超时时间**:
```yaml
# config/rag-server.yaml
api:
  askai:
    timeout: 100  # 秒
    retries: 3
```

2. **数据库连接池**:
```yaml
vector_db:
  max_connections: 20
  idle_timeout: 300s
```

3. **Cloud Run 资源配置**:
```bash
gcloud run services update rag-server-svc-plus \
  --memory 2Gi \
  --cpu 2 \
  --max-instances 10 \
  --min-instances 1 \
  --region asia-northeast1
```

## 📝 维护检查清单

### 每日检查
- [ ] 查看错误日志，确认无异常
- [ ] 检查服务响应时间
- [ ] 验证 API 端点可访问性

### 每周检查
- [ ] 审查性能指标
- [ ] 检查资源使用情况
- [ ] 更新依赖包（如有安全更新）

### 每月检查
- [ ] 审查和优化配置
- [ ] 清理旧的 Cloud Run 版本
- [ ] 更新文档

## 🔐 安全最佳实践

1. **API 密钥管理**:
   - 使用 Google Secret Manager 存储敏感信息
   - 定期轮换 API 密钥
   - 不要在代码中硬编码密钥

2. **访问控制**:
   - 限制 Cloud Run 服务账号权限
   - 使用 IAM 角色管理访问
   - 启用 Cloud Armor 防护

3. **数据安全**:
   - 使用 TLS 加密传输
   - 启用数据库加密
   - 定期备份数据

## 📞 联系信息

### 团队联系方式
- **技术负责人**: [姓名]
- **运维团队**: [邮箱]
- **紧急联系**: [电话]

### 相关链接
- **GitHub**: https://github.com/x-evor/rag-server.svc.plus
- **Cloud Console**: https://console.cloud.google.com/run/detail/asia-northeast1/rag-server-svc-plus
- **监控面板**: [Monitoring Dashboard URL]
- **文档**: [Documentation URL]

## 📚 相关文档

- [API 文档](./API.md)
- [配置指南](./CONFIG.md)
- [开发指南](./DEVELOPMENT.md)
- [故障排查指南](./debug-report.md)

---

**文档维护**: 请在每次重大变更后更新此文档  
**审核周期**: 每季度审核一次  
**版本历史**: 见 Git 提交记录
