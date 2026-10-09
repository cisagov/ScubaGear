# Multiple Tenants

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
AppDisplayName :
ClientId       : 14d82eec-204b-4c2f-b7e8-296a70dab67e
AuthType       : Delegated
TenantId       : ee6afab0-3d70-4380-aa11-243aa9dedef2
TenantName     : Contoso
Scopes         : {Organization.Read.All}
Environment    : commercial
GraphEndpoint  : https://graph.microsoft.com
```

If no session is currently active, `Get-ScubaGearContext` prints a warning and returns nothing
rather than throwing an error. Because the session lives in memory for the current PowerShell
process, `Get-ScubaGearContext` only reflects the connection made in that same terminal/process
— it will not show a connection made in a different PowerShell window.
