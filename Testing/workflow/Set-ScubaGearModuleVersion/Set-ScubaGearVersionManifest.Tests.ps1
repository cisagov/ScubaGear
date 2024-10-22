[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeDiscovery {
    $ImportPath = "../../../utils/workflow/Set-ScubaGearModuleVersion.psm1"
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ImportPath) -Function Set-ScubaGearVersionManifest -Force
}

# This a sanity check test to make sure nothing went wrong. 
# Correctness test will require a refactor of the orginal function
InModuleScope Set-ScubaGearModuleVersion {
    context 'Make the ScubaGear Manifest Version change'{
        It 'should not crash' {
            Mock -CommandName Get-Content {}
            Mock -CommandName ForEach-Object {}
            Mock -CommandName Set-Content {}
            {Set-ScubaGearVersionManifest} | Should -Not -Throw
        }
    }
}


AfterAll {
    Remove-Module Set-ScubaGearModuleVersion -ErrorAction SilentlyContinue
}