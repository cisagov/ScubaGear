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
