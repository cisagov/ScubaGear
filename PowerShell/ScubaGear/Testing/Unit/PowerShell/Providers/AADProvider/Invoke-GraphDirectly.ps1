$ProviderPath = '../../../../../Modules/Providers'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportAADProvider.psm1") -Function 'Get-PrivilegedRole' -Force

InModuleScope ExportAADProvider {
    Describe -Tag 'AADProvider' -Name "Invoke-GraphDirectly" {
        BeforeAll {
            #function Invoke-MgGraphRequest {return @{Value = @{cowsound = "moo"}}
            Mock -ModuleName ExportAADProvider Invoke-MgGraphRequest {return @{Value = @{cowsound = "moo"}}}
        }

        It "should return the expected value from Invoke-MgGraphRequest" {
            $expected = @{cowsound = "moo"}
            $result = Invoke-Graphdirectly("Get-MgBetaUser")
            $result.Keys | Should -Be $expected.Keys
            $result.Values | Should -Be $expected.Values
        }
    }
}

AfterAll {
    Remove-Module ExportAADProvider -Force -ErrorAction SilentlyContinue
}
