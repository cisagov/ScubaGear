$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function Get-ScubaDkimRecords -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Get-ScubaDkimRecord" {
        Context "When the first selector tried works" {
            BeforeAll {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=DKIM1...");
                        "Errors" = @();
                        "NXDomain" = @();
                        "LogEntries" = @("some text")
                    }
                }
            }
            It "Resolves 1 domain name" {
                # Test basic functionality
                $Response = Get-ScubaDkimRecord -Domains @(@{"DomainName" = "example.com"}) `
                    -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.rdata -Contains "v=DKIM1..." | Should -Be $true
            }
            It "Resolves multiple domain names" {
                # Test to ensure function will loop over the domain names provided in the -Domains argument.
                $Response = Get-ScubaDkimRecord -Domains @(@{"DomainName" = "example.com"},
                @{"DomainName" = "example.com"}) `
                     -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 2
                $Response.rdata -Contains "v=DKIM1..." | Should -Be $true
            }
        }

        Context "When not all selectors work" {
            It "Tries multiple selectors" {
                # M365 has several possible DKIM selectors. If one doesn't work, Get-ScubaDkimRecord should
                # try again with a different one.
                Mock -CommandName Invoke-RobustDnsTxt {
                    if ($Qname.Contains("selector1")) {
                        @{
                            "Answers" = @();
                            "Errors" = @();
                            "NXDomain" = $true
                            "LogEntries" = @("Query returned NXDomain")
                        }
                    }
                    else {
                        @{
                            "Answers" = @("v=DKIM1...");
                            "Errors" =@()
                            "NXDomain" = $false;
                            "LogEntries" = @("some text")
                        }
                    }
                }
                $Response = Get-ScubaDkimRecord -Domains @(@{"DomainName" = "example.com"}) `
                     -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 2
                $Response.rdata -Contains "v=DKIM1..." | Should -Be $true
            }

            It "Embeds the domain name into the selector" {
                # M365 has several possible DKIM selectors. One of these is dynamically constructed based on the
                # domain name. If the other selectors don't work, Get-ScubaDkimRecord should try again with this
                # dynamically contructed selector.
                Mock -CommandName Invoke-RobustDnsTxt {
                    if ($Qname -eq "selector1-example-com._domainkey.example.com") {
                        @{
                            "Answers" = @("v=DKIM1...");
                            "Errors" = @();
                            "NXDomain"= $false
                            "LogEntries" = @("some text")
                        }
                    }
                    else {
                        @{
                            "Answers" = @();
                            "Errors" = @();
                            "NXDomain" = $true;
                            "LogEntries" = @("Query returned NXDomain")
                        }
                    }
                }
                $Response = Get-ScubaDkimRecord -Domains @(@{"DomainName" = "example.com"}) `
                     -PreferredDnsResolvers @() -SkipDoH $false
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 3
                $Response.rdata -Contains "v=DKIM1..." | Should -Be $true
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}