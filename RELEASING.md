This document outlines the process of preparing release candidates and creating a new release.

### Preparing Release Candidates

1. Commit updated release version to [manifest](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/ScubaGear.psd1).
2. Redact sample report using redaction tool and commit.
3. Build initial release candidate by manually triggering "Build and Sign Release" action with expected release name (vX.X.X) and tag (X.X.X)  
4. Conduct manual release testing
    1. File a bug for manual testing of each baseline type
    2. Run manual tests of each component per manual testing plans, testing across representive set of environments.
5. If defects are identified, fix defects deemed release blocking.  Restart from step 3 (or step 2 if report substance changed).

### Releasing

1. Update release notes to match expected format, listing major features, bug fixes, documentation improvements, and baseline updates (if any).  Release notes should link to all closed enhanced and bug issues.
2. Uncheck **Set as a pre-release**.
3. Check **Set as latest release**.
4. Click **Publish Release**.
