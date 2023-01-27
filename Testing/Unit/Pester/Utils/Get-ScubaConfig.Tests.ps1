$private:ExecutingTestPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Path
Import-Module -Name $(Join-Path -Path $private:ExecutingTestPath -ChildPath '..\..\..\..\PowerShell\ScubaGear\Modules\Utils\ScubaConfig.psm1')

Describe -tag "Utils" -name 'ScubaConfig' {
    Context 'General case'{
        It 'Good folder name'{
            { Get-ScubaConfig -Path '.'} |
                Should -Throw -ExpectedMessage "Cannot validate argument on parameter 'Path'. SCuBA configuration Path argument must be a file."
        }
        It 'Bad file name throws exception' {
            { Get-ScubaConfig -Path "Bad file name" } |
                Should -Throw -ExpectedMessage "Cannot validate argument on parameter 'Path'. SCuBA configuration file or folder does not exist."
        }
    }
    context 'JSON Configuration' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ScubaConfigTestFile')]
            $ScubaConfigTestFile = Join-Path -Path $PSScriptRoot -ChildPath config_test.json
        }
        BeforeEach {
            Remove-ScubaConfig
        }
        It 'Valid config file'{
            { Get-ScubaConfig -Path $ScubaConfigTestFile } |
                Should -Not -Throw
        }
        It 'Valid string parameter'{
            Get-ScubaConfig -Path $ScubaConfigTestFile
            $ScubaConfig.M365Environment | Should -Be 'commercial'
        }
        It 'Valid array parameter'{
            Get-ScubaConfig -Path $ScubaConfigTestFile
            $ScubaConfig.ProductNames | Should -Contain 'aad'
        }
        It 'Valid boolean parameter'{
            Get-ScubaConfig -Path $ScubaConfigTestFile
            $ScubaConfig.DisconnectOnExit | Should -Be $false
        }
        It 'Valid object parameter'{
            Get-ScubaConfig -Path $ScubaConfigTestFile
            $ScubaConfig.AnObject.name | Should -Be 'MyObjectName'
        }
    }
    context 'YAML Configuration' {
        BeforeAll {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'ScubaConfigTestFile')]
            $ScubaConfigTestFile = Join-Path -Path $PSScriptRoot -ChildPath config_test.yaml
        }
        BeforeEach {
            Remove-ScubaConfig
        }
        It 'Valid config file'{
            { Get-ScubaConfig -Path $ScubaConfigTestFile} |
                Should -Not -Throw
        }
        It 'Valid string parameter'{
            Get-ScubaConfig -Path $ScubaConfigTestFile
            $ScubaConfig.M365Environment | Should -Be 'commercial'
        }
        It 'Valid array parameter'{
            Get-ScubaConfig -Path $ScubaConfigTestFile
            $ScubaConfig.ProductNames | Should -Contain 'aad'
        }
        It 'Valid boolean parameter'{
            Get-ScubaConfig -Path $ScubaConfigTestFile
            $ScubaConfig.DisconnectOnExit | Should -Be $false
        }
        It 'Valid object parameter'{
            Get-ScubaConfig -Path $ScubaConfigTestFile
            $ScubaConfig.AnObject.name | Should -Be 'MyObjectName'
        }
    }
}