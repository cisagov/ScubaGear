1. If using VSCode, use PowerShell extension for breakpoints/visibility into how data is processed

- create .vscode directory, then create launch.json file with the following:

```
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug ScubaGear",
            "type": "PowerShell",
            "request": "launch",
            "script": "Import-Module -Name .\\PowerShell\\ScubaGear; Invoke-SCuBA -ConfigFilePath .\\PowerShell\\ScubaGear\\Sample-Config-Files\\cisaent_noninteractive.yaml -ProductNames aad",
            "args": []
        }
    ]
}
```
2. Run PowerShell unit tests locally.

```
# v3.4.0 of Pester should be installed by default on Windows machines
Get-Module -Name Pester -ListAvailable | Select-Object Name, Version

# To download latest version, run:
Install-Module -Name Pester -Force -SkipPublisherCheck
```

3. Run functional tests locally.
- Full documentation on how to run functional tests locally, https://github.com/cisagov/ScubaGear/blob/main/Testing/Readme.md.

Script to run functional tests noninteractively:

```
$TestContainers = @() 
$TestContainers += New-PesterContainer -Path "../ScubaGear/Testing/Functional/Products/" `
-Data @{ 
    Thumbprint = "<add-thumbprint>";
    TenantDomain = "<add-tenantdomain>"; 
    TenantDisplayName = "<add-displayname>"; 
    AppId = "<appid>";
    ProductName = "teams"; 
    M365Environment = "gcc";
    # Variant = "E#";
} 
$PesterConfig = @{
    Run = @{Container = $TestContainers}
    Filter = @{Tag = @("MS.AAD.3*")}
    Output = @{Verbosity = 'Detailed'}
}

$Config = New-PesterConfiguration -Hashtable $PesterConfig 
Invoke-Pester -Configuration $Config
```

5. Use Invoke-SCuBACached if you want to quickly test different JSON outputs.
6. Test against multiple test tenants:
- e5forscuba (commercial)
- cisaent (GCC with G5 licensing)
- g3forthee (GCC with G3 licensing)
- scubagcchigh (GCC High with G5 licensing)

7. Use custom configuration files for each test tenant to speed up testing.
