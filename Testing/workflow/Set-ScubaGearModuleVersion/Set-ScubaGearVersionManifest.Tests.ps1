BeforeDiscovery {
    $ImportPath = "../../../utils/workflow/Set-ScubaGearModuleVersion.psm1"
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ImportPath) -Function Set-ScubaGearVersionManifest -Force
}

Describe "Check ScubaGear manifest location" {
    It "Should exist" {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ManifestPath')]
        $ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/ScubaGear.psd1"
        {Test-Path $MantifestPath} | Should -Be $true
    }
}

# Sanity check test
Describe 'Make the ScubaGear Manifest Version change' {
    InModuleScope Set-ScubaGearModuleVersion {
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