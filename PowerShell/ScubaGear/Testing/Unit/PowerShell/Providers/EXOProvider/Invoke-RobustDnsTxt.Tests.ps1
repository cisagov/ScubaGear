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
                # Test where Resolve-DnsName works first try
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

            It "Handles NXDOMAIN" {
                # Test where Resolve-DnsName returns NXDOMAIN
                Mock -CommandName Resolve-DnsName {
                    throw "DNS_ERROR_RCODE_NAME_ERROR,Microsoft.DnsClient.Commands.ResolveDnsName"
                }
                Mock -CommandName Invoke-WebRequest {}
                Mock -CommandName ConvertFrom-Json {}
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Resolve-DnsName -Exactly -Times 1
                Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 0
                $Response.Answers.Length | Should -Be 0
                $Response.HighConfidence | Should -Be $true
            }

            It "Tries over DoH if traditional DNS is unavailable" {
                # Test where Resolve-DnsName throws an exception. In this case, Invoke-RobustDnsTxt should try
                # again over DoH
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
                # Test where Resolve-DnsName doesn't throw an exception but also doesn't return an answer.
                # Invoke-RobustDnsTxt should try again over DoH in that this. For context, there are some
                # cases where Resolve-DnsName won't throw an exception but won't actually return an answer.
                # For example, in some cases where the answer can't be using the local resolver but trying
                # over a public resolve will reveal the answer.
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

            It "Indicates low confidence if traditional DNS gives an empty answer and DoH unavailable" {
                # There are some cases where Resolve-DnsName won't throw an exception but won't actually
                # return an answer, but where trying over a public DNS resolver reveals the answer
                # However, many systems block DoH. If Resolve-DnsName returns an empty answer and DoH
                # fails, Invoke-RobustDnsTxt should indicate that the answer is not high-confidence.
                Mock -CommandName Resolve-DnsName { @(
                    @{
                        "Strings" = @("");
                        "Section" = "Authority"
                    }
                    )
                }
                Mock -CommandName ConvertFrom-Json {}
                Mock -CommandName Invoke-WebRequest { throw "some error" }
                $Response = Invoke-RobustDnsTxt -Qname "example.com" -MaxTries 2
                Should -Invoke -CommandName Resolve-DnsName -Exactly -Times 1
                Should -Invoke -CommandName Invoke-WebRequest -Exactly -Times 2
                $Response.Answers.Length | Should -Be 0
                $Response.HighConfidence | Should -Be $false
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}