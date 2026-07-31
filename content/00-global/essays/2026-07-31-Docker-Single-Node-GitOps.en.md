# 🚀 Practical Validation: Single-Node Docker Can Do GitOps Too

**— Zero-Trust Credentials + Declarative State + AI-Accelerated Multi-Environment Delivery in Practice**

![Multi-Cloud Delivery](/assets/images/multi-cloud-delivery.png)

---

**Author Profile**

- **Author**: Haitao Pan
- **Role**: Platform Engineer
- **Projects**: XWorkmate · XConnect · Open Platform
- **Open-Source Organization**: ai-workspace-infra (https://github.com/ai-workspace-infra)
- **Motto**: Bring AI into real work, not just chat—from ideas to workflows, and ultimately to controllable execution.

---

## Abstract

In 2024, I worked as an SRE at a new energy vehicle (NEV) manufacturer, responsible for deploying and maintaining industrial PCs (IPCs) on the production line. These IPCs were exclusively standalone single-node Docker hosts, updated manually with semi-automated tools. Less than four months later, I departed during a round of layoffs, but one question remained stuck in my mind: **Why shouldn't standalone Docker enjoy K8s-level declarative, traceable, and automated deployment experiences?**

The answer is: It can. This article presents a battle-tested solution that answers this question—centering on **doco-cd** (declaring `docker-compose` in a Git repository where pushing equals deploying and `git revert` equals rolling back), layered with **Vault OIDC zero-trust dynamic credentials** and **AI Agent pair programming**. Together, they transform "Single-Node GitOps" from a tagline into a daily production pipeline. This article breaks down the 4 core workflows supporting this architecture (GitOps state backwriting, daily immutable snapshots, Vault ACME certificate rotation, and multi-cloud orchestration hub), while sharing real-world insights on how AI compressed 2–3 months of infrastructure work into a few weeks.

---

## 1. Origin: What Industrial PCs on the Production Line Taught Me

In 2024, I joined an NEV carmaker as an SRE overseeing industrial PCs at the production edge. They shared several common traits: **standalone deployments, Docker runtime, and no cluster**. No Kubernetes, no Service Mesh. How were updates handled? Via semi-automated scripts crafted by hand:

- Build image → manually `scp` to target machine → manually run `docker compose up -d` → pray everything works.

This workflow suffered from three fatal flaws that anyone with traditional ops experience understands:

1. **Non-traceable**: What version is currently running on the server? You only knew by logging in and running `docker ps`. The Git repository was completely blind to production environments.
2. **Non-rollbackable**: Need to roll back when things go wrong? You had to dig through chat history to find the previous image tag, rerun the manual steps, all while services remained unavailable.
3. **Configuration Drift**: Each machine's `docker-compose.yml` was often a copy tweaked manually at some point in history, causing environmental divergence to compound over time.

Four months later, I left during layoffs. But the "standalone Docker deployment experience" problem never left me. Fundamentally, it was an engineering dignity question: **Why should only Kubernetes users enjoy a "declarative, traceable, automated" deployment experience while single-node Docker users are stuck in 2015?**

The answer came later: You can have it without introducing Kubernetes. Internally, we call this solution "Lightweight GitOps"—powered by **doco-cd**, a single-node GitOps engine.

---

## 2. Overall Architecture: Four Components & Three Principles

### 2.1 Tech Stack

The entire delivery stack comprises four core components and one "Engineering Brain":

| Component | Role | Primary Responsibility |
| --- | --- | --- |
| **Docker** | Execution | Immutable container artifacts; Image Tag = Version Identity |
| **GitOps** (doco-cd / ArgoCD) | State | Declarative reconciliation; Git as the Single Source of Truth |
| **HashiCorp Vault** | Security | Dynamic credentials, centralized secrets storage, granular access control |
| **GitHub Actions** | Orchestration | CI/CD pipeline hub & supply chain security gating |
| **AI Agent** | Engineering Brain | Architecture reasoning, troubleshooting, and script debugging |

### 2.2 Three Architecture Principles

1. **Single Source of Truth**: The exact version and state of any application across all environments must be 100% declaratively represented in Git.
2. **Zero-Trust & Centralized Secrets**: Eliminate long-lived static tokens in favor of dynamic, short-lived credentials distributed via Vault + OIDC.
3. **Immutable Infrastructure**: The exact same image tag flows through all environments unchanged, eliminating environment-to-environment drift.

### 2.3 Two-Tier GitOps: doco-cd for Single Nodes, ArgoCD for Clusters

A frequently overlooked fact: GitOps is not exclusive to Kubernetes. Our practice adopts a **two-tier approach based on node scale**:

- **Single Node (Industrial PCs, Edge Hosts, Temporary Load-Testing Nodes)**: Powered by **doco-cd**—a lightweight GitOps engine that uses a Git repository declaring `docker-compose` as the target state, pulling and reconciling local containers periodically (or triggered via webhook);
- **Multi-Node / Clusters**: Powered by **ArgoCD**—declarative state generation and reconciliation tailored for multi-cluster environments.

The underlying logic boils down to one sentence: **Image Tag is the immutable identity, Git Commit is the deployment command, Vault is the dynamic shield, and AI is the engineering accelerator.**

> Diagram Recommendation ①: Multi-cloud delivery architecture topology (Four-color ring capability chart: GitOps / Vault / Docker / GitHub Actions + Open-Source Observability Suite).

---

## 3. Core Workflows (Part 1): State Backwriting & Daily Snapshots

### 3.1 `auto-gitops-tags-update`: Letting Git "Backwrite" Your State

**Pain Point**: Traditional CI pipelines push images directly to servers after building. Git repositories remain "blind" to production environments—making it impossible to know which version is deployed when a rollback is needed.

**Approach**: We practice pure GitOps. Once an image build succeeds, the pipeline never SSHs into any server. Instead, it **programmatically updates the Image Tag in the infrastructure manifest repo and commits the change**:

```text
Image Build Succeeded
  └─▶ Automatically update Image Tag in infra repo
        └─▶ Create Git Commit
              └─▶ doco-cd detects change → auto-pull → auto-reconcile
```

**Outcome**:

- Every upgrade = one `git log` entry. You know exactly what version is running where at any given moment;
- Rollback = `git revert`, simple enough to be delegated to an on-call bot;
- Deployment relies on **Pull** rather than Push. No inbound ports need to be open on the server, minimizing the attack surface.

### 3.2 `daily-main-snapshot.yaml`: A Midnight Reassurance

**Pain Point**: Code "conflicts when merged late and breaks when left stale." Build failures on the eve of release day are every operator's dark moment.

**Approach**: This workflow runs every midnight:

```text
🕛 Every Midnight (cron)
  └─▶ Pull latest main branch
        └─▶ Run full integration test suite
              └─▶ Force-build snapshot-YYYYMMDD immutable Image Tags
```

**Outcome**:

- UAT, temporary load testing, or emergency firefighting—pick any daily snapshot with **100% confidence**;
- Ensures every cloud node pulls the **exact same integration-tested artifact**, eliminating "different version on this machine" drift at its root.

---

## 4. Core Workflows (Part 2): Vault ACME Certificate Rotation (DevSecOps)

**Pain Point**: Managing HTTPS certificates across edge nodes in multi-cloud environments is an operational nightmare—manual applications, email exchanges, midnight expirations, and production outages. Certificate rotation is a ticking time bomb for many platforms.

**Approach**: We automated the full 90-day Let's Encrypt wildcard certificate lifecycle using HashiCorp Vault in three steps:

1. **OIDC / JWT Authentication (Zero-Trust Entry)**: Completely removed plaintext Vault tokens. GitHub Actions uses its native OIDC identity to authenticate with Vault. Vault strictly validates the JWT claim (**only allowing triggers from the `main` branch**) before issuing short-lived tokens.
2. **Automated Issuance & Secure Storage**: Within an **ephemeral container**, the pipeline validates domain ownership via the **Cloudflare DNS API**, issues the Let's Encrypt certificate, and immediately writes the new cert to the centralized Vault cluster using `vault kv put` (under `kv/CICD/domains`).
3. **Zero-Touch Hot Reloading on Edge Nodes**: CI runners leave zero traces and never touch production edge nodes. Edge gateways simply **listen to updates in the corresponding Vault path** and trigger seamless hot-reloading upon detecting new certificates.

**Security Details** (The fundamental difference from "one static key for everything"):

- Dynamic Token permissions are scoped strictly to **read certificate-related paths only**;
- Short token lifespan: **destroys immediately upon pipeline completion**—even if runner logs leak, the leaked token is already invalid;
- Unattended, fully auditable end-to-end rotation.

**Outcome**: Certificate rotation transformed from a "high-risk manual task" into a "routine background job," reducing HTTPS expiration incidents to zero.

---

## 5. Core Workflows (Part 3): `platform-ops.yaml` Orchestration Hub & Integrated Observability

### 5.1 Multi-Cloud Command Brain

`platform-ops.yaml` acts as the **master orchestrator and central bus** for the delivery chain. It compiles no application code; it strictly orchestrates infrastructure operations:

- Analyzes upstream GitOps tags (state of build artifacts);
- Bootstraps Remote Host Monitor Agents (observability proxies);
- Triggers database migration scripts;
- Executes **weighted DNS traffic switching** (blue-green canary traffic shifting).

**Supply Chain Gating**: We enforced strict CI gating—custom validation scripts **prohibit un-audited inline shell scripts inside `run:` blocks**. All scripts must be checked into the repository, code-reviewed, and packaged into reusable actions or script files before execution. This eliminates "pipeline supply chain poisoning" at the source.

### 5.2 Integrated Observability: Monitoring Follows the Workload

Through `platform-ops.yaml`, we do not merely deploy applications; we **bind the infrastructure monitoring lifecycle directly into the deployment workflow**:

- Whenever a new node joins or an environment initializes, the pipeline leverages **Ansible Matrix** to automatically bootstrap **Node Exporter, Process Exporter**, and log collection agents;
- This **Isomorphic Deployment** strategy guarantees that wherever workloads run, the monitoring grid follows seamlessly;
- Coupled with OpenTelemetry instrumentation from `observability.svc.plus`, Prometheus metrics, Loki logs, and Grafana visualization, **environment-drift-induced monitoring blind spots are completely eradicated**—eliminating scenarios where "a service goes live, but nobody knows where it lives."

> Diagram Recommendation ②: GitHub Actions `platform-ops` workflow topology screenshot;  
> Diagram Recommendation ③: Unified UAT monitoring console screenshot;  
> Diagram Recommendation ④: Node Exporter global resource monitoring view.

---

## 6. AI Agent Acceleration & Multi-Repo Ecosystem

### 6.1 From 2–3 Months to 4 Weeks: What AI Actually Accomplished

To be frank, building an infrastructure ecosystem spanning 10+ repositories involving complex integration across Ansible, Terraform, GitHub Actions, Vault, TLS, and OpenTelemetry would traditionally require a senior DevOps engineer **2 to 3 months** of full-time effort. In this refactoring project, through deep pair programming with Agentic AI, the entire milestone was compressed into **a few weeks**, with some complex components completed in days.

AI's contribution wasn't merely "helping write YAML," but four concrete engineering breakthroughs:

1. **Architecture Reasoning & IaC Modular Refactoring**: Deriving repository boundaries and module design directly from requirements;
2. **TLS Certificate Rotation & Vault Zero-Trust Integration**: Bridging cross-system authentication pipelines;
3. **Bash / Python Supply Chain Gating Script Debugging**: Handling tricky edge conditions that AI significantly shortened the debug cycle for;
4. **YAML Syntax Correction & CI/CD Troubleshooting**: Resolving obscure errors (e.g., **cross-cloud OIDC claim rejections, permission scope mismatches**), where AI Agents autonomously analyzed logs, traced execution paths, and provided ready-to-merge PR fixes.

Our takeaway: AI's value density correlates directly with how precisely a problem is defined. Feeding the Agent `[Target State + Constraints + Failure Logs]` is an order of magnitude more efficient than letting it brainstorm freely.

### 6.2 The Building Block Ecosystem Behind It: ai-workspace-infra

This architecture succeeds thanks to the **high-cohesion, low-coupling multi-repo strategy** under the `ai-workspace-infra` organization—not a monolithic repository, but a specialized ecosystem:

| Repository | Responsibility |
| --- | --- |
| `platform-ops-toolkit` | AI-driven platform operations brain (migrations and platform tasks) |
| `gitops` / `playbooks` / `iac_modules` | The GitOps Troika: Environment Manifests (State) / Ansible (Config) / Terraform (Multi-Cloud IaC) |
| `observability.svc.plus` | End-to-end observability stack: OpenTelemetry + Prometheus + Loki |
| `postgresql.svc.plus` | Production-grade PG cluster: Vector search, TLS tunneling, High Availability |
| `artifacts` / `diagram-generator` | Artifact hosting, architecture diagram generation, and utility tools |

This building-block multi-repo strategy decouples IaC, base components, and application code—allowing any layer to evolve and roll back independently.

### 6.3 Future Roadmap: Evolving Toward Advanced SRE Capabilities

Thanks to the modular design of `platform-ops.yaml`, the infrastructure is prepared for the following advanced capabilities:

| Capability | Implementation Path |
| --- | --- |
| **Seamless Multi-Cloud Migration** | Weighted DNS traffic shifting + cross-cloud orchestration for zero-downtime hot migration across cloud vendors |
| **Pre-Deployment Automated Load Testing** | Integrating K6 / JMeter into pre-release pipeline stages using dynamically provisioned load nodes |
| **Automated Disaster Recovery Drills** | Vault active/standby replication + GitHub Actions periodically simulating cross-region failovers |
| **Chaos Engineering** | Chaos Mesh injecting failures (network latency, pod crashes), validated against dense monitoring probes for self-healing |

---

## Conclusion

The essence of this overhaul lies in separating distinct concerns cleanly, then locking them together seamlessly:

- **Docker** handles execution—Immutable artifacts;
- **GitOps (doco-cd / ArgoCD)** handles state—Declarative reconciliation;
- **Vault** handles security—Zero-Trust dynamic credentials;
- **GitHub Actions** handles orchestration—Pipeline hub & supply chain gating;
- **AI Agent** handles intelligence—Architecture reasoning & troubleshooting.

We no longer scatter sensitive configurations across fragmented GitHub Secrets. Instead, we centralize them in Vault, distributing them via fine-grained, short-lived OIDC credentials. Single-node Docker finally gets a Kubernetes-level deployment experience—**and all you need is a `git push`.**

**Open Questions for Discussion**:

1. For single-node / edge scenarios, what GitOps solutions do you use? What other tools besides doco-cd are worth paying attention to?
2. When landing OIDC dynamic credentials, are cross-cloud claim validation and permission scoping the biggest pitfalls? How do you handle them?
3. How can platform engineering teams systematically introduce Agentic AI beyond just "asking it to write YAML"?

**Reference Links**: https://github.com/ai-workspace-infra

---

## Appendix: Image Recommendation List (For Editorial Layout)

1. Multi-cloud delivery architecture topology (Four-color ring capability chart: GitOps / Vault / Docker / GitHub Actions + Open-Source Observability Suite)
2. `platform-ops` GitHub Actions workflow topology screenshot
3. Unified UAT monitoring console screenshot
4. Node Exporter global resource monitoring view

---

*This article is based on the author's real-world engineering practice during multi-environment delivery refactoring.*
