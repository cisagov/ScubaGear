# Microsoft Graph

ScubaGear uses Graph to assess Entra ID and Sharepoint, and one of the following errors can be thrown:

## Infinite Entra ID Signin Loop

Sometimes the Entra ID sign-in prompt will get stuck in a loop, when using interactive mode, repeatedly asking for login credentials. This is likely an issue with the connection to Microsoft Graph. To fix the loop, run this command:

```powershell
# Delete the Graph tokens
Disconnect-MgGraph
```

Then run ScubaGear again.

## Key not valid for use in specified state.

This error can be seen when running ScubaGear. It is due to a [bug](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/554) in the Microsoft Authentication Library. The workaround is to delete broken configuration information by running this command:

```powershell
# Delete folder with Graph tokens and configuration info.
rm -r C:\Users\<username>\.graph
```

After deleting the `.graph` folder in your home directory, re-run ScubaGear, and the error should disappear.

## Could not load file or assembly 'Microsoft.Graph.Authentication'

This error can be seen when running ScubaGear. It indicates that the authentication module is at a version level that conflicts with the MS Graph modules used by ScubaGear. Follow the instructions on the [dependencies page](../prerequisites/dependencies.md) and execute the `Initialize-SCuBA` cmdlet, which will ensure that the module versions get synchronized with dependencies. Then run the tool again.
