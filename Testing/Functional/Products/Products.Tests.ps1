<#
    .SYNOPSIS
    Test script for MS365 Teams product.
    .DESCRIPTION
    Test script to execute Invoke-SCuBA against a given tenant using a service
    principal. Verifies that all teams policies work properly.
    .PARAMETER Thumbprint
    Thumbprint of the certificate associated with the Service Principal.
    .PARAMETER TenantDomain
    The tenant domain name for the organization.
    .PARAMETER TenantDisplayName
    The tenant display name for the organization.
    .PARAMETER AppId
    The Application Id associated with the Service Principal and certificate.
    .PARAMETER ProductName
    The O365 product name to test
    .Parameter M365Environment
    This parameter is used to authenticate to the different commercial/government environments.
    Valid values include "commercial", "gcc", "gcchigh", or "dod".
    - For M365 tenants with E3/E5 licenses enter the value **"commercial"**.
    - For M365 Government community cloud tenants with G3/G5 licenses enter the value **"gcc"**.
    - For M365 Government community cloud High tenants enter the value **"gcchigh"**.
    - For M365 Department of Defense tenants enter the value **"dod"**.
    Default value is 'commercial'.
    .EXAMPLE
    Test using service principal
    $TestContainers = @()
    $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Thumbprint = "04C04809CC43AF66D805399D09B69069041574B0"; TenantDomain = "tqhjy.onmicrosoft.com"; TenantDisplayName = "tqhjy"; AppId = "9947b06c-46a9-4ff2-80c8-27261e58868a"; ProductName = "aad"; M365Environment = "commercial" }
    Invoke-Pester -Container $TestContainers -Output Detailed
    .EXAMPLE
    $TestContainers = @()
    $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ TenantDomain = "tqhjy.onmicrosoft.com"; TenantDisplayName = "tqhjy"; ProductName = "sharepoint"; M365Environment = "commercial" }
    Invoke-Pester -Container $TestContainers -Output Detailed
    .EXAMPLE
    $TestContainers = @()
    $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Thumbprint = "04C04809CC43AF66D805399D09B69069041574B0"; TenantDomain = "tqhjy.onmicrosoft.com"; TenantDisplayName = "tqhjy"; AppId = "9947b06c-46a9-4ff2-80c8-27261e58868a"; ProductName = "aad"; M365Environment = "commercial" }
    $PesterConfig = @{
        Run = @{
            Container = $TestContainers
        }
        Filter = @{
            Tag = @("MS.AAD.2.1v1")
        }
        Output = @{
            Verbosity = 'Detailed'
        }
    }
    $Config = New-PesterConfiguration -Hashtable $PesterConfig
    Invoke-Pester -Configuration $Config
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Thumbprint', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TenantDomain', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TenantDisplayName', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'AppId', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'M365Environment', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Variant', Justification = 'False positive as rule does not scan child scopes')]

[CmdletBinding(DefaultParameterSetName='Manual')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Auto')]
    [AllowEmptyString()]
    [string]
    $Thumbprint,
    [Parameter(Mandatory = $true, ParameterSetName = 'Auto')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
    [ValidateNotNullOrEmpty()]
    [string]
    $TenantDomain,
    [Parameter(Mandatory = $true, ParameterSetName = 'Auto')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
    [ValidateNotNullOrEmpty()]
    [string]
    $TenantDisplayName,
    [Parameter(Mandatory = $true,  ParameterSetName = 'Auto')]
    [AllowEmptyString()]
    [string]
    $AppId,
    [Parameter(Mandatory = $true,  ParameterSetName = 'Auto')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("teams", "exo", "defender", "securitysuite", "aad", "powerplatform", "sharepoint", "powerbi", IgnoreCase = $false)]
    [string]
    $ProductName,
    [Parameter(ParameterSetName = 'Auto')]
    [Parameter(ParameterSetName = 'Manual')]
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $M365Environment = 'gcc',
    [Parameter(ParameterSetName = 'Auto')]
    [Parameter(ParameterSetName = 'Manual')]
    [Parameter(Mandatory = $false)]
    [ValidateNotNull()]
    [string]
    $Variant = [string]::Empty
)

$script:ExecutionProductName = if ($ProductName -eq "defender") { "securitysuite" } else { $ProductName }

BeforeDiscovery {
    $ScubaModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules"
    $ScubaModule = Join-Path -Path $ScubaModulePath -ChildPath "../ScubaGear.psd1"
    $ConnectionModule = Join-Path -Path $ScubaModulePath -ChildPath "Connection/Connection.psm1"
    Import-Module $ScubaModule
    Import-Module $ConnectionModule

    # Convert product name to execution name (defender -> securitysuite mapping)
    $ExecutionProductName = if ($ProductName -eq "defender") { "securitysuite" } else { $ProductName }

    if ($Variant) {
        $TestPlanFileName = "TestPlans/$ExecutionProductName.$Variant.testplan.yaml"
    }
    else {
        $TestPlanFileName = "TestPlans/$ExecutionProductName.testplan.yaml"
    }
    $TestPlanPath = Join-Path -Path $PSScriptRoot -ChildPath $TestPlanFileName
    Test-Path -Path $TestPlanPath -PathType Leaf
    $YamlString = Get-Content -Path $TestPlanPath | Out-String
    $ProductTestPlan = ConvertFrom-Yaml $YamlString
    $TestPlan = $ProductTestPlan.TestPlan.ToArray()
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Tests', Justification = 'Variable is used in ScriptBlock')]
    $Tests = $TestPlan.Tests

    # Convert product name to execution name (defender -> securitysuite mapping)
    $ExecutionProductName = if ($ProductName -eq "defender") { "securitysuite" } else { $ProductName }

    if ($ExecutionProductName -eq "securitysuite") {
        $ProductNames = @($ExecutionProductName, "exo")
    }
    else {
        $ProductNames = @($ExecutionProductName)
    }

    if (-Not [string]::IsNullOrEmpty($AppId)) {
        $TempScubaConfig = New-Object -Type PSObject -Property @{
            'AppID' = $AppId;
            'CertificateThumbprint' = $Thumbprint;
            'Organization' = $TenantDomain;
        }
        $null = Get-ServicePrincipalParams -ScubaConfig $TempScubaConfig
        $M365Environment = Get-M365EnvironmentByDomain -TenantDomain $TenantDomain

        $ServicePrincipalParams = @{CertThumbprintParams = @{
            CertificateThumbprint = $Thumbprint;
            AppID = $AppId;
            Organization = $TenantDomain;
        }}
        Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment -ServicePrincipalParams $ServicePrincipalParams
    }
    else {
        Write-Debug "Manual Connect to Tenant"
        Connect-Tenant -ProductNames $ProductNames -M365Environment $M365Environment
    }
}

BeforeAll {
    # Shared Data for functional test
    $ScubaModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules"
    $ScubaModule = Join-Path -Path $ScubaModulePath -ChildPath "../ScubaGear.psd1"
    $ConnectionModule = Join-Path -Path $ScubaModulePath -ChildPath "Connection/Connection.psm1"
    Import-Module $ScubaModule
    Import-Module $ConnectionModule
    Import-Module Selenium

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ProductDetails', Justification = 'False positive as rule does not scan child scopes')]
  $ProductDetails = @{
        aad = "Azure Active Directory"
      defender = "Security Suite"
      securitysuite = "Security Suite"
        exo = "Exchange Online"
        powerbi = "Microsoft Power BI"
        powerplatform = "Microsoft Power Platform"
        sharepoint = "SharePoint Online"
        teams = "Microsoft Teams"
    }

    # Dot source utility functions
    . (Join-Path -Path $PSScriptRoot -ChildPath "FunctionalTestUtils.ps1")

    # EXO functional tests use REST-backed helper wrappers from FunctionalTestUtils.
    # Initialize EXO REST auth context for test pre/postconditions.
    # SecuritySuite/Defender tests also need EXO REST for live preconditions (6.x tests).
    if ($ProductName -in @("exo", "securitysuite", "defender")) {
        $EXOHelperPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Providers/ProviderHelpers/EXORestHelper.psm1"
        Import-Module $EXOHelperPath -Force
        $ConnectHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1"
        Import-Module $ConnectHelpersPath -Force

        $EXOScope = Get-ExchangeOnlineScope -M365Environment $M365Environment
        if (-Not [string]::IsNullOrEmpty($AppId)) {
            $script:EXOAccessToken = Get-MsalAccessToken `
                -CertificateThumbprint $Thumbprint `
                -AppID $AppId `
                -Tenant $TenantDomain `
                -M365Environment $M365Environment `
                -Scope $EXOScope
        }
        else {
            # Microsoft Exchange Online Remote PowerShell well-known client ID
            $EXOClientId = "fb78d390-0c51-40cd-8e17-fdbfab77341b"
            $script:EXOAccessToken = Get-MsalAccessToken `
                -Tenant $TenantDomain `
                -M365Environment $M365Environment `
                -ClientId $EXOClientId `
                -Scope $EXOScope
        }

        $TokenParts = $script:EXOAccessToken.Split('.')
        if ($TokenParts.Count -lt 2) {
            throw 'Unable to parse EXO access token for tenant id.'
        }

        $JwtPayload = $TokenParts[1].Replace('-', '+').Replace('_', '/')
        switch ($JwtPayload.Length % 4) {
            2 { $JwtPayload += '==' }
            3 { $JwtPayload += '=' }
        }

        $PayloadJson = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($JwtPayload))
        $Payload = $PayloadJson | ConvertFrom-Json
        $script:EXOTenantId = $Payload.tid

        if ([string]::IsNullOrWhiteSpace($script:EXOTenantId)) {
            throw 'Unable to resolve tenant id (tid) from EXO access token.'
        }

        $script:EXOApiEndpoint = Get-ExchangeOnlineApiEndpoint `
            -TenantId $script:EXOTenantId `
            -TenantDomain $TenantDomain `
            -M365Environment $M365Environment `
            -AccessToken $script:EXOAccessToken

    }

    # SharePoint functional tests: acquire SPO REST token for precondition Set-SPOTenant calls.
    # which is visible to functions dot-sourced from FunctionalTestUtils.ps1.
    if ($ProductName -eq "sharepoint") {
        $SPOHelperPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Providers/ProviderHelpers/SPORestHelper.psm1"
        Import-Module $SPOHelperPath -Force
        $ConnectHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1"
        Import-Module $ConnectHelpersPath -Force
        $DomainPrefix = $TenantDomain.Split(".")[0]
        $script:SPOAdminUrl = switch ($M365Environment) {
            "gcchigh" { "https://$DomainPrefix-admin.sharepoint.us" }
            "dod"     { "https://$DomainPrefix-admin.sharepoint-mil.us" }
            default   { "https://$DomainPrefix-admin.sharepoint.com" }
        }
        if (-Not [string]::IsNullOrEmpty($AppId)) {
            $script:SPOAccessToken = Get-MsalAccessToken `
                -CertificateThumbprint $Thumbprint `
                -AppID $AppId `
                -Tenant $TenantDomain `
                -M365Environment $M365Environment `
                -Scope "$($script:SPOAdminUrl)/.default"
        }
        else {
            $script:SPOAccessToken = Get-MsalAccessToken `
                -Tenant $TenantDomain `
                -M365Environment $M365Environment `
                -ClientId "9bc3ab49-b65d-410a-85ad-de819febfddc" `
                -Scope "$($script:SPOAdminUrl)/.default"
        }
    }

    # Power Platform functional tests: acquire REST token for precondition helper calls.
    # Must be in BeforeAll (not InModuleScope) so $script: refers to this file's scope,
    # which is visible to functions dot-sourced from FunctionalTestUtils.ps1.
    if ($ProductName -eq "powerplatform") {
        $PPHelperPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Providers/ProviderHelpers/PowerPlatformRestHelper.psm1"
        Import-Module $PPHelperPath -Force
        $ConnectHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1"
        Import-Module $ConnectHelpersPath -Force
        $script:PPBaseUrl = Get-PowerPlatformBaseUrl -M365Environment $M365Environment
        $PPScope = Get-PowerPlatformScope -M365Environment $M365Environment
        if (-Not [string]::IsNullOrEmpty($AppId)) {
            $script:PPAccessToken = Get-MsalAccessToken `
                -CertificateThumbprint $Thumbprint `
                -AppID $AppId `
                -Tenant $TenantDomain `
                -M365Environment $M365Environment `
                -Scope $PPScope
        }
        else {
            $script:PPAccessToken = Get-MsalAccessToken `
                -Tenant $TenantDomain `
                -M365Environment $M365Environment `
                -ClientId "1950a258-227b-4e31-a9cf-717495945fc2" `
                -Scope $PPScope
        }
    }

    # Power BI functional tests: acquire REST token for precondition helper calls.
    # Must be in BeforeAll (not InModuleScope) so $script: refers to this file's scope,
    # which is visible to functions dot-sourced from FunctionalTestUtils.ps1.
    if ($ProductName -eq "powerbi") {
        $PBIHelperPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Providers/ProviderHelpers/PowerBIRestHelper.psm1"
        Import-Module $PBIHelperPath -Force
        $ConnectHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Connection/ConnectHelpers.psm1"
        Import-Module $ConnectHelpersPath -Force
        $script:PBIBaseUrl = Get-PowerBIBaseUrl -M365Environment $M365Environment
        $PBIScope = Get-PowerBIScope -M365Environment $M365Environment
        if (-Not [string]::IsNullOrEmpty($AppId)) {
            $script:PBIAccessToken = Get-MsalAccessToken `
                -CertificateThumbprint $Thumbprint `
                -AppID $AppId `
                -Tenant $TenantDomain `
                -M365Environment $M365Environment `
                -Scope $PBIScope
        }
        else {
            $script:PBIAccessToken = Get-MsalAccessToken `
                -Tenant $TenantDomain `
                -M365Environment $M365Environment `
                -ClientId "1950a258-227b-4e31-a9cf-717495945fc2" `
                -Scope $PBIScope
        }
    }

    function SetConditions {
        [CmdletBinding(DefaultParameterSetName = 'Actual')]
        param(
            [Parameter(Mandatory = $true, ParameterSetName = 'Actual')]
            [Parameter(Mandatory = $true, ParameterSetName = 'Cached')]
            [AllowEmptyCollection()]
            [array]
            $Conditions,
            [Parameter(Mandatory = $true, ParameterSetName = 'Cached')]
            [string]
            $OutputFolder
        )

        ForEach($Condition in $Conditions){
            $Splat = $Condition.Splat
            if ('Cached' -eq $PSCmdlet.ParameterSetName){
                $Splat.Add("OutputFolder", [string]$OutputFolder)
            }
            if ($Splat) {
                $ScriptBlock = [ScriptBlock]::Create("$($Condition.Command) @Splat")
            }
            else {
                $ScriptBlock = [ScriptBlock]::Create("$($Condition.Command)")
            }
            try {
                $ScriptBlock.Invoke()
            }
            catch {
                Write-Error "Exception: SetConditions failed. $_"
            }
        }
    }

  function RunScuba() {
        $ExecutionProductName = if ($ProductName -eq "defender") { "securitysuite" } else { $ProductName }
        if (-not [string]::IsNullOrEmpty($Thumbprint))
        {
            Invoke-SCuBA -CertificateThumbPrint $Thumbprint -AppId $AppId -Organization $TenantDomain -Productnames $ExecutionProductName -OutPath . -Quiet -KeepIndividualJSON -SilenceBODWarnings
        }
        else {
            if ($ProductName -eq 'exo') {
                Invoke-SCuBA -Productnames $ExecutionProductName -OutPath . -M365Environment $M365Environment -Quiet -KeepIndividualJSON -SilenceBODWarnings
            }
            else {
                Invoke-SCuBA -Login $false -Productnames $ExecutionProductName -OutPath . -M365Environment $M365Environment -Quiet -KeepIndividualJSON -SilenceBODWarnings
            }
        }
    }

}

Describe "Policy Checks for <ProductName>" {
    Context "Start tests for policy <PolicyId>" -ForEach $TestPlan {
        BeforeEach {
            $script:RunScubaError = $null
            $script:Driver = $null

            try {
            # Select which TestDriver to use for a given test plan. TestDriver names (e.g. RunScuba, ScubaCached) must
            # match exactly (including case) the ones used in TestPlans.
            if ($ConfigFileName -and ('RunScuba' -eq $TestDriver)){
                $ExecutionProductName = if ($ProductName -eq "defender") { "securitysuite" } else { $ProductName }
                $FullPath = Join-Path -Path $PSScriptRoot -ChildPath "TestConfigurations/$ExecutionProductName/$PolicyId/$ConfigFileName"

                $ScubaConfig = Get-Content -Path $FullPath | ConvertFrom-Yaml

                if ($AppId){
                    $ScubaConfig.CertificateThumbprint = $Thumbprint
                    $ScubaConfig.AppID = $AppId
                    $ScubaConfig.Organization = $TenantDomain
                }

                $ScubaConfig.M365Environment = $M365Environment

                $TestConfigPath = "$TestDrive\$ProductName\$PolicyId"
                $TestConfigFilePath = Join-Path -Path $TestConfigPath -ChildPath $ConfigFileName

                if (-not (Test-Path -Path $TestConfigPath -PathType Container)){
                    New-Item -Path $TestConfigPath -ItemType Directory
                }

                Set-Content -Path $TestConfigFilePath -Value ($ScubaConfig | ConvertTo-Yaml)
                SetConditions -Conditions $Preconditions.ToArray()
                Invoke-SCuBA -ConfigFilePath $TestConfigFilePath -Quiet -KeepIndividualJSON
                $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
                $script:OutputFolder = $ReportFolders[0].Name

            }
            # Ensure case matches driver in test plan
            elseif ('RunScuba' -eq $TestDriver){
                Write-Debug "Driver: RunScuba"
                SetConditions -Conditions $Preconditions.ToArray()
                RunScuba
                $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
                $script:OutputFolder = $ReportFolders[0].Name
                Write-Debug "Created Output folder (RunScuba) $script:OutputFolder"

            }
            # ScubaCached driver using shared cache
            elseif ('ScubaCached' -eq $TestDriver){
                Write-Debug "Driver: ScubaCached"

                if ($null -eq $script:OutputFolder) {
                    RunScuba
                    $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
                    $script:OutputFolder = $ReportFolders[0].Name
                }

                Write-Debug "Output folder (ScubaCached) $script:OutputFolder"
                SetConditions -Conditions $Preconditions.ToArray() -OutputFolder $script:OutputFolder

                if (-not (Test-Path -Path "$script:OutputFolder/ModifiedProviderSettingsExport.json" -PathType Leaf)){
                    Copy-Item -Path "$script:OutputFolder/ProviderSettingsExport.json" -Destination "$script:OutputFolder/ModifiedProviderSettingsExport.json"
                }

                # Call Scuba cached with the modified provider JSON as an input which gets passed to Rego
                $ExecutionProductName = if ($ProductName -eq "defender") { "securitysuite" } else { $ProductName }
                Invoke-SCuBACached -Productnames $ExecutionProductName -ExportProvider $false -OutPath "$script:OutputFolder" -OutProviderFileName 'ModifiedProviderSettingsExport' -Quiet -KeepIndividualJSON -SilenceBODWarnings

                # Save the ModifiedProviderSettingsExport so that it can be referenced during dev testing of functional test scenarios
                $SavedModifiedProviderFileName = "ModifiedProviderSettingsExport-{0}-{1}.json" -f (Get-Date -Format "yyyyMMdd_HHmmss_fff"), [guid]::NewGuid()
                # $SavedModifiedProviderFileName = "ModifiedProviderSettingsExport-$([guid]::NewGuid()).json"
                $SavedModifiedProviderFilePath = Join-Path $script:OutputFolder $SavedModifiedProviderFileName
                Copy-Item -Path "$script:OutputFolder/ModifiedProviderSettingsExport.json" -Destination $SavedModifiedProviderFilePath

                # Delete the modified settings so next test scenario starts from original cached settings
                Remove-Item -Path "$script:OutputFolder/ModifiedProviderSettingsExport.json"
            }

            else {
                Write-Debug "Driver: $TestDriver"
                Write-Error "Invalid Test Driver: $TestDriver"
            }

            $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
            $OutputFolder = $ReportFolders[0]
            Write-Debug "OutputFolder: $OutputFolder"
            $IntermediateRegoOutput = LoadRegoOutput($OutputFolder)
            # Search the results object for the specific requirement we are validating and ensure the results are what we expect
            $CandidatePolicyIds = @($PolicyId)
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ComparisonPolicyId', Justification = 'Variable is used in ScriptBlock')]
            $ComparisonPolicyId = $CandidatePolicyIds[-1]
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'PolicyResultObj', Justification = 'Variable is used in ScriptBlock')]
            $PolicyResultObj = $IntermediateRegoOutput | Where-Object { $_.PolicyId -in $CandidatePolicyIds }
            $BaselineReports = Join-Path -Path $OutputFolder -ChildPath 'BaselineReports.html'
            $Url = (Get-Item $BaselineReports).FullName
            try {
                $Driver = Start-SeChrome -Headless -Quiet -Arguments @('start-maximized', 'AcceptInsecureCertificates') -Verbose -ImplicitWait 1000
            }
            catch {
                # Sometimes Selenium fails to start in a timely manner.  When that happens,
                # simply try again.  This is a very simplistic attempt to solve the problem,
                # but it seems to work.
                $Driver = Start-SeChrome -Headless -Quiet -Arguments @('start-maximized', 'AcceptInsecureCertificates') -Verbose -ImplicitWait 1000
            }
            Open-SeUrl $Url -Driver $Driver | Out-Null
            }
            catch {
                $script:RunScubaError = $_
                Write-Warning "Functional setup failed for policy [$PolicyId]: $($_.Exception.Message)"
            }
        }
        Context "Execute test, <TestDescription>" -ForEach $Tests {
            It "Check test case results" -Tag $PolicyId {
                if ($null -ne $script:RunScubaError) {
                    throw "Functional setup failed before assertions for [$PolicyId]: $($script:RunScubaError.Exception.Message)`n$($script:RunScubaError.ScriptStackTrace)"
                }

                if ($IsNotChecked) {
                    return
                }

                #Check intermediate output
                ($PolicyResultObj.RequirementMet).Count | Should -BeExactly 1 -Because "only expect a single result for a policy"
                $PolicyResultObj.RequirementMet | Should -Be $ExpectedResult
                $Details = $PolicyResultObj.ReportDetails
                $Details | Should -Not -BeNullOrEmpty -Because "expect details, $Details"

                # Check final HTML output
                $FoundPolicy = $false
                $ExecutionProductNameForLookup = if ($ProductName -eq "defender") { "securitysuite" } else { $ProductName }
                $ExecutionProductNameForLookup | Should -Not -BeNullOrEmpty -Because "execution product name must be set for policy [$PolicyId]"
                $DetailLinkText = $ProductDetails[$ExecutionProductNameForLookup]
                $DetailLinkText | Should -Not -BeNullOrEmpty -Because "product detail link text must exist for execution product [$ExecutionProductNameForLookup]"
                $DetailLink = Get-SeElement -Driver $Driver -Wait -By LinkText $DetailLinkText
                $DetailLink | Should -Not -BeNullOrEmpty
                Invoke-SeClick -Element $DetailLink

                # For better performance turn off implict wait
                $Driver.Manage().Timeouts().ImplicitWait = New-TimeSpan -Seconds 0

                $Tables = Get-SeElement -Driver $Driver -By TagName 'table'
                $Tables.Count | Should -BeGreaterThan 1

                ForEach ($Table in $Tables) {
                    $Rows = Get-SeElement -Element $Table -By TagName 'tr'

                    $TableClass = $Table.GetAttribute("class")
                    $ExpectedColumnSize = Get-ExpectedColumnSize -TableClass $TableClass
                    $ExpectedHeaders = Get-ExpectedHeaderNames -TableClass $TableClass

                    if ($Table.GetProperty("id") -eq "tenant-data"){
                        $Rows.Count | Should -BeGreaterThan 1 -Because "tenant-data table should include header and one data row"
                        if ($Rows.Count -lt 2) {
                            continue
                        }
                        $Rows[1] | Should -Not -BeNullOrEmpty -Because "tenant-data table row is missing for policy [$PolicyId]"
                        $TenantDataColumns = Get-SeElement -Target $Rows[1] -By TagName "td"
                        $TenantDataColumns | Should -Not -BeNullOrEmpty -Because "tenant-data columns are missing for policy [$PolicyId]"
                        $Tenant = $TenantDataColumns[0].Text
                        $Tenant | Should -Be $TenantDisplayName -Because "Tenant is $Tenant"
                    }
                    elseif (
                        $TableClass -eq "caps_table" -or
                        $TableClass -eq "riskyApps_table" -or
                        $TableClass -eq "riskyThirdPartySPs_table"
                    ) {
                        $Rows.Count | Should -BeGreaterThan 0
                        ForEach ($Row in $Rows){
                            $RowHeaders = Get-SeElement -Element $Row -By TagName 'th'
                            $RowData = Get-SeElement -Element $Row -By TagName 'td'

                            ($RowHeaders.Count -eq 0 ) -xor ($RowData.Count -eq 0) | Should -BeTrue -Because "Any given row should be homogenious"

                            # Length of columns depends on the type of table, refer to $ExpectedColumnSize declared above for more information.
                            if ($RowHeaders.Count -gt 0 -and $null -ne $ExpectedHeaders){
                                $RowHeaders.Count | Should -BeExactly $ExpectedColumnSize

                                for ($i = 0; $i -lt $RowHeaders.Count; $i++) {
                                    $RowHeaders[$i].text | Should -BeLikeExactly $ExpectedHeaders[$i] -Because "Table header column $i should match $($ExpectedHeaders[$i])"
                                }
                            }

                            if ($RowData.Count -gt 0){
                                $RowData.Count | Should -BeExactly $ExpectedColumnSize
                            }
                        }
                    }
                    elseif ($Table.GetProperty("id") -eq "license-info") {
                        #Currently empty to determine if necessary and what to test in section
                        $Rows.Count | Should -BeGreaterThan 0
                    }
                    elseif ($Table.GetProperty("id") -eq "privileged-service-principals"){
                        $Rows.Count | Should -BeGreaterThan 0
                        $RowHeaders = Get-SeElement -Element $Rows[0] -By TagName 'th'
                        $RowHeaders.Count | Should -BeExactly 4
                    }
                    elseif ($Table.GetProperty("id") -eq "privileged-users"){
                        $Rows.Count | Should -BeGreaterThan 0
                        $RowHeaders = Get-SeElement -Element $Rows[0] -By TagName 'th'
                        $RowHeaders.Count | Should -BeExactly 4
                        $RowHeaders[0].text | Should -BeLikeExactly "Display Name"
                        $RowHeaders[1].text | Should -BeLikeExactly "Object ID"
                        $RowHeaders[2].text | Should -BeLikeExactly "Roles"
                        $RowHeaders[3].text | Should -BeLikeExactly "On-Prem Immutable ID"
                    }
                    elseif ($null -ne $Table.GetAttribute("class") -and $Table.GetAttribute("class").Contains("dns-table")) {
                        foreach ($Row in $Rows) {
                            $RowHeaders = Get-SeElement -Element $Row -By TagName 'th'
                            $RowData = Get-SeElement -Element $Row -By TagName 'td'

                            if ($RowHeaders.Count -gt 0){
                                $RowHeaders.Count | Should -BeExactly 4
                                $RowHeaders[0].text | Should -BeLikeExactly "Query Name"
                                $RowHeaders[1].text | Should -BeLikeExactly "Query Method"
                                $RowHeaders[2].text | Should -BeLikeExactly "Summary"
                                $RowHeaders[3].text | Should -BeLikeExactly "Answers"
                            }

                            if ($RowData.Count -gt 0){
                                $RowData.Count | Should -BeExactly 4
                            }
                        }
                    }
                    else {
                        $Rows.Count | Should -BeGreaterThan 0

                        # Control report tables
                        ForEach ($Row in $Rows) {
                            $RowHeaders = Get-SeElement -Element $Row -By TagName 'th'
                            $RowData = Get-SeElement -Element $Row -By TagName 'td'

                            ($RowHeaders.Count -eq 0 ) -xor ($RowData.Count -eq 0) | Should -BeTrue -Because "Any given row should be homogenious"

                            if ($RowHeaders.Count -gt 0){
                                $RowHeaders.Count | Should -BeExactly 5
                                $RowHeaders[0].text | Should -BeLikeExactly "Control ID"
                            }

                            if ($RowData.Count -gt 0){
                                $RowData.Count | Should -BeExactly 5

                                if ($RowData[0].text -eq $ComparisonPolicyId) {
                                    $FoundPolicy = $true
                                    $Msg = "Output folder: $OutputFolder; Expected: $ExpectedResult; Result: $($RowData[2].text); Details: $($RowData[4].text)"

                                    if ($IsNotChecked){
                                        $RowData[2].text | Should -BeLikeExactly "N/A" -Because "policies that are not checked should be N/A. [$Msg]"
                                    }
                                    elseif ($true -eq $ExpectedResult) {
                                        $RowData[2].text | Should -BeLikeExactly "Pass" -Because "expected policy to pass. [$Msg]"
                                        IsEquivalence -First $RowData[4].GetAttribute("innerHTML") -Second $PolicyResultObj.ReportDetails | Should -BeTrue
                                    }
                                    elseif ($null -ne $ExpectedResult ) {
                                        if ('Shall' -eq $RowData[3].text) {
                                        $RowData[2].text | Should -BeLikeExactly "Fail" -Because "expected policy to fail. [$Msg]"
                                        }
                                        elseif ('Should' -eq $RowData[3].text){
                                        $RowData[2].text | Should -BeLikeExactly "Warning" -Because "expected policy to warn. [$Msg]"
                                        }
                                        else {
                                        $RowData[2].text | Should -BeLikeExactly "Unknown" -Because "unexpected criticality. [$Msg]"
                                        }
                                        IsEquivalence -First $RowData[4].GetAttribute("innerHTML") -Second $PolicyResultObj.ReportDetails | Should -BeTrue
                                    }
                                    else {
                                        $false | Should -BeTrue -Because "policy should be custom, not checked, or have and expected result. [$Msg]"
                                    }
                                }
                            }
                        }
                    }
                }

                $FoundPolicy | Should -BeTrue -Because "all policies should have a result. [Requested=$PolicyId, Compared=$ComparisonPolicyId]"
                # Turn implict wait back on
                $Driver.Manage().Timeouts().ImplicitWait = New-TimeSpan -Seconds 10
            }
        }
        AfterEach {
            SetConditions -Conditions $Postconditions.ToArray()
            if ($null -ne $Driver) {
                Stop-SeDriver -Driver $Driver | Out-Null
            }
        }
    }
}
