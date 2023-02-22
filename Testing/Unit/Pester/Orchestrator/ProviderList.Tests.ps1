# param($ModuleVersion)

BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Providers/ExportTeamsProvider.psm1
    Mock -ModuleName Orchestrator
}

# Write-Host("(Outside Describe) Module version is: ")
# Write-Host($ModuleVersion)

Describe 'Invoke-ProviderList' {
    # Write-Host($ModuleVersion)
    InModuleScope Orchestrator {
        It 'Invoke-ProviderList' {
            $OutFolderPath = "./output"
            $OutProviderFileName = "ProviderSettingsExport"
            $ProductNames = @("teams")
            $M365Environment = "gcc"
            $TenantDetails = Get-TenantDetail -ProductNames $ProductNames -M365Environment $M365Environment

            #$ModuleVersion = param($ModuleVersion)

            # Write-Host("Module version is: ")
            # Write-Host($ModuleVersion)
            #$ModuleVersion = 0.0

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