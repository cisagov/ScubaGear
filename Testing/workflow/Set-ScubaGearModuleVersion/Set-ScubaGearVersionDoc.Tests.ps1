[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeDiscovery {
    $ImportPath = "../../../utils/workflow/Set-ScubaGearModuleVersion.psm1"
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ImportPath) -Function Set-ScubaGearVersionDoc -Force
}

# This a sanity check test to make sure nothing went wrong. 
# Correctness test will require a refactor of the orginal function
InModuleScope Set-ScubaGearModuleVersion {
    BeforeAll {}
    context 'Make the Documentation Version change'{
        It 'Should not crash' {
            Mock -CommandName Get-Content {}
            Mock -CommandName ForEach-Object {}
            Mock -CommandName Set-Content {}
            {Set-ScubaGearVersionDoc} | Should -Not -Throw
        }
    }
}


AfterAll {
    Remove-Module Set-ScubaGearModuleVersion -ErrorAction SilentlyContinue
}