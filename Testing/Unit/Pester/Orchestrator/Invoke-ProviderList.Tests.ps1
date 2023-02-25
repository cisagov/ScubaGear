BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Providers/ExportTeamsProvider.psm1
    Mock -ModuleName Orchestrator
}

Describe -Tag 'Orchestrator' -Name 'Invoke-ProviderList' {
    InModuleScope Orchestrator {
        It 'Invoke-ProviderList' {
            $OutFolderPath = "./output"
            $OutProviderFileName = "ProviderSettingsExport"
            $ProductNames = @("teams")
            $M365Environment = "gcc"
            $TenantDetails = Get-TenantDetail -ProductNames $ProductNames -M365Environment $M365Environment

            Invoke-ProviderList -ProductNames $ProductNames -M365Environment $M365Environment -TenantDetails $TenantDetails -ModuleVersion $ModuleVersion -OutFolderPath $OutFolderPath -OutProviderfileName $OutProviderFileName

            $Path = Join-Path -Path "$($OutFolderPath)" -ChildPath "$($OutProviderFileName).json"
            $output = Get-Content -Path $Path | Out-String
            $ValidJson = $true
            try {
                ConvertFrom-Json $output -ErrorAction Stop
            }
            catch {
                $ValidJson = $false;
                Write-Warning " $($_)"
            }
            $ValidJson | Should -Be $true
        }
    }
}