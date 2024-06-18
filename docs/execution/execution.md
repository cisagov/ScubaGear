# ScubaGear Execution

ScubaGear is executed with the `Invoke-SCuBA` command on a Windows computer, and it can be invoked interactively or non-interactively. Both modes require the appropriate [permissions](../prerequisites/permissions.md) to be configured and the [dependencies](../prerequisites/dependencies.md) to be installed. Additionally, if ScubaGear was downloaded from GitHub, the module must be imported.

## Import Module

If ScubaGear was installed by [downloading from GitHub](../installation/github.md), it must be imported into every new PowerShell terminal session before it can be executed. To import the module, open a PowerShell 5.1 terminal, navigate to the repository folder, and run this command:

```powershell
# Import the module into the session
Import-Module -Name .\PowerShell\ScubaGear 
```

## Interactive Mode

Interactive mode simply means that the user will be prompted for their credentials that are required to authenticate to the tenant. A prompt may popup for the user to select their profile **for each product being tested** but the user should only have to enter their credentials once.

### All Products

To assess all products, use the `-ProductNames` flag with a wildcard:

```powershell
# Assess all products
Invoke-SCuBA -ProductNames *
```

### Single Product

To assess one product, use the `-ProductNames` flag with a product name:

```powershell
# Only assess Teams
Invoke-SCuBA -ProductNames teams
```

The complete list of all product names can be found on the [parameters](../configuration/parameters.md#productnames) page.

### Multiple Products

To assess multiple products, add them to the `-ProductNames` flag, separated by commas:

```powershell
# Assess SharePoint and Teams
Invoke-SCuBA -ProductNames sharepoint, teams
```

### Custom Output Location

By default, ScubaGear creates a new directory in the current directory and then adds report files to that new directory. To change the location of the output:

```powershell
# Set custom output location
Invoke-SCuBA -ProductNames teams ` 
  -OutPath C:\Users\johndoe\reports
```

More information about the resulting reports can be found on the [reports](reports.md) page.

## Non-interactive Mode

Non-interactive mode means that the credentials that are required by the underlying Microsoft libraries are supplied via command-line parameters or the config file. It uses an Entra ID [service principal](../prerequisites/noninteractive.md) and a certificate thumbprint, thus enabling ScubaGear to be used in automated processes, such as pipelines and scheduled jobs. 

```powershell
# Assess with service principal
Invoke-SCuBA -ProductNames * `
  -CertificateThumbprint fedcba9876543210fedcba9876543210fedcba98 `
  -AppID abcdef0123456789abcde01234566789 `
  -Organization contoso.onmicrosoft.com 
```

## Parameters

Now that you know the basics, you can learn more about setting parameters on the [parameters](../configuration/parameters.md) page or by running `Get-Help`:

```powershell
# Get ScubaGear help
Get-Help -Name Invoke-SCuBA `
  -Full
```