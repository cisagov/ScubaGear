BeforeAll {
    Import-Module ../../../../../ScubaGear/Modules/Providers/ExportEXOProvider.psm1
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

#$Result = foreach ($Domain in $Domains) {
#    Write-Output "DKIM Selector 1 CNAME Record:"
#    nslookup -q=cname selector1._domainkey.$Domain | Select-String "canonical name"
#    Write-Output "DKIM Selector 2 CNAME Record:"
#    nslookup -q=cname selector2._domainkey.$Domain | Select-String "canonical name"
#    Write-Output "DMARC TXT Record:"
#    (nslookup -q=txt _dmarc.$Domain | Select-String "DMARC1") -replace "`t", ""
#    Write-Output "SPF TXT Record:"
#    (nslookup -q=txt $Domain | Select-String "spf1") -replace "`t", ""