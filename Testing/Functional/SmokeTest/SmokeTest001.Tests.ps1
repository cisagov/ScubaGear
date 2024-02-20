<#
    .SYNOPSIS
    Test script to verify Invoke-SCuBA file outputs.
    .DESCRIPTION
    Test script to execute Invoke-SCuBA against a given tenant using a service
    principal. Verifies that all expected products (i.e., files) are generated.
    .PARAMETER Thumbprint
    Thumbprint of the certificate associated with the Service Principal.
    .PARAMETER Organization
    The tenant domain name for the organization.
    .PARAMETER AppId
    The Application Id associated with the Service Principal and certificate.
    .EXAMPLE
    $TestContainer = New-PesterContainer -Path "SmokeTest001.Tests.ps1" -Data @{ Thumbprint = $Thumbprint; Organization = "cisaent.onmicrosoft.com"; AppId = $AppId }
    Invoke-Pester -Container $TestContainer -Output Detailed
    .EXAMPLE
    Invoke-Pester -Script .\Testing\Functional\SmokeTest\SmokeTest001.Tests.ps1 -Output Detailed

#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Thumbprint', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Organization', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'AppId', Justification = 'False positive as rule does not scan child scopes')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'M365Environment', Justification = 'False positive as rule does not scan child scopes')]
[CmdletBinding(DefaultParameterSetName='Manual')]
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
    [Parameter(ParameterSetName = 'Auto')]
    [Parameter(ParameterSetName = 'Manual')]
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $M365Environment = 'gcc'
)

$ScubaModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/ScubaGear.psd1"
Import-Module $ScubaModulePath

Describe "Smoke Test: Generate Output" {
    Context "Invoke Scuba for $Organization" {
        BeforeAll {
            if ($PSCmdlet.ParameterSetName -eq 'Manual'){
                { Invoke-SCuBA -ProductNames "*" -M365Environment $M365Environment -Quiet} |
                Should -Not -Throw
            }
            else {
                { Invoke-SCuBA -CertificateThumbprint $Thumbprint -AppID $AppId -Organization $Organization -ProductNames "*" -M365Environment $M365Environment -Quiet} |
                Should -Not -Throw
            }
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
            @{Item = 'IndividualReports/ENTRAIDReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/DefenderReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/EXOReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/PowerPlatformReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/SharePointReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/TeamsReport.html'; ItemType = 'Leaf'},
            @{Item = 'IndividualReports/images'; ItemType = 'Container'}
        ){
            Test-Path -Path "./$OutputFolder/$Item" -PathType $ItemType |
                Should -Be $true
        }
    }
    Context "Verify exported functions for ScubaGear module" {
        BeforeAll{
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ScubaGearExportedFunctions',
            Justification = 'Variable is used in another scope')]
            $ScubaGearExportedFunctions = @(
                'Disconnect-SCuBATenant',
                'Invoke-RunCached',
                'Invoke-SCuBA',
                'Copy-ScubaBaselineDocument',
                'Copy-ScubaSampleConfigFile',
                'Copy-ScubaSampleReport'
            )
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ExportedCommands',
            Justification = 'Variable is used in another scope')]
            $ExportedCommands = (Get-Module -Name ScubaGear).ExportedCommands
        }
        It "Is <_> exported?" -ForEach $ScubaGearExportedFunctions {
            $ExportedCommands | Should -Contain $_
        }
    }
    Context "Verify Copy* exported commands" -ForEach @(
        @{Command='Copy-ScubaBaselineDocument'; CopiedFiles=@(
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/entraid.md"),
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/defender.md"),
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/exo.md"),
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/powerbi.md"),
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/powerplatform.md"),
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/sharepoint.md"),
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/teams.md")
        )},
        @{Command='Copy-ScubaSampleConfigFile'; CopiedFiles=@(
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/samples/config-files/entraid-config.yaml"),
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/samples/config-files/defender-config.yaml"),
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/samples/config-files/sample-config.json"),
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/samples/config-files/sample-config.yaml")
        )},
        @{Command='Copy-ScubaSampleReport'; CopiedFiles=@(
            (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/samples/reports/BaselineReports.html")
        )}
    ){
        It "Validate call to <Command>" {
            {& $Command -Force} | Should -Not -Throw
        }
        It "Validate <Command> copied file <_>" -ForEach $CopiedFiles {
            Test-Path -Path $_ -PathType Leaf | Should -BeTrue
        }
    }
}