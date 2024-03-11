# ScubaGear Functional Testing Automation <!-- omit in toc --> #

This document outlines the ScubaGear software test automation and its usage. The document also contains instructions for adding new functional tests to existing automation suite.

## Table of Contents <!-- omit in toc --> ##

- [ScubaGear Functional Testing Automation ](#scubagear-functional-testing-automation-)
  - [Table of Contents ](#table-of-contents-)
  - [Functional Testing Structure](#functional-testing-structure)
  - [Functional Testing Usage](#functional-testing-usage)
    - [Test Usage Example](#test-usage-example)
  - [Adding New Functional Tests](#adding-new-functional-tests)
    - [Adding new functional test - Example](#adding-new-functional-test---example)

## Functional Testing Structure ##

ScubaGear functional testing suite has three components:
* Functional test setup: Running ScubaGear functional tests require the end system be setup with Pester, Selenium, Chrome and PowerShell 5.1. The repository provides a few utility scripts to intall and/or update these prerequisite components. Additional details can be found at: https://github.com/cisagov/ScubaGear/blob/main/Testing/Functional/Products/SetupFunctionalProductTesting.md 
* Functional test orchestrator: 
* Product test plans



## Functional Testing Usage ##

ScubaGear major and minor releases are built directly from the main branch.  Branch protections prevent direct push to the main branch.  All changes require a pull request and associated review prior to merge. 
When a new release is planned, the latest commit to be included is tagged with its release versions (e.g., vX.Y.Z).  Patch versions are created from a separate release branch named `release-X.Y.Z` and are branched from the latest release tag or previous patch release branch which they are patching. The patch release branch contains only the cherry picked commits that resolve an identified bug the patch release resolves along with version bumps.

### Test Usage Example

## Adding New Functional Tests ##

The checklist below is used by the development team when it prepares a new release.  The goal of the list below is to ensure consistency and quality in the resulting releases.

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

### Adding new functional test - Example