$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Invoke-RobustDnsTxt' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Invoke-RobustDnsTxt" {
        BeforeAll {
            Mock -CommandName Select-DohServer { "cloudflare-dns.com" }
        }
        Context 'When resolving a domain name' {
            It "Returns correct response when traditional DNS works" {
                Mock -CommandName Resolve-DnsName {
                    @(
                        @{
                            "Strings" = @("v=spf1 include:spf.protection.outlook.com -all");
                            "Section" = "Answer"
                        }
                        )
                    }
                Mock -CommandName Invoke-WebRequest {}
                Mock -CommandName ConvertFrom-Json {}
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Resolve-DnsName -Exactly -Times 1
                Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 0
                $Response.Answers -Contains "v=spf1 include:spf.protection.outlook.com -all" | Should -Be $true
                $Response.HighConfidence | Should -Be $true
            }

            It "Tries over DoH if traditional DNS is unavailable" {
                Mock -CommandName Resolve-DnsName { throw "Some error" }
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
                $Response = Invoke-RobustDnsTxt -Qname "example.com" -MaxTries 2
                Should -Invoke -CommandName Resolve-DnsName -Exactly -Times 2
                Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1
                $Response.Answers -Contains "v=spf1 include:spf.protection.outlook.com -all" | Should -Be $true
                $Response.HighConfidence | Should -Be $true
            }

            It "Tries over DoH if traditional DNS gives an empty answer" {
                Mock -CommandName Resolve-DnsName { @(
                    @{
                        "Strings" = @("");
                        "Section" = "Authority"
                    }
                    )
                }
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
                $Response = Invoke-RobustDnsTxt -Qname "example.com" -MaxTries 2
                Should -Invoke -CommandName Resolve-DnsName -Exactly -Times 1
                Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 1
                $Response.Answers -Contains "v=spf1 include:spf.protection.outlook.com -all" | Should -Be $true
                $Response.HighConfidence | Should -Be $true
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}