$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Get-ScubaSpfRecord' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Get-ScubaSpfRecord" {
        Context "When a txt record is found" {
            It "Handles correct SPF records" {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=spf1 include:spf.protection.outlook.com -all");
                        "Errors" = @();
                        "NXDomain" = $false
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $true
                $Response.Message | Should -Be "SPF record found."
            }

            It "Handles soft fail" {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=spf1 include:spf.protection.outlook.com ~all");
                        "Errors" = @();
                        "NXDomain" = $false
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $true
                $Response.Message |
                    Should -Be "SPF record found."
            }

            It "Handles no fail" {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=spf1 include:spf.protection.outlook.com");
                        "Errors" = @();
                        "NXDomain" = $false
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $false
                $Response.Message |
                    Should -Be "SPF record found, but it does not fail unapproved senders or redirect to one that does."
            }

            It "Handles no SPF record" {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("something else, like a domain verification record");
                        "Errors" = @();
                        "NXDomain" = $false
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $false
                $Response.Message |
                    Should -Be "Domain name exists but no SPF records returned."
            }

            It "Handles multiple SPF records" {
                # RFC 7208 section 4.5: if more than one SPF record is returned,
                # SPF evaluation results in a permerror, so the domain is not compliant
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @(
                            "v=spf1 include:spf.protection.outlook.com -all",
                            "v=spf1 include:example.net -all"
                        );
                        "Errors" = @();
                        "NXDomain" = $false
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $false
                $Response.Message |
                    Should -Be "Multiple SPF records found. A domain must publish exactly one SPF record."
            }

            It "Ignores non-SPF records when exactly one SPF record is found" {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @(
                            "something else, like a domain verification record",
                            "v=spf1 include:spf.protection.outlook.com -all"
                        );
                        "Errors" = @();
                        "NXDomain" = $false
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $true
                $Response.Message | Should -Be "SPF record found."
            }

            It "Handles some errors but answer still found" {
                # There can be errors but still have a valid answer. For example, if the traditional DNS query failed
                # but DoH worked
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=spf1 include:spf.protection.outlook.com -all");
                        "Errors" = @("something went wrong");
                        "NXDomain" = $false
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $true
                $Response.Message | Should -Be "SPF record found."
            }
        }

        Context "When no txt record is found" {
            It "Handles NXDomain" {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @();
                        "Errors" = @();
                        "NXDomain" = $true
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $false
                $Response.Message | Should -Be "Domain does not exist."
            }

            It "Handles empty answer" {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @();
                        "Errors" = @();
                        "NXDomain" = $false
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $false
                $Response.Message | Should -Be "Domain name exists but no answers returned."
            }

            It "Handles errors" {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @();
                        "Errors" = @("something went wrong");
                        "NXDomain" = $false
                        "LogEntries" = @()
                    }
                }
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.Compliant | Should -Be $false
                $Response.Message | Should -Be "Exceptions other than NXDOMAIN returned."
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}