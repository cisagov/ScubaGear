# Multiple Tenants

If testing with multiple tenants, it is a best practice is to use the [DisconnectOnExit parameter](../configuration/parameters.md#disconnectonexit). If you don't use this parameter and are seeing errors about connecting to the wrong tenant, you can resolve this by running the following command:

```powershell
# Delete all tokens
Disconnect-SCuBATenant
```
