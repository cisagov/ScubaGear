$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Out-Utf8NoBom' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Out-Utf8NoBom' {
        BeforeAll {
            function Invoke-WriteAllLines {}
            Mock -ModuleName Orchestrator Invoke-WriteAllLines

            # Setup test directories for testing
            New-Item -ItemType Directory './a/b' -Force -ErrorAction Ignore
            New-Item -ItemType Directory './c' -Force -ErrorAction Ignore
            New-Item -ItemType Directory './shared/a/b' -Force -ErrorAction Ignore
            New-Item -ItemType Directory './shared/c' -Force -ErrorAction Ignore
            #New-SmbShare -Name "Shared" -Path ".\shared" -ReadAccess "Everyone"
        }

        Context 'local file' {
            It 'Set to root drive path' {
                Out-Utf8NoBom -Content "test" -Location "C:\" -FileName "output.json" `
                | Should -Be "C:\output.json"
            }

            It 'Set to absolute subdirectory path' {
                Out-Utf8NoBom -Content "test" -Location "$pwd\a" -FileName "output.json" `
                | Should -Be "$pwd\a\output.json"
            }
        }

        Context 'relative paths' {
            It 'Set to subdirectory relative path' {
                Out-Utf8NoBom -Content "test" -Location "a" -FileName "output.json" `
                | Should -Be "$pwd\a\output.json"
            }

            It 'Set to subdirectory local relative path' {
                Out-Utf8NoBom -Content "test" -Location ".\a" -FileName "output.json" `
                | Should -Be "$pwd\a\output.json"
            }

            It 'Set to subdirectory processing .. and .' {
                Out-Utf8NoBom -Content "test" -Location "a\b\..\..\c\." -FileName "output.json" `
                | Should -Be "$pwd\c\output.json"
            }
        }

        Context 'Check for re-root in path' {
            It 'Does not re-root subdirectory' {
                Out-Utf8NoBom -Content "test" -Location "a\d\..\b\." -FileName "output.json" `
                | Should -Be "$pwd\a\b\output.json"
            }

            It 'Does not re-root subdirectory rooted at local' {
                Out-Utf8NoBom -Content "test" -Location ".\a\d\..\b\." -FileName "output.json" `
                | Should -Be "$pwd\a\b\output.json"
            }

            It 'Does not re-root parent' {
                Out-Utf8NoBom -Content "test" -Location "..\$((Get-Item .).Name)\a\d\..\b\." -FileName "output.json" `
                | Should -Be "$pwd\a\b\output.json"
            }
        }

        # Uses default C$ share to test building UNC paths that exist
        Context 'UNC path' {
            It 'Set to shared UNC path' {
                Out-Utf8NoBom -Content "test" -Location "\\$env:COMPUTERNAME\C$" -FileName "output.json" `
                | Should -Be "\\$env:COMPUTERNAME\C$\output.json"
            }

            It 'Set to shared UNC path' {
                Out-Utf8NoBom -Content "test" -Location "\\$env:COMPUTERNAME\C$" -FileName "output.json" `
                | Should -Be "\\$env:COMPUTERNAME\C$\output.json"
            }
        }

        AfterAll {
            Remove-Module Orchestrator -ErrorAction SilentlyContinue
            Remove-Item -Path "./c" -Force -ErrorAction Ignore
            Remove-Item -Path "./a" -Recurse -Force -ErrorAction Ignore
        }
    }
}
