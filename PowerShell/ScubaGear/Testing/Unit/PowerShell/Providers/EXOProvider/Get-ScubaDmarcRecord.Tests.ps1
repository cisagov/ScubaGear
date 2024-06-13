$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Get-ScubaDmarcRecord' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Get-ScubaDmarcRecord" {
        BeforeAll {
            Mock -CommandName Write-Warning {}
        }
        Context "When high-confidence answers are available" {
            BeforeAll {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=DMARC1...");
                        "HighConfidence" = $true;
                        "LogEntries" = @("some text")
                    }
                }
            }
            It "Resolves 1 domain name" {
                # Test basic functionality
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"})
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
            }

            It "Resolves multiple domain names" {
                # Test to ensure function will loop over the domain names provided in the -Domains argument.
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"},
                    @{"DomainName" = "example.com"})
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 2
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
            }
        }
        Context "When high-confidence answers are not available" {
            BeforeAll {
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=DMARC1...");
                        "HighConfidence" = $false;
                        "LogEntries" = @("some text")
                    }
                }
            }
            It "Prints a warning" {
                # If Invoke-RobustDnsTxt returns a low confidence answer, Get-ScubaDmarcRecord should print a
                # warning.
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"})
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
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
                                "HighConfidence" = $true;
                                "LogEntries" = @("some text")
                            }
                        }
                        else {
                            @{
                                "Answers" = @();
                                "HighConfidence" = $true;
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
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
                $Response.rdata -Contains "v=DMARC1..." | Should -Be $true
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}