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
    .Parameter KeepIndividualJSON
    Keeps ScubaGear legacy output where files are not merged into an all in one JSON.
    This parameter is for backwards compatibility for those working with the older ScubaGear output files.
    .Parameter OutJsonFileName
    If KeepIndividualJSON is not set, the name of the consolidated json created in the folder
    created in OutPath. Defaults to "ScubaResults". The report UUID will be appended to this.
    .Parameter OutCsvFileName
    The CSV created in the folder created in OutPath that contains the CSV version of the test results.
    Defaults to "ScubaResults".
    .Parameter OutActionPlanFileName
    The CSV created in the folder created in OutPath that contains a CSV template prepopulated with the failed
    SHALL controls with fields for documenting failure causes and remediation plans. Defaults to "ActionPlan".
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
    .Parameter SilenceBODWarnings
    Do not warn for requirements specific to BOD compliance (e.g., documenting OrgName in the config file).
    .Parameter NumberOfUUIDCharactersToTruncate
    Controls how many characters will be truncated from the report UUID when appended to the end of OutJsonFileName.
    Valid values are 0, 13, 18, 36
    .Example
    Invoke-SCuBA
    Run an assessment against by default a commercial M365 Tenant against the
    Azure Active Directory, Exchange Online, Microsoft Defender, One Drive, SharePoint Online, and Microsoft Teams
    security baselines. The output will stored in the current directory in a folder called M365BaselineConformance_*.
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
        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames = [ScubaConfig]::ScubaDefault('DefaultProductNames'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment = [ScubaConfig]::ScubaDefault('DefaultM365Environment'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $OPAPath = [ScubaConfig]::ScubaDefault('DefaultOPAPath'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $LogIn = [ScubaConfig]::ScubaDefault('DefaultLogIn'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DisconnectOnExit,

        [Parameter(ParameterSetName = 'VersionOnly')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Version,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppID,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateThumbprint,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Organization,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutPath = [ScubaConfig]::ScubaDefault('DefaultOutPath'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderName = [ScubaConfig]::ScubaDefault('DefaultOutFolderName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName = [ScubaConfig]::ScubaDefault('DefaultOutProviderFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName = [ScubaConfig]::ScubaDefault('DefaultOutRegoFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportName = [ScubaConfig]::ScubaDefault('DefaultOutReportName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $KeepIndividualJSON,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutJsonFileName = [ScubaConfig]::ScubaDefault('DefaultOutJsonFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutCsvFileName = [ScubaConfig]::ScubaDefault('DefaultOutCsvFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutActionPlanFileName = [ScubaConfig]::ScubaDefault('DefaultOutActionPlanFileName'),

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

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $DarkMode,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $Quiet,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $SilenceBODWarnings,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(0, 13, 18, 36)]
        [int]
        $NumberOfUUIDCharactersToTruncate = [ScubaConfig]::ScubaDefault('DefaultNumberOfUUIDCharactersToTruncate')
    )
    process {
        # Retrieve ScubaGear Module versions
        $ParentPath = Split-Path $PSScriptRoot -Parent -ErrorAction 'Stop'
        $ScubaManifest = Import-PowerShellDataFile (Join-Path -Path $ParentPath -ChildPath 'ScubaGear.psd1' -Resolve) -ErrorAction 'Stop'
        $ModuleVersion = $ScubaManifest.ModuleVersion
        if ($Version) {
            Write-Output("SCuBA Gear v$ModuleVersion")
            return
        }

        # Transform ProductNames into list of all products if it contains wildcard
        if ($ProductNames.Contains('*')){
            $ProductNames = $PSBoundParameters['ProductNames'] = "aad", "defender", "exo", "powerplatform", "sharepoint", "teams"
            Write-Debug "Setting ProductName to all products because of wildcard"
        }

        # Default execution ParameterSet
        if ($PSCmdlet.ParameterSetName -eq 'Report'){

            $ProvidedParameters = @{
                'ProductNames' = $ProductNames | Sort-Object -Unique
                'M365Environment' = $M365Environment
                'OPAPath' = $OPAPath
                'LogIn' = $LogIn
                'DisconnectOnExit' = $DisconnectOnExit
                'OutPath' = $OutPath
                'OutFolderName' = $OutFolderName
                'OutProviderFileName' = $OutProviderFileName
                'OutRegoFileName' = $OutRegoFileName
                'OutReportName' = $OutReportName
                'KeepIndividualJSON' = $KeepIndividualJSON
                'OutJsonFileName' = $OutJsonFileName
                'OutCsvFileName' = $OutCsvFileName
                'OutActionPlanFileName' = $OutActionPlanFileName
                'NumberOfUUIDCharactersToTruncate' = $NumberOfUUIDCharactersToTruncate
            }

            $ScubaConfig = New-Object -Type PSObject -Property $ProvidedParameters
        }

        Remove-Resources # Unload helper modules if they are still in the PowerShell session
        Import-Resources # Imports Providers, RunRego, CreateReport, Connection

        # Loads and executes parameters from a Configuration file
        if ($PSCmdlet.ParameterSetName -eq 'Configuration'){
            [ScubaConfig]::ResetInstance()
            if (-Not ([ScubaConfig]::GetInstance().LoadConfig($ConfigFilePath))){
                Write-Error -Message "The config file failed to load: $ConfigFilePath"
            }
            else {
                $ScubaConfig = [ScubaConfig]::GetInstance().Configuration
            }

            # Authentications parameters use below
            $SPparams = 'AppID', 'CertificateThumbprint', 'Organization'

            # Bound parameters indicate a parameter has been passed in.
            # However authentication parameters are special and are not handled within
            # the config module (since you can't make a default).  If an authentication
            # parameter is set in the config file but not supplied on the command line
            # set the Bound parameters value which make it appear as if it was supplied on the
            # command line

            foreach ( $value in $SPparams )
            {
                if  ( $ScubaConfig[$value] -and  (-not  $PSBoundParameters[$value] )) {
                    $PSBoundParameters.Add($value, $ScubaConfig[$value])
                }
            }

            # Now the bound parameters contain the following
            # 1) Non Authentication Parameters explicitly passed in
            # 2) Authentication parameters ( passed in or from the config file as per code above )
            #
            # So to provide for a command line override of config values just set the corresponding
            # config value from the bound parameters to override.  This is redundant copy for
            # the authentication parameters ( but keeps the logic simpler)
            # We do not allow ConfigFilePath to be copied as it will be propagated to the
            # config module by reference and causes issues
            #
            foreach ( $value in $PSBoundParameters.keys ) {
                if ( $value -ne "ConfigFilePath" )
                {
                    $ScubaConfig[$value] = $PSBoundParameters[$value]
                }
            }
        }

        if (-not $SilenceBODWarnings -and $null -eq $ScubaConfig.OrgName) {
            $Warning = "Config file option OrgName not provided. This option is required for BOD "
            $Warning += "submissions. See https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/configuration.md#scuba-compliance-use for more details. "
            $Warning += "This warning can be silenced with the -SilenceBODWarnings parameter"
            Write-Warning $Warning
        }

        if ($ScubaConfig.OutCsvFileName -eq $ScubaConfig.OutActionPlanFileName) {
            $ErrorMessage = "OutCsvFileName and OutActionPlanFileName cannot be equal to each other. "
            $ErrorMessage += "Both are set to $($ScubaConfig.OutCsvFileName). Stopping execution."
            throw $ErrorMessage
        }

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

        # Generate a GUID to uniquely identify the output JSON
        $Guid = New-Guid -ErrorAction 'Stop'

        try {
            # Provider Execution
            $ProviderParams = @{
                'ProductNames'        = $ScubaConfig.ProductNames;
                'M365Environment'     = $ScubaConfig.M365Environment;
                'TenantDetails'       = $TenantDetails;
                'ModuleVersion'       = $ModuleVersion;
                'OutFolderPath'       = $OutFolderPath;
                'OutProviderFileName' = $ScubaConfig.OutProviderFileName;
                'Guid'                = $Guid;
                'BoundParameters'     = $PSBoundParameters;
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

            $FullNameParams = @{
                'OutJsonFileName'                  = $ScubaConfig.OutJsonFileName;
                'Guid'                             = $Guid;
                'NumberOfUUIDCharactersToTruncate' = $ScubaConfig.NumberOfUUIDCharactersToTruncate;
            }
            $FullScubaResultsName = Get-FullOutJsonName @FullNameParams

            if (-not $KeepIndividualJSON) {
                # Craft the complete json version of the output
                $JsonParams = @{
                    'ProductNames'         = $ScubaConfig.ProductNames;
                    'OutFolderPath'        = $OutFolderPath;
                    'OutProviderFileName'  = $ScubaConfig.OutProviderFileName;
                    'TenantDetails'        = $TenantDetails;
                    'ModuleVersion'        = $ModuleVersion;
                    'FullScubaResultsName' = $FullScubaResultsName;
                    'Guid'                 = $Guid;
                    'SilenceBODWarnings' = $SilenceBODWarnings;
                }
                Merge-JsonOutput @JsonParams
            }

            # Craft the csv version of just the results
            $CsvParams = @{
                'ProductNames'          = $ScubaConfig.ProductNames;
                'OutFolderPath'         = $OutFolderPath;
                'FullScubaResultsName'  = $FullScubaResultsName;
                'OutCsvFileName'        = $ScubaConfig.OutCsvFileName;
                'OutActionPlanFileName' = $ScubaConfig.OutActionPlanFileName;
            }
            ConvertTo-ResultsCsv @CsvParams
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

$IndividualReportFolderName = "IndividualReports"

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
        [ValidateNotNullOrEmpty()]
        [string]
        $Guid,

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
                            $RetVal = Export-AADProvider -M365Environment $M365Environment | Select-Object -Last 1
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
                    Write-Warning "Error with the $($BaselineName) Provider: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
                    $ProdProviderFailed += $Product
                    Write-Warning "$($Product) will be omitted from the output because of the failure above `n`n"
                }
            }

            $ProviderJSON = $ProviderJSON.TrimEnd(",")
            $TimeZone = ""
            $CurrentDate = Get-Date -ErrorAction 'Stop'
            $TimestampZulu = $CurrentDate.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
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
                "timestamp_zulu": "$($TimestampZulu)",
                "report_uuid": "$($Guid)",
                "tenant_details": $($TenantDetails),
                "scuba_config": $($ConfigDetails),
                $ProviderJSON
        }
"@

            # PowerShell 5 includes the "byte-order mark" (BOM) when it writes UTF-8 files. However, OPA (as of 0.68) appears to not
            # be able to handle the "\/" character sequence if the input json is UTF-8 encoded with the BOM, resulting
            # in the "unable to parse input: yaml" error message. As such, we need to save the provider output without
            # the BOM
            $ActualSavedLocation = Set-Utf8NoBom -Content $BaselineSettingsExport `
                -Location $OutFolderPath -FileName "$OutProviderFileName.json"
            Write-Debug $ActualSavedLocation

            $ProdProviderFailed
        }
        catch {
            $InvokeProviderListErrorMessage = "Fatal Error involving the Provider functions. `
            Ending ScubaGear execution. Error: $($_.Exception.Message)`
            `n$($_.ScriptStackTrace)"
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
        $OPAPath = [ScubaConfig]::ScubaDefault('DefaultOPAPath'),

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
                    Write-Warning "Error with the $($BaselineName) Rego invocation: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
                    $ProdRegoFailed += $Product
                    Write-Warning "$($Product) will be omitted from the output because of the failure above"
                }
            }

            $TestResultsJson = $TestResults | ConvertTo-Json -Depth 5 -ErrorAction 'Stop'
            $FileName = Join-Path -Path $OutFolderPath "$($OutRegoFileName).json" -ErrorAction 'Stop'
            $TestResultsJson | Set-Content -Path $FileName -Encoding $(Get-FileEncoding) -ErrorAction 'Stop'

            $ProdRegoFailed
        }
        catch {
            $InvokeRegoErrorMessage = "Fatal Error involving the OPA output function. `
            Ending ScubaGear execution. Error: $($_.Exception.Message)`
            `n$($_.ScriptStackTrace)"
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

function Format-PlainText {
    <#
    .Description
    This function sanitizes a given string so that it will render properly in Excel (e.g., remove HTML tags).
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $RawString
    )
    process {
        $CleanString = $RawString
        # Multi-line strings (e.g., the requirment string for MS.EXO.16.1v1) need to be merged into a single
        # line, otherwise the single control will be split into multiple rows in the CSV output
        $CleanString = $CleanString.Replace("`n", " ")
        # The "View all CA policies" link needs to be removed from the spreadsheet as what it links to
        # does not exist in the spreadsheet
        $CleanString = $CleanString.Replace("<a href='#caps'>View all CA policies</a>.", "")
        # Remove HTML tags that won't render properly in the spreadsheet and whose removal won't affect the
        # overall meaning of the string
        $CleanString = $CleanString.Replace("<br/>", " ")
        $CleanString = $CleanString.Replace("<b>", "")
        $CleanString = $CleanString.Replace("</b>", "")

        # Strip out HTML comments
        $CleanString = $CleanString -replace '(.*)(<!--)(.*)(-->)(.*)', '$1$5'
        # The following regex looks for a string with an anchor tag. If it finds an anchor tag, it reformats
        # the string so that the anchor is removed. For example:
        # 'See <a href="https://example.com" target="_blank">this example</a> for more details.'
        # becomes
        # 'See this example, https://example.com for more details.'
        # In-depth interpretation:
        # Group 1: '(.*)' Matches any number of characters before the opening anchor tag
        # Group 2: '<a href="' Matches the opening anchor tag, up to and including the opening quote of the href
        # Group 3: '([\w#./=&?%\-+:;$@,]+)' Matches the href string
        # Group 4: '(".*>)' Matches the last half of the opening anchor tag
        # Group 5: '(.*)' Matches the anchor inner html, i.e., the link's display text
        # Group 6: '(</a>)' Matches the closing anchor tag
        # Group 7: '(.*)' Matches any number of characters after the closing anchor tag
        $CleanString = $CleanString -replace '(.*)(<a href=")([\w#./=&?%\-+:;$@,]+)(".*>)(.*)(</a>)(.*)', '$1$5, $3$7'
        $CleanString
    }
}

function Get-FullOutJsonName {
    <#
    .Description
    This function determines the full file name of the SCuBA results file.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutJsonFileName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Guid,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(0, 13, 18, 36)]
        [int]
        $NumberOfUUIDCharactersToTruncate
    )
    process {
        # Truncate the UUID at the end of the ScubaResults JSON file by the parameter value.
        # This is is to possibly prevent Windows maximum path length errors that may occur when moving files
        # with a large number of characters
        $TruncatedGuid = $Guid.Substring(0, $Guid.Length - $NumberOfUUIDCharactersToTruncate)

        # If the UUID still exists after truncation
        if ($TruncatedGuid.Length -gt 0) {
            $ScubaResultsFileName = "$($OutJsonFileName)_$($TruncatedGuid).json"
        }
        else {
            # Otherwise omit adding it to the resulting file name
            $ScubaResultsFileName = "$($OutJsonFileName).json"
        }

        $ScubaResultsFileName
    }
}

function ConvertTo-ResultsCsv {
    <#
    .Description
    This function converts the controls inside the Results section of the json output to a csv.
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
        [string]
        $OutFolderPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FullScubaResultsName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutCsvFileName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutActionPlanFileName
    )
    process {
        try {
            $ScubaResultsPath = Join-Path $OutFolderPath -ChildPath $FullScubaResultsName

            if (Test-Path $ScubaResultsPath -PathType Leaf) {
                # The ScubaResults file exists, no need to look for the individual json files
                $ScubaResults = Get-Content (Get-ChildItem $ScubaResultsPath).FullName | ConvertFrom-Json
            }
            else {
                # The ScubaResults file does not exists, so we need to look inside the IndividualReports
                # folder for the json file specific to each product
                $ScubaResults = @{"Results" = [PSCustomObject]@{}}
                $IndividualReportPath = Join-Path -Path $OutFolderPath $IndividualReportFolderName -ErrorAction 'Stop'
                foreach ($Product in $ProductNames) {
                    $BaselineName = $ArgToProd[$Product]
                    $FileName = Join-Path $IndividualReportPath "$($BaselineName)Report.json"
                    $IndividualResults = Get-Content $FileName | ConvertFrom-Json
                    $ScubaResults.Results | Add-Member -NotePropertyName $BaselineName `
                        -NotePropertyValue $IndividualResults.Results
                }
            }
            $ActionPlanCsv = @()
            $ScubaResultsCsv = @()
            foreach ($Product in $ScubaResults.Results.PSObject.Properties) {
                foreach ($Group in $Product.Value) {
                    foreach ($Control in $Group.Controls) {
                        $Control.Requirement = Format-PlainText -RawString $Control.Requirement
                        $Control.Details = Format-PlainText -RawString $Control.Details
                        $ScubaResultsCsv += $Control
                        if ($Control.Result -eq "Fail") {
                            # Add blank fields where users can document reasons for failures and timelines
                            # for remediation if they so choose
                            # The space " " instead of empty string makes it so that output from the cells to the
                            # left won't automatically overlap into the space for these columns in Excel
                            $Reason = " "
                            $RemediationDate = " "
                            $Justification = " "
                            $Control | Add-Member -NotePropertyName "Non-Compliance Reason" -NotePropertyValue $Reason
                            $Control | Add-Member -NotePropertyName "Remediation Completion Date" `
                            -NotePropertyValue $RemediationDate
                            $Control | Add-Member -NotePropertyName "Justification" -NotePropertyValue $Justification
                            $ActionPlanCsv += $Control
                        }
                    }
                }
            }
            $ResultsCsvFileName = Join-Path -Path $OutFolderPath "$OutCsvFileName.csv"
            $PlanCsvFileName = Join-Path -Path $OutFolderPath "$OutActionPlanFileName.csv"
            $Encoding = Get-FileEncoding
            $ScubaResultsCsv | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $ResultsCsvFileName -Encoding $Encoding
            if ($ActionPlanCsv.Length -eq 0) {
                # If no tests failed, add the column names to ensure a file is still output
                $Headers = $ScubaResultsCsv[0].psobject.Properties.Name -Join '","'
                $Headers = "`"$Headers`""
                $Headers += '"Non-Compliance Reason","Remediation Completion Date","Justification"'
                $Headers | Set-Content -Path $PlanCsvFileName -Encoding $Encoding
            }
            else {
                $ActionPlanCsv | ConvertTo-Csv -NoTypeInformation | Set-Content -Path $PlanCsvFileName -Encoding $Encoding
            }
        }
        catch {
            Write-Warning "Error creating CSV output file: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
        }
    }
}

function Merge-JsonOutput {
    <#
    .Description
    This function packages all the json output created into a single json file.
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
        [string]
        $OutFolderPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName,

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
        $FullScubaResultsName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Guid,

        [Parameter(Mandatory=$false)]
        [boolean]
        $SilenceBODWarnings
    )
    process {
        try {
            # Files to delete at the end if no errors are encountered
            $DeletionList = @()

            # Load the raw provider output
            $SettingsExportPath = Join-Path $OutFolderPath -ChildPath "$($OutProviderFileName).json"
            $DeletionList += $SettingsExportPath
            $SettingsExport =  Get-Content $SettingsExportPath -Raw
            $SettingsExportObject = $(ConvertFrom-Json $SettingsExport)
            $TimestampZulu = $SettingsExportObject.timestamp_zulu

            # Get a list and abbreviation mapping of the products assessed
            $FullNames = @()
            $ProductAbbreviationMapping = @{}
            foreach ($ProductName in $ProductNames) {
                $BaselineName = $ArgToProd[$ProductName]
                $FullNames += $ProdToFullName[$BaselineName]
                $ProductAbbreviationMapping[$ProdToFullName[$BaselineName]] = $BaselineName
            }

            $Results = [pscustomobject]@{}
            $Summary = [pscustomobject]@{}
            $AnnotatedFailedPolicies = [pscustomobject]@{}
            # Extract the metadata
            $MetaData = [pscustomobject]@{
                "TenantId" = $TenantDetails.TenantId;
                "DisplayName" = $TenantDetails.DisplayName;
                "DomainName" = $TenantDetails.DomainName;
                "ProductSuite" = "Microsoft 365";
                "ProductsAssessed" = $FullNames;
                "ProductAbbreviationMapping" = $ProductAbbreviationMapping
                "Tool" = "ScubaGear";
                "ToolVersion" = $ModuleVersion;
                "TimestampZulu" = $TimestampZulu;
                "ReportUUID" = $Guid;
            }


            # Aggregate the report results and summaries
            $IndividualReportPath = Join-Path -Path $OutFolderPath $IndividualReportFolderName -ErrorAction 'Stop'
            $FailsNotAnnotated = @()
            foreach ($Product in $ProductNames) {
                $BaselineName = $ArgToProd[$Product]
                $FileName = Join-Path $IndividualReportPath "$($BaselineName)Report.json"
                $DeletionList += $FileName
                $IndividualResults = Get-Content $FileName | ConvertFrom-Json

                $Results | Add-Member -NotePropertyName $BaselineName `
                    -NotePropertyValue $IndividualResults.Results

                # The date is listed under the metadata, no need to include it in the summary as well
                $IndividualResults.ReportSummary.PSObject.Properties.Remove('Date')
                $Summary | Add-Member -NotePropertyName $BaselineName `
                    -NotePropertyValue $IndividualResults.ReportSummary

                # Collect the annotated failed policies into a single object
                foreach ($Annotation in $IndividualResults.ReportSummary.AnnotatedFailedPolicies.PSObject.Properties) {
                    if ($null -eq $Annotation.Value.Comment) {
                        $FailsNotAnnotated += $Annotation.Name
                    }
                    $AnnotatedFailedPolicies | Add-Member -NotePropertyName $Annotation.Name `
                        -NotePropertyValue $Annotation.Value
                }
                $IndividualResults.ReportSummary.PSObject.Properties.Remove('AnnotatedFailedPolicies')
            }
            if (-not $SilenceBODWarnings -and $FailsNotAnnotated.Length -gt 0) {
                $Warning = "$($FailsNotAnnotated.Length) controls are failing and are not documented in the config file: "
                $Warning += $FailsNotAnnotated -Join ", "
                $Warning += ". See https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/configuration.md#annotate-policies for more details."
                Write-Warning $Warning
            }
            foreach ($Product in $Results.PSObject.Properties) {
                foreach ($Group in $Product.Value) {
                    foreach ($Control in $Group.Controls) {
                        $Control.Requirement = Format-PlainText -RawString $Control.Requirement
                        $Control.Details = Format-PlainText -RawString $Control.Details
                    }
                }
            }

            # Convert the output a json string
            $MetaData = ConvertTo-Json $MetaData -Depth 3
            $Results = ConvertTo-Json $Results -Depth 5
            $Summary = ConvertTo-Json $Summary -Depth 3
            $AnnotatedFailedPolicies = ConvertTo-Json $AnnotatedFailedPolicies -Depth 3
            $ReportJson = @"
{
    "MetaData": $MetaData,
    "Summary": $Summary,
    "AnnotatedFailedPolicies": $AnnotatedFailedPolicies,
    "Results": $Results,
    "Raw": $SettingsExport
}
"@

            # ConvertTo-Json for some reason converts the <, >, and ' characters into unicode escape sequences.
            # Convert those back to ASCII.
            $ReportJson = $ReportJson.replace("\u003c", "<")
            $ReportJson = $ReportJson.replace("\u003e", ">")
            $ReportJson = $ReportJson.replace("\u0027", "'")

            $ScubaResultsPath = Join-Path $OutFolderPath -ChildPath $FullScubaResultsName -ErrorAction 'Stop'
            $ReportJson | Set-Content -Path $ScubaResultsPath -Encoding $(Get-FileEncoding) -ErrorAction 'Stop'

            # Delete the now redundant files
            foreach ($File in $DeletionList) {
                Remove-Item $File
            }
        }
        catch {
            if ($_.FullyQualifiedErrorId -eq "GetContentWriterPathTooLongError,Microsoft.PowerShell.Commands.SetContentCommand") {
                $MAX_WINDOWS_PATH_LEN = 256
                $PathLengthErrorMessage = "ScubaGear was likely executed in a location where the maximum file path length is greater than the allowable Windows file system limit `
                Please execute ScubaGear in a directory where for Windows file path limit is less than $($MAX_WINDOWS_PATH_LEN).`
                Another option is to change the -NumberOfUUIDCharactersToTruncate, -OutJSONFileName, or -OutFolderName parameters to achieve an acceptable file path length `
                See the Invoke-SCuBA parameters documentation for more details. `
                Error: $($_.Exception.Message) `
                Stacktrace: $($_.ScriptStackTrace)"
                throw $PathLengthErrorMessage
            }
            else {
                $MergeJsonErrorMessage = "Fatal Error involving the Json reports aggregation. `
                Ending ScubaGear execution. Error: $($_.Exception.Message) `
                Stacktrace: $($_.ScriptStackTrace)"
                throw $MergeJsonErrorMessage
            }
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
                $PassesSummary = "<div class='summary'></div>"
                $WarningsSummary = "<div class='summary'></div>"
                $FailuresSummary = "<div class='summary'></div>"
                $BaselineURL = "<a href= `"https://github.com/cisagov/ScubaGear/blob/v$($ModuleVersion)/baselines`" target=`"_blank`"><h3 style=`"width: 100px;`">Baseline Documents</h3></a>"
                $ManualSummary = "<div class='summary'></div>"
                $OmitSummary = "<div class='summary'></div>"
                $IncorrectResultSummary = "<div class='summary'></div>"
                $ErrorSummary = ""

                if ($Report.Passes -gt 0) {
                    $Noun = Pluralize -SingularNoun "pass" -PluralNoun "passes" -Count $Report.Passes
                    $PassesSummary = "<div class='summary pass'>$($Report.Passes) $($Noun)</div>"
                }

                if ($Report.Warnings -gt 0) {
                    $Noun = Pluralize -SingularNoun "warning" -PluralNoun "warnings" -Count $Report.Warnings
                    $WarningsSummary = "<div class='summary warning'>$($Report.Warnings) $($Noun)</div>"
                }

                if ($Report.Failures -gt 0) {
                    $Noun = Pluralize -SingularNoun "failure" -PluralNoun "failures" -Count $Report.Failures
                    $FailuresSummary = "<div class='summary failure'>$($Report.Failures) $($Noun)</div>"
                }

                if ($Report.Manual -gt 0) {
                    $Noun = Pluralize -SingularNoun "check" -PluralNoun "checks" -Count $Report.Manual
                    $ManualSummary = "<div class='summary manual'>$($Report.Manual) manual $($Noun)</div>"
                }

                if ($Report.Omits -gt 0) {
                    $OmitSummary = "<div class='summary manual'>$($Report.Omits) omitted</div>"
                }

                if ($Report.IncorrectResults -gt 0) {
                    $Noun = Pluralize -SingularNoun "incorrect result" -PluralNoun "incorrect results" -Count $Report.IncorrectResults
                    $IncorrectResultSummary = "<div class='summary incorrect'>$($Report.IncorrectResults) $Noun</div>"
                }

                if ($Report.Errors -gt 0) {
                    $Noun = Pluralize -SingularNoun "error" -PluralNoun "errors" -Count $Report.Errors
                    $ErrorSummary = "<div class='summary error'>$($Report.Errors) $($Noun)</div>"
                }

                $Fragment += [pscustomobject]@{
                "Baseline Conformance Reports" = $Link;
                "Details" = "$PassesSummary $WarningsSummary $FailuresSummary $ManualSummary $OmitSummary $IncorrectResultSummary $ErrorSummary"
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

            $ProviderJSONFilePath = Join-Path -Path $OutFolderPath -ChildPath "$($OutProviderFileName).json" -Resolve
            $ReportUuid = $(Get-Utf8NoBom -FilePath $ProviderJSONFilePath | ConvertFrom-Json).report_uuid

            $ReportHtmlPath = Join-Path -Path $ReporterPath -ChildPath "ParentReport" -ErrorAction 'Stop'
            $ReportHTML = (Get-Content $(Join-Path -Path $ReportHtmlPath -ChildPath "ParentReport.html") -ErrorAction 'Stop') -Join "`n"
            $ReportHTML = $ReportHTML.Replace("{TENANT_DETAILS}", $TenantMetaData)
            $ReportHTML = $ReportHTML.Replace("{TABLES}", $Fragment)
            $ReportHTML = $ReportHTML.Replace("{REPORT_UUID}", $ReportUuid)
            $ReportHTML = $ReportHTML.Replace("{MODULE_VERSION}", "v$ModuleVersion")
            $ReportHTML = $ReportHTML.Replace("{BASELINE_URL}", $BaselineURL)

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
            Ending ScubaGear execution. Error: $($_.Exception.Message)`
            `n$($_.ScriptStackTrace)"
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
        Get-AADTenantDetail -M365Environment $M365Environment
    }
    elseif ($ProductNames.Contains("sharepoint")) {
        Get-AADTenantDetail -M365Environment $M365Environment
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

        @('Connection', 'RunRego', 'CreateReport', 'ScubaConfig', 'Support', 'Utility') | ForEach-Object {
            $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath $_ -ErrorAction 'Stop'
            Write-Debug "Importing $_ module"
            Import-Module -Name $ModulePath
        }
    }
    catch {
        $ImportResourcesErrorMessage = "Fatal Error involving importing PowerShell modules. `
            Ending ScubaGear execution. Error: $($_.Exception.Message) `
            `n$($_.ScriptStackTrace)"
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

function Invoke-SCuBACached {
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
    .Parameter KeepIndividualJSON
    Keeps ScubaGear legacy output where files are not merged into an all in one JSON.
    This parameter is for backwards compatibility for those working with the older ScubaGear output files.
    .Parameter OutJsonFileName
    If KeepIndividualJSON is set, the name of the consolidated json created in the folder
    created in OutPath. Defaults to "ScubaResults". The report UUID will be appended to this.
    .Parameter OutCsvFileName
    The CSV created in the folder created in OutPath that contains the CSV version of the test results.
    Defaults to "ScubaResults".
    .Parameter OutActionPlanFileName
    The CSV created in the folder created in OutPath that contains a CSV template prepopulated with the failed
    SHALL controls with fields for documenting failure causes and remediation plans. Defaults to "ActionPlan".
    .Parameter DarkMode
    Set switch to enable report dark mode by default.
    .Parameter SilenceBODWarnings
    Do not warn for requirements specific to BOD compliance (e.g., documenting OrgName in the config file).
    .Parameter NumberOfUUIDCharactersToTruncate
    Controls how many characters will be truncated from the report UUID when appended to the end of OutJsonFileName.
    Valid values are 0, 13, 18, 36
    .Example
    Invoke-SCuBACached
    Run an assessment against by default a commercial M365 Tenant against the
    Azure Active Directory, Exchange Online, Microsoft Defender, One Drive, SharePoint Online, and Microsoft Teams
    security baselines. The output will stored in the current directory in a folder called M365BaselineConformaance_*.
    .Example
    Invoke-SCuBACached -Version
    This example returns the version of SCuBAGear.
    .Example
    Invoke-SCuBACached -ProductNames aad, defender -OPAPath . -OutPath .
    The example will run the tool against the Azure Active Directory, and Defender security
    baselines.
    .Example
    Invoke-SCuBACached -ProductNames * -M365Environment dod -OPAPath . -OutPath .
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
        $ProductNames = [ScubaConfig]::ScubaDefault('AllProductNames'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment = [ScubaConfig]::ScubaDefault('DefaultM365Environment'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateScript({Test-Path -PathType Container $_})]
        [ValidateNotNullOrEmpty()]
        [string]
        $OPAPath = [ScubaConfig]::ScubaDefault('DefaultOPAPath'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $LogIn = [ScubaConfig]::ScubaDefault('DefaultLogIn'),

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
        $OutPath = [ScubaConfig]::ScubaDefault('DefaultOutPath'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName = [ScubaConfig]::ScubaDefault('DefaultOutProviderFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName = [ScubaConfig]::ScubaDefault('DefaultOutRegoFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportName = [ScubaConfig]::ScubaDefault('DefaultOutReportName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [switch]
        $KeepIndividualJSON,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutJsonFileName = [ScubaConfig]::ScubaDefault('DefaultOutJsonFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutCsvFileName = [ScubaConfig]::ScubaDefault('DefaultOutCsvFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutActionPlanFileName = [ScubaConfig]::ScubaDefault('DefaultOutActionPlanFileName'),

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [switch]
        $Quiet,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $DarkMode,

        [Parameter(Mandatory = $false, ParameterSetName = 'Configuration')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [switch]
        $SilenceBODWarnings,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(0, 13, 18, 36)]
        [int]
        $NumberOfUUIDCharactersToTruncate = [ScubaConfig]::ScubaDefault('DefaultNumberOfUUIDCharactersToTruncate')
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

            if ($OutCsvFileName -eq $OutActionPlanFileName) {
                $ErrorMessage = "OutCsvFileName and OutActionPlanFileName cannot be equal to each other. "
                $ErrorMessage += "Both are set to $($OutCsvFileName). Stopping execution."
                throw $ErrorMessage
            }

            # Create outpath if $Outpath does not exist
            if(-not (Test-Path -PathType "container" $OutPath))
            {
                New-Item -ItemType "Directory" -Path $OutPath | Out-Null
            }
            $OutFolderPath = $OutPath
            $ProductNames = $ProductNames | Sort-Object -Unique

            Remove-Resources
            Import-Resources # Imports Providers, RunRego, CreateReport, Connection, Support, Utility

            # Authenticate
            $ConnectionParams = @{
                'LogIn' = $LogIn;
                'ProductNames' = $ProductNames;
                'M365Environment' = $M365Environment;
                'BoundParameters' = $PSBoundParameters;
            }

            # Create a failsafe tenant metadata variable in case the
            # provider cannot retrieve the data.
            $TenantDetails = @{"DisplayName"="Rego Testing";}
            $TenantDetails = $TenantDetails | ConvertTo-Json -Depth 3

            if ($ExportProvider) {
                # Check if there is a previous ScubaResults file
                # delete if found
                $PreviousResultsFiles = Get-ChildItem -Path $OutPath -Filter "$($OutJsonFileName)*.json"
                if ($PreviousResultsFiles) {
                    $PreviousResultsFiles | ForEach-Object {
                        Remove-Item $_.FullName -Force
                    }
                }

                # authenticate
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

                # A new GUID needs to be generated if the provider is run
                $Guid = New-Guid -ErrorAction 'Stop'

                $ProviderParams = @{
                    'ProductNames' = $ProductNames;
                    'M365Environment' = $M365Environment;
                    'TenantDetails' = $TenantDetails;
                    'ModuleVersion' = $ModuleVersion;
                    'OutFolderPath' = $OutFolderPath;
                    'OutProviderFileName' = $OutProviderFileName;
                    'Guid' = $Guid;
                    'BoundParameters' = $PSBoundParameters;
                }
                Invoke-ProviderList @ProviderParams
            }

            $ProviderJSONFilePath = Join-Path -Path $OutPath -ChildPath "$($OutProviderFileName).json"
            if (-not (Test-Path $ProviderJSONFilePath)) {
                # When running Invoke-ScubaCached, the provider output might not exist as a stand-alone
                # file depending on what version of ScubaGear created the output. If the provider output
                # does not exist as a stand-alone file, create it from the ScubaResults file so the other functions
                # can execute as normal.
                $ScubaResultsFileName = Join-Path -Path $OutPath -ChildPath "$($OutJsonFileName)*.json"
                # As there is the possibility that the wildcard will match multiple files,
                # select the one that was created last if there are multiple.
                # By default ScubaGear will output the files into their own folder.
                # The only case this will happen is when someone personally moves multiple files into the
                # same folder.
                $SettingsExport = $(Get-Content (Get-ChildItem $ScubaResultsFileName | Sort-Object CreationTime -Descending | Select-Object -First 1).FullName | ConvertFrom-Json).Raw

                # Uses the custom UTF8 NoBOM function to reoutput the Provider JSON file
                $ProviderContent = $SettingsExport | ConvertTo-Json -Depth 20
                $ActualSavedLocation = Set-Utf8NoBom -Content $ProviderContent `
                -Location $OutPath -FileName "$OutProviderFileName.json"
                Write-Debug $ActualSavedLocation
            }
            $SettingsExport = Get-Content $ProviderJSONFilePath | ConvertFrom-Json

            # Generate a new UUID if the original data doesn't have one
            if (-not (Get-Member -InputObject $SettingsExport -Name "report_uuid" -MemberType Properties)) {
                $Guid = New-Guid -ErrorAction 'Stop'
                $SettingsExport | Add-Member -Name 'report_uuid' -Value $Guid -Type NoteProperty
            }
            else {
                # Otherwise grab the UUID from the JSON itself
                $Guid = $SettingsExport.report_uuid
            }

            $ProviderContent = $SettingsExport | ConvertTo-Json -Depth 20
            $ActualSavedLocation = Set-Utf8NoBom -Content $ProviderContent `
            -Location $OutPath -FileName "$OutProviderFileName.json"
            Write-Debug $ActualSavedLocation

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

            $FullNameParams = @{
                'OutJsonFileName'                  = $OutJsonFileName;
                'Guid'                             = $Guid;
                'NumberOfUUIDCharactersToTruncate' = $NumberOfUUIDCharactersToTruncate;
            }
            $FullScubaResultsName = Get-FullOutJsonName @FullNameParams

            if (-not $KeepIndividualJSON) {
                # Craft the complete json version of the output
                $JsonParams = @{
                    'ProductNames' = $ProductNames;
                    'OutFolderPath' = $OutFolderPath;
                    'OutProviderFileName' = $OutProviderFileName;
                    'TenantDetails' = $TenantDetails;
                    'ModuleVersion' = $ModuleVersion;
                    'FullScubaResultsName' = $FullScubaResultsName;
                    'Guid' = $Guid;
                    'SilenceBODWarnings' = $SilenceBODWarnings;
                }
                Merge-JsonOutput @JsonParams
            }
            # Craft the csv version of just the results
            $CsvParams = @{
                'ProductNames' = $ProductNames;
                'OutFolderPath' = $OutFolderPath;
                'FullScubaResultsName' = $FullScubaResultsName;
                'OutCsvFileName' = $OutCsvFileName;
                'OutActionPlanFileName' = $OutActionPlanFileName;
            }
            ConvertTo-ResultsCsv @CsvParams
        }
    }

Export-ModuleMember -Function @(
    'Invoke-SCuBA',
    'Invoke-SCuBACached'
)
