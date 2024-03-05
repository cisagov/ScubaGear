# ScubaGear Release Process <!-- omit in toc --> #

This document outlines the ScubaGear software release process.

## Table of Contents <!-- omit in toc --> ##

- [Versioning](#versioning)
- [Release branches and tags](#release-branches-and-tags)
- [Preparing ScubaGear release candidate](#preparing-scubagear-release-candidate)
- [Publishing ScubaGear release candidate](#publishing-scubagear-release-candidate)

## Versioning ##

ScubaGear releases use the Semantic Versioning specification [v2.0](https://semver.org/spec/v2.0.0.html) to number its releases.  As such release versions take the form of MAJOR.MINOR.PATCH where:
* MAJOR version when you make incompatible API changes
* MINOR version when you add functionality in a backward compatible manner
* PATCH version when you make backward compatible bug fixes

Additional labels for pre-release and build metadata may also be used as extensions to the MAJOR.MINOR.PATCH format, as determined by the development team.

Note that ScubaGear versions and Secure Configuration Baseline (SCB) policy versions are distinct, but related.  That is, a given version of ScubaGear may operate on one or more SCB, or baseline, versions.  A given ScubaGear version assesses against the baseline version included in the release package.  ScubaGear reports include both the tool and baseline versions for reference.

## Release branches and tags ##

ScubaGear major and minor releases are built directly from the main branch.  Branch protections prevent direct push to the main branch.  All changes require a pull request and associated review prior to merge. 
When a new release is planned, the latest commit to be included is tagged with its release versions (e.g., vX.Y.Z).  Patch versions are created from a separate release branch named `release-X.Y.Z` and are branched from the latest release tag or previous patch release branch which they are patching. The patch release branch contains only the cherry picked commits that resolve an identified bug the patch release resolves along with version bumps.

## Preparing ScubaGear release candidate ##

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

## Publishing ScubaGear release candidate ##

After running the `Build and Sign Release` workflow, a draft release will be visible to development team members for review and revision.  The checklist below is designed to ensure consistency in review and publishing of the release candidate as the final release. 

- [ ] Update release notes manually
  - Adjust default change format to use PR listing as `- #{{TITLE}} ##{{NUMBER}}`
  - Regroup changes into sections: Major new features, Bug fixes, Documentation improvements, and Baseline updates
- [ ] Make the release official and visible to public
  - Uncheck **Set as a pre-release**
  - Check **Set as latest release**
  - Click **Publish Release**
- [ ] Verify that the new release is shown as latest on GitHub repository main page
- [ ] Validate that the new release has been published to PSGallery
