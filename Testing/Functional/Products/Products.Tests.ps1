<#
    .SYNOPSIS
    Test script for MS365 Teams product.
    .DESCRIPTION
    Test script to execute Invoke-SCuBA against a given tenant using a service
    principal. Verifies that all teams policies work properly.
    .PARAMETER Thumbprint
    Thumbprint of the certificate associated with the Service Principal.
    .PARAMETER Organization
    The tenant domain name for the organization.
    .PARAMETER AppId
    The Application Id associated with the Service Principal and certificate.
    .EXAMPLE
    $TestContainer = New-PesterContainer -Path "Teams.Tests.ps1" -Data @{ Thumbprint = $Thumbprint; Organization = "cisaent.onmicrosoft.com"; AppId = $AppId }
    Invoke-Pester -Container $TestContainer -Output Detailed
    .EXAMPLE
    Invoke-Pester -Script .\Testing\Functional\Auto\Products\Teams\Teams.Tests.ps1 -Output Detailed

#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Thumbprint', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Organization', Justification = 'False positive as rule does not scan child scopes')]
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
    [ValidateNotNullOrEmpty()]
    [string]
    $Organization,
    [Parameter(Mandatory = $true,  ParameterSetName = 'Auto')]
    [ValidateNotNullOrEmpty()]
    [string]
    $AppId,
    [Parameter(Mandatory = $true,  ParameterSetName = 'Auto')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Report')]
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
    $Tests = $TestPlan.Tests

    if (-not [string]::IsNullOrEmpty($Thumbprint)){
        $ServicePrincipalParams += @{CertThumbprintParams = @{
            CertificateThumbprint = $Thumbprint;
            AppID = $AppId;
            Organization = $Organization;
        }}
        Connect-Tenant -ProductNames $ProductName -M365Environment $M365Environment -ServicePrincipalParams $ServicePrincipalParams
    }
    else {
        Connect-Tenant -ProductNames $ProductName -M365Environment $M365Environment
    }



BeforeAll{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ProductDetails', Justification = 'False positive as rule does not scan child scopes')]
    $ProductDetails = @{
        aad = "Azure Active Directory"
        defender = "Microsoft 365 Defender"
        exo = "Exchange Online"
        powerplatform = "Microsoft Power Platform"
        sharepoint = "SharePoint Online"
        teams = "Microsoft Teams"
    }

    function SetConditions {
        param(
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]
            $Conditions
        )

        ForEach($Condition in $Conditions){
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Splat', Justification = 'Variable is used in ScriptBlock')]
            $Splat = $Condition.Splat
            $ScriptBlock = [ScriptBlock]::Create("$($Condition.Command) @Splat")

            try {
                $ScriptBlock.Invoke()
            }
            catch [Newtonsoft.Json.JsonReaderException]{
                Write-Error $PSItem.ToString()
            }
        }
    }

    function ExecuteScubagear() {
        # Execute ScubaGear to extract the config data and produce the output JSON
        Invoke-SCuBA -CertificateThumbPrint $Thumbprint -AppId $AppId -Organization $Organization -Productnames $ProductName -OutPath . -M365Environment $M365Environment -Quiet

    }

    function LoadSPOTenantData($OutputFolder) {
        $SPOTenant = Get-Content "$OutputFolder/TestResults.json" -Raw | ConvertFrom-Json
        $SPOTenant
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
            SetConditions -Conditions $Preconditions.ToArray()
            ExecuteScubagear
            $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
            $OutputFolder = $ReportFolders[0]
            $SPOTenant = LoadSPOTenantData($OutputFolder)
            # Search the results object for the specific requirement we are validating and ensure the results are what we expect
            $PolicyResultObj = $SPOTenant | Where-Object { $_.PolicyId -eq $PolicyId }
            $BaselineReports = Join-Path -Path $OutputFolder -ChildPath 'BaselineReports.html'
            $script:url = (Get-Item $BaselineReports).FullName
            $Driver = Start-SeChrome -Headless -Arguments @('start-maximized') 2>$null
            Open-SeUrl $script:url -Driver $Driver 2>$null
        }
        Context "Execute test, <TestDescription>" -ForEach $Tests {
            It "Check intermediate results" {

                # Check intermediate output 
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
                        $Tenant | Should -Be $OrganizationName -Because "Tenant is $Tenant"
                    } else {
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
                                        $RowData[4].text | Should -Match 'Requirement met'
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

                                        $RowData[4].text | Should -Not -BeNullOrEmpty
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
