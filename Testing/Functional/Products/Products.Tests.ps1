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
    - For M365 Government Commercial Cloud tenants with G3/G5 licenses enter the value **"gcc"**.
    - For M365 Government Commercial Cloud High tenants enter the value **"gcchigh"**.
    - For M365 Department of Defense tenants enter the value **"dod"**.
    Default value is 'commercial'.
    .EXAMPLE
    Test using service principal
    $TestContainers = @()
    $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Thumbprint = "04C04809CC43AF66D805399D09B69069041574B0"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; AppId = "9947b06c-46a9-4ff2-80c8-27261e58868a"; ProductName = "aad"; M365Environment = "commercial" }
    Invoke-Pester -Container $TestContainers -Output Detailed
    .EXAMPLE
    $TestContainers = @()
    $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; ProductName = "sharepoint"; M365Environment = "commercial" }
    Invoke-Pester -Container $TestContainers -Output Detailed
    .EXAMPLE
    $TestContainers = @()
    $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Thumbprint = "04C04809CC43AF66D805399D09B69069041574B0"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; AppId = "9947b06c-46a9-4ff2-80c8-27261e58868a"; ProductName = "aad"; M365Environment = "commercial" }
    $PesterConfig = @{
        Run = @{
            Container = $TestContainers
        }
        Filter = @{
            Tag = @("MS.AAD.5.4v1")
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
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ProductName', Justification = 'False positive as rule does not scan child scopes')]
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
    [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", IgnoreCase = $false)]
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

$ScubaModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules"
$ScubaModule = Join-Path -Path $ScubaModulePath -ChildPath "../ScubaGear.psd1"
$ConnectionModule = Join-Path -Path $ScubaModulePath -ChildPath "Connection/Connection.psm1"
Import-Module $ScubaModule
Import-Module $ConnectionModule
Import-Module Selenium

BeforeDiscovery{

    if ($Variant) {
        $TestPlanFileName = "TestPlans/$ProductName.$Variant.testplan.yaml"
    }
    else {
        $TestPlanFileName = "TestPlans/$ProductName.testplan.yaml"
    }
    $TestPlanPath = Join-Path -Path $PSScriptRoot -ChildPath $TestPlanFileName
    Test-Path -Path $TestPlanPath -PathType Leaf

    $YamlString = Get-Content -Path $TestPlanPath | Out-String
    $ProductTestPlan = ConvertFrom-Yaml $YamlString
    $TestPlan = $ProductTestPlan.TestPlan.ToArray()
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Tests', Justification = 'Variable is used in ScriptBlock')]
    $Tests = $TestPlan.Tests

    InModuleScope Connection -Parameters @{
        ProductName = $ProductName
        M365Environment = $M365Environment
        Thumbprint = $Thumbprint
        AppId = $AppId
        TenantDomain = $TenantDomain
    }{
        if ($ProductName -eq "defender"){
            $ProductNames = @($ProductName, "exo")
        }
        else {
            $ProductNames = @($ProductName)
        }

        if (-Not [string]::IsNullOrEmpty($AppId)){
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
}

BeforeAll{
    # Shared Data for functional test
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ProductDetails', Justification = 'False positive as rule does not scan child scopes')]
    $ProductDetails = @{
        aad = "Azure Active Directory"
        defender = "Microsoft 365 Defender"
        exo = "Exchange Online"
        powerplatform = "Microsoft Power Platform"
        sharepoint = "SharePoint Online"
        teams = "Microsoft Teams"
    }

    # Dot source utility functions
    . (Join-Path -Path $PSScriptRoot -ChildPath "FunctionalTestUtils.ps1")

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

            if ($Splat ) {
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
        if (-not [string]::IsNullOrEmpty($Thumbprint))
        {
            Invoke-SCuBA -CertificateThumbPrint $Thumbprint -AppId $AppId -Organization $TenantDomain -Productnames $ProductName -OutPath . -M365Environment $M365Environment -Quiet
        }
        else {
            Invoke-SCuBA -Login $false -Productnames $ProductName -OutPath . -M365Environment $M365Environment -Quiet
        }
    }
}

Describe "Policy Checks for <ProductName>"{
    Context "Start tests for policy <PolicyId>" -ForEach $TestPlan{
        BeforeEach{

            if ($ConfigFileName -and ('RunScuba' -eq $TestDriver)){
                $FullPath = Join-Path -Path $PSScriptRoot -ChildPath "TestConfigurations/$ProductName/$PolicyId/$ConfigFileName"

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
                Invoke-SCuBA -ConfigFilePath $TestConfigFilePath -Quiet
            }
            elseif ('RunScuba' -eq $TestDriver){
                Write-Debug "Driver: RunScuba"
                SetConditions -Conditions $Preconditions.ToArray()
                RunScuba
            }
            elseif ('RunCached' -eq $TestDriver){
                Write-Debug "Driver: RunCached"
                RunScuba
                $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
                $OutputFolder = $ReportFolders[0].Name
                SetConditions -Conditions $Preconditions.ToArray() -OutputFolder $OutputFolder
                Invoke-RunCached -Productnames $ProductName -ExportProvider $false -OutPath $OutputFolder -OutProviderFileName 'ModifiedProviderSettingsExport' -Quiet
            }
            else {
                Write-Debug "Driver: $TestDriver"
                Write-Error "Invalid Test Driver: $TestDriver"
            }

            $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
            $OutputFolder = $ReportFolders[0]
            Write-Debug "OutputFolder: $OutputFolder"
            $IntermediateTestResults = LoadTestResults($OutputFolder)
            # Search the results object for the specific requirement we are validating and ensure the results are what we expect
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'PolicyResultObj', Justification = 'Variable is used in ScriptBlock')]
            $PolicyResultObj = $IntermediateTestResults | Where-Object { $_.PolicyId -eq $PolicyId }
            $BaselineReports = Join-Path -Path $OutputFolder -ChildPath 'BaselineReports.html'
            $Url = (Get-Item $BaselineReports).FullName
            $Driver = Start-SeChrome -Headless -Quiet -Arguments @('start-maximized', 'AcceptInsecureCertificates')
            Open-SeUrl $Url -Driver $Driver | Out-Null
        }
        Context "Execute test, <TestDescription>" -ForEach $Tests {
            It "Check test case results" -Tag $PolicyId {

                #Check intermediate output
                ($PolicyResultObj.RequirementMet).Count | Should -BeExactly 1 -Because "only expect a single result for a policy"
                $PolicyResultObj.RequirementMet | Should -Be $ExpectedResult

                $Details = $PolicyResultObj.ReportDetails
                $Details | Should -Not -BeNullOrEmpty -Because "expect details, $Details"

                if ($IsNotChecked){
                    $Details | Should -Match 'Not currently checked automatically.'
                }

                if ($IsCustomImplementation){
                    $Details | Should -Match 'Custom implementation allowed.'
                }

                # Check final HTML output
                $FoundPolicy = $false
                $DetailLink = Get-SeElement -Driver $Driver -Wait -By LinkText $ProductDetails.$ProductName
                $DetailLink | Should -Not -BeNullOrEmpty
                Invoke-SeClick -Element $DetailLink

                # For better performance turn off implict wait
                $Driver.Manage().Timeouts().ImplicitWait = New-TimeSpan -Seconds 0

                $Tables = Get-SeElement -Driver $Driver -By TagName 'table'
                $Tables.Count | Should -BeGreaterThan 1

                ForEach ($Table in $Tables){
                    $Rows = Get-SeElement -Element $Table -By TagName 'tr'
                    $Rows.Count | Should -BeGreaterThan 0

                    if ($Table.GetProperty("id") -eq "tenant-data"){
                        $Rows.Count | Should -BeExactly 2
                        $TenantDataColumns = Get-SeElement -Target $Rows[1] -By TagName "td"
                        $Tenant = $TenantDataColumns[0].Text
                        $Tenant | Should -Be $TenantDisplayName -Because "Tenant is $Tenant"
                    }
                    elseif ($Table.GetAttribute("class") -eq "caps_table"){
                        ForEach ($Row in $Rows){
                            $RowHeaders = Get-SeElement -Element $Row -By TagName 'th'
                            $RowData = Get-SeElement -Element $Row -By TagName 'td'

                            ($RowHeaders.Count -eq 0 ) -xor ($RowData.Count -eq 0) | Should -BeTrue -Because "Any given row should be homogenious"

                            # NOTE: Checking for 8 columns since first is 'expand' column
                            if ($RowHeaders.Count -gt 0){
                                $RowHeaders.Count | Should -BeExactly 8
                                $RowHeaders[1].text | Should -BeLikeExactly "Name"
                            }

                            if ($RowData.Count -gt 0){
                                $RowData.Count | Should -BeExactly 8
                            }
                        }
                    }
                    else {
                        # Control report tables
                        ForEach ($Row in $Rows){
                            $RowHeaders = Get-SeElement -Element $Row -By TagName 'th'
                            $RowData = Get-SeElement -Element $Row -By TagName 'td'

                            ($RowHeaders.Count -eq 0 ) -xor ($RowData.Count -eq 0) | Should -BeTrue -Because "Any given row should be homogenious"

                            if ($RowHeaders.Count -gt 0){
                                $RowHeaders.Count | Should -BeExactly 5
                                $RowHeaders[0].text | Should -BeLikeExactly "Control ID"
                            }

                            if ($RowData.Count -gt 0){
                                $RowData.Count | Should -BeExactly 5

                                if ($RowData[0].text -eq $PolicyId){
                                    $FoundPolicy = $true
                                    $Msg = "Output folder: $OutputFolder; Expected: $ExpectedResult; Result: $($RowData[2].text); Details: $($RowData[4].text)"

                                    if ($IsCustomImplementation){
                                        $RowData[2].text | Should -BeLikeExactly "N/A" -Because "custom policies should not have results. [$Msg]"
                                        $RowData[4].text | Should -Match 'Custom implementation allowed.'
                                    }
                                    elseif ($IsNotChecked){
                                        $RowData[2].text | Should -BeLikeExactly "N/A" -Because "custom policies should not have results. [$Msg]"
                                        $RowData[4].text | Should -Match 'Not currently checked automatically.'
                                    }
                                    elseif ($true -eq $ExpectedResult) {
                                        $RowData[2].text | Should -BeLikeExactly "Pass" -Because "expected policy to pass. [$Msg]"
                                        $RowData[4].GetAttribute("innerHTML") | FromInnerHtml | Should -BeExactly $PolicyResultObj.ReportDetails
                                    }
                                    elseif ($null -ne $ExpectedResult ) {
                                        if ('Shall' -eq $RowData[3].text){
                                            $RowData[2].text | Should -BeLikeExactly "Fail" -Because "expected policy to fail. [$Msg]"
                                        }
                                        elseif ('Should' -eq $RowData[3].text){
                                            $RowData[2].text | Should -BeLikeExactly "Warning" -Because "expected policy to warn. [$Msg]"
                                        }
                                        else {
                                            $RowData[2].text | Should -BeLikeExactly "Unknown" -Because "unexpected criticality. [$Msg]"
                                        }

                                        $RowData[4].GetAttribute("innerHTML") | FromInnerHtml | Should -BeExactly $PolicyResultObj.ReportDetails
                                    }
                                    else {
                                        $false | Should -BeTrue -Because "policy should be custom, not checked, or have and expected result. [$Msg]"
                                    }
                                }
                            }
                        }
                    }
                }

                $FoundPolicy | Should -BeTrue -Because "all policies should have a result. [$PolicyId]"
                # Turn implict wait back on
                $Driver.Manage().Timeouts().ImplicitWait = New-TimeSpan -Seconds 10
            }
        }
        AfterEach {
            SetConditions -Conditions $Postconditions.ToArray()
            Stop-SeDriver -Driver $Driver | Out-Null
        }
    }
}