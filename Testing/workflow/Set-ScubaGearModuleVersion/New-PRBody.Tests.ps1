[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

BeforeDiscovery {
    $ImportPath = "../../../utils/workflow/Set-ScubaGearModuleVersion.psm1"
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ImportPath) -Function New-PRBody -Force
}

# This a sanity check test to make sure nothing went wrong. 
# Correctness test will require a refactor of the orginal function
InModuleScope Set-ScubaGearModuleVersion {
    BeforeAll {}
    context 'Create the Pull Request Body'{
        It 'Should not crash' {
            Mock -CommandName Get-Content {}
            Mock -CommandName ForEach-Object {}
            {New-PRBody} | Should -Not -Throw
        }
    }
}


AfterAll {
    Remove-Module Set-ScubaGearModuleVersion -ErrorAction SilentlyContinue
}