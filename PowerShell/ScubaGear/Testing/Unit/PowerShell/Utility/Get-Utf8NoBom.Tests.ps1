$UtilityPath = '../../../../Modules/Utility/Utility.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $UtilityPath) -Function 'Get-Utf8NoBom' -Force

InModuleScope Utility {
    Describe -Tag 'Utility' -Name 'Get-Utf8NoBom Pathing' {
        BeforeAll {
            Mock -ModuleName Utility Invoke-ReadAllLines { return "Pass"}

            # Setup test directories for testing
            Push-Location $TestDrive
            New-Item -ItemType Directory "$TestDrive\a\b" -Force -ErrorAction Ignore
            New-Item -ItemType Directory "$TestDrive\c" -Force -ErrorAction Ignore

            $Content = Invoke-ReadAllLines -Path "$TestDrive\a"
            Write-Host "Invoke-ReadAllLines: $Content"
        }

        Context 'local file' {
            It 'Set to root drive path' {
                Get-Utf8NoBom -FilePath "C:\output.json" | Should -Be "Pass"
            }

            It 'Set to absolute subdirectory path' {
                Get-Utf8NoBom -FilePath "$TestDrive\a\output.json" | Should -Be "Pass"
            }
        }

        Context 'relative paths' {
            It 'Set to subdirectory relative path' {
                Get-Utf8NoBom -FilePath "a\output.json" | Should -Be "Pass"
            }

            It 'Set to subdirectory local relative path' {
                Get-Utf8NoBom -FilePath ".\a\output.json" | Should -Be "Pass"
            }

            It 'Set to subdirectory processing .. and .' {
                Get-Utf8NoBom -FilePath "a\b\..\..\c\.\output.json" | Should -Be "Pass"
            }
        }

        Context 'Check for re-root in path' {
            It 'Does not re-root subdirectory' {
                Get-Utf8NoBom -FilePath "a\d\..\b\.\output.json" | Should -Be "Pass"
            }

            It 'Does not re-root subdirectory rooted at local' {
                Get-Utf8NoBom -FilePath ".\a\d\..\b\.\output.json" | Should -Be "Pass"
            }

            It 'Does not re-root parent' {
                Get-Utf8NoBom -FilePath "..\$((Get-Item .).Name)\a\d\..\b\.\output.json" `
                | Should -Be "Pass"
            }
        }

        # Uses default C$ share to test building UNC paths that exist
        Context 'UNC path' {
            It 'Set to shared UNC path' {
                Get-Utf8NoBom -FilePath "\\$env:COMPUTERNAME\C$\output.json" `
                | Should -Be "Pass"
            }

            It 'Set to shared UNC path' {
                Get-Utf8NoBom -FilePath "\\$env:COMPUTERNAME\C$\output.json" `
                | Should -Be "Pass"
            }
        }

        AfterAll {
            Pop-Location
        }
    }

    Describe -Tag 'Utility' -Name 'Get-Utf8NoBom Inputs' {
        BeforeAll {
            Push-Location $TestDrive
        }

        Context 'Special Characters in input' {
                It 'Backslashes properly escaped' {
                    $OrigString = "This string has \ in it." | ConvertTo-Json
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    $RestoredString = Get-Utf8NoBom -FilePath $FilePath | Out-String
                    $RestoredString.Trim() | Should -Be $OrigString
                }

                It 'Escaped sequences properly escaped' {
                    $OrigString = "This string has \r\n in it." | ConvertTo-Json
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    $RestoredString = Get-Utf8NoBom -FilePath $FilePath | Out-String
                    $RestoredString.Trim() | Should -Be $OrigString
                }

                It 'HTML escaped characters back converted properly' {
                    $OrigString = "This string has <, >, and ' in it." | ConvertTo-Json
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    $RestoredString = Get-Utf8NoBom -FilePath $FilePath | Out-String
                    $RestoredString.Trim() | Should -Be $OrigString
                }

                It 'Non-ASCII unicode characters back converted properly' {
                    $OrigString = "This string has º, ¢, ∞,¢, and £ in it." | ConvertTo-Json
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    $RestoredString = Get-Utf8NoBom -FilePath $FilePath | Out-String
                    $RestoredString.Trim() | Should -Be $OrigString
                }

                It 'DateTime string with backslash passes' {
                    $OrigString = $(Get-Date).Date | ConvertTo-JSON
                    $FilePath = Set-Utf8NoBom -Content $OrigString -Location $TestDrive -FileName output.txt
                    $RestoredString = Get-Utf8NoBom -FilePath $FilePath | Out-String
                    $RestoredString.Trim() | Should -Be "$OrigString"
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
