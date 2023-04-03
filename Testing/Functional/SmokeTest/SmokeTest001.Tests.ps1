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
        @{Item = 'IndividualReports'; ItemType = 'Container'}
    ){
        Test-Path -Path "./$OutputFolder/$Item" -PathType $ItemType |
            Should -Be $true
	}
}
