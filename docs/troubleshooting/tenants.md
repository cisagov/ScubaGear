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

`Get-ScubaGearContext` doesn't sign in on its own. While a session is connected, it reads that session and
asks Microsoft Graph for the details. ScubaGear disconnects when `Invoke-SCuBA` finishes by default, which
discards its tokens, so afterwards there is nothing live to query. In that case `Get-ScubaGearContext` shows the
credentials the most recent run used, from a short record saved just before the disconnect. The record holds the
account or app, the authentication type, the tenant, and the environment, never tokens. It is labeled
`Disconnected (last run)`. It lives only in the current PowerShell process, so it is gone when you close the
window, and it is not written to the report or the debug log.

The run's console output deliberately does not print the account or tenant, because screenshots of the console
are often pasted into public bug reports. Run `Get-ScubaGearContext` whenever you want to confirm which
credentials a run used, as described above.

```powershell
Invoke-SCuBA -ProductNames aad -M365Environment commercial   # sign in to Tenant A, scan, then disconnect
Get-ScubaGearContext                                          # shows the credentials the last run used (disconnected)
Invoke-SCuBA -ProductNames aad -M365Environment commercial   # sign in to Tenant B
Get-ScubaGearContext                                          # shows Tenant B's credentials
```

To query the live session instead (tenant name, domain, and scopes), keep it with `-DisconnectOnExit:$false`:

```powershell
Invoke-SCuBA -ProductNames aad -M365Environment commercial -DisconnectOnExit:$false   # keep the session
Get-ScubaGearContext                                          # live details; Status is Connected
Disconnect-SCuBATenant                                        # clear the session before switching
```

Example output of a live session:

```powershell
Status         : Connected
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

Example output after the run has disconnected:

```powershell
Status             : Disconnected (last run)
Account            : admin@contoso.onmicrosoft.com
ClientId           : 14d82eec-204b-4c2f-b7e8-296a70dab67e
AuthType           : Delegated
Tenant             : ee6afab0-3d70-4380-aa11-243aa9dedef2
Environment        : commercial
DisconnectedAtZulu : 2026-10-29T12:00:00.000Z
```

`TenantDomain` is the tenant's initial verified domain. `AppDisplayName` comes from the
client application's service principal. If that lookup fails for the standard interactive
Graph client, ScubaGear uses its documented name, Microsoft Graph Command Line Tools. Tenant
name, domain, and scopes are only available from a live session.

If no session is currently active and no run has finished in this PowerShell process,
`Get-ScubaGearContext` prints a warning and returns nothing rather than throwing an error. Because
both the session and the last-run record live in memory for the current PowerShell process,
`Get-ScubaGearContext` only reflects runs made in that same terminal/process
— it will not show a connection made in a different PowerShell window.
