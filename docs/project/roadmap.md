# Roadmap

S2DCartographer follows a milestone-based release cadence. Each milestone targets a single focused capability area. The current stable release is **v1.0.0**.

---

## v1.1.0 — What-If Planning

*Target: next minor release*

| Issue | Feature |
| --- | --- |
| [#27](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/27) | **What-if capacity calculator** — model the impact of adding nodes or drives before committing hardware. Given a proposed change (e.g., +4 drives per node), compute the new waterfall stages, reserve status, and usable capacity delta. |
| [#30](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/30) | **Documentation improvements** — individual collector reference pages, architecture diagram, connection guide, health checks reference, roadmap, troubleshooting, admonitions and Mermaid throughout. |

---

## v1.2.0 — OEM Disk Enrichment

*Target: after v1.1.0*

| Issue | Feature |
| --- | --- |
| [#25](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/25) | **OEM-specific disk enrichment** — extend `Get-S2DPhysicalDiskInventory` with vendor-specific data from Dell iDRAC, HPE iLO, Lenovo XClarity, and DataON interfaces. Surfaces drive bay location, predicted failure, and platform-level health alongside the standard S2D disk data. |

---

## v1.3.0 — Historical Trending

*Target: after v1.2.0*

| Issue | Feature |
| --- | --- |
| [#26](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/26) | **Snapshot storage and comparison** — persist cluster data snapshots to a local or network store, then compare any two snapshots to report capacity consumed, volumes added or removed, wear delta, and health regressions over time. |

---

## v2.0.0 — Cloud Integration

*Target: future major release — no committed timeline*

| Issue | Feature |
| --- | --- |
| [#28](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/28) | **Teams / Slack webhook alerts** — post health check failures and capacity threshold breaches as actionable cards to a Teams channel or Slack workspace. |
| [#29](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/29) | **Azure Monitor integration** — emit S2D capacity and health metrics as custom Azure Monitor metrics. Enables alerting, dashboards, and workbook integration alongside the Azure portal's native HCI views. |

---

## Completed

| Version | Summary |
| --- | --- |
| **v1.0.0** | Full pipeline: all 6 collectors, HTML/Word/PDF/Excel reports, 6 SVG diagram types, `Invoke-S2DCartographer` orchestrator, 119 Pester tests, MkDocs documentation site. |
| **v0.1.0-preview2** | Bug fix: non-domain-joined connectivity (`Connect-S2DCluster`). |
| **v0.1.0-preview1** | Foundation: `S2DCapacity` class, `ConvertTo-S2DCapacity`, `Connect-S2DCluster`, `Get-S2DPhysicalDiskInventory`. |

---

## Requesting Features

Open an issue at [AzureLocal/azurelocal-s2d-cartographer](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/new) using the feature request template. Include the cluster configuration context (node count, drive types, Azure Local version) — most useful features come from real deployment scenarios.
