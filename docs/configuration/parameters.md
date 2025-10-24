# ScubaGear Parameters

The `Invoke-SCuBA` cmdlet has several command-line parameters, which are described below.

> **Note**: Some parameters can also be specified in a [configuration file](configuration.md). If specified in both, command-line parameters have precedence over the config file.

> **Note**: Parameters use the Pascal case convention, and their names are consistent with those in the configuration file.

## AppID

**AppID** is the application ID of the service principal that is used during non-interactive mode authentication.

| Parameter   | Value  |
|-------------|--------|
| Optional    | Yes    |
| Datatype    | String |
| Default     | n/a    |
| Config File | Yes    |

Here is an example using `-AppID`:

```powershell
# Authenticate with a service principal
Invoke-SCuBA -ProductNames teams `
  -CertificateThumbprint fedcba9876543210fedcba9876543210fedcba98 `
  -AppID abcdef0123456789abcde01234566789 `
  -Organization contoso.onmicrosoft.com
```

> **Note**: AppID, CertificateThumbprint, and Organization are part of a parameter set used for authentication; if one is specified, all three must be specified.

## CertificateThumbprint

**CertificateThumbprint** is the thumbprint of the certificate that is used for non-interactive mode authentication. The underlying PowerShell modules retrieve the certificate from the user's certificate store.

| Parameter   | Value  |
|-------------|--------|
| Optional    | Yes    |
| Datatype    | String |
| Default     | n/a    |
| Config File | Yes    |

Here is an example using `-CertificateThumbprint`:

```powershell
# Authenticate with a service principal
Invoke-SCuBA -ProductNames teams `
  -CertificateThumbprint fedcba9876543210fedcba9876543210fedcba98 `
  -AppID abcdef0123456789abcde01234566789 `
  -Organization contoso.onmicrosoft.com
```

> **Note**: AppID, CertificateThumbprint, and Organization are part of a parameter set used for authentication; if one is specified, all three must be specified.

## ConfigFilePath

**ConfigFilePath** is the path of a [configuration file](configuration.md) that ScubaGear parses for input parameters.

| Parameter   | Value                                 |
|-------------|---------------------------------------|
| Optional    | Yes                                   |
| Datatype    | String                                |
| Default     | Directory where ScubaGear is executed |
| Config File | No                                    |

Here's an example using `-ConfigFilePath`:

```powershell
# Set the inputs using a configuration file
Invoke-SCuBA -ProductNames teams `
  -ConfigFilePath C:\users\johndoe\Documents\scuba\config.json
```

If `-ConfigFilePath` is specified, default values will be used for any parameters that are not added to the config file. These default values are shown in the [full config file](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/full_config.yaml).

More information about the configuration file can be found on the [configuration page](configuration.md).

> **Note**: Path can be absolute or relative.

## DarkMode

**DarkMode** enables the HTML report to have a dark mode look.

| Parameter   | Value  |
|-------------|--------|
| Optional    | Yes    |
| Datatype    | Switch |
| Default     | n/a    |
| Config File | No     |

```powershell
# View the HTML report in dark mode
Invoke-SCuBA -ProductNames teams `
  -DarkMode
```

## DisconnectOnExit

**DisconnectOnExit** deletes the authentication tokens from your local machine that were used to connect to the Microsoft APIs; this will require you to re-authenticate the next time you run ScubaGear. The name of this parameter is a misnomer.

| Parameter   | Value  |
|-------------|--------|
| Optional    | Yes    |
| Datatype    | Switch |
| Default     | n/a    |
| Config File | Yes    |

```powershell
# Delete the auth tokens
Invoke-SCuBA -ProductNames teams `
  -DisconnectOnExit
```

## KeepIndividualJSON

**KeepIndividualJSON** Keeps the individual JSON files (e.g., `TeamsReport.json`) in the `IndividualReports` folder along with `ProviderSettingsExport.json` without combining the results in to one uber JSON file named the `ScubaResults.json`. The parameter is for backwards compatibility with older versions of ScubaGear.

| Parameter   | Value  |
|-------------|--------|
| Optional    | Yes    |
| Datatype    | Switch |
| Default     | n/a    |
| Config File | No     |

```powershell
# Outputs legacy ScubaGear individual JSON output
Invoke-SCuBA -ProductNames teams `
  -KeepIndividualJSON
```


## LogIn

**LogIn** enforces or bypasses authentication. If `$true`, ScubaGear will prompt the user to provide credentials to establish a connection to the specified M365 products in the `ProductNames` variable. If `$false`, it will use the previously issued authentication token, if it has not expired.

| Parameter   | Value   |
|-------------|---------|
| Optional    | Yes     |
| Datatype    | Boolean |
| Default     | `$true` |
| Config File | Yes     |

This variable should typically be `$true`, as a connection is established in the current PowerShell terminal session with the first authentication. If another verification is run in the same PowerShell session, then this variable can be set to false to bypass a second authenticate.

```powershell
# Reuse previous authentication
Invoke-SCuBA -ProductNames teams `
  -LogIn $false
```

> **Note**: Defender will ask for authentication even if this variable is set to false.

## M365Environment

**M365Environment** is used to authenticate to the various M365 commercial/government environments.

| Parameter   | Value        |
|-------------|--------------|
| Optional    | Yes          |
| Datatype    | String       |
| Default     | `commercial` |
| Config File | Yes          |

> **Note**: This parameter is required if authenticating to Power Platform. It is also required if executing the tool against GCC High or DoD tenants.

```powershell
# Assess a government commercial account
Invoke-SCuBA -ProductNames teams `
  -M365Environment gcc
```

The list of acceptable values are:

| Tenant                          | Value      |
|---------------------------------|------------|
| Non-government tenants          | commercial |
| Government cloud tenants        | gcc        |
| Government cloud tenants (high) | gcchigh    |
| Department of Defense tenants   | dod        |


## NumberOfUUIDCharactersToTruncate

**NumberOfUUIDCharactersToTruncate** controls how many characters will be truncated from the report UUID when appended to the end of **OutJsonFileName**.

| Parameter   | Value              |
|-------------|--------------------|
| Optional    | Yes                |
| Datatype    | Integer            |
| Default     | 18                 |
| Config File | Yes                |


The list of acceptable values are:

| Description                            | Value      |
|----------------------------------------|------------|
| Do no truncation of the appended UUID  | 0          |
| Remove one octet of the appended UUID  | 13         |
| Remove two octets of the appended UUID | 18         |
| Remove the appended UUID completely    | 36         |

```powershell
# Truncate the UUID at the end of OutJsonFileName by 18 characters
Invoke-SCuBA -ProductNames exo `
  -NumberOfUUIDCharactersToTruncate 18
```

## OPAPath

**OPAPath** is the location of the folder that contains the Open Policy Agent (OPA) policy engine executable file. The executable must be named `opa_windows_amd64.exe`. For most cases, this parameter should not be used.

| Parameter   | Value                               |
|-------------|-------------------------------------|
| Optional    | Yes                                 |
| Datatype    | String                              |
| Default     | `C:\Users\johndoe\.scubagear\Tools` |
| Config File | Yes                                 |

```powershell
# Change the directory that contains the OPA exe
Invoke-SCuBA -ProductNames teams `
  -OPAPath "C:\Users\johndoe\Downloads"
```

> **Note**: Path can be absolute or relative.

## Organization

**Organization** is the organization that's used in non-interactive mode authentication.  It is of the form `contoso.onmicrosoft.com`.

| Parameter   | Value  |
|-------------|--------|
| Optional    | Yes    |
| Datatype    | String |
| Default     | n/a    |
| Config File | Yes    |

Here is an example using Organization:

```powershell
# Authenticate with a service principal
Invoke-SCuBA -ProductNames teams `
  -CertificateThumbprint fedcba9876543210fedcba9876543210fedcba98 `
  -AppID abcdef0123456789abcde01234566789 `
  -Organization contoso.onmicrosoft.com
```

> **Note**: AppID, CertificateThumbprint, and Organization are part of a parameter set used for authentication; if one is specified, all three must be specified.

## OutActionPlanFileName

**OutActionPlanFileName** renames the file for the action plan template for the test results. This should only be the base file name, as the extension `.csv` will automatically be added.

| Parameter   | Value        |
|-------------|--------------|
| Optional    | Yes          |
| Datatype    | String       |
| Default     | `ActionPlan` |
| Config File | Yes          |


```powershell
# Change the output action plan file
Invoke-SCuBA -ProductNames teams `
  -OutActionPlanFileName myplan
```

## OutCsvFileName

**OutCsvFileName** renames the file for the CSV version of the test results. This should only be the base file name, as the extension `.csv` will automatically be added.

| Parameter   | Value          |
|-------------|----------------|
| Optional    | Yes            |
| Datatype    | String         |
| Default     | `ScubaResults` |
| Config File | Yes            |


```powershell
# Change the output CSV file
Invoke-SCuBA -ProductNames teams `
  -OutCsvFileName myresults
```

## OutFolderName

**OutFolderName** is the first half of the name of the folder where the [report files](../execution/reports.md) will be created. The second half is a timedate stamp. The location of this folder is determined by the [OutPath](#outpath) parameter.

| Parameter   | Value                     |
|-------------|---------------------------|
| Optional    | Yes                       |
| Datatype    | String                    |
| Default     | `M365BaselineConformance` |
| Config File | Yes                       |

```powershell
# Change the output folder
Invoke-SCuBA -ProductNames teams `
  -OutFolderName testing
```

## OutJsonFileName

**OutJsonFileName** specifies the base file name of the uber output JSON file that is created after a ScubaGear run. This should only be the base file name; the report UUID as well as the extension, `.json`, will automatically be added.

| Parameter   | Value          |
|-------------|----------------|
| Optional    | Yes            |
| Datatype    | String         |
| Default     | `ScubaResults` |
| Config File | Yes            |

> **Note**: This parameter does not work if the `-KeepIndividualJSON` parameter is present.

```powershell
# Change the output JSON file
Invoke-SCuBA -ProductNames teams `
  -OutJsonFileName myresults
```
In the above example, the resulting JSON file name would be `myresults_21189b0e-f045-43ee-b9ba-653b32744e45.json` (substituting in the actual report UUID.)

## OutPath

**OutPath** is the folder path where the [report files](../execution/reports.md) will be created. The folder will be created if it does not exist.

| Parameter   | Value                                      |
|-------------|--------------------------------------------|
| Optional    | Yes                                        |
| Datatype    | String                                     |
| Default     | `M365BaselineConformance` with a timestamp |
| Config File | Yes                                        |

```powershell
# Change the output path
Invoke-SCuBA -ProductNames teams `
  -OutPath myresults
```

> **Note**: Path can be absolute or relative.

## OutProviderFileName

**OutProviderFileName** is the name the JSON file that contains all of the information that ScubaGear extracted from the products.

| Parameter   | Value                    |
|-------------|--------------------------|
| Optional    | Yes                      |
| Datatype    | String                   |
| Default     | `ProviderSettingsExport` |
| Config File | Yes                      |

```powershell
# Change the provider settings file
Invoke-SCuBA -ProductNames teams `
  -OutProviderFileName mysettings
```

> **Note**: ScubaGear will automatically add the `.json` to this filename.

## OutRegoFileName

**OutRegoFileName** is the name of the JSON test results file that is created in the output folder, containing the raw Rego output.

| Parameter   | Value         |
|-------------|---------------|
| Optional    | Yes           |
| Datatype    | String        |
| Default     | `TestResults` |
| Config File | Yes           |

```powershell
# Change the rego file
Invoke-SCuBA -ProductNames teams `
  -OutRegoFileName mytestresults
```

> **Note**: ScubaGear will automatically add the the `.json` to this filename.

## OutReportName

**OutReportName** is the name of the HTML file that is a summary of the detailed reports created in the output folder.

| Parameter   | Value             |
|-------------|-------------------|
| Optional    | Yes               |
| Datatype    | String            |
| Default     | `BaselineReports` |
| Config File | Yes               |

```powershell
# Change the HTML report file
Invoke-SCuBA -ProductNames teams `
  -OutReportName myreport
```

> **Note**: ScubaGear will automatically add the `.html` to this filename.

## PreferredDnsResolvers

**PreferredDnsResolvers** is a list of IP addresses of DNS resolvers that should
be used to retrieve any DNS records required by specific SCuBA policies. Currently,
the only applicable SCuBA polices are the following:
- MS.EXO.2.2v2
- MS.EXO.3.1v1
- MS.EXO.4.1v1
- MS.EXO.4.2v1
- MS.EXO.4.3v1
- MS.EXO.4.4v1

Optional; if not provided, the system default resolver will be used.

| Parameter   | Value           |
|-------------|-----------------|
| Optional    | Yes             |
| Datatype    | List of strings |
| Default     | []              |
| Config File | Yes             |

Here is an example using `-PreferredDnsResolvers`:

```powershell
Invoke-SCuBA -ProductNames exo `
  -PreferredDnsResolvers 8.8.8.8,8.8.4.4
```

## ProductNames

**ProductNames** provides one or more M365 shortened product names that ScubaGear will assess.

| Parameter   | Value                                             |
|-------------|---------------------------------------------------|
| Optional    | Yes                                               |
| Datatype    | List of Strings                                   |
| Default     | ["aad", "defender", "exo", "sharepoint", "teams"] |
| Config File | Yes                                               |

The list of acceptable values are:

| Product                                      | Product Name |
|----------------------------------------------|--------------|
| Entra ID                                     | aad          |
| Defender for Office 365                      | defender     |
| Exchange Online                              | exo          |
| Power Platform                               | powerplatform|
| SharePoint Online and OneDrive for Business  | sharepoint   |
| Microsoft Teams                              | teams        |

```powershell
# Assess two products
Invoke-SCuBA -ProductNames teams, exo
```

>**Note**: Product names are separated by commas.

## Quiet

**Quiet** prevents the HTML report from being opened in an external web browser.

| Parameter   | Value  |
|-------------|--------|
| Optional    | Yes    |
| Datatype    | Switch |
| Default     | n/a    |
| Config File | No     |

```powershell
# Do not open the browser
Invoke-SCuBA -ProductNames teams `
  -Quiet
```

## SilenceBODWarnings

**SilenceBODWarnings** silences warnings relating to BOD submissions requirements, e.g., the requirement to document `OrgName` in the config file.

| Parameter   | Value  |
|-------------|--------|
| Optional    | Yes    |
| Datatype    | Switch |
| Default     | n/a    |
| Config File | No     |

```powershell
# Silence warning related to BOD submission requirements
Invoke-SCuBA -SilenceBODWarnings
```

## SkipDoH

**SkipDoH** allows the user to disable the DoH fallback which would normally be
done if the traditional DNS requests fail when retrieving any DNS records
required by specific SCuBA policies. See [PreferredDnsResolvers](#preferreddnsresolvers)
for the list of applicable policies.

| Parameter   | Value   |
|-------------|---------|
| Optional    | Yes     |
| Datatype    | Boolean |
| Default     | $false  |
| Config File | Yes     |

Here is an example using `-SkipDoH`:

```powershell
Invoke-SCuBA -ProductNames exo `
  -SkipDoH $true
```

## Version

**Version** writes the current ScubaGear version to the console.  ScubaGear will not be run.  When the `Version` parameter is used, no other parameters should be included.

| Parameter   | Value  |
|-------------|--------|
| Optional    | Yes    |
| Datatype    | Switch |
| Default     | n/a    |
| Config File | No     |

```powershell
# Check the version
Invoke-SCuBA -Version
```


## Muting the Version Check Warnings

To prevent ScubaGear from trying to determine if a newer release is available and emitting a warning at import time, set the environment variable `SCUBAGEAR_SKIP_VERSION_CHECK` to any non-whitespace value.

```powershell
# Prevent ScubaGear from emitting the version update notification.
$env:SCUBAGEAR_SKIP_VERSION_CHECK = $true
```
