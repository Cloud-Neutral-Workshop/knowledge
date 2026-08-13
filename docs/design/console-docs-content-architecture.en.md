---
title: "Cloud-Neutral Content Service Architecture Specification"
description: "Architecture specification for Portal Frontend, Docs Gateway, content-service backend, and knowledge.git repository."
slug: console-docs-content-architecture
lang: en
date: 2026-08-13T00:00:00Z
author: shenlan
category: design
tags:
  - architecture
  - docs
  - content-service
  - gitops
---

# Cloud-Neutral Content Service Architecture Specification

> **⚠️ Core Principles**:
> 1. **Separation of Code & Content**.
> 2. **Zero Hardcoded Domains**: All domains (, ) must be injected dynamically via environment variables across PROD, UAT, and DEV.
> 3. **High-Performance In-Memory Search & GitOps Auto-Sync**.

---

## 1. System Topology



---

## 2. Multi-Environment Configuration Matrix

| Env Key | Description | PROD Example | UAT Example | Local Dev |
| :--- | :--- | :--- | :--- | :--- |
|  | Portal Web Entrance Domain |  |  |  |
|  | Content Microservice Domain |  |  |  |
|  | Domain Suffix |  |  |  |
|  | Upstream Git Repo URL |  |  | Local Path |
|  | Local Container Path |  |  | Local Path |
