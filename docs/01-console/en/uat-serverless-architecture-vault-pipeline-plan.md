# UAT on Serverless Minimalist Zero-Cost Architecture Plan and Implementation Guide

> **InfoQ Architect Deep Dive**  
> **Target System**: `ai-workspace-service` Matrix (`portal`, `edge-gateway`, `accounts`, `billing-service`, `content-service`, `postgresql`)  
> **Technology Stack**: Cloudflare Pages + Cloudflare Worker + GCP Cloud Run (Scale-to-0) + Supabase Cloud Free + HashiCorp Vault (`vault.svc.plus`)  
> **Core Principle**: **"Data persistent, compute ephemeral on-demand, credentials centralized, development & testing at zero cost ($0/month)"**

---

## 📌 1. Background & Philosophy

Traditional User Acceptance Testing (UAT) environments typically suffer from two pain points:
1. **Idle Infrastructure Waste**: Keeping multiple virtual machines and databases running continuously for occasional testing generates unnecessary recurring bills;
2. **Re-provisioning Friction**: Tearing everything down manually requires repeated schema migrations and fixture seeding, dragging down engineering velocity.

This architecture introduces a **"Persistent Data + Ephemeral On-Demand Compute"** serverless UAT paradigm:
* **Persistent Data Layer**: **Supabase Cloud Free** stores schemas, mock users, and testing workspace fixtures permanently with **zero data loss and zero database maintenance costs**;
* **Ephemeral Compute Layer**: Go microservices run on **GCP Cloud Run** (defaulting to `min-instances=0`, scaling to 0 when idle), with automated pipelines provisioning at 09:00 on demand and deleting services at 20:00;
* **Edge Ingress Layer**: Frontend runs on **Cloudflare Pages** and API gateway runs on **Cloudflare Workers**, utilizing global free tier quotas;
* **Single Source of Truth for Credentials**: All credentials across Cloudflare, GCP, and Supabase are centrally stored in **HashiCorp Vault (`https://vault.svc.plus`)**.

---

## 🔐 2. Vault KV Path Structure (`https://vault.svc.plus`)

Following the platform's 3-tier Vault security model, all UAT Serverless credentials reside under **`kv/data/uat/serverless/`**:

```text
kv/data/uat/serverless/
├── cloudflare/                 # Cloudflare Pages & Workers deployment credentials
│   ├── CLOUDFLARE_ACCOUNT_ID   # Account ID
│   ├── CLOUDFLARE_API_TOKEN    # Deployment Token (Pages & Worker permissions)
│   ├── CLOUDFLARE_ZONE_ID      # svc.plus Zone ID
│   ├── PAGES_PROJECT_NAME      # "ai-workspace-portal-uat"
│   ├── WORKER_NAME             # "edge-gateway-uat"
│   ├── UAT_PORTAL_DOMAIN       # "uat-console.svc.plus"
│   └── UAT_API_DOMAIN          # "uat-api.svc.plus"
│
├── gcp/                        # GCP Cloud Run deployment credentials
│   ├── GCP_PROJECT_ID          # "ai-workspace-uat-project"
│   ├── GCP_REGION              # "asia-east1"
│   ├── GCP_SA_KEY_JSON         # Service Account JSON (Cloud Run Admin role)
│   └── ARTIFACT_REGISTRY_URL   # "asia-east1-docker.pkg.dev/ai-workspace-uat/serverless"
│
├── supabase/                   # Supabase Cloud UAT database connectivity
│   ├── PROJECT_REF             # Supabase Project ID (e.g. abcd1234efgh)
│   ├── PROJECT_URL             # "https://abcd1234efgh.supabase.co"
│   ├── ANON_KEY                # Frontend anonymous key
│   ├── SERVICE_ROLE_KEY        # Backend service role key
│   ├── DB_PASSWORD             # Master database password
│   ├── DATABASE_DIRECT_URL     # "postgres://postgres:PWD@db.abcd1234efgh.supabase.co:5432/postgres"
│   └── DATABASE_POOLER_URL     # "postgres://postgres.abcd1234efgh:PWD@aws-0-asia-east1.pooler.supabase.com:6543/postgres?pgbouncer=true"
│
└── app-secrets/                # Shared application secrets
    ├── JWT_SECRET              # Unified JWT verification secret (shared with edge-gateway and accounts)
    ├── STRIPE_WEBHOOK_SECRET   # UAT test Stripe Webhook signature secret
    └── TIMEOUT_MS              # "2500"
```

---

## 🗺️ 3. Service Deployment & Infrastructure Mapping

```mermaid
graph TD
    subgraph Edge Ingress (Cloudflare Edge)
        User[QA / Developer] -->|Access Portal| Portal[portal: Cloudflare Pages<br/>uat-console.svc.plus<br/>💰 $0 / Unlimited Bandwidth]
        User -->|API Calls| Gateway[edge-gateway: Cloudflare Worker<br/>uat-api.svc.plus<br/>💰 $0 / 100k free reqs/day]
    end

    subgraph Ephemeral Compute (GCP Cloud Run - On-Demand 09:00 / Destroyed 20:00)
        Gateway -->|/api/v1/accounts/*| Acc[accounts: Cloud Run (min=0, max=2)]
        Gateway -->|/api/v1/billing/*| Bill[billing-service: Cloud Run (min=0, max=2)]
        Gateway -->|/api/v1/content/*| Content[content-service: Cloud Run (min=0, max=2)]
    end

    subgraph Persistent Storage (Supabase Cloud Free - Permanent Store)
        Acc -->|Supavisor Pooler 6543| Supa[(Supabase PostgreSQL: ai-workspace-uat<br/>• Permanent mock fixtures & schema<br/>• Weekly automated keepalive)]
        Bill -->|Supavisor Pooler 6543| Supa
        Content -->|Supavisor Pooler 6543| Supa
    end

    subgraph Centralized Vault SOT
        Vault[(vault.svc.plus: kv/data/uat/serverless/*)] -.->|Dynamic Injection| Gateway
        Vault -.->|Dynamic Injection| Acc
        Vault -.->|Dynamic Injection| Bill
        Vault -.->|Dynamic Injection| Content
        Vault -.->|Dynamic Injection| Portal
    end
```

| Repository | Local Path | Target Platform | Runtime Config (Sourced from Vault) |
| :--- | :--- | :--- | :--- |
| **`portal`** | `ai-workspace-service/portal` | **Cloudflare Pages** | `NEXT_PUBLIC_API_URL=https://uat-api.svc.plus`<br>`NEXT_PUBLIC_SUPABASE_ANON_KEY` |
| **`edge-gateway`** | `ai-workspace-service/edge-gateway.svc.plus` | **Cloudflare Worker** | `PRIMARY_UPSTREAM=Cloud Run URL`<br>`JWT_SECRET` |
| **`accounts`** | `ai-workspace-service/accounts` | **GCP Cloud Run** | `min-instances=0, max-instances=2`<br>`DATABASE_URL=Supabase Pooler 6543` |
| **`billing-service`** | `ai-workspace-service/billing-service` | **GCP Cloud Run** | `min-instances=0, max-instances=2`<br>`DATABASE_URL=Supabase Pooler 6543` |
| **`content-service`** | `ai-workspace-service/content-service` | **GCP Cloud Run** | `min-instances=0, max-instances=2`<br>`DATABASE_URL=Supabase Pooler 6543` |
| **`postgresql`** | `ai-workspace-service/postgresql` | **Supabase Cloud Free** | Permanent seed fixtures & schema |

---

## 🛠️ 4. Standalone Automation & Pipeline Layout

### 1. `platform-ops-toolkit` Orchestrator Layout
```text
platform-ops-toolkit/
├── .github/
│   └── workflows/
│       ├── uat-serverless-orchestrator.yml   # Master entry pipeline (Manual + PR + Cron 09:00)
│       ├── uat-daily-cleanup.yml             # Daily 20:00 automated teardown of Cloud Run compute
│       └── uat-supabase-keepalive.yml        # Weekly keepalive ping
└── scripts/
    └── serverless_uat/
        ├── deploy_orchestrator.py            # Master Python controller (Vault fetch & dispatch)
        ├── deploy_cloudrun_services.sh       # Deploy Go containers (min=0)
        ├── deploy_cloudflare_worker.sh       # Deploy edge-gateway
        ├── deploy_cloudflare_pages.sh        # Deploy portal
        ├── destroy_ephemeral_compute.sh      # Destroy Cloud Run instances and stale images
        └── supabase_keepalive.sh             # Lightweight keepalive probe
```

### 2. Ansible Role Extension (`playbooks/roles/saas/serverless_uat/`)
```text
playbooks/roles/saas/serverless_uat/
├── defaults/
│   └── main.yml                              # Default configs (Vault paths, Cloud Run specs)
├── tasks/
│   ├── main.yml                              # Master task entrypoint
│   ├── fetch_vault_credentials.yml           # Vault extraction task
│   ├── deploy_cloudrun.yml                   # Cloud Run deployment task
│   ├── deploy_cloudflare.yml                 # Cloudflare Worker & Pages task
│   ├── smoke_test.yml                        # Automated smoke verification
│   └── destroy.yml                           # Ephemeral compute cleanup
└── README.md                                 # Role documentation
```

### 3. IaC Module Extension (`iac_modules/terraform-hcl-standard/modules/serverless_uat/`)
```text
iac_modules/terraform-hcl-standard/modules/serverless_uat/
├── main.tf                                   # Cloud Run v2 and Cloudflare resource declarations
├── variables.tf                              # Input variables (vault_addr, env, image_tags)
├── outputs.tf                                # Service endpoint outputs
└── README.md                                 # Module documentation
```

---

## 💰 5. Total Cost Analysis & Production Checklist

### Cost Breakdown
| Component | Operational Policy | Monthly Bill |
| :--- | :--- | :--- |
| **Cloudflare Pages (UAT Frontend)** | Global CDN static hosting, unlimited bandwidth | **$0.00** |
| **Cloudflare Worker (UAT Gateway)** | < 1000 requests/day, within 100k daily free tier | **$0.00** |
| **GCP Cloud Run (UAT Go Containers)** | Active 8 hours on-demand, destroyed at night | **$0.00** |
| **Supabase Cloud (UAT Database)** | 500MB free storage, weekly keepalive | **$0.00** |
| **HashiCorp Vault (Credential SOT)** | Hosted on existing `vault.svc.plus` | **$0.00** |
| **Total Monthly UAT Budget** | **Complete Full-Stack Enterprise UAT Environment** | **$0.00 / mo** |

### Implementation Checklist
- [ ] Create 4 secret paths under `kv/data/uat/serverless/` on `vault.svc.plus`;
- [ ] Implement `scripts/serverless_uat/` and GitHub Actions workflows in `platform-ops-toolkit`;
- [ ] Implement Ansible role in `playbooks/roles/saas/serverless_uat`;
- [ ] Implement Terraform module in `iac_modules`;
- [ ] Run initial end-to-end UAT verification and smoke tests.
