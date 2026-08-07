# 🚀 Practice Verification: How to Safely "Mirror" PROD Data to UAT? — Circuit Breakers, Schema Contracts, and Automated Validation Loops

**— From Daily Immutable Tags to 4-Layer Safeguard Barriers: Leveraging Production Data to Safely Validate UAT Releases**

![SAFE DATA MIRRORING & UAT PARITY](/assets/images/data-parity-architecture.png)

---

**Author Information**

- Author: Haitao Pan
- Role: Platform Engineer
- Projects: XWorkmate · XConnect · Open Platform
- Organization: ai-workspace-infra (https://github.com/ai-workspace-infra)
- One-liner: *Bring AI into real work, not just chat — from ideas to workflows, to controllable execution.*

---

## Executive Summary

In our previous two essays, we argued why [*Platform Engineering Core Proposition: Development Environment ≠ Build Environment ≠ Runtime Environment*](https://console-uat.onwalk.net/blogs/00-global/essays/2026-07-31-Platform-Engineering-Environment-Isolation-and-Convergence.zh) and implemented [*Practice Verification: Docker Single-Node GitOps*](https://console-uat.onwalk.net/blogs/00-global/essays/2026-07-31-Docker-Single-Node-GitOps.zh).

However, once container artifacts and infrastructure configurations become immutable, platform teams quickly hit the final invisible trap of **Environment Parity: Data Disconnect**. 
In UAT, code is up to date, but the database holds only artificial test rows. Complex historical edge cases and real-world business scenarios can never be thoroughly tested. Conversely, dumping a raw production database directly to staging introduces catastrophic risks of **accidental overwrites, writing back to production, or leaking sensitive customer data**.

This article leverages three core GitHub Actions workflows in `platform-ops-toolkit` (`daily-main-snapshot.yaml`, `platform-ops.yaml`, and `data-migration.yaml`) to demonstrate how we achieve safe `PROD -> UAT` data mirroring via **Schema Hash Contracts, a 4-Layer Safeguard Architecture, and Automated Incremental Reconciliation**.

---

## 1. The Pain Point: Code Is Converged, But Data Is "Fake Clean"

During continuous delivery, teams frequently hit these walls:

1. **The False Security of "Empty DB Testing"**:
   Features pass tests in UAT but crash in production with primary key collisions, foreign key violations, or truncated fields. The root cause is simple: UAT test data is "ideal data" manually entered by developers, while production harbors years of legacy edge cases.
2. **The High-Wire Act of "Manual SQL Imports"**:
   Operators manually dump `prod.sql` and run `psql -h uat_db < prod.sql`. One day, a typo replaces `-h uat_db` with `-h prod_db`, and production data is permanently destroyed in a split second.
3. **Schema Drift & Field Incompatibility**:
   PROD runs `v1.2` database schemas while UAT has been upgraded to `v1.3` with new DDL migrations. A naive full `pg_dump` overwrites UAT's new schema definitions, causing application startup crashes.

**Core Challenge**: How can UAT **safely leverage production-derived data** to validate new releases while **physically eliminating production write risks**?

---

## 2. Overall Architecture: The Triad of Artifacts, Deployment, and Data Mirroring

In `platform-ops-toolkit`, we decouple UAT release validation into three standardized pipeline phases:

```text
 ┌────────────────────────┐
 │ daily-main-snapshot    │  1. Midnight Cron: Cross-repo immutable daily-build-YYYY.MM.DD Tag
 └───────────┬────────────┘
             │
             ▼
 ┌────────────────────────┐
 │ platform-ops.yaml      │  2. IaC Provision & Auto GitOps Tag Update -> doco-cd Reconciliation
 └───────────┬────────────┘
             │
             ▼
 ┌────────────────────────┐
 │ data-migration.yaml    │  3. Safeguard Assertions -> PROD Export -> UAT Dry-Run -> Merge
 └────────────────────────┘
```

### 2.1 Daily Immutable Snapshots (`daily-main-snapshot.yaml`)
- Triggered every midnight via cron using short-lived GitHub App tokens issued by Vault OIDC.
- Runs integration tests across multi-repo organizations (`ai-workspace-infra`, `ai-workspace-services`) and tags commits with `daily-build-YYYY.MM.DD`.
- Ensures that UAT validation runs against an **immutable, single source of truth artifact**.

### 2.2 Multi-Cloud Deployment & GitOps Sync (`platform-ops.yaml`)
- Handles VPS infrastructure provisioning and Ansible base setup.
- Upon successful deployment, programmatically updates manifest tags in the `gitops` repository, triggering single-node GitOps engines (such as `doco-cd`) to reconcile container states.

### 2.3 Safe Data Mirroring & Migration (`data-migration.yaml`)
- Purpose-built workflow for `PROD -> UAT` data mirroring, featuring an embedded logical incremental merger (`migratectl`) protected by **4 layers of safeguards**.

---

## 3. Core Protection: 4-Layer Safeguard Architecture

To ensure data can be safely mirrored without any possibility of writing back to production, we established strict **circuit breakers** across database kernel, operating system, pipeline scripts, and Vault credential scopes:

| Safeguard Layer | Defensive Mechanism | Physical Effect |
| :--- | :--- | :--- |
| **1. PROD DB Kernel Read-Only** | PostgreSQL role configured as `NOSUPERUSER NOCREATEDB NOCREATEROLE` with `SELECT, USAGE` permissions only | Any `INSERT/UPDATE/DELETE` is rejected immediately by the Postgres engine (`permission denied`) |
| **2. OS Account Isolation** | Linux `readonly` SSH user excluded from `sudo` and `docker` groups | Cannot execute `docker exec` or modify container volume files on host |
| **3. Script String Circuit Breaker** | `accounts_data_migration.sh` executes hardcoded DSN assertions | If `TARGET_DSN` contains PROD domains (`svc.plus`), lacks UAT indicators (`onwalk.net`/loopback), or equals Source DSN, **script aborts with `exit 1` before connecting to any DB** |
| **4. Vault Credential Isolation** | PROD read-only credentials stored exclusively under Vault path `kv/data/uat/accounts-migration` | Scoped Vault role grants read-only DSN access; PROD write admin passwords **never enter** this pipeline |

```bash
# Safety assertion logic (from accounts_data_migration_safeguard_test.sh):
if [[ "$MIGRATION_TARGET_DSN" == *"svc.plus"* ]]; then
    echo "::error::CRITICAL: Target DSN contains PROD domain! Aborting to prevent disaster."
    exit 1
fi
```

---

## 4. Technical Deep Dive: Single Binary & Dual Transports

### 4.1 Schema Contract & Single Binary Constraint (`migratectl`)
Traditional migrations fail when schemas drift between environments. To guarantee strict Schema agreement between export and import steps:

- Services embed a Go CLI tool named `migratectl`;
- During build, `schema.sql` is embedded into the binary and a unique `schemaHash` is computed;
- Snapshots exported by `migratectl export` embed this hash;
- During `migratectl import`, **the CLI validates that the snapshot hash exactly matches the binary's hash**, rejecting mismatched versions.
- **CI Rule**: `data-migration_accounts_build-migratectl.sh` builds **a single binary** used for both export and import steps in the pipeline, eliminating version drift at the root.

### 4.2 Dual Transport Modes: `direct` vs `ssh`

```text
 Mode A: direct (Runner Direct DSN Connection)
 [Runner (migratectl)] ──(SELECT DSN)──► [PROD DB:5432]
                       ──(WRITE DSN)───► [UAT DB:5432]

 Mode B: ssh (Container NetNS Fallback — Zero Public Exposure)
 [Runner] ──(SSH readonly)──► [PROD Host] ──(docker exec)──► [PROD DB (loopback)]
          ──(SSH deploy)────► [UAT Host]  ──(docker exec)──► [UAT DB (loopback)]
```

1. **`direct` Mode**:
   Used when GitHub Runners can reach PostgreSQL endpoints directly. Dynamically fetches `MIGRATION_SOURCE_DSN` (read-only) and `MIGRATION_TARGET_DSN` (write) from Vault.
2. **`ssh` Mode**:
   Used when database ports are isolated from public ingress (only exposing 5433 Stunnel TLS listeners). The runner connects via SSH with a restricted `readonly` key, invoking `migratectl` inside the `web-saas-postgresql` container's network namespace (NetNS) over loopback `trust` authentication.

---

## 5. Automated Execution: From Dry-Run Preview to Convergence Assertion

The worst automated migration failure is a green CI status when no data was actually imported. `data-migration.yaml` solves this with a two-pass verification loop:

### 5.1 Dry-Run Preview (`accounts_dry_run = true`)
```bash
migratectl import \
  --dsn "$MIGRATION_TARGET_DSN" \
  --file /tmp/account-prod-snapshot.yaml \
  --dry-run \
  --merge \
  --merge-strategy timestamp
```
Executes snapshot merging inside a Postgres transaction and performs an immediate `ROLLBACK`, printing a granular diff report of inserted, updated, and skipped conflict rows.

### 5.2 Incremental Apply (`accounts_dry_run = false`)
Applies timestamp-based merging:
- New PROD users: Incrementally inserted into UAT;
- Conflicts: Retains the row with the newer `updated_at` timestamp;
- UAT-only test accounts: **Preserved without deletion**, keeping developer test environments intact.

### 5.3 Second-Pass Convergence Assertion
Following the import, the script executes a second `--dry-run` against UAT using the **same PROD snapshot**:

$$\text{Assert: } \text{inserted}_{\text{users}} = 0 \quad \land \quad \text{inserted}_{\text{identities}} = 0 \quad \land \quad \text{inserted}_{\text{sessions}} = 0$$

If any non-zero insert count is detected, it proves data failed to converge, causing the pipeline to abort with `exit 1`.

---

## 6. Summary & Engineering Principles

From build environment isolation (LFS/Docker), to declarative state management (GitOps), to safe data parity, platform engineering adheres to consistent principles:

1. **Isolation Precedes Stability**: Environments, credentials, and database roles must remain isolated by default and communicate strictly via explicit contracts.
2. **Safeguards Outweigh Guidelines**: Never rely on manual operator discipline. Hardware-level and kernel-level read-only constraints (`NOSUPERUSER` + string assertions) guarantee security.
3. **Processes Become Products**: Data migration is not a manual script; it is a **reproducible, verifiable, and audited automated product pipeline**.

With this infrastructure, our team automatically pairs daily immutable code tags with safe production data snapshots every midnight — making UAT the most reliable proving ground prior to production releases.

---

### **Open Questions for Discussion**
1. How does your team handle test data in staging/UAT — manual seed data, mock generators, or sanitized production mirrors?
2. When synchronizing data across environments, do you prefer sanitizing sensitive fields (e.g., emails, credentials) at the export boundary or during the import pipeline?
3. What hard automated "safeguards" or circuit breakers have saved your production systems from accidental operator error?

*Share your experience and thoughts in the comments below!*
