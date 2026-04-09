# Automation

Documents every GitHub Actions workflow in this repository.

---

## Workflow Summary

| File | Name | Trigger | Purpose |
|------|------|---------|---------|
| `add-to-project.yml` | Add to Project | Issues/PRs opened or labeled | Adds S2DCartographer issues/PRs to the shared AzureLocal project and sets custom fields |
| `deploy-docs.yml` | Deploy Documentation | Push to `main` touching `docs/**` or `mkdocs.yml` | Builds MkDocs site and deploys to GitHub Pages |
| `validate.yml` | Validate | Pull requests, non-`main` pushes, manual run | Validates MkDocs and the PowerShell module manifest before merge; runs Pester unit tests |
| `release-please.yml` | Release Please | Push to `main` | Automates CHANGELOG and releases |
| `publish-psgallery.yml` | Publish to PSGallery | GitHub release published, or manual dispatch | Validates and publishes the module to PowerShell Gallery |

---

## add-to-project.yml

**Trigger:** `issues` (opened, reopened, labeled) and `pull_request` (opened, labeled)
**Permissions required:** `ADD_TO_PROJECT_PAT` — classic PAT with `project` scope

**What it does:**

1. Calls the shared `reusable-add-to-project.yml` workflow in `AzureLocal/.github`
2. Sets the `ID` field to `S2DCART-{number}`
3. Maps `solution/s2dcartographer` to the Solution field on the project board

> **Note:** The `solution-option-id` in the workflow must be updated once the `s2dcartographer` solution option is added to the org project board.

---

## deploy-docs.yml

**Trigger:** Push to `main` touching `docs/**` or `mkdocs.yml`
**Permissions:** `contents: read`, `pages: write`, `id-token: write`
**Concurrency group:** `pages` (cancel-in-progress: false)

Two-job pipeline:

**build:**
1. Sets up Python 3.12
2. Installs `mkdocs-material`
3. `mkdocs build --strict` — fails on warnings
4. Uploads `site/` as a pages artifact

**deploy:**
1. Uses `actions/deploy-pages@v4` to publish to GitHub Pages

---

## validate.yml

**Trigger:** Pull requests, pushes to any branch except `main`, or manual run
**Purpose:** Catch documentation or module issues before merge.

Two parallel jobs:

**validate-docs-and-module** (ubuntu-latest):
1. Sets up Python 3.12 and MkDocs Material
2. Runs `mkdocs build --strict`
3. Validates `S2DCartographer.psd1` with `Test-ModuleManifest`
4. Imports the root module to confirm the shell still loads cleanly

**pester-unit** (windows-latest):
1. Installs Pester 5.6+
2. Imports the module
3. Runs all tests in `tests/maproom/unit/`
4. Publishes NUnit XML test results

---

## release-please.yml

**Trigger:** Push to `main`
**Permissions:** `contents: write`, `pull-requests: write`

Calls the shared `reusable-release-please.yml` workflow. Maintains an automated release PR that updates `CHANGELOG.md` and bumps the module version. Merging the release PR creates the GitHub release and tag.

Both `release-please-config.json` and `.release-please-manifest.json` must exist at the repo root.

---

## publish-psgallery.yml

**Trigger:** GitHub release published; or manual dispatch with `dry_run` input
**Permissions:** `contents: read`
**Secret required:** `PSGALLERY_API_KEY`

Steps:
1. Validates `S2DCartographer.psd1` with `Test-ModuleManifest`
2. Runs Pester unit tests from `tests/maproom/unit/` — aborts on failure
3. If not a dry run: copies module to staging directory and calls `Publish-Module`
4. If dry run: prints summary and exits without publishing

To test publishing without actually pushing to PSGallery, trigger manually with `dry_run: true`.
