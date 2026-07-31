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

MicrosoftTeams 7.9.0 ships `Microsoft.Identity.Client` assembly version `4.82.0.0`. ScubaGear therefore initially pins `Microsoft.Identity.Client` and `Microsoft.Identity.Client.Broker` 4.82.0. Newer versions are advisory until fresh-process load-order and Teams/WAM validation passes.

## Migration status

- [x] Lock the complete NuGet dependency closure.
- [x] Verify NuGet and Authenticode signatures.
- [x] Bundle managed and native MSAL/Broker files.
- [x] Record hashes and signers in `msal-lock.json`.
- [x] Replace Graph Authentication assembly discovery.
- [x] Enable system-browser delegated authentication by default with opt-in Broker/WAM and a Teams 7.9.0 host compatibility exception.
- [x] Add internal Graph session and REST transport.
- [x] Replace executable Graph Authentication cmdlet calls.
- [x] Remove Microsoft.Graph.Authentication from RequiredVersions.ps1.
- [x] Complete live delegated WAM tests for GCC Graph, MicrosoftTeams 7.9.0, and combined same-process use.
- [ ] Complete live certificate authentication tests.
- [x] Complete MicrosoftTeams load-order tests in fresh processes.
- [ ] Complete sovereign-cloud tenant tests where tenants are available.