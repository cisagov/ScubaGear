Import-Module "$PSScriptRoot\..\..\..\PowerShell\ScubaGear\Modules\Connection\ConnectHelpers.psm1"
Import-Module "$PSScriptRoot\..\pester-installables\Pester\src\Pester.psd1"

Describe "Connection Helper Tests: "{
    $script:test=0
    $script:test++
    It "$("$script:test".padleft(3, '0')): Syntax test"{
            $script:syntax = Get-Content "$PSScriptRoot\ConnectionHelper-mock-data.txt" |Out-String
            (Get-Command -Syntax Connect-EXOHelper).Trim()| Should -Be $script:syntax #Can be changed if someone gives me the output of the command before the pipeline
        }
    $script:test++
    It "$("$script:test".padleft(3, '0')): Compatibility with test objects - Success"{
        try{
            Connect-EXOHelper -M365Environment "commercial" 
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
            Connect-EXOHelper -M365Environment "commercial-fail" 
             $false| Should -BeTrue  #Can be changed if someone gives me the output of Get-DomainComputer in xml format, after export the object via $object|Export-CliXML "<Path>"
            }
        catch{
              Write-Host "$($_.exception.message) $($_.errordetails.message)"
              $true| Should -BeTrue
             }
            }
    }
