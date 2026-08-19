# Cloud-Neutral Radar | Infra & Platform · Serverless & Edge Cloud Architecture

This directory covers modern Cloud-Neutral and Edge-First Serverless Infrastructure Architectures, focusing on multi-environment setups, hybrid scheduling between edge workers, containerized elastic compute, and managed stateful cloud databases.

## Documents & Guides

- [如何利用好 Free SaaS 开启自己的在线服务 (中文版)](./how-to-leverage-free-saas-for-online-services.zh.md)
- [How to Leverage Free SaaS to Launch Online Services (English Version)](./how-to-leverage-free-saas-for-online-services.en.md)

---

## Architectural Archetypes Comparison

```
┌─────────────────────────┬─────────────────────────┬─────────────────────────┐
│      Self-Host VPS      │     Pure Serverless     │ Hybrid Edge & Free SaaS │
├─────────────────────────┼─────────────────────────┼─────────────────────────┤
│ 1. Ingress Layer        │ 1. Ingress Layer        │ 1. Edge Ingress & Route │
│    - Direct IP / Nginx  │    - API Gateway costs  │    - Cloudflare Edge    │
│    - No Global CDN      │      per-request        │      absorbs 90% traffic│
│    - Volumetric risk    │    - Scraper cost risks │    - 5 Edge SSR Workers │
├─────────────────────────┼─────────────────────────┼─────────────────────────┤
│ 2. Compute Layer        │ 2. Compute Layer        │ 2. Elastic & Failover   │
│    - Monolith on 1 VPS  │    - Fragmented FaaS    │    - GCP Cloud Run      │
│    - Single point (SPOF)│    - Cold start latency │      Scale-to-Zero      │
│                         │    - High concurrency $ │    - Primary-to-Cloud   │
│                         │                         │      failover routing   │
├─────────────────────────┼─────────────────────────┼─────────────────────────┤
│ 3. Database Layer       │ 3. Database Layer       │ 3. Managed DB & Pooling │
│    - Local Postgres disk│    - Direct connections │    - Supabase Postgres  │
│    - Manual maintenance │      exhaust pool limits│    - Supavisor txn pool │
├─────────────────────────┼─────────────────────────┼─────────────────────────┤
│ 💡 BEST FOR             │ 💡 BEST FOR             │ 💡 BEST FOR             │
│    - Fixed $5 budget dev│    - Event-driven burst │    - $0–$5/mo bootstrap │
│    - Toy / Internal POC │    - Enterprise budgets │    - Global low-latency │
│    - Single-region apps │    - Zero-ops preference│    - Indie Hackers SaaS │
└─────────────────────────┴─────────────────────────┴─────────────────────────┘
```
