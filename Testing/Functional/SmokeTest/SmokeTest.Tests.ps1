BeforeAll {
    Import-Module "$($PSScriptRoot)/../../../../../PowerShell/ScubaGear/ScubaGear.psd1"
    Invoke-SCuBA -CertificateThumbprint $Env:Thumbprint -AppID $Env:AppId -Organization $Env:Organization -ProductNames "onedrive" -M365Environment "gcc"
}

Describe "Valid Json" {
    It "returns 'None' when no users are included" {
        $ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
        $OutputFolder = $ReportFolders[0]
        Test-Path -Path ".\$OutputFolder\TestResults.json" -PathType Leaf |
            Should -Be $true
	}
}