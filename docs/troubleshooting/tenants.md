# Multiple Tenants

ScubaGear shares an in-memory MSAL user token cache between the Microsoft client applications used by its products. After the first sign-in, each client attempts silent authentication; MSAL can reuse family refresh tokens where Microsoft permits it. Additional browser windows can still be required for clients outside that family, consent, or tenant authentication policies. By default, ScubaGear clears this cache when each run finishes (the [DisconnectOnExit parameter](../configuration/parameters.md#disconnectonexit) defaults to `$true`), so every run signs in on its own and cannot reuse a previous run's tenant or credentials. If you run `Invoke-SCuBA -DisconnectOnExit:$false`, repeated runs in the same PowerShell process retain this cache; closing PowerShell or calling `Disconnect-SCuBATenant` clears it. Use `-Verbose` to see which clients acquired tokens silently and why others required interaction.

If a later client needs the browser, ScubaGear supplies the account already selected for the scan and omits the forced account selector. Entra can then reuse its browser session without asking you to select the same account again. A browser window or tab opening does not necessarily mean credentials must be entered again; consent, MFA, and other policy requirements are still controlled by Entra.

If you keep the session between runs with `-DisconnectOnExit:$false` and test with multiple tenants or accounts, run `Disconnect-SCuBATenant` before switching tenants, switching credentials (for example from one user to another), or switching between interactive and service principal authentication. A kept session is reused as it is, so skipping this step can connect to the wrong tenant. You can resolve this by running the following command:

```powershell
# Delete all tokens
Disconnect-SCuBATenant
```

## Confirming which tenant/account you're connected as

ScubaGear authenticates using MSAL directly rather than the `Microsoft.Graph.Authentication`
module, so `Get-MgContext` is not available. Use `Get-ScubaGearContext` instead to see which
account (or app/service principal) and tenant the current PowerShell session is authenticated
to. This is especially useful when working across multiple tenants or accounts, to confirm a
prior session was cleared before connecting to a different tenant.

`Get-ScubaGearContext` reads the session ScubaGear already established; it doesn't sign in on
its own. Because ScubaGear clears its session when `Invoke-SCuBA` finishes by default, keep the session
with `-DisconnectOnExit:$false` (or run it during a run that is still in progress) before calling it,
in the same PowerShell terminal:

```powershell
Invoke-SCuBA -ProductNames aad -M365Environment commercial -DisconnectOnExit:$false   # sign in to Tenant A and keep the session
Get-ScubaGearContext                                          # confirm which tenant/account you're on
Disconnect-SCuBATenant                                        # clear the session before switching
Invoke-SCuBA -ProductNames aad -M365Environment commercial   # sign in to Tenant B
Get-ScubaGearContext                                          # confirm it's now Tenant B
```

Example output:

```powershell
Account        : admin@contoso.onmicrosoft.com
AppDisplayName : Microsoft Graph Command Line Tools
ClientId       : 14d82eec-204b-4c2f-b7e8-296a70dab67e
AuthType       : Delegated
TenantId       : ee6afab0-3d70-4380-aa11-243aa9dedef2
TenantName     : Contoso
TenantDomain   : contoso.onmicrosoft.com
Scopes         : {Organization.Read.All}
Environment    : commercial
GraphEndpoint  : https://graph.microsoft.com
```

`TenantDomain` is the tenant's initial verified domain. `AppDisplayName` comes from the
client application's service principal. If that lookup fails for the standard interactive
Graph client, ScubaGear uses its documented name, Microsoft Graph Command Line Tools.

If no session is currently active, `Get-ScubaGearContext` prints a warning and returns nothing
rather than throwing an error. Because the session lives in memory for the current PowerShell
process, `Get-ScubaGearContext` only reflects the connection made in that same terminal/process
— it will not show a connection made in a different PowerShell window.
