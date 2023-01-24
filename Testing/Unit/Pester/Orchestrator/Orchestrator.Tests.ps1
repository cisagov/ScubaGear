# TODO: Decompose Orchestrator into individual function tests

BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
}

Describe 'Orchestrator' {
    InModuleScope Orchestrator{
        It 'Invoke-Scuba: given the product name will validate configuration' {
            #Invoke-Scuba -Login $True -ProductNames @("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", "onedirve") -Endpoint "usgov" -OPAPath "./" -OutPath output #just make sure that this runs completely there isnt really much to test
            $ProductNames = @("teams")
            $M365Environment = "gcc"
            $OPAPath = "../"
            $OutPath = "output"
            Invoke-Scuba -Login $True -ProductNames $ProductNames -M365Environment $M365Environment -OPAPath $OPAPath -OutPath $OutPath #just make sure that this runs completely there isnt really much to test
            $LASTEXITCODE | Should -Be 0
        }

        It 'Invoke-ProviderList' {
            $OutFolderPath = "./output"
            $OutProviderFileName = "ProviderSettingsExport"
            $ProductNames = @("teams")
            $M365Environment = "gcc"
            $TenantDetails = Get-TenantDetail -ProductNames $ProductNames -M365Environment $M365Environment
            Invoke-ProviderList -ProductNames $ProductNames -M365Environment $M365Environment -TenantDetails $TenantDetails -OutFolderPath $OutFolderPath -OutProviderfileName $OutProviderFileName
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

        It 'Invoke-RunRego' {
            #how to call this?
            $ProductNames = @("teams")
            $OPAPath = "../"
            $ParentPath = "../"
            $CurFolderPath = "./"
            $OutFolderPath = get-childitem $CurFolderPath -Directory | sort-object LastWriteTime -Descending | select-object -First 1
            $OutProviderFileName = "ProviderSettingsExport"
            $OutRegoFileName = "TestResults"
            Invoke-RunRego -ProductNames $ProductNames -OPAPath $OPAPath -ParentPath $ParentPath -OutFolderPath $OutFolderPath -OutProviderFileName $OutProviderFileName -OutRegoFileName $OutRegoFileName
            $output = Get-Content -path "$($OutFolderPath)/$($OutRegoFileName).json"
            $b = $false
            if ($output)
            {$b = $true}
            $b | should -Be $true
        }

        It 'Invoke-ReportCreation' {
            $ProductNames = @("teams")
            $M365Environment = "gcc"
            $TenantDetails = Get-TenantDetail -ProductNames $ProductNames -M365Environment $M365Environment
            $OutFolderPath = "./"
            $OutProviderFileName = "ProviderSettingsExport"
            $OutRegoFileName = "TestResults"
            $OutReportName = "BaselineReports"
            Invoke-ReportCreation -ProductNames $ProductNames -TenantDetails $TenantDetails -OutFolderPath $OutFolderPath -OutProviderFileName $OutProviderFileName -OutRegoFileName $OutRegoFileName -OutReportName $OutReportName
            test-path "$($OutFolderPath)/$($OutReportName).html" | should -Be $true
        }

        It 'Get-TenantDetail' {
            $ProductNames = @("teams")
            $M365Environment = "gcc"
            $output = Get-TenantDetail -ProductNames $ProductNames -M365Environment $M365Environment
            $ValidJson = $true
            try {
                ConvertFrom-Json $output -ErrorAction Stop;
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson| Should -Be $true

        }

        It 'Invoke-Connection' {
            $ProductNames = @("teams")
            $LogIn = $true
            $M365Environment = "gcc"
            Invoke-Connection -LogIn $LogIn -ProductNames $ProductNames -M365Environment $M365Environment
            $LASTEXITCODE | Should -Be 0
        }

        It 'Import-Resources' {
            Import-Resources
            $LASTEXITCODE | Should -Be 0
        }

        It 'Remove-Resources' {
            Remove-Resources
            $LASTEXITCODE | Should -Be 0
        }
    }
}
