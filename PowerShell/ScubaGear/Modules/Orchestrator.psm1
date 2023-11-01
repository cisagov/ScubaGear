using module 'ScubaConfig\ScubaConfig.psm1'


function Invoke-SCuBA {
    <#
    .SYNOPSIS
    Execute the SCuBAGear tool security baselines for specified M365 products.
    .Description
    This is the main function that runs the Providers, Rego, and Report creation all in one PowerShell script call.
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
    .Parameter Version
    Will output the current ScubaGear version to the terminal without running this cmdlet.
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
    .Parameter DarkMode
    Set switch to enable report dark mode by default.
    .Parameter Quiet
    Do not launch external browser for report.
    .Example
    Invoke-SCuBA
    Run an assessment against by default a commercial M365 Tenant against the
    Azure Active Directory, Exchange Online, Microsoft Defender, One Drive, SharePoint Online, and Microsoft Teams
    security baselines. The output will stored in the current directory in a folder called M365BaselineConformaance_*.
    .Example
    Invoke-SCuBA -Version
    This example returns the version of SCuBAGear.
    .Example
    Invoke-SCuBA -ConfigFilePath MyConfig.json
    This example uses the specified configuration file when executing SCuBAGear.
    .Example
    Invoke-SCuBA -ProductNames aad, defender -OPAPath . -OutPath .
    The example will run the tool against the Azure Active Directory, and Defender security
    baselines.
    .Example
    Invoke-SCuBA -ProductNames * -M365Environment dod -OPAPath . -OutPath .
    This example will run the tool against all available security baselines with the
    'dod' teams endpoint.
    .Example
    Invoke-SCuBA -ProductNames aad,exo -M365Environment gcc -OPAPath . -OutPath . -DisconnectOnExit
    Run the tool against Azure Active Directory and Exchange Online security
    baselines, disconnecting connections for those products when complete.
    .Example
    Invoke-SCuBA -ProductNames * -CertificateThumbprint <insert-thumbprint> -AppID <insert-appid> -Organization "tenant.onmicrosoft.com"
    This example will run the tool against all available security baselines while authenticating using a Service Principal with the CertificateThumprint bundle of parameters.
    .Functionality
    Public
    #>
    [CmdletBinding(DefaultParameterSetName='Report')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames = @("teams", "exo", "defender", "aad", "sharepoint"),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment = "commercial",

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $OPAPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\.."),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $LogIn = $true,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DisconnectOnExit,

        [Parameter(ParameterSetName = 'VersionOnly')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Version,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppID,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateThumbprint,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Organization,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutPath = '.',

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderName = "M365BaselineConformance",

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName = "ProviderSettingsExport",

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName = "TestResults",

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportName = "BaselineReports",

        [Parameter(Mandatory = $true, ParameterSetName = 'Configuration')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            if (-Not ($_ | Test-Path)){
                throw "SCuBA configuration file or folder does not exist. $_"
            }
            if (-Not ($_ | Test-Path -PathType Leaf)){
                throw "SCuBA configuration Path argument must be a file."
            }
            return $true
        })]
        [System.IO.FileInfo]
        $ConfigFilePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DarkMode,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $Quiet
    )
    process {
        # Retrive ScubaGear Module versions
        $ParentPath = Split-Path $PSScriptRoot -Parent -ErrorAction 'Stop'
        $ScubaManifest = Import-PowerShellDataFile (Join-Path -Path $ParentPath -ChildPath 'ScubaGear.psd1' -Resolve) -ErrorAction 'Stop'
        $ModuleVersion = $ScubaManifest.ModuleVersion
        if ($Version) {
            Write-Output("SCuBA Gear v$ModuleVersion")
            return
        }

        # Default execution ParameterSet
        if ($PSCmdlet.ParameterSetName -eq 'Report'){

            if ($ProductNames -eq '*'){
                $ProductNames = "teams", "exo", "defender", "aad", "sharepoint", "powerplatform"
            }

            $ProvidedParameters = @{
                'ProductNames' = $ProductNames | Sort-Object
                'M365Environment' = $M365Environment
                'OPAPath' = $OPAPath
                'LogIn' = $LogIn
                'DisconnectOnExit' = $DisconnectOnExit
                'OutPath' = $OutPath
                'OutFolderName' = $OutFolderName
                'OutProviderFileName' = $OutProviderFileName
                'OutRegoFileName' = $OutRegoFileName
                'OutReportName' = $OutReportName
            }

            $ScubaConfig = New-Object -Type PSObject -Property $ProvidedParameters
        }

        Remove-Resources # Unload helper modules if they are still in the PowerShell session
        Import-Resources # Imports Providers, RunRego, CreateReport, Connection

        # Loads and executes parameters from a Configuration file
        if ($PSCmdlet.ParameterSetName -eq 'Configuration'){
            if (-Not ([ScubaConfig]::GetInstance().LoadConfig($ConfigFilePath))){
                Write-Error -Message "The config file failed to load: $ConfigFilePath"
            }
            else {
                $ScubaConfig = [ScubaConfig]::GetInstance().Configuration
            }

            if ($ScubaConfig.AppID){
                $PSBoundParameters.Add("AppID", $ScubaConfig.AppID)
                $PSBoundParameters.Add("CertificateThumbprint", $ScubaConfig.CertificateThumbprint)
                $PSBoundParameters.Add("Organization", $ScubaConfig.Organization)
            }
        }

        # The equivalent of ..\..
        $ParentPath = Split-Path $(Split-Path $ParentPath -Parent) -Parent

        # Creates the output folder
        $Date = Get-Date -ErrorAction 'Stop'
        $FormattedTimeStamp = $Date.ToString("yyyy_MM_dd_HH_mm_ss")
        $OutFolderPath = $ScubaConfig.OutPath
        $FolderName = "$($ScubaConfig.OutFolderName)_$($FormattedTimeStamp)"
        New-Item -Path $OutFolderPath -Name $($FolderName) -ItemType Directory -ErrorAction 'Stop' | Out-Null
        $OutFolderPath = Join-Path -Path $OutFolderPath -ChildPath $FolderName -ErrorAction 'Stop'

        # Product Authentication
        $ConnectionParams = @{
            'LogIn' = $ScubaConfig.LogIn;
            'ProductNames' = $ScubaConfig.ProductNames;
            'M365Environment' = $ScubaConfig.M365Environment;
            'BoundParameters' = $PSBoundParameters;
        }
        $ProdAuthFailed = Invoke-Connection @ConnectionParams
        if ($ProdAuthFailed.Count -gt 0) {
            $ScubaConfig.ProductNames = Compare-ProductList -ProductNames $ScubaConfig.ProductNames `
            -ProductsFailed $ProdAuthFailed `
            -ExceptionMessage 'All indicated Products were unable to authenticate'
        }

        # Tenant Metadata for the Report
        $TenantDetails = Get-TenantDetail -ProductNames $ScubaConfig.ProductNames -M365Environment $ScubaConfig.M365Environment

        try {
            # Provider Execution
            $ProviderParams = @{
                'ProductNames' = $ScubaConfig.ProductNames;
                'M365Environment' = $ScubaConfig.M365Environment;
                'TenantDetails' = $TenantDetails;
                'ModuleVersion' = $ModuleVersion;
                'OutFolderPath' = $OutFolderPath;
                'OutProviderFileName' = $ScubaConfig.OutProviderFileName;
                'BoundParameters' = $PSBoundParameters;
            }
            $ProdProviderFailed = Invoke-ProviderList @ProviderParams
            if ($ProdProviderFailed.Count -gt 0) {
                $ScubaConfig.ProductNames = Compare-ProductList -ProductNames $ScubaConfig.ProductNames `
                 -ProductsFailed $ProdProviderFailed `
                 -ExceptionMessage 'All indicated Product Providers failed to execute'
            }

            # OPA Rego invocation
            $RegoParams = @{
                'ProductNames' = $ScubaConfig.ProductNames;
                'OPAPath' = $ScubaConfig.OPAPath;
                'ParentPath' = $ParentPath;
                'OutFolderPath' = $OutFolderPath;
                'OutProviderFileName' = $ScubaConfig.OutProviderFileName;
                'OutRegoFileName' = $ScubaConfig.OutRegoFileName;
            }
            $ProdRegoFailed = Invoke-RunRego @RegoParams
            if ($ProdRegoFailed.Count -gt 0) {
                $ScubaConfig.ProductNames = Compare-ProductList -ProductNames $ScubaConfig.ProductNames `
                -ProductsFailed  $ProdRegoFailed `
                -ExceptionMessage 'All indicated Product Rego invocations failed'
            }

            # Report Creation
            # Converted back from JSON String for PS Object use
            $TenantDetails = $TenantDetails | ConvertFrom-Json
            $ReportParams = @{
                'ProductNames' = $ScubaConfig.ProductNames
                'TenantDetails' = $TenantDetails
                'ModuleVersion' = $ModuleVersion
                'OutFolderPath' = $OutFolderPath
                'OutProviderFileName' = $ScubaConfig.OutProviderFileName
                'OutRegoFileName' = $ScubaConfig.OutRegoFileName
                'OutReportName' = $ScubaConfig.OutReportName
                'DarkMode' = $DarkMode
                'Quiet' = $Quiet
            }
            Invoke-ReportCreation @ReportParams
        }
        finally {
            if ($ScubaConfig.DisconnectOnExit) {
                if ($VerbosePreference -eq "Continue") {
                    Disconnect-SCuBATenant -ProductNames $ScubaConfig.ProductNames -ErrorAction SilentlyContinue -Verbose
                }
                else {
                    Disconnect-SCuBATenant -ProductNames $ScubaConfig.ProductNames -ErrorAction SilentlyContinue
                }
            }
            [ScubaConfig]::ResetInstance()
        }
    }
}

$ArgToProd = @{
    teams = "Teams";
    exo = "EXO";
    defender = "Defender";
    aad = "AAD";
    powerplatform = "PowerPlatform";
    sharepoint = "SharePoint";
}

$ProdToFullName = @{
    Teams = "Microsoft Teams";
    EXO = "Exchange Online";
    Defender = "Microsoft 365 Defender";
    AAD = "Azure Active Directory";
    PowerPlatform = "Microsoft Power Platform";
    SharePoint = "SharePoint Online";
}

function Get-FileEncoding{
    <#
    .Description
    This function returns encoding type for setting content.
    .Functionality
    Internal
    #>
    $PSVersion = $PSVersionTable.PSVersion

    $Encoding = 'utf8'

    if ($PSVersion -ge '6.0'){
        $Encoding = 'utf8NoBom'
    }

    return $Encoding
}

function Invoke-ProviderList {
    <#
    .Description
    This function runs the various providers modules stored in the Providers Folder
    Output will be stored as a ProviderSettingsExport.json in the OutPath Folder
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TenantDetails,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleVersion,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName,

        [Parameter(Mandatory = $true)]
        [hashtable]
        $BoundParameters
    )
    process {
        try {
            # yes the syntax has to be like this
            # fixing the spacing causes PowerShell interpreter errors
            $ProviderJSON = @"
"@
            $N = 0
            $Len = $ProductNames.Length
            $ProdProviderFailed = @()
            $ConnectTenantParams = @{
                'M365Environment' = $M365Environment
            }
            $SPOProviderParams = @{
                'M365Environment' = $M365Environment
            }

            $PnPFlag = $false
            if ($BoundParameters.AppID) {
                $ServicePrincipalParams = Get-ServicePrincipalParams -BoundParameters $BoundParameters
                $ConnectTenantParams += @{ServicePrincipalParams = $ServicePrincipalParams; }
                $PnPFlag = $true
                $SPOProviderParams += @{PnPFlag = $PnPFlag }
            }

            foreach ($Product in $ProductNames) {
                $BaselineName = $ArgToProd[$Product]
                $N += 1
                $Percent = $N * 100 / $Len
                $Status = "Running the $($BaselineName) Provider; $($N) of $($Len) Product settings extracted"
                $ProgressParams = @{
                    'Activity' = "Running the provider for each baseline";
                    'Status' = $Status;
                    'PercentComplete' = $Percent;
                    'Id' = 1;
                    'ErrorAction' = 'Stop';
                }
                Write-Progress @ProgressParams
                try {
                    $RetVal = ""
                    switch ($Product) {
                        "aad" {
                            $RetVal = Export-AADProvider | Select-Object -Last 1
                        }
                        "exo" {
                            $RetVal = Export-EXOProvider | Select-Object -Last 1
                        }
                        "defender" {
                            $RetVal = Export-DefenderProvider @ConnectTenantParams  | Select-Object -Last 1
                        }
                        "powerplatform" {
                            $RetVal = Export-PowerPlatformProvider -M365Environment $M365Environment | Select-Object -Last 1
                        }
                        "sharepoint" {
                            $RetVal = Export-SharePointProvider @SPOProviderParams | Select-Object -Last 1
                        }
                        "teams" {
                            $RetVal = Export-TeamsProvider | Select-Object -Last 1
                        }
                        default {
                            Write-Error -Message "Invalid ProductName argument"
                        }
                    }
                    $ProviderJSON += $RetVal
                }
                catch {
                    Write-Error "Error with the $($BaselineName) Provider. See the exception message for more details:  $($_)"
                    $ProdProviderFailed += $Product
                    Write-Warning "$($Product) will be omitted from the output because of the failure above `n`n"
                }
            }

            $ProviderJSON = $ProviderJSON.TrimEnd(",")
            $TimeZone = ""
            $CurrentDate = Get-Date -ErrorAction 'Stop'
            $GetTimeZone = Get-TimeZone -ErrorAction 'Stop'
            if (($CurrentDate).IsDaylightSavingTime()) {
                $TimeZone = ($GetTimeZone).DaylightName
            }
            else {
                $TimeZone = ($GetTimeZone).StandardName
            }

        $ConfigDetails = @(ConvertTo-Json -Depth 100 $([ScubaConfig]::GetInstance().Configuration))
        if(! $ConfigDetails) {
            $ConfigDetails = "{}"
        }

        $BaselineSettingsExport = @"
        {
                "baseline_version": "1",
                "module_version": "$ModuleVersion",
                "date": "$($CurrentDate) $($TimeZone)",
                "tenant_details": $($TenantDetails),
                "scuba_config": $($ConfigDetails),

                $ProviderJSON
        }
"@
            $BaselineSettingsExport = $BaselineSettingsExport.replace("\`"", "'")
            $BaselineSettingsExport = $BaselineSettingsExport.replace("\", "")
            $FinalPath = Join-Path -Path $OutFolderPath -ChildPath "$($OutProviderFileName).json" -ErrorAction 'Stop'
            $BaselineSettingsExport | Set-Content -Path $FinalPath -Encoding $(Get-FileEncoding) -ErrorAction 'Stop'
            $ProdProviderFailed
        }
        catch {
            $InvokeProviderListErrorMessage = "Fatal Error involving the Provider functions. `
            Ending ScubaGear execution. See the exception message for more details: $($_)"
            throw $InvokeProviderListErrorMessage
        }
    }
}

function Invoke-RunRego {
    <#
    .Description
    This function runs the RunRego module.
    Which runs the various rego files against the
    ProviderSettings.json using the specified OPA executable
    Output will be stored as a TestResults.json in the OutPath Folder
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [ValidateNotNullOrEmpty()]
        [string]
        $OPAPath = $PSScriptRoot,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ParentPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OutFolderPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $OutProviderFileName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName
    )
    process {
        try {
            $ProdRegoFailed = @()
            $TestResults = @()
            $N = 0
            $Len = $ProductNames.Length
            foreach ($Product in $ProductNames) {
                $BaselineName = $ArgToProd[$Product]
                $N += 1
                $Percent = $N * 100 / $Len

                $Status = "Running the $($BaselineName) Rego Verification; $($N) of $($Len) Rego verifications completed"
                $ProgressParams = @{
                    'Activity' = "Running the rego for each baseline";
                    'Status' = $Status;
                    'PercentComplete' = $Percent;
                    'Id' = 1;
                    'ErrorAction' = 'Stop';
                }
                Write-Progress @ProgressParams
                $InputFile = Join-Path -Path $OutFolderPath "$($OutProviderFileName).json" -ErrorAction 'Stop'
                $RegoFile = Join-Path -Path $ParentPath -ChildPath "Rego" -ErrorAction 'Stop'
                $RegoFile = Join-Path -Path $RegoFile -ChildPath "$($BaselineName)Config.rego" -ErrorAction 'Stop'
                $params = @{
                    'InputFile' = $InputFile;
                    'RegoFile' = $RegoFile;
                    'PackageName' = $Product;
                    'OPAPath' = $OPAPath
                }
                try {
                    $RetVal = Invoke-Rego @params
                    $TestResults += $RetVal
                }
                catch {
                    Write-Error "Error with the $($BaselineName) Rego invocation. See the exception message for more details:  $($_)"
                    $ProdRegoFailed += $Product
                    Write-Warning "$($Product) will be omitted from the output because of the failure above"
                }
            }

            $TestResultsJson = $TestResults | ConvertTo-Json -Depth 5 -ErrorAction 'Stop'
            $FileName = Join-Path -Path $OutFolderPath "$($OutRegoFileName).json" -ErrorAction 'Stop'
            $TestResultsJson | Set-Content -Path $FileName -Encoding $(Get-FileEncoding) -ErrorAction 'Stop'

            foreach ($Product in $TestResults) {
                foreach ($Test in $Product) {
                    # ConvertTo-Csv struggles with the nested nature of the ActualValue
                    # and Commandlet fields. Explicitly convert these to json strings before
                    # calling ConvertTo-Csv
                    $Test.ActualValue = $Test.ActualValue | ConvertTo-Json -Depth 3 -Compress -ErrorAction 'Stop'
                    $Test.Commandlet = $Test.Commandlet -Join ", "
                }
            }
            $TestResultsCsv = $TestResults | ConvertTo-Csv -NoTypeInformation -ErrorAction 'Stop'
            $CSVFileName = Join-Path -Path $OutFolderPath "$($OutRegoFileName).csv" -ErrorAction 'Stop'
            $TestResultsCsv | Set-Content -Path $CSVFileName -Encoding $(Get-FileEncoding) -ErrorAction 'Stop'
            $ProdRegoFailed
        }
        catch {
            $InvokeRegoErrorMessage = "Fatal Error involving the OPA output function. `
            Ending ScubaGear execution. See the exception message for more details: $($_)"
            throw $InvokeRegoErrorMessage
        }
    }
}

function Pluralize {
    <#
    .Description
    This function whether the singular or plural version of the noun
    is needed and returns the appropriate version.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SingularNoun,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PluralNoun,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Count
    )
    process {
        if ($Count -gt 1) {
            $PluralNoun
        }
        else {
            $SingularNoun
        }
    }
}

function Invoke-ReportCreation {
    <#
    .Description
    This function runs the CreateReport Module
    which creates an HTML report using the TestResults.json.
    Output will be stored as various HTML files in the OutPath Folder.
    The report Home page will be named BaselineReports.html
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [object]
        $TenantDetails,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleVersion,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Quiet,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DarkMode
    )
    process {
        try {
            $N = 0
            $Len = $ProductNames.Length
            $Fragment = @()
            $IndividualReportFolderName = "IndividualReports"
            $IndividualReportPath = Join-Path -Path $OutFolderPath -ChildPath $IndividualReportFolderName
            New-Item -Path $IndividualReportPath -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null

            $ReporterPath = Join-Path -Path $PSScriptRoot -ChildPath "CreateReport" -ErrorAction 'Stop'
            $Images = Join-Path -Path $ReporterPath -ChildPath "images" -ErrorAction 'Stop'
            Copy-Item -Path $Images -Destination $IndividualReportPath -Force -Recurse -ErrorAction 'Stop'

            $SecureBaselines =  Import-SecureBaseline -ProductNames $ProductNames

            foreach ($Product in $ProductNames) {
                $BaselineName = $ArgToProd[$Product]
                $N += 1
                $Percent = $N*100/$Len
                $Status = "Running the $($BaselineName) Report creation; $($N) of $($Len) Baselines Reports created";
                $ProgressParams = @{
                    'Activity' = "Creating the reports for each baseline";
                    'Status' = $Status;
                    'PercentComplete' = $Percent;
                    'Id' = 1;
                    'ErrorAction' = 'Stop';
                }
                Write-Progress @ProgressParams

                $FullName = $ProdToFullName[$BaselineName]

                $CreateReportParams = @{
                    'BaselineName' = $BaselineName;
                    'FullName' = $FullName;
                    'IndividualReportPath' = $IndividualReportPath;
                    'OutPath' = $OutFolderPath;
                    'OutProviderFileName' = $OutProviderFileName;
                    'OutRegoFileName' = $OutRegoFileName;
                    'DarkMode' = $DarkMode;
                    'SecureBaselines' = $SecureBaselines
                }

                $Report = New-Report @CreateReportParams
                $LinkPath = "$($IndividualReportFolderName)/$($BaselineName)Report.html"
                $LinkClassName = '"individual_reports"' # uses no escape characters
                $Link = "<a class=$($LinkClassName) href='$($LinkPath)'>$($FullName)</a>"

                $PassesSummary = "<div class='summary pass'>$($Report.Passes) tests passed</div>"
                $WarningsSummary = "<div class='summary'></div>"
                $FailuresSummary = "<div class='summary'></div>"
                $ManualSummary = "<div class='summary'></div>"
                $ErrorSummary = "<div class='summary'></div>"

                if ($Report.Warnings -gt 0) {
                    $Noun = Pluralize -SingularNoun "warning" -PluralNoun "warnings" -Count $Report.Warnings
                    $WarningsSummary = "<div class='summary warning'>$($Report.Warnings) $($Noun)</div>"
                }

                if ($Report.Failures -gt 0) {
                    $Noun = Pluralize -SingularNoun "test" -PluralNoun "tests" -Count $Report.Failures
                    $FailuresSummary = "<div class='summary failure'>$($Report.Failures) $($Noun) failed</div>"
                }

                if ($Report.Manual -gt 0) {
                    $Noun = Pluralize -SingularNoun "check" -PluralNoun "checks" -Count $Report.Manual
                    $ManualSummary = "<div class='summary manual'>$($Report.Manual) manual $($Noun) needed</div>"
                }

                if ($Report.Errors -gt 0) {
                    $Noun = Pluralize -SingularNoun "error" -PluralNoun "errors" -Count $Report.Errors
                    $ErrorSummary = "<div class='summary error'>$($Report.Errors) $($Noun)</div>"
                }

                $Fragment += [pscustomobject]@{
                "Baseline Conformance Reports" = $Link;
                "Details" = "$($PassesSummary) $($WarningsSummary) $($FailuresSummary) $($ManualSummary) $($ErrorSummary)"
                }
            }
            $TenantMetaData += [pscustomobject]@{
                "Tenant Display Name" = $TenantDetails.DisplayName;
                "Tenant Domain Name" = $TenantDetails.DomainName
                "Tenant ID" = $TenantDetails.TenantId;
                "Report Date" = $Report.Date;
            }
            $TenantMetaData = $TenantMetaData | ConvertTo-Html -Fragment -ErrorAction 'Stop'
            $TenantMetaData = $TenantMetaData -replace '^(.*?)<table>','<table class ="tenantdata" style = "text-align:center;">'
            $Fragment = $Fragment | ConvertTo-Html -Fragment -ErrorAction 'Stop'

            $ReportHtmlPath = Join-Path -Path $ReporterPath -ChildPath "ParentReport" -ErrorAction 'Stop'
            $ReportHTML = (Get-Content $(Join-Path -Path $ReportHtmlPath -ChildPath "ParentReport.html") -ErrorAction 'Stop') -Join "`n"
            $ReportHTML = $ReportHTML.Replace("{TENANT_DETAILS}", $TenantMetaData)
            $ReportHTML = $ReportHTML.Replace("{TABLES}", $Fragment)
            $ReportHTML = $ReportHTML.Replace("{MODULE_VERSION}", "v$ModuleVersion")

            $CssPath = Join-Path -Path $ReporterPath -ChildPath "styles" -ErrorAction 'Stop'
            $MainCSS = (Get-Content $(Join-Path -Path $CssPath -ChildPath "main.css") -ErrorAction 'Stop') -Join "`n"
            $ReportHTML = $ReportHTML.Replace("{MAIN_CSS}", "<style>$($MainCSS)</style>")

            $ParentCSS = (Get-Content $(Join-Path -Path $CssPath -ChildPath "ParentReportStyle.css") -ErrorAction 'Stop') -Join "`n"
            $ReportHTML = $ReportHTML.Replace("{PARENT_CSS}", "<style>$($ParentCSS)</style>")

            $ScriptsPath = Join-Path -Path $ReporterPath -ChildPath "scripts" -ErrorAction 'Stop'
            $ParentReportJS = (Get-Content $(Join-Path -Path $ScriptsPath -ChildPath "ParentReport.js") -ErrorAction 'Stop') -Join "`n"
            $UtilsJS = (Get-Content $(Join-Path -Path $ScriptsPath -ChildPath "utils.js") -ErrorAction 'Stop') -Join "`n"
            $ParentReportJS = "$($ParentReportJS)`n$($UtilsJS)"
            $ReportHTML = $ReportHTML.Replace("{MAIN_JS}", "<script>
                let darkMode = $($DarkMode.ToString().ToLower());
                $($ParentReportJS)
            </script>")

            Add-Type -AssemblyName System.Web -ErrorAction 'Stop'
            $ReportFileName = Join-Path -Path $OutFolderPath "$($OutReportName).html" -ErrorAction 'Stop'
            [System.Web.HttpUtility]::HtmlDecode($ReportHTML) | Out-File $ReportFileName -ErrorAction 'Stop'
            if (-Not $Quiet) {
                Invoke-Item $ReportFileName
            }
        }
        catch {
            $InvokeReportErrorMessage = "Fatal Error involving the Report Creation. `
            Ending ScubaGear execution. See the exception message for more details: $($_)"
            throw $InvokeReportErrorMessage
        }
    }
}

function Get-TenantDetail {
    <#
    .Description
    This function gets the details of the M365 Tenant using
    the various M365 PowerShell modules
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    # organized by best tenant details information
    if ($ProductNames.Contains("aad")) {
        Get-AADTenantDetail
    }
    elseif ($ProductNames.Contains("sharepoint")) {
        Get-AADTenantDetail
    }
    elseif ($ProductNames.Contains("teams")) {
        Get-TeamsTenantDetail -M365Environment $M365Environment
    }
    elseif ($ProductNames.Contains("powerplatform")) {
        Get-PowerPlatformTenantDetail -M365Environment $M365Environment
    }
    elseif ($ProductNames.Contains("exo")) {
        Get-EXOTenantDetail -M365Environment $M365Environment
    }
    elseif ($ProductNames.Contains("defender")) {
        Get-EXOTenantDetail -M365Environment $M365Environment
    }
    else {
        $TenantInfo = @{
            "DisplayName" = "Orchestrator Error retrieving Display name";
            "DomainName" = "Orchestrator Error retrieving Domain name";
            "TenantId" = "Orchestrator Error retrieving Tenant ID";
            "AdditionalData" = "Orchestrator Error retrieving additional data";
        }
        $TenantInfo = $TenantInfo | ConvertTo-Json -Depth 3
        $TenantInfo
    }
}

function Invoke-Connection {
    <#
    .Description
    This function uses the Connection.psm1 module
    which uses the various PowerShell modules to establish
    a connection to an M365 Tenant associated with provided
    credentials
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [boolean]
        $LogIn,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment = "commercial",

        [Parameter(Mandatory=$true)]
        [hashtable]
        $BoundParameters
    )

    $ConnectTenantParams = @{
        'ProductNames' = $ProductNames;
        'M365Environment' = $M365Environment
    }

    if ($BoundParameters.AppID) {
        $ServicePrincipalParams = Get-ServicePrincipalParams -BoundParameters $BoundParameters
        $ConnectTenantParams += @{ServicePrincipalParams = $ServicePrincipalParams;}
    }

    if ($LogIn) {
        $AnyFailedAuth = Connect-Tenant @ConnectTenantParams
        $AnyFailedAuth
    }
}

function Compare-ProductList {
    <#
    .Description
    Compares two ProductNames Lists and returns the Diff between them
    Used to compare a failed execution list with the original list
    .Functionality
    Internal
    #>
    param(

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductsFailed,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ExceptionMessage
    )

    $Difference = Compare-Object $ProductNames -DifferenceObject $ProductsFailed -PassThru
    if (-not $Difference) {
        throw "$($ExceptionMessage); aborting ScubaGear execution"
    }
    else {
        $Difference
    }
}

function Get-ServicePrincipalParams {
    <#
    .Description
    Returns a valid a hastable of parameters for authentication via
    Service Principal. Throws an error if there are none.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [hashtable]
    $BoundParameters
    )

    $ServicePrincipalParams = @{}

    $CheckThumbprintParams = ($BoundParameters.CertificateThumbprint) `
    -and ($BoundParameters.AppID) -and ($BoundParameters.Organization)

    if ($CheckThumbprintParams) {
        $CertThumbprintParams = @{
            CertificateThumbprint = $BoundParameters.CertificateThumbprint;
            AppID = $BoundParameters.AppID;
            Organization = $BoundParameters.Organization;
        }
        $ServicePrincipalParams += @{CertThumbprintParams = $CertThumbprintParams}
    }
    else {
        throw "Missing parameters required for authentication with Service Principal Auth; Run Get-Help Invoke-Scuba for details on correct arguments"
    }
    $ServicePrincipalParams
}

function Import-Resources {
    <#
    .Description
    This function imports all of the various helper Provider,
    Rego, and Reporter modules to the runtime
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param()
    try {
        $ProvidersPath = Join-Path -Path $PSScriptRoot `
        -ChildPath "Providers" `
        -Resolve `
        -ErrorAction 'Stop'
        $ProviderResources = Get-ChildItem $ProvidersPath -Recurse | Where-Object { $_.Name -like 'Export*.psm1' }
        if (!$ProviderResources)
        {
            throw "Provider files were not found, aborting this run"
        }

        foreach ($Provider in $ProviderResources.Name) {
            $ProvidersPath = Join-Path -Path $PSScriptRoot -ChildPath "Providers" -ErrorAction 'Stop'
            $ModulePath = Join-Path -Path $ProvidersPath -ChildPath $Provider -ErrorAction 'Stop'
            Import-Module $ModulePath
        }
        $ConnectionPath = Join-Path -Path $PSScriptRoot -ChildPath "Connection" -ErrorAction 'Stop'
        $RegoPath = Join-Path -Path $PSScriptRoot -ChildPath "RunRego" -ErrorAction 'Stop'
        $ReporterPath = Join-Path -Path $PSScriptRoot -ChildPath "CreateReport" -ErrorAction 'Stop'
        $ScubaConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "ScubaConfig" -ErrorAction 'Stop'
        Import-Module $ConnectionPath
        Import-Module $RegoPath
        Import-Module $ReporterPath
        Import-Module $ScubaConfigPath
    }
    catch {
        $ImportResourcesErrorMessage = "Fatal Error involving importing PowerShell modules. `
            Ending ScubaGear execution. See the exception message for more details: $($_)"
            throw $ImportResourcesErrorMessage
    }
}

function Remove-Resources {
    <#
    .Description
    This function cleans up all of the various imported modules
    Mostly meant for dev work
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    $Providers = @("ExportPowerPlatform", "ExportEXOProvider", "ExportAADProvider",
    "ExportDefenderProvider", "ExportTeamsProvider", "ExportSharePointProvider")
    foreach ($Provider in $Providers) {
        Remove-Module $Provider -ErrorAction "SilentlyContinue"
    }

    Remove-Module "ScubaConfig" -ErrorAction "SilentlyContinue"
    Remove-Module "RunRego" -ErrorAction "SilentlyContinue"
    Remove-Module "CreateReport" -ErrorAction "SilentlyContinue"
    Remove-Module "Connection" -ErrorAction "SilentlyContinue"
}

function Invoke-RunCached {
    <#
    .SYNOPSIS
    Specially execute the SCuBAGear tool security baselines for specified M365 products.
    Can be executed on static provider JSON.
    .Description
    This is the function for running the tool provider JSON that has already been extracted.
    This functions comes with the extra ExportProvider parameter to omit exporting the provider
    if set to $false.
    The rego will be run on a static provider JSON in the specified OutPath.
    <#
    .Parameter ExportProvider
    This parameter will when set to $true export the provider and act like Invoke-Scuba.
    When set to $false will instead omit authentication plus pulling the provider and will
    instead look in OutPath and run just the Rego verification and Report creation.
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
    For M365 tenants with E3/E5 licenses enter the value **"commercial"**.
    For M365 Government Commercial Cloud tenants with G3/G5 licenses enter the value **"gcc"**.
    For M365 Government Commercial Cloud High tenants enter the value **"gcchigh"**.
    For M365 Department of Defense tenants enter the value **"dod"**.
    Default is 'commercial'.
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
    .Parameter Version
    Will output the current ScubaGear version to the terminal without running this cmdlet.
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
    .Parameter DarkMode
    Set switch to enable report dark mode by default.
    .Example
    Invoke-RunCached
    Run an assessment against by default a commercial M365 Tenant against the
    Azure Active Directory, Exchange Online, Microsoft Defender, One Drive, SharePoint Online, and Microsoft Teams
    security baselines. The output will stored in the current directory in a folder called M365BaselineConformaance_*.
    .Example
    Invoke-RunCached -Version
    This example returns the version of SCuBAGear.
    .Example
    Invoke-RunCached -ProductNames aad, defender -OPAPath . -OutPath .
    The example will run the tool against the Azure Active Directory, and Defender security
    baselines.
    .Example
    Invoke-RunCached -ProductNames * -M365Environment dod -OPAPath . -OutPath .
    This example will run the tool against all available security baselines with the
    'dod' teams endpoint.
    .Example
    Invoke-SCuBA -ProductNames * -CertificateThumbprint <insert-thumbprint> -AppID <insert-appid> -Organization "tenant.onmicrosoft.com"
    This example will run the tool against all available security baselines while authenticating using a Service Principal with the CertificateThumprint bundle of parameters.
    .Functionality
    Public
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [boolean]
        $ExportProvider = $true,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames = '*',

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment = "commercial",

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateScript({Test-Path -PathType Container $_})]
        [ValidateNotNullOrEmpty()]
        [string]
        $OPAPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\.."),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $LogIn = $true,

        [Parameter(ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Version,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppID,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateThumbprint,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Organization,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutPath = '.',

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName = "ProviderSettingsExport",

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName = "TestResults",

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportName = "BaselineReports",

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [switch]
        $Quiet,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $DarkMode
        )
        process {
            $ParentPath = Split-Path $PSScriptRoot -Parent
            $ScubaManifest = Import-PowerShellDataFile (Join-Path -Path $ParentPath -ChildPath 'ScubaGear.psd1' -Resolve)
            $ModuleVersion = $ScubaManifest.ModuleVersion

            if ($Version) {
                Write-Output("SCuBA Gear v$ModuleVersion")
                return
            }

            if ($ProductNames -eq '*'){
                $ProductNames = "teams", "exo", "defender", "aad", "sharepoint", "powerplatform"
            }

            # The equivalent of ..\..
            $ParentPath = Split-Path $(Split-Path $ParentPath -Parent) -Parent

            # Create outpath if $Outpath does not exist
            if(-not (Test-Path -PathType "container" $OutPath))
            {
                New-Item -ItemType "Directory" -Path $OutPath | Out-Null
            }
            $OutFolderPath = $OutPath
            $ProductNames = $ProductNames | Sort-Object

            Remove-Resources
            Import-Resources # Imports Providers, RunRego, CreateReport, Connection

            # Authenticate
            $ConnectionParams = @{
                'LogIn' = $LogIn;
                'ProductNames' = $ProductNames;
                'M365Environment' = $M365Environment;
                'BoundParameters' = $PSBoundParameters;
            }

            # Rego Testing failsafe
            $TenantDetails = @{"DisplayName"="Rego Testing";}
            $TenantDetails = $TenantDetails | ConvertTo-Json -Depth 3
            if ($ExportProvider) {
                $ProdAuthFailed = Invoke-Connection @ConnectionParams
                if ($ProdAuthFailed.Count -gt 0) {
                    $Difference = Compare-Object $ProductNames -DifferenceObject $ProdAuthFailed -PassThru
                    if (-not $Difference) {
                        throw "All products were unable to establish a connection aborting execution"
                    }
                    else {
                        $ProductNames = $Difference
                    }
                }
                $TenantDetails = Get-TenantDetail -ProductNames $ProductNames -M365Environment $M365Environment
                $ProviderParams = @{
                    'ProductNames' = $ProductNames;
                    'M365Environment' = $M365Environment;
                    'TenantDetails' = $TenantDetails;
                    'ModuleVersion' = $ModuleVersion;
                    'OutFolderPath' = $OutFolderPath;
                    'OutProviderFileName' = $OutProviderFileName;
                    'BoundParameters' = $PSBoundParameters;
                }
                Invoke-ProviderList @ProviderParams
            }
            $FileName = Join-Path -Path $OutPath -ChildPath "$($OutProviderFileName).json"
            $SettingsExport = Get-Content $FileName | ConvertFrom-Json
            $TenantDetails = $SettingsExport.tenant_details
            $RegoParams = @{
                'ProductNames' = $ProductNames;
                'OPAPath' = $OPAPath;
                'ParentPath' = $ParentPath;
                'OutFolderPath' = $OutFolderPath;
                'OutProviderFileName' = $OutProviderFileName;
                'OutRegoFileName' = $OutRegoFileName;
            }
            $ReportParams = @{
                'ProductNames' = $ProductNames;
                'TenantDetails' = $TenantDetails;
                'ModuleVersion' = $ModuleVersion;
                'OutFolderPath' = $OutFolderPath;
                'OutProviderFileName' = $OutProviderFileName;
                'OutRegoFileName' = $OutRegoFileName;
                'OutReportName' = $OutReportName;
                'Quiet' = $Quiet;
                'DarkMode' = $DarkMode;
            }
            Invoke-RunRego @RegoParams
            Invoke-ReportCreation @ReportParams
        }
    }

Export-ModuleMember -Function @(
    'Invoke-SCuBA',
    'Invoke-RunCached'
)
