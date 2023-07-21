#Requires -Modules @{ ModuleName='Selenium'; ModuleVersion='3.0.0'}
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
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Thumbprint', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TenantDomain', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TenantDisplayName', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'AppId', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ProductName', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'M365Environment', Justification = 'False positive as rule does not scan child scopes')]

[CmdletBinding(DefaultParameterSetName='Auto')]
param (
    [Parameter(Mandatory = $true, ParameterSetName = 'Auto')]
    [ValidateNotNullOrEmpty()]
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
    [ValidateNotNullOrEmpty()]
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
    $M365Environment = 'gcc'
)

$ScubaModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/ScubaGear.psd1"
Import-Module $ScubaModulePath
Import-Module Selenium

BeforeDiscovery{
    $TestPlanPath = Join-Path -Path $PSScriptRoot -ChildPath "TestPlans/$ProductName.testplan.yaml"
    Test-Path -Path $TestPlanPath -PathType Leaf

    $YamlString = Get-Content -Path $TestPlanPath | Out-String
    $ProductTestPlan = ConvertFrom-Yaml $YamlString
    $TestPlan = $ProductTestPlan.TestPlan.ToArray()
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Tests', Justification = 'Variable is used in ScriptBlock')]
    $Tests = $TestPlan.Tests

    $ServicePrincipalParams = @{CertThumbprintParams = @{
        CertificateThumbprint = $Thumbprint;
        AppID = $AppId;
        Organization = $TenantDomain;
    }}

    InModuleScope Connection -Parameters @{
        ProductName = $ProductName
        M365Environment = $M365Environment
        ServicePrincipalParams = $ServicePrincipalParams
    }{
        if (-not [string]::IsNullOrEmpty($ServicePrincipalParams.CertThumbprintParams)){

            Connect-Tenant -ProductNames $ProductName -M365Environment $M365Environment -ServicePrincipalParams $ServicePrincipalParams
        }
        else {
            Connect-Tenant -ProductNames $ProductName -M365Environment $M365Environment
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
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Splat', Justification = 'Variable is used in ScriptBlock')]
            $Splat = $Condition.Splat

            if ('Cached' -eq $PSCmdlet.ParameterSetName){
                Write-Output "Setting output folder to: $OutputFolder"
                $Splat.Add("OutputFolder", [string]$OutputFolder)
            }

            $ScriptBlock = [ScriptBlock]::Create("$($Condition.Command) @Splat")

            try {
                $ScriptBlock.Invoke()
            }
            catch {
                Write-Error $PSItem.ToString()
            }
        }
    }

    function UpdateProviderExport{
        param(
            [Parameter(Mandatory = $true)]
            [AllowNull()]
            [object]
            $Updates,
            [Parameter(Mandatory = $true)]
            [string]
            $OutputFolder
        )

        $ProviderExport = LoadProviderExport($OutputFolder)

        foreach ($Update in $Updates.ToArray()){
            $Key = $Update.Key
            $ProviderExport.$Key = $Update.Value
        }

        PublishProviderExport -OutputFolder $OutputFolder -Export $ProviderExport

    }

    function RunScuba() {
        # Execute ScubaGear to extract the config data and produce the output JSON
        Invoke-SCuBA -CertificateThumbPrint $Thumbprint -AppId $AppId -Organization $TenantDomain -Productnames $ProductName -OutPath . -M365Environment $M365Environment -Quiet
    }

    function LoadTestResults($OutputFolder) {
        $IntermediateTestResults = Get-Content "$OutputFolder/TestResults.json" -Raw | ConvertFrom-Json
        $IntermediateTestResults
    }
    function LoadProviderExport($OutputFolder) {
        if (-not (Test-Path -Path "$OutputFolder/ModifiedProviderSettingsExport.json" -PathType Leaf)){
            Copy-Item -Path "$OutputFolder/ProviderSettingsExport.json" -Destination "$OutputFolder/ModifiedProviderSettingsExport.json"
        }

        $ProviderExport = Get-Content "$OutputFolder/ModifiedProviderSettingsExport.json" -Raw | ConvertFrom-Json
        $ProviderExport
    }

    function PublishProviderExport() {
        param(
            [Parameter(Mandatory = $true)]
            [string]
            $OutputFolder,
            [Parameter(Mandatory = $true)]
            [object]
            $Export
        )
        $Json = $Export | ConvertTo-Json -Depth 10 | Out-String
        Set-Content -Path "$OutputFolder/ModifiedProviderSettingsExport.json" -Value $Json
    }

    function RemoveConditionalAccessPolicyByName{
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $DisplayName
        )

        $Ids = Get-MgIdentityConditionalAccessPolicy | Where-Object {$_.DisplayName -match $DisplayName} | Select-Object -Property Id

       foreach($Id in $Ids){
            if (-not ([string]::IsNullOrEmpty($Id.Id))){
                Write-Output "Removing $DisplayName with id of $($Id.Id)"
                Remove-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $Id.Id
            }
        }
    }

    function UpdateConditionalAccessPolicyByName{
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $DisplayName,
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [hashtable]
            $Updates
        )

        $Ids = Get-MgIdentityConditionalAccessPolicy | Where-Object {$_.DisplayName -match $DisplayName} | Select-Object -Property Id

        foreach($Id in $Ids){
            if (-not ([string]::IsNullOrEmpty($Id.Id))){
                Write-Output "Updating $DisplayName with id of $($Id.Id)"
                Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $Id.Id @Updates
                break
            }
        }
    }
}

Describe "Policy Checks for <ProductName>"{
    Context "Start tests for policy <PolicyId>" -ForEach $TestPlan{
        BeforeEach{
            if ('RunScuba' -eq $TestDriver){
                SetConditions -Conditions $Preconditions.ToArray()
                RunScuba
            }
            elseif ('RunCached' -eq $TestDriver){
                RunScuba
                $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
                $OutputFolder = $ReportFolders[0].Name
                SetConditions -Conditions $Preconditions.ToArray() -OutputFolder $OutputFolder
                Invoke-RunCached -Productnames $ProductName -ExportProvider $false -OutPath $OutputFolder -OutProviderFileName 'ModifiedProviderSettingsExport' -Quiet
            }
            else {
                Write-Error -Message "Invalid Test Driver: $TestDriver"
            }

            $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
            $OutputFolder = $ReportFolders[0]
            $IntermediateTestResults = LoadTestResults($OutputFolder)
            # Search the results object for the specific requirement we are validating and ensure the results are what we expect
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'PolicyResultObj', Justification = 'Variable is used in ScriptBlock')]
            $PolicyResultObj = $IntermediateTestResults | Where-Object { $_.PolicyId -eq $PolicyId }
            $BaselineReports = Join-Path -Path $OutputFolder -ChildPath 'BaselineReports.html'
            $script:url = (Get-Item $BaselineReports).FullName
            $Driver = Start-SeChrome -Headless -Arguments @('start-maximized') 2>$null
            Open-SeUrl $script:url -Driver $Driver 2>$null
        }
        Context "Execute test, <TestDescription>" -ForEach $Tests {
            It "Check test case results" {

                #Check intermediate output
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
            Stop-SeDriver -Driver $Driver 2>$null
        }
    }
}
