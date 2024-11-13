BeforeDiscovery {
    $ImportPath = "../../../utils/workflow/Set-ScubaGearModuleVersion.psm1"
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ImportPath) -Function Set-ScubaGearVersionDoc -Force
}

Describe "Check installation via GitHub documentation location" {
    It "Should exist" {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'DocPath')]
        $DocPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../docs/installation/github.md"
        {Test-Path $DocPath} | Should -Be $true
    }
}

Describe "Check installation via PSGallery documentation location" {
    It "Should exist" {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'DocPath')]
        $DocPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../docs/installation/psgallery.md"
        {Test-Path $DocPath} | Should -Be $true
    }
}

# Sanity check test
Describe "Make ScubaGear Module version change" {
    InModuleScope Set-ScubaGearModuleVersion {
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