$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Get-ScubaDmarcRecord' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Get-ScubaDmarcRecord" {
        Context "When answers are available at full domain" {
            BeforeAll {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=DMARC1; p=reject");
                        "Errors" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @("some text")
                    }
                }
            }
            It "Resolves 1 domain name" {
                $Response = Get-ScubaDmarcRecord -Domains @(
                    @{
                        "DomainName" = "example.com";
                        "IsCoexistenceDomain" = $false
                    }
                ) -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.rdata -Contains "v=DMARC1; p=reject" | Should -Be $true
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
                $Response.rdata -Contains "v=DMARC1; p=reject" | Should -Be $true
            }

            It "Ignores the coexistence domain" {
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
                $Response.rdata -Contains "v=DMARC1; p=reject" | Should -Be $true
            }
        }

        Context "When the DMARC record is unavailable at the full domain" {
            BeforeAll {
                Mock -CommandName Invoke-RobustDnsTxt {
                    if ($Qname -eq "_dmarc.example.com") {
                        @{
                            "Answers" = @("v=DMARC1; p=reject");
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
            It "Returns the highest valid policy found by the tree walk" {
                $Response = Get-ScubaDmarcRecord -Domains @(@{"DomainName" = "a.b.example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 4
                Should -Invoke -CommandName Invoke-RobustDnsTxt -ParameterFilter {
                    $Qname -eq "_dmarc.example.com"
                } -Exactly -Times 1
                $Response.rdata -Contains "v=DMARC1; p=reject" | Should -Be $true
            }
        }

        Context "When the public suffix contains multiple labels" {
            BeforeAll {
                Mock -CommandName Invoke-RobustDnsTxt {
                    if ($Qname -eq "_dmarc.example.fed.us") {
                        @{
                            "Answers" = @("v=DMARC1; p=reject; psd=n");
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

            It "Finds the organizational-domain policy and stops at its PSD boundary" {
                $Response = Get-ScubaDmarcRecord -Domains @(
                    @{"DomainName" = "subdomain.example.fed.us"}
                ) -PreferredDnsResolvers @() -SkipDoH $false

                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 2
                Should -Invoke -CommandName Invoke-RobustDnsTxt -ParameterFilter {
                    $Qname -eq "_dmarc.example.fed.us"
                } -Exactly -Times 1
                $Response.rdata -Contains "v=DMARC1; p=reject; psd=n" | Should -Be $true
            }
        }

        Context "When the domain exceeds the tree-walk query limit" {
            BeforeAll {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @();
                        "Errors" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @("Query returned NXDomain")
                    }
                }
            }

            It "Makes no more than eight DNS queries" {
                $Response = Get-ScubaDmarcRecord -Domains @(
                    @{"DomainName" = "a.b.c.d.e.f.g.h.i.j.k.example.com"}
                ) -PreferredDnsResolvers @() -SkipDoH $false

                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 8
                $Response.rdata.Count | Should -Be 0
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}
