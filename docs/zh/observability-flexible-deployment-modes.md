# Observability 多模式兼容与平滑演进指南

> **适用范围**：`ai-workspace-infra/playbooks` (`deploy_observability.yml`, `deploy_observability_server.yml`, `deploy_observability_agent.yml`)  
> **核心原则**：完整保留原有的 **`self_hosted`（自建全栈）模式**作为默认兜底方案，同时无缝扩展对 **`grafana_cloud`** 与 **`victoria_cloud`** 托管模式的支持。

---

## 一、 架构设计：三轨并行兼容模式

在 Ansible Playbooks 中通过全局变量 `observability_mode` 控制部署行为，默认保持完全向下兼容：

```mermaid
graph TD
    Playbook[deploy_observability.yml] --> Check{observability_mode 变量}

    Check -->|self_hosted <默认>| Mode1[模式 1: 完整自建 Self-Hosted]
    Check -->|grafana_cloud| Mode2[模式 2: Grafana Cloud 托管]
    Check -->|victoria_cloud| Mode3[模式 3: Victoria Cloud 托管]

    subgraph 模式 1: Self-Hosted (原方案 100% 保留)
        Mode1 --> Server1[deploy_observability_server.yml<br/>拉起 Prometheus / VictoriaLogs / Grafana 容器]
        Mode1 --> Agent1[deploy_observability_agent.yml<br/>推送遥测数据至本地 Server IP]
    end

    subgraph 模式 2 & 3: 云端托管模式
        Mode2 --> Server2[deploy_observability_server.yml<br/>自动跳过/输出提示]
        Mode2 --> Agent2[deploy_observability_agent.yml<br/>根据 Cloud 凭据推送至 Grafana OTLP/Loki]

        Mode3 --> Server3[deploy_observability_server.yml<br/>自动跳过/输出提示]
        Mode3 --> Agent3[deploy_observability_agent.yml<br/>推送至 VictoriaMetrics/Logs Cloud API]
    end
```

---

## 二、 三种兼容模式详细对比

| 部署模式 (`observability_mode`) | **1. `self_hosted` (默认原方案)** | **2. `grafana_cloud` (云端模式)** | **3. `victoria_cloud` (云端模式)** |
| :--- | :--- | :--- | :--- |
| **`deploy_observability_server.yml`** | ✅ **正常运行**，拉起本地全套 Docker 容器 | ⏸️ **自动跳过**（输出 Cloud 模式提示） | ⏸️ **自动跳过**（输出 Cloud 模式提示） |
| **`deploy_observability_agent.yml`** | ✅ **正常运行**，遥测数据送往本地 IP | ✅ **正常运行**，遥测数据送往 Grafana Cloud | ✅ **正常运行**，遥测数据送往 Victoria Cloud |
| **数据目的地 (Sink)** | 本地 Prometheus (9090) & VictoriaLogs (9428) | Grafana Prometheus RemoteWrite & Loki Endpoint | VictoriaMetrics RemoteWrite & VictoriaLogs Endpoint |
| **适用场景** | 私有云、局域网物理集群、完全数据自主 | 云原生 Serverless、免服务端运维、使用云端大盘 | 预测型 Tier 计费、超高吞吐日志与指标 |

---

## 三、 Ansible Playbook 落地扩充方案

在保持原有 Playbook 文件结构不变的前提下，通过增加条件渲染实现兼容：

### 1. 全局变量配置 (`group_vars/all.yml` 或 `.env`)

```yaml
# 遥测模式选型: self_hosted (默认) | grafana_cloud | victoria_cloud
observability_mode: "{{ lookup('ansible.builtin.env', 'OBSERVABILITY_MODE') | default('self_hosted', true) }}"

# ===== 模式 2: Grafana Cloud 专属凭据 =====
grafana_cloud_metrics_url: "https://prometheus-prod-us-central-0.grafana.net/api/v1/push"
grafana_cloud_metrics_user: "{{ lookup('ansible.builtin.env', 'GRAFANA_CLOUD_METRICS_USER') | default('', true) }}"
grafana_cloud_api_key: "{{ lookup('ansible.builtin.env', 'GRAFANA_CLOUD_API_KEY') | default('', true) }}"
grafana_cloud_logs_url: "https://logs-prod-us-central-0.grafana.net/loki/api/v1/push"
grafana_cloud_logs_user: "{{ lookup('ansible.builtin.env', 'GRAFANA_CLOUD_LOGS_USER') | default('', true) }}"

# ===== 模式 3: Victoria Cloud 专属凭据 =====
victoria_cloud_metrics_url: "https://<your-instance>.victoriametrics.com/api/v1/write"
victoria_cloud_bearer_token: "{{ lookup('ansible.builtin.env', 'VICTORIA_CLOUD_BEARER_TOKEN') | default('', true) }}"
```

### 2. 保留并增强 `deploy_observability_server.yml`

```yaml
---
- name: Deploy Observability Server Stack (Prometheus, VictoriaLogs, VictoriaTraces & Grafana)
  hosts: "{{ observability_server_hosts | default('install.svc.plus') }}"
  become: true
  tasks:
    - name: Run Self-Hosted Server Role
      ansible.builtin.include_role:
        name: docker/observability-server
      when: (observability_mode | default('self_hosted')) == 'self_hosted'

    - name: Notice for Cloud Mode
      ansible.builtin.debug:
        msg: "observability_mode is set to '{{ observability_mode }}'. Skipping local server stack deployment."
      when: (observability_mode | default('self_hosted')) != 'self_hosted'
```

### 3. 增强 `deploy_observability_agent.yml` (Vector Agent 动态模版)

修改 Vector Agent 配置模板（`vector.yaml.j2`），实现按模式分发：

```toml
# Prometheus 指标采集源
[sources.prometheus_scrapers]
type = "prometheus_scrape"
endpoints = ["http://localhost:9100/metrics", "http://localhost:9187/metrics"]

{% if observability_mode == 'grafana_cloud' %}
# ----------------------------------------------------------------------
# 模式 2: Grafana Cloud 适配 Sink
# ----------------------------------------------------------------------
[sinks.grafana_cloud_metrics]
type = "prometheus_remote_write"
inputs = ["prometheus_scrapers"]
endpoint = "{{ grafana_cloud_metrics_url }}"
auth.strategy = "basic"
auth.user = "{{ grafana_cloud_metrics_user }}"
auth.password = "{{ grafana_cloud_api_key }}"

[sinks.grafana_cloud_logs]
type = "loki"
inputs = ["journal_logs", "docker_logs"]
endpoint = "{{ grafana_cloud_logs_url }}"
auth.strategy = "basic"
auth.user = "{{ grafana_cloud_logs_user }}"
auth.password = "{{ grafana_cloud_api_key }}"

{% elif observability_mode == 'victoria_cloud' %}
# ----------------------------------------------------------------------
# 模式 3: Victoria Cloud 适配 Sink
# ----------------------------------------------------------------------
[sinks.victoria_cloud_metrics]
type = "prometheus_remote_write"
inputs = ["prometheus_scrapers"]
endpoint = "{{ victoria_cloud_metrics_url }}"
auth.strategy = "bearer"
auth.token = "{{ victoria_cloud_bearer_token }}"

{% else %}
# ----------------------------------------------------------------------
# 模式 1: Self-Hosted 本地自建 Sink (默认 100% 保持原逻辑)
# ----------------------------------------------------------------------
[sinks.local_prometheus]
type = "prometheus_remote_write"
inputs = ["prometheus_scrapers"]
endpoint = "http://{{ observability_server_ip | default('127.0.0.1') }}:9090/api/v1/write"

[sinks.local_victorialogs]
type = "vector"
inputs = ["journal_logs", "docker_logs"]
address = "{{ observability_server_ip | default('127.0.0.1') }}:9428"
{% endif %}
```

---

## 四、 总结

1. **核心文件原封不动**：`deploy_observability.yml`、`deploy_observability_server.yml` 和 `deploy_observability_agent.yml` 保持不变。
2. **零破坏性扩展**：在 `observability_mode: self_hosted` 默认配置下，运行逻辑与过去 100% 一致。
3. **一键切云**：只需在执行命令前传入 `OBSERVABILITY_MODE=grafana_cloud`，即可自动跳过本地 Server 部署并将 Agent 流量安全引入云端托管平台！
