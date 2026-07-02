$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Get-ScubaDmarcRecord' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Get-ScubaDmarcRecord" {
        Context "When answers are available at full domain" {
            BeforeAll {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=DMARC1...");
                        "Errors" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @("some text")
                    }
                }
            }
            It "Resolves 1 domain name" {
                # Test basic functionality
                $Response = Get-ScubaDmarcRecord -Domains @(
                    @{
                        "DomainName" = "example.com";
                        "IsCoexistenceDomain" = $false
                    }
                ) -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
            }

            It "Resolves multiple domain names" {
                # Test to ensure function will loop over the domain names provided in the -Domains argument.
                $Response = Get-ScubaDmarcRecord -Domains @(
                    @{
                        "DomainName" = "example1.com";
                        "IsCoexistenceDomain" = $false
                    },
                    @{
                        "DomainName" = "example2.com";
                        "IsCoexistenceDomain" = $false
                    }
                ) -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 2
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
            }

            It "Ignores the coexistence domain" {
                # Get-ScubaDmarcRecord needs to skip the coexistence domain because DMARC
                # records can't be added for it
                $Response = Get-ScubaDmarcRecord -Domains @(
                    @{
                        "DomainName" = "example1.com";
                        "IsCoexistenceDomain" = $false
                    },
                    @{
                        "DomainName" = "example2.com";
                        "IsCoexistenceDomain" = $true
                    }
                ) -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
            }
        }

        Context "When the DMARC record is unavailable at the full domain" {
            BeforeEach {
                $script:DmarcQueries = @()
                $script:DmarcAnswerName = "_dmarc.example.com"
                Mock -CommandName Invoke-RobustDnsTxt {
                    $script:DmarcQueries += $Qname
                    if ($Qname -eq $script:DmarcAnswerName) {
                        @{
                            "Answers" = @("v=DMARC1...");
                            "Errors" = @();
                            "NXDomain" = $false;
                            "LogEntries" = @("some text")
                        }
                    }
                    else {
                        @{
                            "Answers" = @();
                            "Errors" = @();
                            "NXDomain" = $false;
                            "LogEntries" = @("Query returned NXDomain")
                        }
                    }
                }
            }
            It "Checks at the organization level" {
                # If no policy is available at the author domain, use the RFC 9989
                # DNS Tree Walk to find the applicable policy.
                $Response = Get-ScubaDmarcRecord -Domains @(@{"DomainName" = "a.b.example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 4
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
                $script:DmarcQueries | Should -Be @(
                    "_dmarc.a.b.example.com",
                    "_dmarc.b.example.com",
                    "_dmarc.example.com",
                    "_dmarc.com"
                )
            }

            It "Checks the correct policy domain for a multi-label public suffix" {
                $script:DmarcAnswerName = "_dmarc.example.fed.us"

                $Response = Get-ScubaDmarcRecord -Domains @(@{"DomainName" = "subdomain.example.fed.us"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
                $script:DmarcQueries | Should -Contain "_dmarc.example.fed.us"
            }

            It "Limits RFC 9989 tree-walk lookups to eight total DNS queries" {
                $script:DmarcAnswerName = "_dmarc.not-a-query.example"
                $Response = Get-ScubaDmarcRecord -Domains @(
                    @{"DomainName" = "a.b.c.d.e.f.g.h.i.j.mail.example.com"}
                ) -PreferredDnsResolvers @() -SkipDoH $false

                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 8
                $Response.rdata.Length | Should -Be 0
                $script:DmarcQueries | Should -Be @(
                    "_dmarc.a.b.c.d.e.f.g.h.i.j.mail.example.com",
                    "_dmarc.g.h.i.j.mail.example.com",
                    "_dmarc.h.i.j.mail.example.com",
                    "_dmarc.i.j.mail.example.com",
                    "_dmarc.j.mail.example.com",
                    "_dmarc.mail.example.com",
                    "_dmarc.example.com",
                    "_dmarc.com"
                )
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}
