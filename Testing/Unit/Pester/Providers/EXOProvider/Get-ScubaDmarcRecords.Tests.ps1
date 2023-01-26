BeforeAll {
    Import-Module ../../../PowerShell/ScubaGear/Modules/Providers/ExportEXOProvider.psm1
    Import-Module ExchangeOnlineManagement
    Connect-ExchangeOnline
}

Describe "Get-ScubaDmarcRecords" {
    It "return DMARC Records" {
        InModuleScope ExportEXOProvider {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessInfo.FileName = "python"
            $ProcessInfo.RedirectStandardError = $true
            $ProcessInfo.RedirectStandardOutput = $true
            $ProcessInfo.UseShellExecute = $false

            $domains = Get-AcceptedDomain
            $DMARCRecords = Get-ScubaDmarcRecords $domains
            foreach ($R in $DMARCRecords){
                $stderr = ''
                $Process = New-Object System.Diagnostics.Process
                $ProcessInfo.Arguments = @("$(Get-Location)/Providers/EXOProvider/DNSRecords.py", $R.domain, "dmarc")
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

Describe "Get-ScubaSpfRecords" {
    It "return SPF Records" {
        InModuleScope ExportEXOProvider {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessInfo.FileName = "python"
            $ProcessInfo.RedirectStandardError = $true
            $ProcessInfo.RedirectStandardOutput = $true
            $ProcessInfo.UseShellExecute = $false

            $domains = Get-AcceptedDomain
            $SPFRecords = Get-ScubaSpfRecords $domains
            foreach ($R in $SPFRecords){
                $stderr = ''
                $Process = New-Object System.Diagnostics.Process
                $ProcessInfo.Arguments = @("$(Get-Location)/Providers/EXOProvider/DNSRecords.py", $R.domain, "spf")
                $Process.StartInfo = $ProcessInfo
                $Process.Start() | Out-Null
                $Process.WaitForExit()
                $stderr = $Process.StandardError.ReadToEnd()
                $stderr | Should -Be ''
                $stdout = $Process.StandardOutput.ReadToEnd()
                $R.rdata.Trim() | Should -Contain $stdout.Trim()
            }
		}
	}
}

Describe "Get-ScubaDkimRecords" {
    It "return handles a domain with DKIM" {
        InModuleScope ExportEXOProvider {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessInfo.FileName = "python"
            $ProcessInfo.RedirectStandardError = $true
            $ProcessInfo.RedirectStandardOutput = $true
            $ProcessInfo.UseShellExecute = $false

            $domains = @{"DomainName"="test365.cisa.dhs.gov"}
            $DKIMRecords = Get-ScubaDkimRecords $domains
            foreach ($R in $DKIMRecords){
                $R.rdata.Trim() | Should -BeLike "v=DKIM1;*" 
            }
		}
	}

    It "return handles a domain without DKIM" {
        InModuleScope ExportEXOProvider {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $ProcessInfo.FileName = "python"
            $ProcessInfo.RedirectStandardError = $true
            $ProcessInfo.RedirectStandardOutput = $true
            $ProcessInfo.UseShellExecute = $false

            $domains = @{"DomainName"="example.com"}
            $DKIMRecords = Get-ScubaDkimRecords $domains
            foreach ($R in $DKIMRecords){
                $R.rdata.Trim() | Should -BeLike "" 
            }
		}
	}
}

#$Result = foreach ($Domain in $Domains) {
#    Write-Output "DKIM Selector 1 CNAME Record:"
#    nslookup -q=cname selector1._domainkey.$Domain | Select-String "canonical name"
#    Write-Output "DKIM Selector 2 CNAME Record:"
#    nslookup -q=cname selector2._domainkey.$Domain | Select-String "canonical name"
#    Write-Output "DMARC TXT Record:"
#    (nslookup -q=txt _dmarc.$Domain | Select-String "DMARC1") -replace "`t", ""
#    Write-Output "SPF TXT Record:"
#    (nslookup -q=txt $Domain | Select-String "spf1") -replace "`t", ""