function Invoke-SCuBA {
    <#
    .Description
    This is the orchestrator function that runs the Providers, Rego, and Report creation all in one
    PowerShell script call
    .Parameter ProductNames
    Which Baseline Names to run their respective Providers and Rego tests
    .Parameter Endpoint
    The Endpoint parameter for PowerPlatform authentication
    .Parameter OPAPath
    Path to the OPA executuable
    .Parameter LogIn
    Set $true to authenticate yourself to a tenant or if you are already authenticated set to $false
    .Example
    Invoke-SCuBA -LogIn $True -ProductNames @("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive")  -Endpoint "usgov" -OPAPath "./"  -OutPath output
    .Example
    Invoke-SCuBA -LogIn $False -ProductNames @("powerplatform", "exo")  -Endpoint "prod" -OPAPath "./"  -OutPath "/Reports"
    .Functionality
    Public
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive", IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [string]
        $Endpoint = "",

        [Parameter(Mandatory=$true)]
        [string]
        $OPAPath = $PSScriptRoot,

        [boolean]
        $LogIn = $true,

        [switch]
        $Version,

        [string]
        $OutPath = $PSScriptRoot
        )
        process {
            # The equivalent of ..\..
            $ParentPath = Split-Path $PSScriptRoot -Parent
            $ParentPath = Split-Path $(Split-Path $ParentPath -Parent) -Parent
            $ModuleVersion = $MyInvocation.MyCommand.ScriptBlock.Module.Version

            if($Version) {
                Write-Output("SCuBA Gear v$ModuleVersion")
                return
            }

            # Create a folder to dump everything into
            $Date = Get-Date
            $DateStr = $Date.ToString("yyyy_MM_dd_HH_mm_ss")

            $FormattedTimeStamp = $DateStr

            $OutFolderPath = $OutPath
            $FolderName = "M365BaselineConformance_$($FormattedTimeStamp)"
            New-Item -Path $OutFolderPath -Name $($FolderName) -ItemType Directory | Out-Null
            $OutFolderPath = Join-Path -Path $OutFolderPath -ChildPath $FolderName

            $ProductNames = $ProductNames | Sort-Object

            $ConnectionParams = @{
                'LogIn' = $LogIn;
                'ProductNames' = $ProductNames;
                'Endpoint' = $Endpoint;
            }

            # If a PowerShell module  is updated, the changes
            # will not reflect until it is reimported into the runtime
            Remove-Resources
            Import-Resources # Imports Providers, RunRego, CreateReport

            Invoke-Connection @ConnectionParams

            $TenantDetails = Get-TenantDetails -ProductNames $ProductNames
            $ProviderParams = @{
                'ProductNames' = $ProductNames;
                'TenantDetails' = $TenantDetails;
                'OutFolderPath' = $OutFolderPath;
            }
            $RegoParams = @{
                'ProductNames' = $ProductNames;
                'OPAPath' = $OPAPath;
                'ParentPath' = $ParentPath;
                'OutFolderPath' = $OutFolderPath;
            }
            $DisplayName = $TenantDetails | ConvertFrom-Json
            $DisplayName = $DisplayName.DisplayName
            $ReportParams = @{
                'ProductNames' = $ProductNames;
                'DisplayName' = $DisplayName
                'OutFolderPath' = $OutFolderPath;
            }
            Invoke-ProviderList @ProviderParams
            Invoke-RunRego @RegoParams
            Invoke-ReportCreation @ReportParams
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
        $TenantDetails,

        [Parameter(Mandatory=$true)]
        [string]
        $OutFolderPath
    )
    process {
        # yes the syntax has to be like this
        # fixing the spacing causes PowerShell interpreter errors
        $ProviderJSON = @"
"@
        $ModuleVersion = $MyInvocation.MyCommand.ScriptBlock.Module.Version
        $N = 0
        $Len = $ProductNames.Length
        foreach ($Product in $ProductNames) {
            $BaselineName = $ArgToProd[$Product]
            $N += 1
            $Percent = $N*100/$Len
            Write-Progress -Activity "Running the provider for each baseline" -Status "Running the $($BaselineName) Provider; $($n) of $($Len) Product settings extracted" -PercentComplete $Percent -Id 1
            $RetVal = ""
            switch ($Product) {
                "aad"{
                    $RetVal = Export-AADProvider | Select-Object -Last 1
                }
                "exo" {
                    $RetVal = Export-EXOProvider | Select-Object -Last 1
                }
                "defender" {
                    $RetVal = Export-DefenderProvider | Select-Object -Last 1
                }
                "powerplatform"{
                    $RetVal = Export-PowerPlatformProvider | Select-Object -Last 1
                }
                "onedrive"{
                    $RetVal = Export-OneDriveProvider | Select-Object -Last 1
                }
                "sharepoint"{
                    $RetVal = Export-SharePointProvider | Select-Object -Last 1
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

        # Clean up EXO - Defender conflicts
        if($ProductNames -contains "defender") {
            Disconnect-ExchangeOnline -Confirm:$false -InformationAction Ignore -ErrorAction SilentlyContinue | Out-Null
            Disconnect-ExchangeOnline -Confirm:$false -InformationAction Ignore -ErrorAction SilentlyContinue | Out-Null
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
        $FinalPath = Join-Path -Path $OutFolderPath -ChildPath "ProviderSettingsExport.json"
        $BaselineSettingsExport | Set-Content -Path $FinalPath
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
        $OutFolderPath
    )
    process {
        $TestResults = @()
        $N = 0
        $Len = $ProductNames.Length
        foreach ($Product in $ProductNames) {
            $BaselineName = $ArgToProd[$Product]
            $N += 1
            $Percent = $N*100/$Len
            Write-Progress -Activity "Running the rego for each baseline" -Status "Running the $($BaselineName) Rego Verification; $($n) of $($Len) Rego verifications completed" -PercentComplete $Percent -Id 1
            $InputFile = Join-Path -Path $OutFolderPath "ProviderSettingsExport.json"
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
            $FileName = Join-Path -path $OutFolderPath "TestResults.json"
            $TestResultsJson | Set-Content -Path $FileName

            foreach ($Product in $TestResults) {
                foreach ($Test in $Product) {
                    # ConvertTo-Csv struggles with the nested nature of the ActualValue
                    # field. Explicitly convert the ActualValues to json strings before
                    # calling ConvertTo-Csv
                    $Test.ActualValue = $Test.ActualValue | ConvertTo-Json -Depth 3 -Compress
                }
            }

            $TestResultsCsv = $TestResults | ConvertTo-Csv -NoTypeInformation
            $CSVFileName = Join-Path -Path $OutFolderPath "TestResults.csv"
            $TestResultsCsv | Set-Content -Path $CSVFileName
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
            return $PluralNoun
        }
        else {
            return $SingularNoun
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
        [string]
        $DisplayName,

        [Parameter(Mandatory=$true)]
        [String]
        $OutFolderPath
    )
    process {
        $N = 0
        $Len = $ProductNames.Length
        $Fragment = @()
        $ModuleVersion = $MyInvocation.MyCommand.Module.Version

        $IndividualReportFolderName = "IndividualReports"
        $IndividualReportPath = Join-Path -Path $OutFolderPath -ChildPath $IndividualReportFolderName
        New-Item -Path $IndividualReportPath -ItemType "Directory" -ErrorAction "SilentlyContinue" | Out-Null

        $ReporterPath = Join-Path -Path $PSScriptRoot -ChildPath "CreateReport"
        $Logo = Join-Path -Path $ReporterPath -ChildPath "cisa_logo.png"
        Copy-Item -Path $Logo -Destination $IndividualReportPath -Force

        $ProdToFullName = @{
            Teams = "Microsoft Teams";
            EXO = "Exchange Online";
            Defender = "Microsoft 365 Defender";
            AAD = "Azure Active Directory";
            PowerPlatform = "Microsoft Power Platform";
            SharePoint = "SharePoint Online";
            OneDrive = "OneDrive for Business";
        }

        foreach ($Product in $ProductNames) {
            $BaselineName = $ArgToProd[$Product]
            $N += 1
            $Percent = $N*100/$Len
            Write-Progress -Activity "Creating the reports for each baseline" -Status "Running the $($BaselineName) Report creation; $($n) of $($Len) Baselines Reports created" -PercentComplete $Percent -Id 1

            $FullName = $ProdToFullName[$BaselineName]

            $CreateReportParams = @{
                'BaselineName' = $BaselineName;
                'FullName' = $FullName;
                'IndividualReportPath' = $IndividualReportPath;
                'OutPath' = $OutFolderPath;
            }

            $Report = New-Report @CreateReportParams
            $LinkPath = "$($IndividualReportFolderName)/$($BaselineName)Report.html"
            $LinkClassName = '"individual_reports"' # uses no escape characters
            $Link = "<a class=$($LinkClassName) href='$($LinkPath)'>$($FullName)</a>"

            $PassesSummary = "<div class='summary pass'>$($Report.Passes) tests passed</div>"
            $WarningsSummary = "<div class='summary'></div>"
            $FailuresSummary = "<div class='summary'></div>"
            $ManualSummary = "<div class='summary'></div>"

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

            $Fragment += [pscustomobject]@{
            "Baseline Conformance Reports" = $Link;
            "Details" = "$($PassesSummary) $($WarningsSummary) $($FailuresSummary) $($ManualSummary)"
            }
        }

        $Fragment = $Fragment | ConvertTo-Html -Fragment

        $ReportHTML = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "ParentReportTemplate.html")
        $ReportHTML = $ReportHTML.Replace("{TENANT_NAME}", $DisplayName)
        $ReportHTML = $ReportHTML.Replace("{TABLES}", $Fragment)
        $ReportHTML = $ReportHTML.Replace("{REPORT_TIME}", $Report.Date)
        $ReportHTML = $ReportHTML.Replace("{MODULE_VERSION}", "v$ModuleVersion")

        $MainCSS = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "main.css")
        $ReportHTML = $ReportHTML.Replace("{MAIN_CSS}", "<style>$($MainCSS)</style>")

        $ParentCSS = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "ParentStyle.css")
        $ReportHTML = $ReportHTML.Replace("{PARENT_CSS}", "<style>$($ParentCSS)</style>")

        Add-Type -AssemblyName System.Web
        $ReportFileName = Join-Path -Path $OutFolderPath "BaselineReports.html"
        [System.Web.HttpUtility]::HtmlDecode($ReportHTML) | Out-File $ReportFileName
        Invoke-Item $ReportFileName
    }
}

function Get-TenantDetails {
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
        [string[]]
        $ProductNames
    )

    # organized by best tenant details information
    if ($ProductNames.Contains("teams")) {
        Get-TeamsTenantDetail
    }
    elseif ($ProductNames.Contains("aad")) {
        Get-AADTenantDetail
    }
    elseif ($ProductNames.Contains("exo")) {
        Get-EXOTenantDetail
    }
    elseif ($ProductNames.Contains("defender")) {
        Get-DefenderTenantDetail
    }
    elseif ($ProductNames.Contains("powerplatform")) {
        Get-PowerPlatformTenantDetail
    }
    elseif ($ProductNames.Contains("sharepoint")) {
        Get-AADTenantDetail
    }
    elseif ($ProductNames.Contains("onedrive")) {
        Get-AADTenantDetail
    }
    else {
        $TenantInfo = @{"DisplayName"="Undefined Name";}
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

        [string]
        $Endpoint
    )
    if ($LogIn) {
        $ConnectionPath = Join-Path -Path $PSScriptRoot -ChildPath "Connection"
        Remove-Module "Connection" -ErrorAction "SilentlyContinue"
        Import-Module $ConnectionPath
        Connect-Tenant -ProductNames $ProductNames -Endpoint $Endpoint
    }
}

function Import-Resources {
    <#
    .Description
    This function imports all of the various helper Provider,
    Rego, and Reporter modules to the runtime
    .Functionality
    Internal
    #>
    $ProvidersPath = Join-Path -Path $PSScriptRoot `
    -ChildPath "Providers" `
    -Resolve
    $ProviderResources = Get-ChildItem $ProvidersPath -Recurse | Where-Object { $_.Name -like 'Export*.psm1' }
    if (!$ProviderResources)
    {
        Write-Error "Provider files were not found, aborting"
        break
    }

    foreach ($Provider in $ProviderResources.Name) {
        $ProvidersPath = Join-Path -Path $PSScriptRoot -ChildPath "Providers"
        $ModulePath = Join-Path -Path $ProvidersPath -ChildPath $Provider
        Import-Module $ModulePath
    }
    $RegoPath = Join-Path -Path $PSScriptRoot -ChildPath "RunRego"
    $ReporterPath = Join-Path -Path $PSScriptRoot -ChildPath "CreateReport"
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
    .Description
    This is the function for Rego testing. Sometimes you don't want to pull the provider
    JSON every single time.
    This functions comes with the extra ExportProvider parameter to omit exporting the provider
    if set to $false
    The rego will be run on a static provider JSON in the specified OutPath.
    .Functionality
    Public
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedrive", IgnoreCase = $false)]
        [string[]]
        $ProductNames,

        [string]
        $Endpoint = "",

        # The path to the OPA executable. Defaults to this directory.
        [Parameter(Mandatory=$true)]
        [string]
        $OPAPath = $PSScriptRoot,

        [boolean]
        $LogIn = $true,

        # true to export the provider
        # false to not export
        [Parameter(Mandatory=$true)]
        [boolean]
        $ExportProvider,

        # The destination folder for the output.
        [string]
        $OutPath = $PSScriptRoot
        )
        process {
            # The equivalent of ..\..
            $ParentPath = Split-Path $PSScriptRoot -Parent
            $ParentPath = Split-Path $(Split-Path $ParentPath -Parent) -Parent

            $OutFolderPath = $OutPath
            $ProductNames = $ProductNames | Sort-Object

            # Authenticate
            $ConnectionParams = @{
                'LogIn' = $LogIn;
                'ProductNames' = $ProductNames;
                'Endpoint' = $Endpoint;
            }

            #Rego Testing
            $TenantDetails = @{"DisplayName"="Rego Testing";}
            $TenantDetails = $TenantDetails | ConvertTo-Json -Depth 3

            $ProviderParams = @{
                'ProductNames' = $ProductNames;
                'TenantDetails' = $TenantDetails;
                'OutFolderPath' = $OutFolderPath;
            }
            $RegoParams = @{
                'ProductNames' = $ProductNames;
                'OPAPath' = $OPAPath;
                'ParentPath' = $ParentPath;
                'OutFolderPath' = $OutFolderPath;
            }

            $DisplayName = $TenantDetails | ConvertFrom-Json
            $DisplayName = $DisplayName.DisplayName
            $ReportParams = @{
                'ProductNames' = $ProductNames;
                'DisplayName' = $DisplayName
                'OutFolderPath' = $OutFolderPath;
            }

            # If a PowerShell module  is updated, the changes
            # will not reflect until it is reimported into the runtime
            Remove-Resources
            Import-Resources # Imports Providers, RunRego, CreateReport

            if ($ExportProvider) {
                Invoke-Connection @ConnectionParams
                Invoke-ProviderList @ProviderParams
            }
            Invoke-RunRego @RegoParams
            Invoke-ReportCreation @ReportParams
        }
    }

Export-ModuleMember -Function @(
    'Invoke-SCuBA',
    'Invoke-RunCached'
)
