# Proxy

If you receive connection or network proxy errors, try running the following command:

```powershell
$Wcl=New-Object System.Net.WebClient
$Wcl.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials
```

This will utilize the Windows credentials (user name, password, and domain) of the user running the application.

If you need to set proxy value, do so in the system default web browser (e.g., Edge).
