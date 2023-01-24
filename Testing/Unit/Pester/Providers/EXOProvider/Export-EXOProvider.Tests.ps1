BeforeAll {
    Import-Module ../../../../../ScubaGear/Modules/Providers/ExportEXOProvider.psm1
    Import-Module ExchangeOnlineManagement
    Connect-ExchangeOnline
}

Describe "Export-EXOProvider" {
    It "return JSON" {
        InModuleScope ExportEXOProvider {
            $json = Export-EXOProvider
            $json = $json.TrimEnd(",")
            $json = "{$($json)}"
            $ValidJson = $true
            try {
                ConvertFrom-Json $json -ErrorAction Stop;
            }
            catch {
                $ValidJson = $false;
            }
            $ValidJson| Should -Be $true
        }
    }
}

# there are 3 new functions regarding spf,dkim,dmarc records. weill need to figure out a way to validate those
<#
    - change all dns functions to use nslookup for cross compatibility?
    - parse output of the checkdmarc python program
    - possibly change the python library to powershell to avoid python dependency

#>


