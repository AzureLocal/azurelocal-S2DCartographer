# Roadmap

S2DCartographer follows a milestone-based release cadence. Each milestone targets a focused capability area. The current stable release is **v1.3.0**.

Live status of everything below is tracked on [GitHub Milestones](https://github.com/AzureLocal/azurelocal-s2d-cartographer/milestones).

---

## Future Roadmap

*Tracked but not scheduled to a specific release.*

| Issue | Feature |
| --- | --- |
| [#25](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/25) | **OEM-specific disk enrichment** — extend `Get-S2DPhysicalDiskInventory` with vendor-specific data from Dell iDRAC, HPE iLO, Lenovo XClarity, and DataON interfaces. Surfaces drive bay location, predicted failure, and platform-level health alongside the standard S2D disk data. Pending a validation environment across all four vendors. |

---

## v2.0.0 — Reserved for breaking changes

*No issues currently assigned. Held for any future change that requires a major version bump (removed cmdlets, renamed parameters, changed output object shape).*

---

## Explicitly out of scope

The following ideas were considered and rejected because they do not fit the tool's shape. S2DCartographer is a **point-in-time audit and reporting tool** — run once, produce a report, exit. Features that require a continuously-running service belong elsewhere.

| Issue | Decision |
| --- | --- |
| [#26](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/26) | Historical trending with time-series charts and retention — closed as out-of-scope. Continuous trending belongs in Azure Monitor. A narrow "diff two JSON snapshots" use case may be filed as a separate issue later. |
| [#28](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/28) | Teams / Slack webhook alerts — closed as out-of-scope. A webhook alert only fires when the module is run; for real proactive alerting, customers should use Azure Monitor Alert Rules against the cluster's native telemetry. |
| [#29](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/29) | Azure Monitor integration — closed as out-of-scope. Azure Monitor already instruments Azure Local clusters natively; there is no reason for this module to become a data ingestion pipeline. |

---

## Completed

| Version | Highlights |
| --- | --- |
| **v1.3.0** | What-if capacity modeling (`Invoke-S2DCapacityWhatIf`), thin provisioning risk detection (Check 6 tiered thresholds + new Check 11 ThinReserveRisk), `ThinGrowthHeadroom` / `MaxPotentialFootprint` volume properties, Thin Provision Risk KPI in HTML report, `Invoke-S2DWaterfallCalculation` pure function. Closes [#27](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/27), [#44](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/44). |
| **v1.2.1** | Capacity model correctness — pool-member-only Stage 1, purely theoretical Stages 7/8, resiliency factor from pool settings. Closes [#43](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/43). |
| **v1.2.0** | JSON snapshot export (SchemaVersion 1.0), opt-in CSV per-collector tables, pool-member disk filter (`IsPoolMember`) across reports and health checks, Surveyor cross-link in docs, `-IncludeNonPoolDisks` switch. Closes [#35](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/35), [#40](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/40), [#41](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/41), [#42](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/42). |
| **v1.1.1** | Fix parameter-set splat in `Invoke-S2DCartographer` that broke `-KeyVaultName` and explicit `-Authentication`; added `-Username` parameter for Key Vault secrets without a ContentType tag. Closes [#39](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/39). |
| **v1.1.0** | Default `-Format` changed to `All`; `ImportExcel` bundled as a `RequiredModules` dependency; per-run output folder structure `<OutputDir>\<ClusterName>\<yyyyMMdd-HHmm>\`; session log file; thicker pool allocation breakdown bar; full authentication / remoting / node fan-out docs with flowchart diagram. Closes [#34](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/34), [#36](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/36), [#37](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/37), [#38](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/38). |
| **v1.0.8** | Fix `Get-S2DHealthStatus` crash on live clusters — replaced `Generic.List[S2DHealthCheck]` with a plain array to work around PowerShell class type resolution on dot-sourced classes. |
| **v1.0.7** | Storage Pool Health bar (WAC-style), Pool Allocation Breakdown bar, Capacity Model stage descriptions, Critical Reserve Status KPI. |
| **v1.0.2 – v1.0.6** | Workgroup / non-domain-joined connectivity fixes — WinRM authentication inheritance, TrustedHosts short-name resolution, per-node CIM fan-out FQDN resolution, pre-flight credential validation. |
| **v1.0.0** | Full pipeline: all 6 collectors, HTML/Word/PDF/Excel reports, 6 SVG diagram types, `Invoke-S2DCartographer` orchestrator, 119 Pester tests, MkDocs documentation site. |
| **v0.1.0-preview2** | Bug fix: non-domain-joined connectivity (`Connect-S2DCluster`). |
| **v0.1.0-preview1** | Foundation: `S2DCapacity` class, `ConvertTo-S2DCapacity`, `Connect-S2DCluster`, `Get-S2DPhysicalDiskInventory`. |

---

## Requesting Features

Open an issue at [AzureLocal/azurelocal-s2d-cartographer](https://github.com/AzureLocal/azurelocal-s2d-cartographer/issues/new) using the feature request template. Include the cluster configuration context (node count, drive types, Azure Local version) — most useful features come from real deployment scenarios.
