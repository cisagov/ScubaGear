BeforeAll {
    Import-Module ../../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
}

Describe -Tag 'Orchestrator' -Name 'Invoke-RunRego' {
    InModuleScope Orchestrator {
        It 'Invoke-RunRego' {
            #how to call this?
            $ProductNames = @("teams")
            $OPAPath = "../../../../"
            $ParentPath = "../../../../"
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
    }
}
