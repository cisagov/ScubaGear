BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
}

Describe -Tag 'Orchestrator' -Name 'Invoke-ReportCreation' {
    InModuleScope Orchestrator {
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
    }
}