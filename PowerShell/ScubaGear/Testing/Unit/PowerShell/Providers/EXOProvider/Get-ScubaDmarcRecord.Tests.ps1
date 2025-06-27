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
                )
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
                )
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
                )
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
            }
        }

        Context "When the DMARC record is unavailable at the full domain" {
            BeforeAll {
                Mock -CommandName Invoke-RobustDnsTxt {
                    Mock -CommandName Invoke-RobustDnsTxt {
                        if ($Qname -eq "_dmarc.example.com") {
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
            }
            It "Checks at the organization level" {
                # There are two locations where DMARC records can be found. If it's not available at the
                # full domain level, GetScubaDmarcRecord should try again at the organization domain level
                $Response = Get-ScubaDmarcRecord -Domains @(@{"DomainName" = "a.b.example.com"})
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 2
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}