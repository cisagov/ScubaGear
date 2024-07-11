$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Select-DohServer' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Select-DohServer" {
        It "Returns the first server that works" {
            # Test when Invoke-Webrequest does not throw exceptions so we expect cloudflare-dns.com to
            # be the return value
            Mock -CommandName Invoke-WebRequest {}
            $Server = Select-DohServer
            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1
            $Server | Should -Be "cloudflare-dns.com"
        }
        It "Tries with the IPv6 address if the domain name fails" {
            # Test where Invoke-WebRequest throws an exception when cloudflare-dns.com is the server.
            # Select-DohServer should try again over IPv6 if the domain name fails.
            Mock -CommandName Invoke-WebRequest {
                if ($Uri.ToString().Contains("cloudflare-dns.com")) {
                    throw "some error"
                }
                else {}
            }
            $Server = Select-DohServer
            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 2
            $Server | Should -Be "[2606:4700:4700::1111]"
        }
        It "Tries with the IPv4 address if both the domain name and the IPv6 address fail" {
            # Test where Invoke-WebRequest throws an exception when either cloudflare-dns.com or the
            # Cloudflare's IPv6 address is the server. Select-DohServer should try again over IPv4
            # if both the domain name and IPv6 address fail.
            Mock -CommandName Invoke-WebRequest {
                if ($Uri.ToString().Contains("cloudflare-dns.com")) {
                    throw "some error"
                }
                elseif ($Uri.ToString().Contains("[2606:4700:4700:0000:0000:0000:0000:1111]")) {
                    # Note that $Uri.ToString() expands [2606:4700:4700::1111] to
                    # [2606:4700:4700:0000:0000:0000:0000:1111]
                    throw "some error"
                }
                else {}
            }
            $Server = Select-DohServer
            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 3
            $Server | Should -Be "1.1.1.1"
        }
        It "Returns null if no servers work" {
            # If Invoke-WebRequest fails in all cases, Select-DohServer should return $null.
            Mock -CommandName Invoke-WebRequest { throw "some error" }
            $Server = Select-DohServer
            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 3
            $Server | Should -Be $null
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}