$UtilityPath = '../../../../Modules/Utility/Utility.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $UtilityPath) -Function 'Set-Utf8NoBom' -Force

InModuleScope Utility {
    Describe -Tag 'Utility' -Name 'Set-Utf8NoBom Pathing' {
        BeforeAll {
            function Invoke-WriteAllText { return "Pass" }
            Mock -ModuleName Utility Invoke-WriteAllText

            # Setup test directories for testing
            Push-Location $TestDrive
            New-Item -ItemType Directory "$TestDrive\a\b" -Force -ErrorAction Ignore
            New-Item -ItemType Directory "$TestDrive\c" -Force -ErrorAction Ignore
        }

        Context 'local file' {
            It 'Set to root drive path' {
                Set-Utf8NoBom -Content "test" -Location "C:\" -FileName "output.json" `
                | Should -Be "C:\output.json"
            }

            It 'Set to absolute subdirectory path' {
                Set-Utf8NoBom -Content "test" -Location "$TestDrive\a" -FileName "output.json" `
                | Should -Be "$TestDrive\a\output.json"
            }
        }

        Context 'relative paths' {
            It 'Set to subdirectory relative path' {
                Set-Utf8NoBom -Content "test" -Location "a" -FileName "output.json" `
                | Should -Be "$TestDrive\a\output.json"
            }

            It 'Set to subdirectory local relative path' {
                Set-Utf8NoBom -Content "test" -Location ".\a" -FileName "output.json" `
                | Should -Be "$TestDrive\a\output.json"
            }

            It 'Set to subdirectory processing .. and .' {
                Set-Utf8NoBom -Content "test" -Location "a\b\..\..\c\." -FileName "output.json" `
                | Should -Be "$TestDrive\c\output.json"
            }
        }

        Context 'Check for re-root in path' {
            It 'Does not re-root subdirectory' {
                Set-Utf8NoBom -Content "test" -Location "a\d\..\b\." -FileName "output.json" `
                | Should -Be "$TestDrive\a\b\output.json"
            }

            It 'Does not re-root subdirectory rooted at local' {
                Set-Utf8NoBom -Content "test" -Location ".\a\d\..\b\." -FileName "output.json" `
                | Should -Be "$TestDrive\a\b\output.json"
            }

            It 'Does not re-root parent' {
                Set-Utf8NoBom -Content "test" -Location "..\$((Get-Item .).Name)\a\d\..\b\." -FileName "output.json" `
                | Should -Be "$TestDrive\a\b\output.json"
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
            Pop-Location
        }
    }

    Describe -Tag 'Utility' -Name 'Set-Utf8NoBom Inputs' {
        BeforeAll {
            Push-Location $TestDrive
        }

        Context 'Special Characters in input' {
                It 'Backslashes properly escaped' {
                    $OrigString = "This string has \ in it." | ConvertTo-Json
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    Get-Utf8NoBom -FilePath $FilePath |  Should -Be $OrigString
                }

                It 'Escaped sequences properly escaped' {
                    $OrigString = "This string has \r\n in it." | ConvertTo-Json
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    Get-Utf8NoBom -FilePath $FilePath | Should -Be $OrigString
                }

                It 'HTML escaped characters back converted properly' {
                    $OrigString = "This string has <, >, and ' in it." | ConvertTo-Json
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    Get-Utf8NoBom -FilePath $FilePath | Should -Be $OrigString
                }

                It 'Non-ASCII unicode characters back converted properly' {
                    $OrigString = "This string has º, ¢, ∞,¢, and £ in it." | ConvertTo-Json
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    Get-Utf8NoBom -FilePath $FilePath | Should -Be $OrigString
                }

                It 'DateTime string with backslash passes' {
                    $OrigString = $(Get-Date).Date | ConvertTo-JSON
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    Get-Utf8NoBom -FilePath $FilePath | Should -Be "$OrigString"
                }
        }

        AfterAll {
            Pop-Location
        }
    }

    AfterAll {
        Remove-Module Utility -ErrorAction SilentlyContinue
    }
}
