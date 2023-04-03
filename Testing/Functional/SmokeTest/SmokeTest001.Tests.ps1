$ScubaModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/ScubaGear.psd1"
Import-Module $ScubaModulePath

Describe "Smoke Test: Generate Output" {
    BeforeAll {
        Invoke-SCuBA -CertificateThumbprint $Env:Thumbprint -AppID $Env:AppId -Organization $Env:Organization -ProductNames "*" -M365Environment "gcc"
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
        @{Item = 'IndividualReports/AADReport'; ItemType = 'Leaf'},
        @{Item = 'IndividualReports/DefenderReport'; ItemType = 'Leaf'},
        @{Item = 'IndividualReports/EXOReport'; ItemType = 'Leaf'},
        @{Item = 'IndividualReports/OneDriveReport'; ItemType = 'Leaf'},
        @{Item = 'IndividualReports/PowerPlatformReport'; ItemType = 'Leaf'},
        @{Item = 'IndividualReports/SharePointReport'; ItemType = 'Leaf'},
        @{Item = 'IndividualReports/TeamsReport'; ItemType = 'Leaf'}
    ){
        Test-Path -Path "./$OutputFolder/$Item" -PathType $ItemType |
            Should -Be $true
	}
}
