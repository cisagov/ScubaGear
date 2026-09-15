# Microsoft Graph

ScubaGear uses Graph to assess Entra ID and Sharepoint, and one of the following errors can be thrown:

## Infinite Entra ID Signin Loop

Sometimes the Entra ID sign-in prompt will get stuck in a loop when using interactive mode. Close the current PowerShell session to clear ScubaGear's in-memory account and token cache, then run ScubaGear again.

## Key not valid for use in specified state.

This error can be seen when running ScubaGear. It is due to a [bug](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/554) in the Microsoft Authentication Library. The workaround is to delete broken configuration information by running this command:

```powershell
# Delete folder with Graph tokens and configuration info.
rm -r C:\Users\johndoe\.graph
```

After deleting the `.graph` folder in your home directory, re-run ScubaGear, and the error should disappear.

## Could not load a Microsoft.Identity.Client assembly

This indicates that another module loaded an incompatible MSAL assembly before ScubaGear, or that a bundled file failed validation. Start a new Windows PowerShell session and import ScubaGear before other Microsoft 365 modules. If the error continues, reinstall ScubaGear so the signed dependency files and lock manifest are restored.
