BeforeAll {
    $ScubaModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/ScubaGear.psd1"
    Import-Module $ScubaModulePath
   }

Describe "Smoke Test <Config>" -ForEach @(
    @{ConfigPath = "SmokeTestConfig001.yaml"; ExpectedResults = "SmokeTestExpected001.json"},
    @{ConfigPath = "SmokeTestConfig002.yaml"; ExpectedResults = "SmokeTestExpected002.json"}
){
    It "Config: <ConfigPath>; Expected: <ExpectedResults>" {
        Invoke-SCuBA -CertificateThumbprint $Env:Thumbprint -AppID $Env:AppId -Organization $Env:Organization -ProductNames "onedrive" -M365Environment "gcc"
        $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
        $OutputFolder = $ReportFolders[0]
        Test-Path -Path ".\$OutputFolder\TestResults.json" -PathType Leaf |
            Should -Be $true
	}
}
