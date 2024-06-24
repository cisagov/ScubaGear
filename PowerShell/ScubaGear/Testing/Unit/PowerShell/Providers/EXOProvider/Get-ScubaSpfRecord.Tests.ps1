$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Get-ScubaSpfRecord' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Get-ScubaSpfRecord" {
        Context "When high-confidence answers are available" {
            BeforeAll {
                Mock -CommandName Write-Warning {}
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=spf1...");
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
                $Response.rdata -Contains "v=spf1..." | Should -Be $true
            }

            It "Resolves multiple domain names" {
                # Test to ensure function will loop over the domain names provided in the -Domains argument.
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"},
                    @{"DomainName" = "example.com"})
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 2
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
                $Response.rdata -Contains "v=spf1..." | Should -Be $true
            }
        }
        Context "When high-confidence answers are not available" {
            BeforeAll {
                Mock -CommandName Write-Warning {}
                Mock -CommandName Invoke-RobustDnsTxt {
                    @{
                        "Answers" = @("v=spf1...");
                        "HighConfidence" = $false;
                        "LogEntries" = @("some text")
                    }
                }
            }
            It "Prints a warning" {
                # If Invoke-RobustDnsTxt returns a low confidence answer, Get-ScubaSpfRecord should print a
                # warning.
                $Response = Get-ScubaSpfRecord -Domains @(@{"DomainName" = "example.com"})
                Should -Invoke -CommandName Invoke-RobustDnsTxt -Exactly -Times 1
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
                $Response.rdata -Contains "v=spf1..." | Should -Be $true
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}