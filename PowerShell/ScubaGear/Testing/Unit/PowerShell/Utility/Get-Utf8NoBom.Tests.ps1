$UtilityPath = '../../../../Modules/Utility/Utility.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $UtilityPath) -Function 'Get-Utf8NoBom' -Force

InModuleScope Utility {
    Describe -Tag 'Utility' -Name 'Get-Utf8NoBom Pathing' {
        BeforeAll {
            Mock -ModuleName Utility Invoke-ReadAllText { return "Pass"}

            # Setup test directories for testing
            Push-Location $TestDrive
            New-Item -ItemType Directory "$TestDrive\a\b" -Force -ErrorAction Ignore
            New-Item -ItemType Directory "$TestDrive\c" -Force -ErrorAction Ignore
        }

        Context 'local file' {
            It 'Set to root drive path' {
                $TestFile = "TestDrive:\output.json"
                New-Item -ItemType File $TestFile -Force -ErrorAction Ignore
                Get-Utf8NoBom -FilePath $TestFile | Should -Be "Pass"
            }

            It 'Set to absolute subdirectory path' {
                $TestFile = "$TestDrive\a\output.json"
                New-Item -ItemType File $TestFile -Force -ErrorAction Ignore
                Get-Utf8NoBom -FilePath $TestFile | Should -Be "Pass"
            }
        }

        Context 'relative paths' {
            It 'Set to subdirectory relative path' {
                $TestFile = "a\output.json"
                New-Item -ItemType File $TestFile -Force -ErrorAction Ignore
                Get-Utf8NoBom -FilePath $TestFile | Should -Be "Pass"
            }

            It 'Set to subdirectory local relative path' {
                $TestFile = ".\a\output.json"
                New-Item -ItemType File $TestFile -Force -ErrorAction Ignore
                Get-Utf8NoBom -FilePath $TestFile | Should -Be "Pass"
            }

            It 'Set to subdirectory processing .. and .' {
                $TestFile = "a\b\..\..\c\.\output.json"
                New-Item -ItemType File $TestFile -Force -ErrorAction Ignore
                Get-Utf8NoBom -FilePath $TestFile | Should -Be "Pass"
            }
        }

        Context 'Check for re-root in path' {
            It 'Does not re-root subdirectory' {
                $TestFile = "a\d\..\b\.\output.json"
                New-Item -ItemType File $TestFile -Force -ErrorAction Ignore
                Get-Utf8NoBom -FilePath $TestFile | Should -Be "Pass"
            }

            It 'Does not re-root subdirectory rooted at local' {
                $TestFile = ".\a\d\..\b\.\output.json"
                New-Item -ItemType File $TestFile -Force -ErrorAction Ignore
                Get-Utf8NoBom -FilePath $TestFile | Should -Be "Pass"
            }

            It 'Does not re-root parent' {
                $TestFile = "..\$((Get-Item .).Name)\a\d\..\b\.\output.json"
                New-Item -ItemType File $TestFile -Force -ErrorAction Ignore
                Get-Utf8NoBom -FilePath $TestFile | Should -Be "Pass"
            }
        }

        # Uses default system drive share to test building UNC paths that exist
        # Assumes TestDrive is on system drive
        Context 'UNC path' {
            It 'Set to shared UNC path' {
                $TempFolder = $($(Resolve-Path $TestDrive).ProviderPath).Substring(2)
                $ShareName = $env:SYSTEMDRIVE.Trim(':')
                $TestFile = "\\$env:COMPUTERNAME\$ShareName$\$TempFolder\output.json"
                New-Item -ItemType File $TestFile
                Get-Utf8NoBom -FilePath $TestFile | Should -Be "Pass"
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
                    Get-Utf8NoBom -FilePath $FilePath | Should -Be $OrigString
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
