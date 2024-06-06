$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Select-DohServer' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Select-DohServer" {
        It "Returns the first server that works" {
            Mock -CommandName Invoke-WebRequest {}
            $Server = Select-DohServer
            Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1
            $Server | Should -Be "cloudflare-dns.com"
        }
        It "Tries with IP address if domain is blocked" {
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
        It "Returns null if no servers work" {
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