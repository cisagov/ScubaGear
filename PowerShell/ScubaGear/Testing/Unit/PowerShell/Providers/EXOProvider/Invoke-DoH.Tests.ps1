$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Invoke-DoH' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Invoke-DoH" {
        BeforeAll {
            Mock -CommandName Select-DohServer { "cloudflare-dns.com" }
        }
        Context 'When resolving a domain name' {
            It "Returns correct response when DoH works" {
                $DohResponseHeaders = @(
                    "HTTP/1.1 200 OK",
                    "Connection: keep-alive",
                    "Access-Control-Allow-Origin: *",
                    "CF-RAY: some value",
                    "Content-Length: 123",
                    "Content-Type: application/dns-json",
                    "Date: some date",
                    "Server: cloudflare"
                )
                Mock -CommandName ConvertFrom-Json {
                    @{
                        "Status" = 0;
                        "Answer" = @(@{
                            "name" = "example.com";
                            "type" = 16;
                            "data" = "`"v=spf1 include:spf.protection.outlook.com -all`"";
                        })
                    }
                }
                Mock -CommandName Invoke-WebRequest {
                    @{
                        "RawContent" = ($DohResponseHeaders -Join "`r`n") + "`r`n" + "json encoded answer"
                    }
                }
                $Response = Invoke-DoH -Qname "example.com" -MaxTries 2
                Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1
                $Response.Answers -Contains "v=spf1 include:spf.protection.outlook.com -all" | Should -Be $true
                $Response.Errors.Length | Should -Be 0
                $Response.NXDomain | Should -Be $false
            }

            It "Reports error when DoH unavailable" {
                Mock -CommandName ConvertFrom-Json {}
                Mock -CommandName Invoke-WebRequest { throw "some error" }
                $Response = Invoke-DoH -Qname "example.com" -MaxTries 2
                Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 2
                $Response.Answers.Length | Should -Be 0
                $Response.Errors.Length | Should -Be 2
                $Response.NXDomain | Should -Be $false
            }

            It "Does not error with no answer" {
                $DohResponseHeaders = @(
                    "HTTP/1.1 200 OK",
                    "Connection: keep-alive",
                    "Access-Control-Allow-Origin: *",
                    "CF-RAY: some value",
                    "Content-Length: 123",
                    "Content-Type: application/dns-json",
                    "Date: some date",
                    "Server: cloudflare"
                )
                # If there is no answer (e.g., the domain name exists but there are no txt records), the answer section
                # will just be gone
                Mock -CommandName ConvertFrom-Json {
                    @{
                        "Status" = 0;
                    }
                }
                Mock -CommandName Invoke-WebRequest {
                    @{
                        "RawContent" = ($DohResponseHeaders -Join "`r`n") + "`r`n" + "json encoded answer"
                    }
                }
                $Response = Invoke-DoH -Qname "example.com" -MaxTries 2
                Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1
                $Response.Answers.Length | Should -Be 0
                $Response.Errors.Length | Should -Be 0
                $Response.NXDomain | Should -Be $false
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}