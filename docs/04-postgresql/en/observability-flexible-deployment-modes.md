# Observability Multi-Mode Compatibility & Evolutionary Deployment Guide

> **Scope**: `ai-workspace-infra/playbooks` (`deploy_observability.yml`, `deploy_observability_server.yml`, `deploy_observability_agent.yml`)  
> **Core Principle**: Fully retain the original **`self_hosted` (Dedicated Stack) mode** as the canonical default fallback, while seamlessly adding support for **`grafana_cloud`** and **`victoria_cloud`** managed cloud modes.

---

## 1. Architecture: Tri-Mode Parallel Compatibility

In Ansible Playbooks, deployment behavior is controlled via the global variable `observability_mode`, ensuring 100% backward compatibility by default:

```mermaid
graph TD
    Playbook[deploy_observability.yml] --> Check{observability_mode Variable}

    Check -->|self_hosted <Default>| Mode1[Mode 1: Full Self-Hosted]
    Check -->|grafana_cloud| Mode2[Mode 2: Grafana Cloud Managed]
    Check -->|victoria_cloud| Mode3[Mode 3: Victoria Cloud Managed]

    subgraph Mode 1: Self-Hosted (100% Preserved)
        Mode1 --> Server1[deploy_observability_server.yml<br/>Launches Prometheus / VictoriaLogs / Grafana Containers]
        Mode1 --> Agent1[deploy_observability_agent.yml<br/>Pushes telemetry data to local server IP]
    end

    subgraph Mode 2 & 3: Managed Cloud Modes
        Mode2 --> Server2[deploy_observability_server.yml<br/>Automatically skips with notice]
        Mode2 --> Agent2[deploy_observability_agent.yml<br/>Pushes telemetry to Grafana OTLP/Loki]

        Mode3 --> Server3[deploy_observability_server.yml<br/>Automatically skips with notice]
        Mode3 --> Agent3[deploy_observability_agent.yml<br/>Pushes telemetry to VictoriaMetrics/Logs Cloud API]
    end
```

---

## 2. Comparison of the Three Compatible Modes

| Deployment Mode (`observability_mode`) | **1. `self_hosted` (Default Canonical)** | **2. `grafana_cloud` (Cloud Mode)** | **3. `victoria_cloud` (Cloud Mode)** |
| :--- | :--- | :--- | :--- |
| **`deploy_observability_server.yml`** | ✅ **Runs normally**, launches local Docker containers | ⏸️ **Skips automatically** (outputs Cloud mode notice) | ⏸️ **Skips automatically** (outputs Cloud mode notice) |
| **`deploy_observability_agent.yml`** | ✅ **Runs normally**, telemetry sent to local IP | ✅ **Runs normally**, telemetry sent to Grafana Cloud | ✅ **Runs normally**, telemetry sent to Victoria Cloud |
| **Data Sink Target** | Local Prometheus (9090) & VictoriaLogs (9428) | Grafana Prometheus RemoteWrite & Loki Endpoint | VictoriaMetrics RemoteWrite & VictoriaLogs Endpoint |
| **Use Cases** | Private clouds, physical LAN host clusters, data sovereignty | Cloud-native Serverless, zero server ops, cloud UI | Predictable tier pricing, heavy log/metric throughput |

---

## 3. Ansible Playbook Expansion Plan

While keeping the original playbook file structure completely unchanged, multi-mode compatibility is achieved via conditional rendering:

### 1. Global Variables Configuration (`group_vars/all.yml` or `.env`)

```yaml
# Telemetry mode selection: self_hosted (default) | grafana_cloud | victoria_cloud
observability_mode: "{{ lookup('ansible.builtin.env', 'OBSERVABILITY_MODE') | default('self_hosted', true) }}"

# ===== Mode 2: Grafana Cloud Credentials =====
grafana_cloud_metrics_url: "https://prometheus-prod-us-central-0.grafana.net/api/v1/push"
grafana_cloud_metrics_user: "{{ lookup('ansible.builtin.env', 'GRAFANA_CLOUD_METRICS_USER') | default('', true) }}"
grafana_cloud_api_key: "{{ lookup('ansible.builtin.env', 'GRAFANA_CLOUD_API_KEY') | default('', true) }}"
grafana_cloud_logs_url: "https://logs-prod-us-central-0.grafana.net/loki/api/v1/push"
grafana_cloud_logs_user: "{{ lookup('ansible.builtin.env', 'GRAFANA_CLOUD_LOGS_USER') | default('', true) }}"

# ===== Mode 3: Victoria Cloud Credentials =====
victoria_cloud_metrics_url: "https://<your-instance>.victoriametrics.com/api/v1/write"
victoria_cloud_bearer_token: "{{ lookup('ansible.builtin.env', 'VICTORIA_CLOUD_BEARER_TOKEN') | default('', true) }}"
```

### 2. Preserve and Enhance `deploy_observability_server.yml`

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

### 3. Enhance `deploy_observability_agent.yml` (Vector Agent Dynamic Template)

Modify the Vector Agent configuration template (`vector.yaml.j2`) for mode-based dispatching:

```toml
# Prometheus Metrics Scraper
[sources.prometheus_scrapers]
type = "prometheus_scrape"
endpoints = ["http://localhost:9100/metrics", "http://localhost:9187/metrics"]

{% if observability_mode == 'grafana_cloud' %}
# ----------------------------------------------------------------------
# Mode 2: Grafana Cloud Sink
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
# Mode 3: Victoria Cloud Sink
# ----------------------------------------------------------------------
[sinks.victoria_cloud_metrics]
type = "prometheus_remote_write"
inputs = ["prometheus_scrapers"]
endpoint = "{{ victoria_cloud_metrics_url }}"
auth.strategy = "bearer"
auth.token = "{{ victoria_cloud_bearer_token }}"

{% else %}
# ----------------------------------------------------------------------
# Mode 1: Self-Hosted Local Sink (100% Retained Default Logic)
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

## 4. Summary

1. **Original Files Intact**: `deploy_observability.yml`, `deploy_observability_server.yml`, and `deploy_observability_agent.yml` remain the entrypoint files.
2. **Zero-Breaking Change**: Under default configuration (`observability_mode: self_hosted`), behavior is 100% identical to existing self-hosted deployments.
3. **One-Click Cloud Switch**: Setting `OBSERVABILITY_MODE=grafana_cloud` before running Ansible automatically skips local server deployment and streams telemetry data safely to the cloud!
