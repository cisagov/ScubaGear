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
    - OneDrive: onedrive
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
    .Example
    Invoke-SCuBA
    Run an assessment against by default a commercial M365 Tenant against the
    Azure Active Directory, Exchange Online, Microsoft Defender, One Drive, SharePoint Online, and Microsoft Teams
    security baselines. The output will stored in the current directory in a folder called M365BaselineConformaance_*.
    .Example
    Invoke-SCuBA -Version
    This example returns the version of SCuBAGear.
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
    .Functionality
    Public
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames = @("teams", "exo", "defender", "aad", "sharepoint", "onedrive"),

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

        [Parameter(Mandatory = $false)]
        [switch]
        $DisconnectOnExit,

        [Parameter(ParameterSetName = 'Report')]
        [switch]
        $Version,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [string]
        $AppID,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [string]
        $CertificateThumbprint,

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
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
        $OutReportName = "BaselineReports"
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
            $ProductNames = "teams", "exo", "defender", "aad", "sharepoint", "onedrive", "powerplatform"
        }

        # The equivalent of ..\..
        $ParentPath = Split-Path $(Split-Path $ParentPath -Parent) -Parent

        # Creates the output folder
        $Date = Get-Date
        $DateStr = $Date.ToString("yyyy_MM_dd_HH_mm_ss")
        $FormattedTimeStamp = $DateStr

        $OutFolderPath = $OutPath
        $FolderName = "$($OutFolderName)_$($FormattedTimeStamp)"
        New-Item -Path $OutFolderPath -Name $($FolderName) -ItemType Directory | Out-Null
        $OutFolderPath = Join-Path -Path $OutFolderPath -ChildPath $FolderName

        $ProductNames = $ProductNames | Sort-Object

        Remove-Resources
        Import-Resources # Imports Providers, RunRego, CreateReport, Connection

        $ConnectionParams = @{
            'LogIn' = $LogIn;
            'ProductNames' = $ProductNames;
            'M365Environment' = $M365Environment;
            'BoundParameters' = $PSBoundParameters;
        }

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
        $RegoParams = @{
            'ProductNames' = $ProductNames;
            'OPAPath' = $OPAPath;
            'ParentPath' = $ParentPath;
            'OutFolderPath' = $OutFolderPath;
            'OutProviderFileName' = $OutProviderFileName;
            'OutRegoFileName' = $OutRegoFileName;
        }
        # Converted back from JSON String for PS Object use
        $TenantDetails = $TenantDetails | ConvertFrom-Json
        $ReportParams = @{
            'ProductNames' = $ProductNames;
            'TenantDetails' = $TenantDetails;
            'ModuleVersion' = $ModuleVersion;
            'OutFolderPath' = $OutFolderPath;
            'OutProviderFileName' = $OutProviderFileName;
            'OutRegoFileName' = $OutRegoFileName;
            'OutReportName' = $OutReportName;
        }

        try {
            Invoke-ProviderList @ProviderParams
            Invoke-RunRego @RegoParams
            Invoke-ReportCreation @ReportParams
        } finally {
            if ($DisconnectOnExit) {
                if($VerbosePreference -eq "Continue") {
                    Disconnect-SCuBATenant -ProductNames $ProductNames -ErrorAction SilentlyContinue -Verbose
                }
                else {
                    Disconnect-SCuBATenant -ProductNames $ProductNames -ErrorAction SilentlyContinue
                }
            }
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
    onedrive = "OneDrive";
}

$ProdToFullName = @{
    Teams = "Microsoft Teams";
    EXO = "Exchange Online";
    Defender = "Microsoft 365 Defender";
    AAD = "Azure Active Directory";
    PowerPlatform = "Microsoft Power Platform";
    SharePoint = "SharePoint Online";
    OneDrive = "OneDrive for Business";
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
        [Parameter(Mandatory=$true)]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory=$true)]
        [string]
        $M365Environment,

        [Parameter(Mandatory=$true)]
        [string]
        $TenantDetails,

        [Parameter(Mandatory=$true)]
        [string]
        $ModuleVersion,

        [Parameter(Mandatory=$true)]
        [string]
        $OutFolderPath,

        [Parameter(Mandatory=$true)]
        [string]
        $OutProviderFileName,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $BoundParameters
    )
    process {
        # yes the syntax has to be like this
        # fixing the spacing causes PowerShell interpreter errors
        $ProviderJSON = @"
"@
        $N = 0
        $Len = $ProductNames.Length
        $ConnectTenantParams = @{
            'M365Environment' = $M365Environment
        }
        if ($BoundParameters.AppID) {
            $ServicePrincipalParams = Get-ServicePrincipalParams -BoundParameters $BoundParameters
            $ConnectTenantParams += @{ServicePrincipalParams = $ServicePrincipalParams;}
        }

        foreach ($Product in $ProductNames) {
            $BaselineName = $ArgToProd[$Product]
            $N += 1
            $Percent = $N*100/$Len
            $Status = "Running the $($BaselineName) Provider; $($N) of $($Len) Product settings extracted"
            $ProgressParams = @{
                'Activity' = "Running the provider for each baseline"
                'Status' = $Status;
                'PercentComplete' = $Percent;
                'Id' = 1;
            }
            Write-Progress @ProgressParams
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
                "onedrive" {
                    $RetVal = Export-OneDriveProvider -M365Environment $M365Environment | Select-Object -Last 1
                }
                "sharepoint" {
                    $RetVal = Export-SharePointProvider -M365Environment $M365Environment | Select-Object -Last 1
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

        $ProviderJSON = $ProviderJSON.TrimEnd(",")
        $TimeZone = ""
        if ((Get-Date).IsDaylightSavingTime()) {
            $TimeZone = (Get-TimeZone).DaylightName
        }
        else {
            $TimeZone = (Get-TimeZone).StandardName
        }
        $BaselineSettingsExport = @"
{
        "baseline_version": "0.1",
        "module_version": "$ModuleVersion",
        "date": "$(Get-Date) $($TimeZone)",
        "tenant_details": $($TenantDetails),

        $ProviderJSON
}
"@
        $BaselineSettingsExport = $BaselineSettingsExport.replace("\`"", "'")
        $BaselineSettingsExport = $BaselineSettingsExport.replace("\", "")
        $FinalPath = Join-Path -Path $OutFolderPath -ChildPath "$($OutProviderFileName).json"
        $BaselineSettingsExport | Set-Content -Path $FinalPath -Encoding $(Get-FileEncoding)
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
        [Parameter(Mandatory=$true)]
        [string[]]
        $ProductNames,

        [string]
        $OPAPath = $PSScriptRoot,

        [Parameter(Mandatory=$true)]
        [String]
        $ParentPath,

        [Parameter(Mandatory=$true)]
        [String]
        $OutFolderPath,

        [Parameter(Mandatory=$true)]
        [String]
        $OutProviderFileName,

        [Parameter(Mandatory=$true)]
        [string]
        $OutRegoFileName
    )
    process {
        $TestResults = @()
        $N = 0
        $Len = $ProductNames.Length
        foreach ($Product in $ProductNames) {
            $BaselineName = $ArgToProd[$Product]
            $N += 1
            $Percent = $N*100/$Len

            $Status = "Running the $($BaselineName) Rego Verification; $($N) of $($Len) Rego verifications completed"
            $ProgressParams = @{
                'Activity' = "Running the rego for each baseline";
                'Status' = $Status;
                'PercentComplete' = $Percent;
                'Id' = 1;
            }
            Write-Progress @ProgressParams
            $InputFile = Join-Path -Path $OutFolderPath "$($OutProviderFileName).json"
            $RegoFile = Join-Path -Path $ParentPath -ChildPath "Rego"
            $RegoFile = Join-Path -Path $RegoFile -ChildPath "$($BaselineName)Config.rego"
            $params = @{
                'InputFile' = $InputFile;
                'RegoFile' = $RegoFile;
                'PackageName' = $Product;
                'OPAPath' = $OPAPath
            }
            $RetVal = Invoke-Rego @params
            $TestResults += $RetVal
            }

            $TestResultsJson = $TestResults | ConvertTo-Json -Depth 5
            $FileName = Join-Path -path $OutFolderPath "$($OutRegoFileName).json"
            $TestResultsJson | Set-Content -Path $FileName -Encoding $(Get-FileEncoding)

            foreach ($Product in $TestResults) {
                foreach ($Test in $Product) {
                    # ConvertTo-Csv struggles with the nested nature of the ActualValue
                    # and Commandlet fields. Explicitly convert these to json strings before
                    # calling ConvertTo-Csv
                    $Test.ActualValue = $Test.ActualValue | ConvertTo-Json -Depth 3 -Compress
                    $Test.Commandlet = $Test.Commandlet -Join ", "
                }
            }

            $TestResultsCsv = $TestResults | ConvertTo-Csv -NoTypeInformation
            $CSVFileName = Join-Path -Path $OutFolderPath "$($OutRegoFileName).csv"
            $TestResultsCsv | Set-Content -Path $CSVFileName -Encoding $(Get-FileEncoding)
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
        [string]
        $SingularNoun,

        [Parameter(Mandatory=$true)]
        [string]
        $PluralNoun,

        [Parameter(Mandatory=$true)]
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
        [string[]]
        $ProductNames,

        [Parameter(Mandatory=$true)]
        [object]
        $TenantDetails,

        [Parameter(Mandatory=$true)]
        [string]
        $ModuleVersion,

        [Parameter(Mandatory=$true)]
        [string]
        $OutFolderPath,

        [Parameter(Mandatory=$true)]
        [string]
        $OutProviderFileName,

        [Parameter(Mandatory=$true)]
        [string]
        $OutRegoFileName,

        [Parameter(Mandatory=$true)]
        [string]
        $OutReportName,

        [Parameter(Mandatory = $false)]
        [boolean]
        $Quiet = $false
    )
    process {
        $N = 0
        $Len = $ProductNames.Length
        $Fragment = @()

        $IndividualReportFolderName = "IndividualReports"
        $IndividualReportPath = Join-Path -Path $OutFolderPath -ChildPath $IndividualReportFolderName
        New-Item -Path $IndividualReportPath -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null

        $ReporterPath = Join-Path -Path $PSScriptRoot -ChildPath "CreateReport"
        $Logo = Join-Path -Path $ReporterPath -ChildPath "cisa_logo.png"
        Copy-Item -Path $Logo -Destination $IndividualReportPath -Force

        foreach ($Product in $ProductNames) {
            $BaselineName = $ArgToProd[$Product]
            $N += 1
            $Percent = $N*100/$Len
            $Status = "Running the $($BaselineName) Report creation; $($N) of $($Len) Baselines Reports created";
            $ProgressParams = @{
                'Activity' = "Creating the reports for each baseline"
                'Status' = $Status;
                'PercentComplete' = $Percent;
                'Id' = 1;
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
                $Noun = Pluralize -SingularNoun "check" -PluralNoun "errors" -Count $Report.Manual
                $ErrorSummary = "<div class='summary error'>$($Report.Errors) PowerShell $($Noun)</div>"
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
        $TenantMetaData = $TenantMetaData | ConvertTo-Html -Fragment
        $TenantMetaData = $TenantMetaData -replace '^(.*?)<table>','<table class ="tenantdata" style = "text-align:center;">'
        $Fragment = $Fragment | ConvertTo-Html -Fragment

        $ReportHTML = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "ParentReportTemplate.html")
        $ReportHTML = $ReportHTML.Replace("{TENANT_DETAILS}", $TenantMetaData)
        $ReportHTML = $ReportHTML.Replace("{TABLES}", $Fragment)
        $ReportHTML = $ReportHTML.Replace("{MODULE_VERSION}", "v$ModuleVersion")

        $MainCSS = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "main.css")
        $ReportHTML = $ReportHTML.Replace("{MAIN_CSS}", "<style>$($MainCSS)</style>")

        $ParentCSS = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "ParentStyle.css")
        $ReportHTML = $ReportHTML.Replace("{PARENT_CSS}", "<style>$($ParentCSS)</style>")

        Add-Type -AssemblyName System.Web
        $ReportFileName = Join-Path -Path $OutFolderPath "$($OutReportName).html"
        [System.Web.HttpUtility]::HtmlDecode($ReportHTML) | Out-File $ReportFileName
        if ($Quiet -eq $False) {
            Invoke-Item $ReportFileName
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
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive", IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
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
    elseif ($ProductNames.Contains("onedrive")) {
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
        [boolean]
        $LogIn,

        [Parameter(Mandatory=$true)]
        [string[]]
        $ProductNames,

        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]
        $M365Environment = "commercial",

        [Parameter(Mandatory=$true)]
        [hashtable]
        $BoundParameters
    )

    # Increase PowerShell Maximum Function Count to support version 5.1 limitation
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'MaximumFunctionCount')]
    $MaximumFunctionCount = 32000

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
    $ProvidersPath = Join-Path -Path $PSScriptRoot `
    -ChildPath "Providers" `
    -Resolve
    $ProviderResources = Get-ChildItem $ProvidersPath -Recurse | Where-Object { $_.Name -like 'Export*.psm1' }
    if (!$ProviderResources)
    {
        throw "Provider files were not found, aborting this run"
    }

    foreach ($Provider in $ProviderResources.Name) {
        $ProvidersPath = Join-Path -Path $PSScriptRoot -ChildPath "Providers"
        $ModulePath = Join-Path -Path $ProvidersPath -ChildPath $Provider
        Import-Module $ModulePath
    }
    $ConnectionPath = Join-Path -Path $PSScriptRoot -ChildPath "Connection"
    $RegoPath = Join-Path -Path $PSScriptRoot -ChildPath "RunRego"
    $ReporterPath = Join-Path -Path $PSScriptRoot -ChildPath "CreateReport"
    Import-Module $ConnectionPath
    Import-Module $RegoPath
    Import-Module $ReporterPath
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
    "ExportDefenderProvider", "ExportTeamsProvider", "ExportSharePointProvider", "ExportOneDriveProvider")
    foreach ($Provider in $Providers) {
        Remove-Module $Provider -ErrorAction "SilentlyContinue"
    }

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
    - OneDrive: onedrive
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
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames = '*',

        [Parameter(Mandatory = $false, ParameterSetName = 'Report')]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
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

        [Parameter(ParameterSetName = 'Report')]
        [switch]
        $Version,

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
        [boolean]
        $Quiet = $false
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
                $ProductNames = "teams", "exo", "defender", "aad", "sharepoint", "onedrive"
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
            }
            Invoke-RunRego @RegoParams
            Invoke-ReportCreation @ReportParams
        }
    }

Export-ModuleMember -Function @(
    'Invoke-SCuBA',
    'Invoke-RunCached'
)