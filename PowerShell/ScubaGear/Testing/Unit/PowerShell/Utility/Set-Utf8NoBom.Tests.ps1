$UtilityPath = '../../../../Modules/Utility/Utility.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $UtilityPath) -Function 'Set-Utf8NoBom' -Force

InModuleScope Utility {
    Describe -Tag 'Utility' -Name 'Set-Utf8NoBom' {
        BeforeAll {
            function Invoke-WriteAllLines {}
            Mock -ModuleName Utility Invoke-WriteAllLines

            # Setup test directories for testing
            New-Item -ItemType Directory './a/b' -Force -ErrorAction Ignore
            New-Item -ItemType Directory './c' -Force -ErrorAction Ignore
            New-Item -ItemType Directory './shared/a/b' -Force -ErrorAction Ignore
            New-Item -ItemType Directory './shared/c' -Force -ErrorAction Ignore
            #New-SmbShare -Name "Shared" -Path ".\shared" -ReadAccess "Everyone"
        }

        Context 'local file' {
            It 'Set to root drive path' {
                Set-Utf8NoBom -Content "test" -Location "C:\" -FileName "output.json" `
                | Should -Be "C:\output.json"
            }

            It 'Set to absolute subdirectory path' {
                Set-Utf8NoBom -Content "test" -Location "$pwd\a" -FileName "output.json" `
                | Should -Be "$pwd\a\output.json"
            }
        }

        Context 'relative paths' {
            It 'Set to subdirectory relative path' {
                Set-Utf8NoBom -Content "test" -Location "a" -FileName "output.json" `
                | Should -Be "$pwd\a\output.json"
            }

            It 'Set to subdirectory local relative path' {
                Set-Utf8NoBom -Content "test" -Location ".\a" -FileName "output.json" `
                | Should -Be "$pwd\a\output.json"
            }

            It 'Set to subdirectory processing .. and .' {
                Set-Utf8NoBom -Content "test" -Location "a\b\..\..\c\." -FileName "output.json" `
                | Should -Be "$pwd\c\output.json"
            }
        }

        Context 'Check for re-root in path' {
            It 'Does not re-root subdirectory' {
                Set-Utf8NoBom -Content "test" -Location "a\d\..\b\." -FileName "output.json" `
                | Should -Be "$pwd\a\b\output.json"
            }

            It 'Does not re-root subdirectory rooted at local' {
                Set-Utf8NoBom -Content "test" -Location ".\a\d\..\b\." -FileName "output.json" `
                | Should -Be "$pwd\a\b\output.json"
            }

            It 'Does not re-root parent' {
                Set-Utf8NoBom -Content "test" -Location "..\$((Get-Item .).Name)\a\d\..\b\." -FileName "output.json" `
                | Should -Be "$pwd\a\b\output.json"
            }
        }

        # Uses default C$ share to test building UNC paths that exist
        Context 'UNC path' {
            It 'Set to shared UNC path' {
                Set-Utf8NoBom -Content "test" -Location "\\$env:COMPUTERNAME\C$" -FileName "output.json" `
                | Should -Be "\\$env:COMPUTERNAME\C$\output.json"
            }

            It 'Set to shared UNC path' {
                Set-Utf8NoBom -Content "test" -Location "\\$env:COMPUTERNAME\C$" -FileName "output.json" `
                | Should -Be "\\$env:COMPUTERNAME\C$\output.json"
            }
        }

        AfterAll {
            Remove-Module Utility -ErrorAction SilentlyContinue
            Remove-Item -Path "./c" -Force -ErrorAction Ignore
            Remove-Item -Path "./a" -Recurse -Force -ErrorAction Ignore
        }
    }
}
