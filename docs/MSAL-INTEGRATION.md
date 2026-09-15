# MSAL integration tracker

## Restoration checkpoint

- Pre-integration commit: `721e7e1e544c8ec507a0b0b9c02c73e73ff10550`
- Branch at capture: `2305-the-current-msal-auth-in-main-is-pulling-via-interactive-code-that-spawns-a-web-browser-for-authentication`
- Capture date: 2026-07-31
- The working tree was dirty. No automatic checkpoint commit or tag was created because that would combine pre-existing user work with this migration.

Files modified before this integration began:

- `PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1`
- `PowerShell/ScubaGear/Modules/Connection/Connection.psm1`
- `PowerShell/ScubaGear/Modules/Orchestrator.psm1`
- `PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfigDefaults.json`
- `PowerShell/ScubaGear/Modules/ScubaConfig/ScubaConfigSchema.json`
- `PowerShell/ScubaGear/Modules/Support/Support.psm1`
- `PowerShell/ScubaGear/Sample-Config-Files/full_config.yaml`
- `PowerShell/ScubaGear/Testing/Unit/PowerShell/Connection/Connect-GraphHelper.Tests.ps1`
- `PowerShell/ScubaGear/Testing/Unit/PowerShell/Connection/Connect-Tenant.Tests.ps1`
- `PowerShell/ScubaGear/Testing/Unit/PowerShell/Orchestrator/Connect-Tenant.Tests.ps1`
- `PowerShell/ScubaGear/Testing/Unit/PowerShell/Orchestrator/Invoke-Scuba.Tests.ps1`
- `PowerShell/ScubaGear/Testing/Unit/PowerShell/ScubaConfig/ScubaConfig.JsonDefaults.Tests.ps1`
- `PowerShell/ScubaGear/Testing/Unit/PowerShell/ScubaConfig/ScubaConfig.JsonSchema.Tests.ps1`
- `PowerShell/ScubaGear/Testing/Unit/PowerShell/Support/New-SCuBAConfig.Tests.ps1`
- `docs/configuration/parameters.md`

To inspect the committed baseline without changing the current worktree:

```powershell
git worktree add ..\SCUBA2305-pre-msal 721e7e1e544c8ec507a0b0b9c02c73e73ff10550
```

## Compatibility decision

ScubaGear pins `Microsoft.Identity.Client` 4.89.0. The signed assemblies are not bundled in the repo; they are downloaded from NuGet on first use and cached under `~/.scubagear/MSAL/<version>/net462`, mirroring how the OPA executable is handled. Interactive authentication uses the system browser only (loopback redirect); the WAM broker and its native runtime are not used. Newer MSAL versions are advisory until signature and hash integrity validation passes.

## Migration status

- [x] Lock the complete NuGet dependency closure.
- [x] Verify NuGet and Authenticode signatures.
- [x] Download and cache managed MSAL files into `~/.scubagear/MSAL` at install and runtime.
- [x] Record the pinned versions, hashes, and signer in `RequiredVersions.ps1` (`$MsalDependency`).
- [x] Replace Graph Authentication assembly discovery.
- [x] Use system-browser delegated authentication (WAM broker removed).
- [x] Add internal Graph session and REST transport.
- [x] Replace executable Graph Authentication cmdlet calls.
- [x] Remove Microsoft.Graph.Authentication from RequiredVersions.ps1.
- [ ] Complete live certificate authentication tests.
- [ ] Complete sovereign-cloud tenant tests where tenants are available.