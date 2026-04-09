---
name: TRAILHEAD Milestone Gate
about: Track end-of-milestone Operation TRAILHEAD validation before closing a release milestone.
title: "[TRAILHEAD GATE] vX.Y.Z — milestone-end validation"
labels: ["type/infra", "priority/high", "solution/s2dcartographer"]
assignees: []
---

## Summary

Use this issue to track the Operation TRAILHEAD release gate for a delivery milestone.
Do not close the release milestone until this issue is closed or explicitly waived in a comment.

## Milestone Context

- Release milestone: `vX.Y.Z — <name>`
- Target version: `vX.Y.Z`
- Test environment: `<cluster-name (node count, hardware)>`
- Planned validation date: `YYYY-MM-DD`
- Related TRAILHEAD milestone: `Operation TRAILHEAD — vX.Y.Z Field Validation` or `N/A`
- TRAILHEAD run log: `tests/trailhead/logs/run-YYYYMMDD-HHMM.md`

## Entry Criteria

- [ ] All in-scope milestone issues are closed, deferred, or explicitly waived
- [ ] CHANGELOG.md or release notes draft is updated
- [ ] `Invoke-Pester -Path .\tests` passes cleanly
- [ ] No known blocker bug remains open without an explicit release waiver

## Required TRAILHEAD Scope

Choose one. If not using the full cycle, document the rationale in a comment.

- [ ] Full P0-P7 TRAILHEAD cycle required
- [ ] Targeted TRAILHEAD cycle required for impacted phases only
- [ ] No live cycle required; waiver documented and approved

## Impacted Areas

- [ ] Credentials or authentication (`Connect-S2DCluster`)
- [ ] Connectivity or CIM sessions
- [ ] Physical disk collector
- [ ] Capacity math or unit conversion
- [ ] Output generation (reports, diagrams)
- [ ] Docs or help only
- [ ] Release or publish automation

## Execution Checklist

- [ ] Start a TRAILHEAD run log with `tests/trailhead/scripts/Start-TrailheadRun.ps1`
- [ ] Run phases P0–P7 per `tests/trailhead/field-testing.md`
- [ ] Commit run log: `git commit -m "test(trailhead): run log TRAILHEAD-YYYYMMDD-HHMM"`
- [ ] All phase issues passed or explicitly waived
- [ ] This gate issue closed to unblock milestone close
