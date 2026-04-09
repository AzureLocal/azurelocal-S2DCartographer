## Summary

<!-- What does this PR do? One or two sentences. -->

## Changes

<!-- List the main changes. Delete or add bullet points as needed. -->

- 
- 

## Type

- [ ] `feat` — new feature
- [ ] `fix` — bug fix
- [ ] `docs` — documentation only
- [ ] `infra` — CI/CD, workflows, repo structure
- [ ] `refactor` — code restructure, no behavior change
- [ ] `chore` — maintenance, dependencies

## Testing

<!-- How was this tested? Pester? TRAILHEAD? Manual? -->

- [ ] Pester unit tests pass: `Invoke-Pester -Path .\tests\maproom\unit -Output Detailed`
- [ ] Module manifest valid: `Test-ModuleManifest .\S2DCartographer.psd1`
- [ ] Module imports clean: `Import-Module .\S2DCartographer.psd1 -Force`

## Checklist

- [ ] Conventional commit format used (`feat:`, `fix:`, `docs:`, etc.)
- [ ] CHANGELOG.md not manually edited (managed by release-please)
- [ ] No real environment data, credentials, or customer names in test fixtures
