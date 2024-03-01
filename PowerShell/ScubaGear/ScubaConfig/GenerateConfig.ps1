Import-Module powershell-yaml


function Generate-Config {
    <#
    .SYNOPSIS
    Generate a config file for the ScubaGear tool
    .Description
    Using provided user input generate a config file to run ScubaGear tailored to the end user
    .Parameter ProductNames
    A list of one or more M365 shortened product names that the tool will assess when it is executed. Acceptable product name values are listed below.
    To assess Azure Active Directory you would enter the value aad.
    To assess Exchange Online you would enter exo and so forth.
    - Azure Active Directory: aad
    - Defender for Office 365: defender
    - Exchange Online: exo
    - MS Power Platform: powerplatform
    - SharePoint Online: sharepoint
    - MS Teams: teams.
    Use '*' to run all baselines.
    .Parameter M365Environment
    This parameter is used to authenticate to the different commercial/government environments.
    Valid values include "commercial", "gcc", "gcchigh", or "dod".
    - For M365 tenants with E3/E5 licenses enter the value **"commercial"**.
    - For M365 Government Commercial Cloud tenants with G3/G5 licenses enter the value **"gcc"**.
    - For M365 Government Commercial Cloud High tenants enter the value **"gcchigh"**.
    - For M365 Department of Defense tenants enter the value **"dod"**.
    Default value is 'commercial'.
    .Parameter OPAPath
    The folder location of the OPA Rego executable file.
    The OPA Rego executable embedded with this project is located in the project's root folder.
    If you want to execute the tool using a version of OPA Rego located in another folder,
    then customize the variable value with the full path to the alternative OPA Rego exe file.
    .Parameter LogIn
    A `$true` or `$false` variable that if set to `$true`
    will prompt you to provide credentials if you want to establish a connection
    to the specified M365 products in the **$ProductNames** variable.
    For most use cases, leave this variable to be `$true`.
    A connection is established in the current PowerShell terminal session with the first authentication.
    If you want to run another verification in the same PowerShell session simply set
    this variable to be `$false` to bypass the reauthenticating in the same session. Default is $true.
    Note: defender will ask for authentication even if this variable is set to `$false`
    ;;;.Parameter Version
    ;;;Will output the current ScubaGear version to the terminal without running this cmdlet.
    .Parameter AppID
    The application ID of the service principal that's used during certificate based
    authentication. A valid value is the GUID of the application ID (service principal).
    .Parameter CertificateThumbprint
    The thumbprint value specifies the certificate that's used for certificate base authentication.
    The underlying PowerShell modules retrieve the certificate from the user's certificate store.
    As such, a copy of the certificate must be located there.
    .Parameter Organization
    Specify the organization that's used in certificate based authentication.
    Use the tenant's tenantname.onmicrosoft.com domain for the parameter value.
    .Parameter OutPath
    The folder path where both the output JSON and the HTML report will be created.
    The folder will be created if it does not exist. Defaults to current directory.
    .Parameter OutFolderName
    The name of the folder in OutPath where both the output JSON and the HTML report will be created.
    Defaults to "M365BaselineConformance". The client's local timestamp will be appended.
    .Parameter OutProviderFileName
    The name of the Provider output JSON created in the folder created in OutPath.
    Defaults to "ProviderSettingsExport".
    .Parameter OutRegoFileName
    The name of the Rego output JSON and CSV created in the folder created in OutPath.
    Defaults to "TestResults".
    .Parameter OutReportName
    The name of the main html file page created in the folder created in OutPath.
    Defaults to "BaselineReports".
    .Parameter DisconnectOnExit
    Set switch to disconnect all active connections on exit from ScubaGear (default: $false)
    .Parameter ConfigFilePath
    Local file path to a JSON or YAML formatted configuration file.
    Configuration file parameters can be used in place of command-line
    parameters. Additional parameters and variables not available on the
    command line can also be included in the file that will be provided to the
    tool for use in specific tests.
    ;;;.Parameter DarkMode
    ;;;Set switch to enable report dark mode by default.
    ;;;.Parameter Quiet
    ;;;Do not launch external browser for report.
    .Functionality
    Public
    #>
    [CmdletBinding(DefaultParameterSetName='Report')]
    param (

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description = "YAML configuration file with default description", #(Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames = @("aad", "defender", "exo", "sharepoint", "teams"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment = "commercial",

        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $OPAPath = ".", #(Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $LogIn = $true,
        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $DisconnectOnExit = $false,

        
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutPath = '.',

        [Parameter(Mandatory = $false)] 
        [ValidateNotNullOrEmpty()]
        [string]
        $AppID,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateThumbprint,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Organization,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderName = "M365BaselineConformance",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName = "ProviderSettingsExport",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName = "TestResults",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportName = "BaselineReports"

        #[Parameter(Mandatory = $false)]
        #[ValidateNotNullOrEmpty()]
        #[switch]
        #$DarkMode,

        #[Parameter(Mandatory = $false)]
        #[switch]
        #$Quiet
    )

    write-host "Hello World!"
    
    #$config = @{}
    $config = New-Object ([System.Collections.specialized.OrderedDictionary])

    ($MyInvocation.MyCommand.Parameters ).Keys | %{
        $val = (Get-Variable -Name $_ -EA SilentlyContinue).Value
        if( $val.length -gt 0 ) {
            #$config[$_] = $val
            $config.add($_, $val)
        }
    }
    $capExclusionNamespace = @(
        "MS.AAD.1.1v1",
        "MS.AAD.2.1v1",
        "MS.AAD.2.3v1",
        "MS.AAD.3.1v1",
        "MS.AAD.3.2v1",
        "MS.AAD.3.3v1",
        "MS.AAD.3.6v1",
        "MS.AAD.3.7v1",
        "MS.AAD.3.8v1"
        )
    $roleExclusionNamespace = "MS.AAD.7.4v1"


    
    $aadTemplate = New-Object ([System.Collections.specialized.OrderedDictionary])
    $aadCapExclusions = New-Object ([System.Collections.specialized.OrderedDictionary])
    $aadRoleExclusions = New-Object ([System.Collections.specialized.OrderedDictionary])
    
    $aadCapExclusions = @{ CapExclusions = @{} }
    $aadCapExclusions["CapExclusions"].add("Users", @(""))
    $aadCapExclusions["CapExclusions"].add("Groups", @(""))
    $aadRoleExclusions = @{ RoleExclusions = @{} }
    $aadRoleExclusions["RoleExclusions"].add("Users", @(""))
    $aadRoleExclusions["RoleExclusions"].add("Groups", @(""))

    foreach ($cap in $capExclusionNamespace){
        $aadTemplate.add($cap, $aadCapExclusions)
    }

    $aadTemplate.add($roleExclusionNamespace, $aadRoleExclusions)
    
    $products = (Get-Variable -Name ProductNames -EA SilentlyContinue).Value
    foreach ($product in $products){
        switch ($product){
            "aad" {
                $config.add("Aad", $aadTemplate)
                }
            "defender" {;break}
        }
    }
    convertto-yaml $config
}

Generate-Config
