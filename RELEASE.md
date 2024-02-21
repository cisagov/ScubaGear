# ScubaGear Release Process <!-- omit in toc --> #

This document outlines the ScubaGear software release process.

## Table of Contents <!-- omit in toc --> ##

- [Preparing ScubaGear release candidate](#preparing-scubagear-release-candidate)
- [Publishing ScubaGear release candidate](#publishing-scubagear-release-candidate)

## Preparing ScubaGear release candidate ##

- [ ] Ensure all [blocked](https://github.com/cisagov/ScubaGear/labels/) issues and pull requests are resolved.
- [ ] (future) Update CHANGELOG
- [ ] Validate that all tests pass on CI for the release branch before proceeding
- [ ] Update ModuleVersion in the [manifest](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/ScubaGear.psd1) to match release version
- [ ] Update the module version in the [README.md](https://github.com/cisagov/ScubaGear/blob/main/README.md) badge image link and release download artifact name.
- [ ] Check and update copyright dates in [manifest](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/ScubaGear.psd1) as needed
- [ ] If baselines changed, update `baseline_version` in [Orchestrator module](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Modules/Orchestrator.psm1)
- [ ] Update and redact the sample report using the redaction tool and manual review
- [ ] Check README for any necessary changes and documentation updates as needed
- [ ] Build initial release candidate by manually triggering `Build and Sign Release` action with expected release name (vX.X.X) and release version (X.X.X) based on semantic versioning
- [ ] Conduct automated release testing of each baseline
- [ ] Fix critical defects deemed release blocking
- [ ] Document non-critical issues for future development cycle
- [ ] If fixes applied, restart release process

## Publishing ScubaGear release candidate ##

After running the `Build and Sign Release` workflow, a draft release will be visible to development team members for review and revision.

- [ ] Update release notes to match expected format, including major new features, bug fixes, documentation improvements, and baseline updates Release notes should link to associated closed pull requests.
- [ ] To make the release official and visible to public
  - Uncheck **Set as a pre-release**
  - Check **Set as latest release**
  - Click **Publish Release**
- Verify that the new release is shown as latest on GitHub repository main page
- Validate that the new release has been published to PSGallery
