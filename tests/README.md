# Tests

S2DCartographer testing is split into two named solutions:

- `tests/trailhead/` for live field validation
- `tests/maproom/` for offline synthetic and post-collection testing

## Purpose

The test layout is intentionally split into one live home and one offline home:

- `tests/` is the repo-root entry point
- `tests/trailhead/` handles every test that requires a real S2D cluster
- `tests/maproom/` handles every test that can run from fixture data

## Named Solutions

### `TRAILHEAD`

`TRAILHEAD` is the live field-validation solution.

It holds:

- live test-cycle documentation
- run scripts
- committed run logs
- milestone-close execution evidence

### `MAPROOM`

`MAPROOM` is the offline synthetic and fixture-backed testing solution.

It holds:

- fixtures (mock cluster data)
- Pester unit tests
- integration tests
- synthetic cluster data scripts
- output validation workflows that do not require a live cluster

## Layout

```text
tests/
  trailhead/
    scripts/
    logs/
    docs/
    field-testing.md
    README.md
  maproom/
    Fixtures/
    unit/
    integration/
    scripts/
    docs/
    README.md
```

## Folder Summary

- `tests/trailhead/scripts/` holds live TRAILHEAD workflow helpers.
- `tests/trailhead/logs/` holds committed TRAILHEAD run logs.
- `tests/trailhead/docs/` holds detailed TRAILHEAD documentation.
- `tests/trailhead/field-testing.md` defines the live field-testing methodology.
- `tests/maproom/Fixtures/` holds committed fixture data used by offline tests.
- `tests/maproom/unit/` holds Pester unit tests.
- `tests/maproom/integration/` holds fixture-backed integration tests.
- `tests/maproom/scripts/` holds synthetic cluster data and offline validation scripts.
- `tests/maproom/docs/` holds detailed MAPROOM documentation.

## Running Tests

Run the full suite from the repo root:

```powershell
Invoke-Pester -Path .\tests -Output Detailed
```

Run only unit tests:

```powershell
Invoke-Pester -Path .\tests\maproom\unit -Output Detailed
```
