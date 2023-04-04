<#
    .SYNOPSIS
    Test script to verify Invoke-SCuBA file outputs.
    .DESCRIPTION
    Test script to execute Invoke-SCuBA against a given tenant using a service
    principal. Verifies that all expected products (i.e., files) are generated.
    .PARAMETER Thumbprint
    Thumbprint of thee certificate associated with the Service Principal.
    .PARAMETER Organization
    The tenant domain name for the organization.
    .PARAMETER AppId
    The Application Id associated with the Service Principal and certificate.
    .EXAMPLE
    $TestContainer = New-PesterContainer -Path "SmokeTest001.Tests.ps1" -Data @{ Thumbprint = $Thumbprint; Organization = "cisaent.onmicrosoft.com"; AppId = $AppId }
    Invoke-Pester -Container $TestContainer -Output Detailed

#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Thumbprint', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Organization', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'AppId', Justification = 'False positive as rule does not scan child scopes')]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Thumbprint,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Organization,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $AppId
)

$ScubaModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/ScubaGear.psd1"
Import-Module $ScubaModulePath

Describe "Smoke Test: Generate Output" {
    Context "Invoke Scuba for $Organization" {
        BeforeAll {
            Invoke-SCuBA -CertificateThumbprint $Thumbprint -AppID $AppId -Organization $Organization -ProductNames "*" -M365Environment "gcc"
            $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'OutputFolder',
            Justification = 'Variable is used in another scope')]
            $OutputFolder = $ReportFolders[0]
        }
        It "Item, <Item>, exists" -ForEach @(
            @{Item = 'BaselineReports.html'; ItemType = 'Leaf'},
            @{Item = 'TestResults.json'; ItemType = 'Leaf'},
            @{Item = 'TestResults.csv'; ItemType = 'Leaf'},
            @{Item = 'ProviderSettingsExport.json'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports'; ItemType = 'Container'},
            @{Item = 'IndividualReports/AADReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/DefenderReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/EXOReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/OneDriveReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/PowerPlatformReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/SharePointReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/TeamsReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/images'; ItemType = 'Container'},
            @{Item = 'IndividualReports/images/angle-down-solid.svg'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/images/angle-right-solid.svg'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/images/cisa_logo.png'; ItemType = 'Leaf'}
        ){
            Test-Path -Path "./$OutputFolder/$Item" -PathType $ItemType |
                Should -Be $true
        }    }
}
