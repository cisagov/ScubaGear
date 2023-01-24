BeforeAll {
    import-module ../../../PowerShell/ScubaGear/Modules/Providers/ExportEXOProvider
    import-module ExchangeOnlineManagement
}
#there are 3 new functions regarding spf,dkim,dmarc records. weill need to figure out a way to validate those
#Describe "Export-EXOProvider" {
#    It "return JSON" {
#        InModuleScope ExportEXOProvider {
#
#            $json = Export-EXOProvider
#            $json = $json.TrimEnd(",")
#            $json = "{$($json)}" 
#            $json | test-json | should -BeTrue
#        }
#    }
#}
#
#Describe "Export-EXOProvider" {
#    It "return JSON" {
#        InModuleScope ExportEXOProvider {
#            $json = Get-EXOTenantDetail
#            $json = $json | convertfrom-json 
#            $json = $json[0]
#            $json = $json | convertto-json
#            $json | test-json | should -BeTrue
#        }
#    }
#}

<#

    - change all dns functions to use nslookup for cross compatibility?
    - parse output of the checkdmarc python program
    - possibly change the python library to powershell to avoid python dependency

#>

Describe "Get-ScubaDmarcRecords" {
    It "return DMARC Records" {
        InModuleScope ExportEXOProvider {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessInfo.FileName = "python"
            $ProcessInfo.RedirectStandardError = $true
            $ProcessInfo.RedirectStandardOutput = $true
            $ProcessInfo.UseShellExecute = $false
            
            connect-exchangeonline
            $domains = Get-AcceptedDomain
            $DMARCRecords = Get-ScubaDmarcRecords $domains
            foreach ($R in $DMARCRecords){
                $stderr = ''
                $Process = New-Object System.Diagnostics.Process
                $ProcessInfo.Arguments = @("$(Get-Location)/DNSRecords.py", $R.domain, "dmarc")
                $Process.StartInfo = $ProcessInfo
                $Process.Start() | Out-Null
                $Process.WaitForExit()
                $stderr = $Process.StandardError.ReadToEnd()
                $stderr | Should -Be ''
                $stdout = $Process.StandardOutput.ReadToEnd()
                $stdout.Trim() | Should -Be $R.rdata.Trim()
            }
		}
	}
}