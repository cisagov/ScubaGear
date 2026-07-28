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

        Context "When the tree walk encounters ambiguous or boundary-marking records" {
            BeforeEach {
                $script:DmarcQueries = @()
                $script:DmarcAnswersByName = @{}
                Mock -CommandName Invoke-RobustDnsTxt {
                    $script:DmarcQueries += $Qname
                    if ($script:DmarcAnswersByName.ContainsKey($Qname)) {
                        @{
                            "Answers" = @($script:DmarcAnswersByName[$Qname]);
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

            It "Stops the walk early when a valid record carries psd=y" {
                # RFC 9989 step 6: a psd tag marks the walk boundary explicitly.
                $script:DmarcAnswersByName["_dmarc.b.example.com"] = "v=DMARC1; p=none; psd=y;"
                $script:DmarcAnswersByName["_dmarc.example.com"] = "v=DMARC1; p=reject;"

                $Response = Get-ScubaDmarcRecord -Domains @(@{"DomainName" = "a.b.example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false

                $Response.rdata | Should -Be @("v=DMARC1; p=none; psd=y;")
                $script:DmarcQueries | Should -Be @(
                    "_dmarc.a.b.example.com",
                    "_dmarc.b.example.com"
                )
            }

            It "Stops the walk early when a valid record carries psd=n" {
                $script:DmarcAnswersByName["_dmarc.b.example.com"] = "v=DMARC1; p=none; psd=n;"
                $script:DmarcAnswersByName["_dmarc.example.com"] = "v=DMARC1; p=reject;"

                $Response = Get-ScubaDmarcRecord -Domains @(@{"DomainName" = "a.b.example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false

                $Response.rdata | Should -Be @("v=DMARC1; p=none; psd=n;")
                $script:DmarcQueries | Should -Be @(
                    "_dmarc.a.b.example.com",
                    "_dmarc.b.example.com"
                )
            }

            It "Discards a non-DMARC answer during the tree walk and keeps walking" {
                # A TXT record at "_dmarc.<name>" that isn't itself a DMARC record
                # (missing the v=DMARC1 tag) must not be treated as this target's
                # policy - the walk should continue past it.
                $script:DmarcAnswersByName["_dmarc.b.example.com"] = "some unrelated TXT record"
                $script:DmarcAnswersByName["_dmarc.example.com"] = "v=DMARC1; p=reject;"

                $Response = Get-ScubaDmarcRecord -Domains @(@{"DomainName" = "a.b.example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false

                $Response.rdata | Should -Be @("v=DMARC1; p=reject;")
                $script:DmarcQueries | Should -Be @(
                    "_dmarc.a.b.example.com",
                    "_dmarc.b.example.com",
                    "_dmarc.example.com",
                    "_dmarc.com"
                )
            }

            It "Treats multiple valid DMARC records at one target as unusable and keeps walking" {
                # RFC 7489 6.6.3: more than one DMARC TXT record at a name is a
                # discovery failure at that name, not a usable policy.
                $script:DmarcAnswersByName["_dmarc.b.example.com"] = @("v=DMARC1; p=none;", "v=DMARC1; p=quarantine;")
                $script:DmarcAnswersByName["_dmarc.example.com"] = "v=DMARC1; p=reject;"

                $Response = Get-ScubaDmarcRecord -Domains @(@{"DomainName" = "a.b.example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false

                $Response.rdata | Should -Be @("v=DMARC1; p=reject;")
                $script:DmarcQueries | Should -Be @(
                    "_dmarc.a.b.example.com",
                    "_dmarc.b.example.com",
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
