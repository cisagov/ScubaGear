Import-Module "$PSScriptRoot/../../../PowerShell/ScubaGear/Modules/Connection/Connection.psm1"
Import-Module "$PSScriptRoot/../pester-installables/Pester/src/Pester.psd1"

Describe "Connection Tests: "{
    $script:test=0
    $script:test++
    It "$("$script:test".padleft(3, '0')): Syntax test"{
            $script:syntax = Get-Content "$PSScriptRoot/MockData/SyntaxMockData/Connect-Tenant-Mock-Data.txt" |Out-String
            (Get-Command -Syntax Connect-Tenant).Trim()| Should -Be $script:syntax #Can be changed if someone gives me the output of the command before the pipeline
        }
    $script:test++
    It "$("$script:test".padleft(3, '0')): Compatibility with test objects - Success"{
        try{
            Connect-Teams -ProductNames "teams" -M365Environment "commercial" 
            $true| Should -BeTrue  #Can be changed if someone gives me the output of Get-DomainComputer in xml format, after export the object via $object|Export-CliXML "<Path>"
         }
         catch{
            Write-Host "$($_.exception.message) $($_.errordetails.message)"
            $false| Should -BeTrue
         }
        }
    $script:test++
    It "$("$script:test".padleft(3, '0')): Compatibility with test objects - failure"{
        try{
             Connect-Teams -ProductNames "teams" -M365Environment "commercial-fail" 
             $false| Should -BeTrue  #Can be changed if someone gives me the output of Get-DomainComputer in xml format, after export the object via $object|Export-CliXML "<Path>"
            }
        catch{
              Write-Host "$($_.exception.message) $($_.errordetails.message)"
              $true| Should -BeTrue
             }
            }
    }

    Describe "Connection Tests: Disconnect-SCuBATenant"{
        $script:test=0
        $script:test++
        It "$("$script:test".padleft(3, '0')): Syntax test"{
                $script:syntax = Get-Content "$PSScriptRoot/MockData/SyntaxMockData/Disconnect-SCuBATenant-Mock-Data.txt" |Out-String
                (Get-Command -Syntax Disconnect-SCuBATenant).Trim()| Should -Be $script:syntax #Can be changed if someone gives me the output of the command before the pipeline
            }
        $script:test++
        It "$("$script:test".padleft(3, '0')): Compatibility with test objects - Success"{
            try{
                Disconnect-SCuBATenant -ProductNames "teams"
                $true| Should -BeTrue  #Can be changed if someone gives me the output of Get-DomainComputer in xml format, after export the object via $object|Export-CliXML "<Path>"
             }
             catch{
                Write-Host "$($_.exception.message) $($_.errordetails.message)"
                $false| Should -BeTrue
             }
            }
        $script:test++
        It "$("$script:test".padleft(3, '0')): Compatibility with test objects - failure"{
            try{
                Disconnect-SCuBATenant -ProductNames "teams-fail" 
                 $false| Should -BeTrue  #Can be changed if someone gives me the output of Get-DomainComputer in xml format, after export the object via $object|Export-CliXML "<Path>"
                }
            catch{
                  Write-Host "$($_.exception.message) $($_.errordetails.message)"
                  $true| Should -BeTrue
                 }
                }
        }