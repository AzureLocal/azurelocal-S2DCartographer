# Contributing to S2DCartographer

Thank you for your interest in contributing to S2DCartographer. This guide covers the basics of how to contribute code, tests, documentation, and bug reports.

---

## Getting Started

1. Fork the repository and clone your fork locally.
2. Install [PowerShell 7.x](https://github.com/PowerShell/PowerShell).
3. Install test dependencies: `Install-Module Pester -MinimumVersion 5.6 -Force`
4. Install optional report dependencies: `Install-Module ImportExcel -Force`
5. Import the module: `Import-Module .\S2DCartographer.psd1 -Force`

---

## Repository Layout

```
S2DCartographer/
├── Public/         Exported cmdlets — one file per function
├── Private/        Internal helper functions — not exported
├── Classes/        PowerShell classes (S2DCapacity, etc.)
├── Tests/
│   ├── Unit/       Pester unit tests — run without a live cluster
│   ├── Integration/Pester integration tests — require mock or live cluster
│   └── Mocks/      Simulated cluster JSON data for offline tests
├── docs/           MkDocs documentation source
├── Templates/      HTML, Word, and diagram template files
└── .github/        GitHub Actions CI/CD workflows and issue templates
```

---

## Pull Request Process

1. Create a feature branch: `git checkout -b feat/my-feature`
2. Write code. Write tests that cover the new behaviour.
3. Run the full Pester suite and confirm zero failures: `Invoke-Pester ./Tests -Output Detailed`
4. Update `CHANGELOG.md` under `[Unreleased]` following the Keep a Changelog format.
5. Open a pull request with a clear description of the change and its motivation.

---

## Code Standards

- **PowerShell 7.x only** — no compatibility shims for Windows PowerShell 5.1.
- **Approved verbs** — use only PowerShell approved verbs (`Get-Verb` to check).
- **No live cluster required for unit tests** — unit tests in `Tests/Unit/` must run offline using mock data or mocked functions.
- **TiB/TB dual display** — any function that returns a capacity value must return or accept an `S2DCapacity` object (or use `ConvertTo-S2DCapacity`).
- **No credentials in tests** — mock all authentication; never commit real credentials.
- **Pester 5 syntax** — use `Describe`/`Context`/`It`/`Should` from Pester 5. Do not use legacy `Should Be` syntax.

---

## Reporting Issues

Use the GitHub issue templates for bug reports and feature requests. When reporting a bug, always include:
- PowerShell version (`$PSVersionTable`)
- Module version
- The complete error message and stack trace
- Whether the issue occurs with mock data or only against a live cluster

---

## Working Independently

This repository can be used as a standalone project without the parent multi-root workspace.

### Open Only This Repository

1. Open VS Code
2. File > Open Workspace from File > select `azurelocal-S2DCartographer.code-workspace`
3. All recommended extensions will be prompted for installation

### Prerequisites

- Python 3.x and pip (for MkDocs documentation)
- [MkDocs Material](https://squidfunk.github.io/mkdocs-material/): `pip install mkdocs-material`

### Run Documentation Locally

```bash
mkdocs serve
```

Browse to <http://127.0.0.1:8000>

### Build Documentation

```bash
mkdocs build
```

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
