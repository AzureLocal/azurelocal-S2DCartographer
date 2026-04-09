# Repository Setup

Documents how this repository is configured. Use this as the reference when setting up a new repo or auditing existing settings.

---

## Branch Protection

**Protected branch:** `main`

| Setting | Value |
|---------|-------|
| Require pull request before merging | Yes |
| Required approvals | 1 |
| Dismiss stale reviews on new commits | Yes |
| Require status checks to pass | Yes |
| Require branches to be up to date | Yes |
| Restrict force pushes | Yes |
| Allow admins to bypass | Yes |

---

## Labels

Labels are defined in `azurelocal.github.io/.github/labels.yml` — that is the source of truth for all repos. Labels are applied here when they change in the source repo or manually via `workflow_dispatch` on `sync-labels.yml` in `azurelocal.github.io`.

S2DCartographer uses the shared `type/*`, `priority/*`, and `status/*` labels plus `solution/s2dcartographer` for module-specific work.

---

## Secrets

| Secret | Used By | Description |
|--------|---------|-------------|
| `ADD_TO_PROJECT_PAT` | `add-to-project.yml` | Classic PAT with `project` scope. Required for org project integration. |
| `PSGALLERY_API_KEY` | `publish-psgallery.yml` | NuGet API key for publishing to PowerShell Gallery. |
| `GITHUB_TOKEN` | All other workflows | Built-in GitHub token. |

---

## Issue Intake

Issue intake is standardized with repo-local templates under `.github/ISSUE_TEMPLATE/`:

- `bug_report.yml`
- `feature_request.yml`
- `trailhead_milestone_gate.md`
- `config.yml`

---

## Project Board

S2DCartographer participates in the shared org-level project board: [AzureLocal Projects #3](https://github.com/orgs/AzureLocal/projects/3).

| Setting | Value |
|---------|-------|
| Project | `AzureLocal/projects/3` |
| Project ID | `PVT_kwDOCxeiOM4BR2KZ` |
| Integration | `.github/workflows/add-to-project.yml` |
| ID Prefix | `S2DCART` |

### Custom Fields

| Field | Type | Field ID | Use |
|-------|------|----------|-----|
| ID | Text | `PVTF_lADOCxeiOM4BR2KZzhADImQ` | Auto-set to `S2DCART-{issueNumber}` |
| Solution | Single Select | `PVTSSF_lADOCxeiOM4BR2KZzg_jXuY` | Set from `solution/s2dcartographer` |
| Priority | Single Select | `PVTSSF_lADOCxeiOM4BR2KZzg_jXvs` | Set from `priority/*` |
| Category | Single Select | `PVTSSF_lADOCxeiOM4BR2KZzg_jXxA` | Set from `type/*` |

> **Note:** The `solution/s2dcartographer` label and its project board option ID need to be added to the org project. See `azurelocal.github.io/repo-management/setup.md` for the process.

---

## Milestones

S2DCartographer uses milestones aligned to the development phases defined in `plan.md`:

| Milestone | Scope |
|-----------|-------|
| `Phase 1 — Foundation` | Module scaffold, Connect/Disconnect, ConvertTo-S2DCapacity, Get-S2DPhysicalDiskInventory |
| `Phase 2 — Core Collectors` | Storage pool, volumes, cache tier, health status, capacity waterfall |
| `Phase 3 — Reporting Engine` | HTML, Excel, Word, PDF report generation |
| `Phase 4 — Diagrams` | SVG diagram types |
| `Phase 5 — Orchestrator` | Invoke-S2DCartographer, PSGallery publish |
| `Post-v1` | OEM enrichment, trending, what-if calculator |

---

## Issue Metadata Requirements

Every issue should have at minimum:

- one `type/*` label
- one `priority/*` label
- `solution/s2dcartographer`
- a milestone if it represents planned delivery work
