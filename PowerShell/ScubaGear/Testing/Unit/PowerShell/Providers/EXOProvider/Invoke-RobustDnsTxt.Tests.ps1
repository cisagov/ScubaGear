$ProviderPath = "../../../../../Modules/Providers"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "$($ProviderPath)/ExportEXOProvider.psm1") `
    -Function 'Invoke-RobustDnsTxt' -Force

InModuleScope 'ExportEXOProvider' {
    Describe -Tag 'ExportEXOProvider' -Name "Invoke-RobustDnsTxt" {
        Context 'When a txt record exists' {
            It "Returns correct response when traditional DNS works" {
                Mock -CommandName Invoke-TraditionalDns {
                    @{
                        "Answers" = @("v=spf1 include:spf.protection.outlook.com -all");
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                Mock -CommandName Invoke-DoH {}
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Invoke-TraditionalDns -Exactly -Times 1
                Should -Invoke -CommandName Invoke-DoH -Exactly -Times 0
                $Response.Answers -Contains "v=spf1 include:spf.protection.outlook.com -all" | Should -Be $true
                $Response.Errors.Length | Should -Be 0
                $Response.NXDomain | Should -Be $false
            }

            It "Handles when traditional DNS doesn't return an answer but DoH does" {
                Mock -CommandName Invoke-TraditionalDns {
                    @{
                        "Answers" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                Mock -CommandName Invoke-DoH {
                    @{
                        "Answers" = @("v=spf1 include:spf.protection.outlook.com -all");
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Invoke-TraditionalDns -Exactly -Times 1
                Should -Invoke -CommandName Invoke-DoH -Exactly -Times 1
                $Response.Answers -Contains "v=spf1 include:spf.protection.outlook.com -all" | Should -Be $true
                $Response.Errors.Length | Should -Be 0
                $Response.NXDomain | Should -Be $false
            }

            It "Handles when traditional DNS has errors but DoH works" {
                Mock -CommandName Invoke-TraditionalDns {
                    @{
                        "Answers" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @("something went wrong");
                    }
                }
                Mock -CommandName Invoke-DoH {
                    @{
                        "Answers" = @("v=spf1 include:spf.protection.outlook.com -all");
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Invoke-TraditionalDns -Exactly -Times 1
                Should -Invoke -CommandName Invoke-DoH -Exactly -Times 1
                $Response.Answers -Contains "v=spf1 include:spf.protection.outlook.com -all" | Should -Be $true
                $Response.Errors.Length | Should -Be 1
                $Response.NXDomain | Should -Be $false
            }
        }

        Context 'When a txt record does not exist' {
            It "Handles NXDomain when traditional DNS works" {
                Mock -CommandName Invoke-TraditionalDns {
                    @{
                        "Answers" = @();
                        "NXDomain" = $true;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                Mock -CommandName Invoke-DoH {
                    @{
                        "Answers" = @();
                        "NXDomain" = $true;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Invoke-TraditionalDns -Exactly -Times 1
                Should -Invoke -CommandName Invoke-DoH -Exactly -Times 1
                $Response.Answers.Length| Should -Be 0
                $Response.Errors.Length | Should -Be 0
                $Response.NXDomain | Should -Be $true
            }

            It "Handles NXDomain when traditional DNS does not work" {
                Mock -CommandName Invoke-TraditionalDns {
                    @{
                        "Answers" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @("something went wrong");
                    }
                }
                Mock -CommandName Invoke-DoH {
                    @{
                        "Answers" = @();
                        "NXDomain" = $true;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Invoke-TraditionalDns -Exactly -Times 1
                Should -Invoke -CommandName Invoke-DoH -Exactly -Times 1
                $Response.Answers.Length| Should -Be 0
                $Response.Errors.Length | Should -Be 1
                $Response.NXDomain | Should -Be $true
            }

            It "Handles NXDomain from DoH when traditional DNS gives empty answer" {
                Mock -CommandName Invoke-TraditionalDns {
                    @{
                        "Answers" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                Mock -CommandName Invoke-DoH {
                    @{
                        "Answers" = @();
                        "NXDomain" = $true;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Invoke-TraditionalDns -Exactly -Times 1
                Should -Invoke -CommandName Invoke-DoH -Exactly -Times 1
                $Response.Answers.Length| Should -Be 0
                $Response.Errors.Length | Should -Be 0
                $Response.NXDomain | Should -Be $true
            }

            It "Handles empty answer from both traditional and DoH" {
                Mock -CommandName Invoke-TraditionalDns {
                    @{
                        "Answers" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                Mock -CommandName Invoke-DoH {
                    @{
                        "Answers" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @();
                    }
                }
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Invoke-TraditionalDns -Exactly -Times 1
                Should -Invoke -CommandName Invoke-DoH -Exactly -Times 1
                $Response.Answers.Length| Should -Be 0
                $Response.Errors.Length | Should -Be 0
                $Response.NXDomain | Should -Be $false
            }

            It "Handles errors from both traditional and DoH" {
                Mock -CommandName Invoke-TraditionalDns {
                    @{
                        "Answers" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @("something went wrong");
                    }
                }
                Mock -CommandName Invoke-DoH {
                    @{
                        "Answers" = @();
                        "NXDomain" = $false;
                        "LogEntries" = @();
                        "Errors" = @("something went wrong");
                    }
                }
                $Response = Invoke-RobustDnsTxt -Qname "example.com"
                Should -Invoke -CommandName Invoke-TraditionalDns -Exactly -Times 1
                Should -Invoke -CommandName Invoke-DoH -Exactly -Times 1
                $Response.Answers.Length| Should -Be 0
                $Response.Errors.Length | Should -Be 2
                $Response.NXDomain | Should -Be $false
            }
        }
    }
}
AfterAll {
    Remove-Module ExportEXOProvider -Force -ErrorAction SilentlyContinue
}