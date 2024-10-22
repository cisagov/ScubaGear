BeforeDiscovery {
    $ImportPath = "../../../utils/workflow/Set-ScubaGearModuleVersion.psm1"
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ImportPath) -Function New-PRBody -Force
}

Describe "Check PR template location" {
    It "Should exist" {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'TemplatePath')]
        $TemplatePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../.github/pull_request_template.md"
        {Test-Path $TemplatePath} | Should -Be $true
    }
}

# Sanity check test
Describe "Create the Pull Request Body" {
    InModuleScope Set-ScubaGearModuleVersion {
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