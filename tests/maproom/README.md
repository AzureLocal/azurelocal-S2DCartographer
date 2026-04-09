# MAPROOM

This directory contains the offline synthetic and fixture-backed testing solution for S2DCartographer.

## Contents

- `Fixtures/` — fixture data used by offline and simulation tests (mock cluster JSON)
- `unit/` — Pester unit tests
- `integration/` — fixture-backed integration tests
- `scripts/` — synthetic cluster data generator and manual validation scripts
- `docs/` — detailed MAPROOM documentation

## Scope

Everything under `tests/maproom/` is part of offline testing.
It exists so capacity math, disk inventory processing, and other post-collection features can be tested without requiring a live S2D cluster or WinRM session.

## Running Tests

```powershell
# All maproom tests
Invoke-Pester -Path .\tests\maproom -Output Detailed

# Unit tests only
Invoke-Pester -Path .\tests\maproom\unit -Output Detailed
```
