$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Invoke-TraditionalDns' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Invoke-TraditionalDns" {
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
                $Response = Invoke-TraditionalDns -Qname "example.com" -PreferredDnsResolvers @()
                Should -Invoke -CommandName Resolve-DnsName -Exactly -Times 1
                $Response.Answers -Contains "v=spf1 include:spf.protection.outlook.com -all" | Should -Be $true
                $Response.Errors.Length | Should -Be 0
                $Response.NXDomain | Should -Be $false
            }

            It "Handles NXDOMAIN" {
                # Test where Resolve-DnsName returns NXDOMAIN
                Mock -CommandName Resolve-DnsName {
                    throw "DNS_ERROR_RCODE_NAME_ERROR,Microsoft.DnsClient.Commands.ResolveDnsName"
                }
                $Response = Invoke-TraditionalDns -Qname "example.com" -PreferredDnsResolvers @()
                Should -Invoke -CommandName Resolve-DnsName -Exactly -Times 1
                $Response.Answers.Length | Should -Be 0
                $Response.Errors.Length | Should -Be 0
                $Response.NXDomain | Should -Be $true
            }

            It "Reports errors correctly" {
                # Test where Resolve-DnsName throws an exception. Should try twice then report the error
                Mock -CommandName Resolve-DnsName { throw "Some error" }
                $Response = Invoke-TraditionalDns -Qname "example.com" -MaxTries 2 -PreferredDnsResolvers @()
                Should -Invoke -CommandName Resolve-DnsName -Exactly -Times 2
                $Response.Answers.Length | Should -Be 0
                $Response.Errors.Length | Should -Be 2
                $Response.NXDomain | Should -Be $false
            }

            It "Handles empty answer correctly" {
                # Test where Resolve-DnsName doesn't throw an exception but also doesn't return an answer.
                # For example, in some cases where the answer can't be using the local resolver but trying
                # over a public resolve will reveal the answer.
                Mock -CommandName Resolve-DnsName { @(
                    @{
                        "Strings" = @("");
                        "Section" = "Authority"
                    }
                    )
                }
                $Response = Invoke-TraditionalDns -Qname "example.com" -MaxTries 2 -PreferredDnsResolvers @()
                Should -Invoke -CommandName Resolve-DnsName -Exactly -Times 1
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