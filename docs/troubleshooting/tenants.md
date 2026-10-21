# Multiple Tenants

ScubaGear shares an in-memory MSAL user token cache between the Microsoft client applications used by its products. After the first sign-in, each client attempts silent authentication; MSAL can reuse family refresh tokens where Microsoft permits it. Additional browser windows can still be required for clients outside that family, consent, or tenant authentication policies. Repeated `Invoke-SCuBA` runs in the same PowerShell process retain this cache. Closing PowerShell, calling `Disconnect-SCuBATenant`, or using `-DisconnectOnExit` clears it. Use `-Verbose` to see which clients acquired tokens silently and why others required interaction.

If a later client needs the browser, ScubaGear supplies the account already selected for the scan and omits the forced account selector. Entra can then reuse its browser session without asking you to select the same account again. A browser window or tab opening does not necessarily mean credentials must be entered again; consent, MFA, and other policy requirements are still controlled by Entra.

If testing with multiple tenants, it is a best practice is to use the [DisconnectOnExit parameter](../configuration/parameters.md#disconnectonexit). If you don't use this parameter and are seeing errors about connecting to the wrong tenant, you can resolve this by running the following command:

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
its own. Run it after a cmdlet that authenticates (such as `Invoke-SCuBA`), in the same
PowerShell terminal:

```powershell
Invoke-SCuBA -ProductNames aad -M365Environment commercial   # sign in to Tenant A
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
