# Architecture Review Addendum — Pragmatic Trade-offs for the Interview Build

**Document status:** Companion to `architecture.md` (v1.0)
**Purpose:** A self-critique from a Principal Architect perspective, calibrated for the reality that this is a **technical interview exercise deployed to a personal Azure subscription** — not a production rollout.
**Audience:** Reviewers, interview panel, and future-me.

---

## 0. How to Read This Document

Every finding below is tagged with one of three actions:

| Tag | Meaning |
|---|---|
| **[IMPLEMENT]** | Worth the time — actually change the code/Terraform for this build. |
| **[DOCUMENT]** | Not worth implementing at this scale/budget, but must be called out in `architecture.md`, code comments, or the README so reviewers see it was considered. |
| **[VERBAL]** | Talk about it in the interview when asked; no code or doc change required. |

The point of this addendum is to prove two things simultaneously:
1. I can see the gaps a Principal Architect would raise.
2. I can make **grown-up trade-off calls** about what to fix versus what to defer in a time-boxed, personal-subscription context — instead of gold-plating for its own sake.

---

## 1. Context & Constraints

- **Environment:** Personal Azure subscription (Pay-As-You-Go / MSDN credit).
- **Purpose:** Demonstrable, defensible interview artefact — not a production system serving real users.
- **Budget:** ~5 hours build time; must be inexpensive to leave running (or destroy-and-recreate on demand).
- **Data classification:** The seed data is public-domain quotes. The assessment *requires me to treat it as critical PII* — I honour that treatment in the design language, but calibrate real-world spend accordingly.
- **Blast radius:** Only me. There is no on-call rotation, no compliance auditor, no SOC 2 evidence collection.

These constraints justify de-scoping several enterprise controls. The controls are still discussed — that discussion **is** the interview value.

---

## 2. Security Findings

### 2.1 Key Vault has a public endpoint — [IMPLEMENT]
**Original claim in architecture.md:** Key Vault public access accepted as a "Phase 2" trade-off.
**Reality:** App Service Key Vault References work fine over a Private Endpoint with VNet integration + the `privatelink.vaultcore.azure.net` DNS zone. The "Phase 2" framing is a cop-out.
**Action:** Add a Key Vault Private Endpoint. Set `public_network_access_enabled = false`, `network_acls.default_action = "Deny"`. ~15 min of Terraform.
**Why implement even for a demo:** It costs cents, it's a demonstrable control, and reviewers will ask "why is Key Vault public if you claim zero trust?" I don't want that question.

### 2.2 `X-Azure-FDID` header check alone is spoofable — [IMPLEMENT]
**Gap:** Header-only checks are trivially bypassed if the App Service default hostname is reachable.
**Action:** Combine the `X-Azure-FDID` header restriction with an **IP-based rule using the `AzureFrontDoor.Backend` service tag**. Both together = the documented Microsoft pattern.
**Not implementing:** Front Door Premium + Private Link to origin. That's ~$330/mo minimum and busts the personal-subscription budget. **[DOCUMENT]** as the correct production hardening path.

### 2.3 Seed job identity is under-specified and probably over-privileged — [IMPLEMENT (simplified)]
**Gap:** Original doc conflated CI's `Contributor` with data-plane write rights.
**Action (pragmatic):**
- Create a **User-Assigned Managed Identity** (`uami-qotd-seeder`) used *only* for seeding.
- Assign it `db_datawriter` on the quotes DB.
- The seed job runs as a GitHub Actions job that federates to this UAMI (separate federated credential from the Terraform SP).
- CI's Terraform SP does **not** carry DB write rights at runtime.
**Not implementing:** Full separation of duties with a dedicated seeder pipeline running in ACI inside the VNet. **[DOCUMENT]** — for prod PII, seeding must run inside the VNet; for a demo, temporarily allowing the GitHub-hosted runner via a just-in-time firewall rule during the seed step (added and removed in the same workflow) is acceptable and demonstrates the pattern.

### 2.4 No CMK, no Always Encrypted, no data classification — [DOCUMENT]
**Reality check:** The "PII" here is famous quotes. Layering CMK-TDE, Always Encrypted, and Purview classification on public-domain text is theatre.
**Action:** Add a **PII Handling Trade-off Note** to `architecture.md` §7 explicitly stating:
> "Microsoft-managed TDE is enabled by default. For genuinely sensitive PII, this design would add: CMK-TDE via Key Vault, infrastructure double encryption, Always Encrypted on identifier columns, Dynamic Data Masking for non-privileged reads, and SQL Data Classification labels emitted to audit logs. These are omitted here because the dataset is public-domain quotes and adding them without real PII columns to protect is security theatre."
**Interview value:** Naming the controls proves I know them. Not implementing them proves I know when *not* to over-engineer. Both are senior signals.

### 2.5 System-Assigned Managed Identity is fragile across recreates — [IMPLEMENT]
**Gap:** SAMI's object ID is bound to the App Service. Rename/recreate = every RBAC + SQL Entra mapping breaks.
**Action:** Use **User-Assigned Managed Identity** for the App Service. Same UAMI can be assigned to the staging slot too (SAMI can't — slots get separate identities).
**Why implement:** Zero extra cost, one extra Terraform resource, eliminates a real footgun. This is the single highest-leverage fix in this document.

### 2.6 SQL Entra user creation from a public-runner is architecturally undefined — [IMPLEMENT (pragmatic path)]
**Gap:** `CREATE USER [x] FROM EXTERNAL PROVIDER` requires network line-of-sight to a private-endpoint-only SQL server, executed by an Entra-authenticated principal. Not possible from a stock GitHub-hosted runner without extra plumbing.
**Action (chosen for this build):** Use a **just-in-time firewall rule** pattern for the initial user-provisioning step only:
1. Terraform provisions SQL with public network access **disabled**.
2. A one-shot bootstrap workflow temporarily adds the GitHub runner's egress IP as a **firewall rule** on the SQL server (using the CI SP's `Contributor` rights), runs the `CREATE USER` + `ALTER ROLE db_datareader ADD MEMBER` + `db_datawriter` grants for the seeder UAMI, then removes the firewall rule.
3. Steady-state: SQL is private-only again, only the seeder UAMI (writer) and app UAMI (reader) can talk to it, both from inside the VNet.
**Not implementing:** Azure Deployment Scripts or a self-hosted VNet-integrated runner. **[DOCUMENT]** — for prod, one of those is mandatory; the JIT firewall pattern is a demo-grade shortcut and I will label it as such in the code comments.

### 2.7 Front Door WAF ruleset version not specified — [IMPLEMENT]
**Action:** Pin `Microsoft_DefaultRuleSet_2.1` in Prevention mode. Add a rate-limit custom rule (100 req/min per IP) with `/health*` excluded. ~5 lines of Terraform.
**Not implementing:** Bot Manager ruleset (Premium-tier only). **[DOCUMENT]** as the Premium-tier addition.

### 2.8 No DDoS Standard, NAT Gateway, or egress control — [DOCUMENT]
**Reality:** DDoS Protection Standard is ~$3k/mo. Azure Firewall is ~$900/mo. Neither belongs in a personal subscription.
**Action:** Add a "What This Design Deliberately Omits" section to `architecture.md` §7 listing DDoS Standard, Azure Firewall / NAT Gateway egress control, and Private DNS Resolver — with a one-line justification for each ("cost prohibitive for demo; would be included in enterprise deployment").

### 2.9 No secret rotation story — [DOCUMENT]
**Action:** Add a one-liner to §7: *"This design has zero rotatable secrets by construction — all workload authentication is Entra-token-based. There is nothing to rotate."* That is the strongest possible answer; say it plainly instead of leaving it implicit.

### 2.10 GitHub security controls named but not enforced — [IMPLEMENT (the free ones)]
**Action — do all of these, they're free and take minutes:**
- Enable **GitHub Push Protection** for secrets (org/repo setting).
- Enable **Dependabot** for `npm` and `github-actions` ecosystems.
- Enable **CodeQL** default setup for JavaScript.
- Add a `SECURITY.md`.
- Enable **artifact attestation** on the app-build workflow (`actions/attest-build-provenance`).
**Not implementing:** Signed commits requirement (adds friction for solo work), GitHub Advanced Security paid features. **[VERBAL]** if asked.

---

## 3. High Availability Findings

### 3.1 The 99.95% composite SLA claim is arithmetic-optimistic — [IMPLEMENT (fix the number)]
**Correction:** 99.99% × 99.95% × 99.99% = **99.93%**.
**Action:** Update `architecture.md` §1 and §6 to publish **99.93%** and stop rounding up. Honest math is a senior signal.

### 3.2 Single-region HA is regional-outage-fragile — [DOCUMENT]
**Reality:** True multi-region (SQL failover group + secondary App Service + Front Door priority-2 origin) is ~2 additional hours of Terraform and roughly doubles cost. Both bust the constraints.
**Action:** In `architecture.md` §6, replace "highly available" with **"zone-resilient with region-restore DR (RTO ~1h, RPO ≤ 15min)"** — the honest description of what this build actually delivers.
**[VERBAL]** talking point: whiteboard the Phase 2 multi-region topology on request. Have the answer ready — SQL failover group, warm-standby App Service, Front Door priority-based origin group, `Standard_ZRS` for any additional storage.

### 3.3 Slot swap ≠ rollback for schema-breaking changes — [DOCUMENT]
**Action:** Add an "Expand-Migrate-Contract" note to §14 stating that all DB migrations must be backward-compatible so slot swap remains a valid rollback. Costs nothing to say, huge maturity signal.

### 3.4 No chaos / failover validation — [IMPLEMENT (lightweight)]
**Action:** Add a `scripts/failover-drill.sh` that runs `az sql db failover` against the demo DB, and instrument App Insights to display retry behaviour on the demo dashboard. ~15 minutes.
**Why implement:** Being able to say "here, watch me trigger a zone failover live" in the interview is an unmatched demo moment.

### 3.5 Zone-redundant SKU availability not pre-flighted — [IMPLEMENT]
**Action:** Hardcode a region known to support zone-redundant P1v3 + zone-redundant SQL GP (e.g., `eastus2`, `westeurope`, `northeurope`). Add a comment in `variables.tf` documenting why.
**Cost of not doing this:** `terraform apply` fails at minute 4:55 of the 5-hour build. Not worth the risk.

### 3.6 Node.js SQL driver retry behaviour undefined — [IMPLEMENT]
**Action:** Configure the `mssql` driver with a pool + retry policy handling the SQL transient error list (40613, 40197, 10928, 10929, 40501, etc.). ~10 lines. Without this, zone failover surfaces as visible 500s to the user during the demo.

---

## 4. Terraform Anti-Patterns

### 4.1 Two-phase Front Door apply is a circular dependency — [IMPLEMENT]
**Fix:** Move Front Door **profile + endpoint + WAF policy** into the `platform` layer, but move **origin group + origin + route** into the `application` layer where it belongs (it depends on the App Service that lives there anyway). Single-pass apply per layer, no `-target` gymnastics.
**Why implement:** The two-phase apply is embarrassing to demo and confusing to explain. Fixing it is ~30 minutes of module refactoring.

### 4.2 Cross-layer `terraform_remote_state` is fragile — [IMPLEMENT (partial)]
**Action:** Use `data "azurerm_*"` lookups by name (via a shared `locals.tf` naming convention) instead of `terraform_remote_state` where possible. Falls back to `terraform_remote_state` only for values that aren't discoverable by name (e.g., generated random suffixes).
**Trade-off documented:** Naming-convention-based lookup means the naming convention is now a **contract** — document it explicitly in the README.

### 4.3 `azurerm ~> 3.100` in 2026 is a sunset provider — [IMPLEMENT]
**Action:** Pin `azurerm ~> 4.x` (or the current major at implementation time). Update any v3→v4 breaking schema references. Add a `.terraform-version` file.
**Why implement:** Trivial to do now, painful to migrate later, and reviewers will notice a sunset pin.

### 4.4 God-modules vs. thin-modules vs. AVM — [IMPLEMENT (partial: AVM where it fits)]
**Action:** Use **Azure Verified Modules (AVM)** for the well-known building blocks where they exist and are stable:
- `Azure/avm-res-web-serverfarm/azurerm` and `Azure/avm-res-web-site/azurerm`
- `Azure/avm-res-keyvault-vault/azurerm`
- `Azure/avm-res-operationalinsights-workspace/azurerm`
- `Azure/avm-res-network-virtualnetwork/azurerm`

Keep custom modules only for the composition-heavy pieces (`sql_database` with private endpoint + audit + Entra admin) where AVM feels over-parameterised for a small demo.
**Trade-off documented:** Full AVM adoption would be more consistent but would also make me spend an hour reading AVM READMEs. Hybrid approach is the pragmatic call.
**[VERBAL]** talking point: name-drop AVM as the current Microsoft-recommended pattern even where I chose not to adopt it.

### 4.5 `null_resource` + `local-exec` for SQL seeding — [IMPLEMENT (the JIT firewall pattern from §2.6)]
**Action:** Seeding runs from a GitHub Actions job (not from `terraform apply`), using the JIT firewall pattern described in §2.6. Keeps Terraform declarative; keeps data-plane operations out of the IaC layer where they don't belong.

### 4.6 No `pre-commit`, no `terraform-docs`, no `tflint` — [IMPLEMENT]
**Action:** Add a `.pre-commit-config.yaml` with `terraform_fmt`, `terraform_validate`, `terraform_docs`, `tflint`, `checkov`. ~15 minutes total. Big maturity signal for near-zero cost.

### 4.7 Tagging is aspirational, not enforced — [IMPLEMENT (locals) / DOCUMENT (Azure Policy)]
**Action:**
- [IMPLEMENT] `locals.common_tags` merged into every resource block via `tags = merge(local.common_tags, { ... })`.
- [DOCUMENT] Azure Policy enforcement — mention it as the enterprise addition; don't provision policy assignments in a personal subscription.

### 4.8 State storage account has no delete-lock or immutability — [IMPLEMENT (lock only)]
**Action:** Add `azurerm_management_lock "state_rg"` with `lock_level = "CanNotDelete"` on the bootstrap RG. Two lines.
**Not implementing:** Immutable blob policy (adds ops friction for a demo I want to be able to tear down).

---

## 5. GitHub Actions Risks

### 5.1 `pull_request` federated credential could be abused by forks — [IMPLEMENT]
**Action:**
- No federated credential on `pull_request` for external PRs.
- Plan workflow uses `if: github.event.pull_request.head.repo.full_name == github.repository` to skip fork PRs.
- For internal PRs, use the `environment:plan` federated credential subject (requires the workflow to declare `environment: plan`, which forks can't do by default).

### 5.2 Terraform plan as PR comment leaks metadata — [DOCUMENT]
**Reality:** The repo is a personal demo repo and will be **private** during the interview. Public post-interview publication is optional.
**Action:** Post the plan comment in-workflow (fine while private). Add a note in the README: *"If publishing publicly, scrub plan output first."*
**[VERBAL]** talking point if asked.

### 5.3 No SHA-pinning on actions — [IMPLEMENT]
**Action:** Pin every third-party action to a full commit SHA. Dependabot will keep them updated. `actions/checkout@<sha> # v4.2.2` pattern.
**Cost:** ~10 minutes. Post-`tj-actions/changed-files` incident, this is table stakes.

### 5.4 `workflow_run` race between infra apply and app deploy — [IMPLEMENT]
**Fix:** Single **orchestrator workflow** `release.yml` that runs `validate → plan → apply-platform → apply-application → seed → deploy-slot → smoke-test → swap` as jobs with explicit `needs:`. Deterministic order, single source of truth.
**Why implement:** Simpler than orchestrating multiple `workflow_run` chains, and easier to demo (one green pipeline view).

### 5.5 No `concurrency:` control — [IMPLEMENT]
**Action:** `concurrency: { group: "release-${{ github.ref }}", cancel-in-progress: false }` on the release workflow. Prevents parallel-apply state corruption. Two lines.

### 5.6 OIDC audience not called out — [DOCUMENT]
**Action:** Explicit `audience: api://AzureADTokenExchange` in `azure/login` calls, with a comment. No behavioural change — just makes the config self-documenting.

### 5.7 No approval on `dev` deploy — [VERBAL]
**Reality:** Personal subscription, single dev environment, single operator. Approval gate on my own PRs to my own repo is pure friction with no benefit.
**Action:** Skip. Mention in the interview: *"In a shared subscription I'd add a 5-min wait timer even on dev to catch runaway pipelines; here it'd just slow me down."*

---

## 6. Cost Inefficiencies (Most Impactful Section for a Personal Subscription)

### 6.1 P1v3 + GP 2vCore SQL is 10-20× oversized for this workload — [IMPLEMENT]
**Action:** Rightsize the single deployed environment:

| Component | Original spec | Demo spec | Approx cost |
|---|---|---|---|
| App Service Plan | P1v3 zone-redundant, min 2 | **B2** single instance | ~$26/mo |
| Azure SQL | GP 2vCore zone-redundant | **GP Serverless, 0.5–2 vCore, auto-pause 60min** | ~$5–15/mo (near-zero when idle) |
| Front Door | Standard | Standard | ~$35/mo + traffic |
| Log Analytics | pay-as-you-go | pay-as-you-go with **1 GB/day cap** | ~$3/mo |
| Key Vault | Standard | Standard | ~$0.03/mo |
| **Total** | ~$250/mo | **~$70/mo** (and less when idle) | |

**Trade-off documented — this is important for the interview:**
- B2 single-instance loses the zone-redundant SLA (99.95% → 99.9%).
- Serverless SQL auto-pause causes ~30s cold-start on first request after idle.
- **Both are correct for a demo; neither would be correct for prod.** The `terraform/environments/prod/*.tfvars` file is committed but *never applied* — it shows the production sizing I would deploy if this were real. Reviewers can `terraform plan` it to see the intended prod topology.

**Pre-demo tip:** Hit the site 60 seconds before the interview to wake serverless SQL.

### 6.2 Zone-redundant SQL GP is a premium SKU — [DOCUMENT]
**Action:** Covered by §6.1 — demo runs non-zone-redundant Serverless GP; `prod.tfvars` shows zone-redundant GP as the production topology.

### 6.3 Front Door Premium + Private Link would blow the budget — [DOCUMENT]
**Action:** Use Standard. Add an ADR entry:
> "Front Door Standard chosen over Premium; Premium would provide Private Link to origin (eliminating origin-bypass risk entirely) at ~10× the cost. For this demo, origin bypass is mitigated via combined `X-Azure-FDID` header + `AzureFrontDoor.Backend` service tag IP restriction, which is the documented Microsoft pattern for Standard-tier deployments."

### 6.4 Log Analytics cost runaway — [IMPLEMENT]
**Action:**
- `daily_quota_gb = 1` on the workspace.
- `retention_in_days = 30` (billed minimum anyway).
- Consider **Basic Logs** plan for the highest-volume tables (Front Door access logs) — cuts ingestion cost ~80% for those tables.

### 6.5 Application Insights unbounded sampling — [IMPLEMENT]
**Action:** Adaptive sampling target = 5 items/sec (SDK config). One line. Meaningful at any volume above trivial.

### 6.6 Two applied environments doubles cost — [IMPLEMENT]
**Action:** Only apply `dev` (call it `demo` to be honest about its purpose). `prod` exists in the repo structure and can be plan'd to prove the code works — but never applied. **Explicitly documented in the README** so reviewers understand this is a deliberate choice, not an oversight.

### 6.7 Reserved capacity / Savings Plans — [VERBAL]
**Action:** Skip. If asked about production cost optimization, mention App Service Reserved Instances (up to 55% savings on 3-year commit) and SQL vCore reserved capacity.

---

## 7. Structural Additions Worth Making

### 7.1 AI usage section is generic — [IMPLEMENT]
**Action:** Rewrite `architecture.md` §15 with **specifics**:
- Which Copilot Agent prompts were used at each phase (paraphrase, one per phase).
- **What hallucinations were caught.** Copilot frequently invents `azurerm` resource arguments that don't exist (e.g., outdated attribute names from v2/v3 provider docs). Concretely name at least one that I caught via `terraform validate`.
- Which AI outputs were rejected wholesale and why.
- What the review-and-refine workflow looked like (draft → `terraform plan` → adjust → CI validation).

**Why implement:** The assessment explicitly says "please call out where and how [AI] is used" and warns the panel will ask. Generic answers here forfeit points.

### 7.2 STRIDE threat model — [IMPLEMENT (one-page)]
**Action:** Add a one-page STRIDE table to `architecture.md` §7:

| Threat | Vector | Mitigation |
|---|---|---|
| **S**poofing | Attacker mints Entra token for App identity | UAMI, federated credentials scoped to exact repo/env, no shared secrets |
| **T**ampering | Modified WAF-bypass request to origin | Combined FDID header + service-tag IP restriction; WAF Prevention mode |
| **R**epudiation | Unattributable data access | Key Vault + SQL + Front Door audit logs to Log Analytics; retention 30d |
| **I**nformation Disclosure | DB exfiltration | Private endpoint only, least-priv `db_datareader`, no public network access |
| **D**enial of Service | Volumetric attack on public endpoint | Front Door absorbs L3/L4; WAF rate-limit rule for L7; DDoS Basic (free) |
| **E**levation of Privilege | Compromised app process pivots | UAMI scoped to KV Secrets User + `db_datareader` only; no `Contributor` at runtime |

**Cost to implement:** ~15 minutes. Huge interview payoff.

### 7.3 Cost-per-environment table — [IMPLEMENT]
**Action:** Add the table from §6.1 to `architecture.md` as a new §3 subsection. FinOps awareness is a senior signal, and the table also *justifies* the demo-vs-prod split cleanly.

### 7.4 Runbook stubs are empty — [IMPLEMENT (minimum viable)]
**Action:** Populate `docs/runbooks/disaster-recovery.md` with:
- Exact `az sql db restore` command sequence for PITR.
- Exact `terraform apply` sequence to rebuild into a new region.
- A rehearsed RTO measurement from a previous test.

`docs/runbooks/incident-response.md`:
- 3-5 Kusto queries for the most likely incident types (5xx spike, SQL timeout, WAF block flood).
- Escalation path (for a solo demo, this is "me" — say so honestly).

### 7.5 `azd` (Azure Developer CLI) — [VERBAL]
**Reality:** `azd` would compress this build significantly and is the current Microsoft-recommended path.
**Action:** If asked, my answer is: *"I chose raw Terraform to demonstrate IaC depth for the interview. In a real greenfield project I'd start with `azd init` for the scaffold, then evolve toward the module structure shown here as complexity grows."*

### 7.6 SBOM / provenance — [IMPLEMENT (attestation only)]
**Action:** Add `actions/attest-build-provenance@<sha>` to the app-build workflow. Two lines. Emits a signed provenance attestation for the deployed artifact.
**Not implementing:** Full syft SBOM upload — nice-to-have but not visible in demo. **[VERBAL]** if asked.

---

## 8. Consolidated Action List (Sorted by ROI)

### Do before demo (~90 min total)
1. Switch to **User-Assigned Managed Identity** everywhere. *(15 min, eliminates a real footgun)*
2. Add **Key Vault Private Endpoint**. *(15 min)*
3. Fix **Front Door two-phase apply** — move origin to application layer. *(30 min)*
4. **Rightsize** to B2 + Serverless SQL for the demo environment. *(10 min)*
5. Add **`concurrency:`** and **SHA-pinning** to workflows. *(10 min)*
6. Set **Log Analytics `daily_quota_gb = 1`** + **App Insights adaptive sampling**. *(5 min)*
7. Add **combined FDID header + service-tag IP** restriction on App Service. *(5 min)*

### Do if time permits (~60 min)
8. Bump `azurerm` provider to **v4.x**. *(15 min)*
9. Add **`pre-commit` hooks**. *(15 min)*
10. Add **STRIDE table** + **cost-per-env table** to architecture.md. *(20 min)*
11. Add **`scripts/failover-drill.sh`** for live-demo failover moment. *(15 min)*
12. Rewrite **AI usage section** with concrete examples of caught hallucinations. *(15 min)*

### Deliberately not doing — document as trade-off
- Multi-region active-active (cost + time)
- Front Door Premium + Private Link to origin (cost)
- CMK-TDE, Always Encrypted, Data Classification (dataset isn't real PII)
- DDoS Standard, Azure Firewall, NAT Gateway egress control (cost)
- Full AVM adoption for every resource (time; hybrid approach is pragmatic)
- Azure Policy enforcement (personal subscription — no governance boundary to enforce)
- Immutable blob storage on Terraform state (ops friction for a demo)
- Approval gate on `dev` deploys (single-operator demo)
- Signed commits requirement (solo work friction)

### Verbal-only talking points (know the answers cold)
- Phase 2 multi-region topology whiteboard
- `azd` positioning vs. raw Terraform
- Reserved Instances / Savings Plans for prod cost optimization
- Full SBOM / SLSA provenance chain
- Enterprise landing zone integration (subscription vending, management groups, hub-spoke)

---

## 9. Closing Note

The point of this addendum is to demonstrate the judgement layer that sits *above* the technical design. Any competent engineer can list every Azure security control. A senior engineer decides which ones to actually build given the context, and can defend both the inclusions and the omissions on their merits.

Every omission in this build is intentional, priced, and reversible. That is the story to tell in the interview.