Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/CreateReport')

InModuleScope CreateReport {
    Describe -Tag CreateReport -Name 'Get-OmissionState' {
        BeforeAll {
            Mock -CommandName Write-Warning {}
        }

        Context "When no expiration date is provided" {
            It 'Returns false if the policy ID is not in the config' {
                # If the policy is not in the config, the expriation date is N/A and the function
                # should mark the policy as not omitted.
                $Config = [PSCustomObject]@{
                    "OmitPolicy" = [PSCustomObject]@{
                        "MS.EXO.1.1v1" = [PSCustomObject]@{ "Rationale" = "Example rationale" }
                    }
                }
                $Result = Get-OmissionState $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be $false
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }

            It 'Returns true if the policy ID is in the config' {
                # If the policy is in the config and the expriation date is not provided, as the
                # expiration date is optional, the function should mark the policy as omitted.
                $Config = [PSCustomObject]@{
                    "OmitPolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{ "Rationale" = "Example rationale" }
                    }
                }
                $Result = Get-OmissionState $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be $true
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }
        }

        Context "When an expiration date is provided" {
            BeforeAll {
                Mock -CommandName Get-Date {
                    # Modify the Get-Date function so that it returns a fixed date when
                    # no date is provided, instead of the current time.
                    if ($null -eq $Date) {
                        Get-Date -Date "2024-01-02"
                    }
                    else {
                        # If a specific date is requested, operate as normal
                        $Date
                    }
                }
            }

            It 'Returns true if the expiration is in the future' {
                # If the date is in the future, the function should still mark the
                # policy as not omitted.
                $Config = [PSCustomObject]@{
                    "OmitPolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Rationale" = "Example rationale";
                            "Expiration" = "2024-01-03" }
                    }
                }
                $Result = Get-OmissionState $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be $true
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }

            It 'Returns false and warns if the expiration is in the past' {
                # If the date is in the past, the functions should warn the user
                # and mark the policy as not omitted.
                $Config = [PSCustomObject]@{
                    "OmitPolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Rationale" = "Example rationale";
                            "Expiration" = "2024-01-01" }
                    }
                }
                $Result = Get-OmissionState $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be $false
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
            }

            It 'Returns false and warns if the expiration is malformed' {
                # The functions should recognize that the date is malformed, warn the user,
                # and mark the policy as not omitted.
                $Config = [PSCustomObject]@{
                    "OmitPolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Rationale" = "Example rationale";
                            "Expiration" = "bad date" }
                    }
                }
                $Result = Get-OmissionState $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be $false
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
            }
        }
    }

    AfterAll {
        Remove-Module CreateReport -ErrorAction SilentlyContinue
    }
}
