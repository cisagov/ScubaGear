Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/CreateReport') `
    -Function 'Add-Annotation' -Force

InModuleScope CreateReport {
    Describe -Tag CreateReport -Name 'Add-Annotation' {
        BeforeAll {
            Mock -CommandName Write-Warning {}
        }

        Context "When marked incorrect" {
            It 'Handles failing controls' {
                $Result = @{
                    "DisplayString" = "Fail";
                    "Details" = "Details"
                }
                $Config = [PSCustomObject]@{
                    "AnnotatePolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Comment" = "Example comment";
                            "IncorrectResult" = $true;
                        }
                    }
                }
                $Result = Add-Annotation $Result $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be "Test result marked incorrect by user. <span class='comment-heading'>User justification</span>`"Example comment`""
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }
            It 'Warns if no justification provided' {
                $Result = @{
                    "DisplayString" = "Fail";
                    "Details" = "Details"
                }
                $Config = [PSCustomObject]@{
                    "AnnotatePolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "IncorrectResult" = $true;
                        }
                    }
                }
                $Result = Add-Annotation $Result $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be "Test result marked incorrect by user. <span class='comment-heading'>User justification not provided</span>"
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
            }
            It 'Does not overwrite details if control already passing' {
                $Result = @{
                    "DisplayString" = "Pass";
                    "Details" = "Details"
                }
                $Config = [PSCustomObject]@{
                    "AnnotatePolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "IncorrectResult" = $true;
                            "Comment" = "Example comment";
                        }
                    }
                }
                $Result = Add-Annotation $Result $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be "Details<span class='comment-heading'>User comment</span>`"Example comment`""
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }
        }

        Context "When not marked incorrect" {
            It 'Handles failing controls' {
                $Result = @{
                    "DisplayString" = "Fail";
                    "Details" = "Details"
                }
                $Config = [PSCustomObject]@{
                    "AnnotatePolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Comment" = "Example comment";
                        }
                    }
                }
                $Result = Add-Annotation $Result $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be "Details<span class='comment-heading'>User comment</span>`"Example comment`""
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }
            It 'Handles passing controls' {
                $Result = @{
                    "DisplayString" = "Pass";
                    "Details" = "Details"
                }
                $Config = [PSCustomObject]@{
                    "AnnotatePolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Comment" = "Example comment";
                        }
                    }
                }
                $Result = Add-Annotation $Result $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be "Details<span class='comment-heading'>User comment</span>`"Example comment`""
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }
        }

        Context "When a remediation date is provided" {
            BeforeAll {
                Mock -CommandName Get-Date {
                    # Modify the Get-Date function so that it returns a fixed date when
                    # no date is provided, instead of the current time.
                    if ($null -eq $Date) {
                        Get-Date -Date "2025-01-01"
                    }
                    else {
                        # If a specific date is requested, operate as normal
                        $Date
                    }
                }
            }
            It 'Adds date to details' {
                $Result = @{
                    "DisplayString" = "Fail";
                    "Details" = "Details"
                }
                $Config = [PSCustomObject]@{
                    "AnnotatePolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Comment" = "Example comment";
                            "RemediationDate" = "2025-01-02"
                        }
                    }
                }
                $Result = Add-Annotation $Result $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be "Details<span class='comment-heading'>User comment</span>`"Example comment`"<span class='comment-heading'>Anticipated remediation date</span>`"2025-01-02`""
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }
            It 'Warns if date in past and still failing' {
                $Result = @{
                    "DisplayString" = "Fail";
                    "Details" = "Details"
                }
                $Config = [PSCustomObject]@{
                    "AnnotatePolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Comment" = "Example comment";
                            "RemediationDate" = "2024-01-02"
                        }
                    }
                }
                $Result = Add-Annotation $Result $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be "Details<span class='comment-heading'>User comment</span>`"Example comment`"<span class='comment-heading'>Anticipated remediation date</span>`"2024-01-02`""
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
            }
            It 'Does not warn if date in past but passing' {
                $Result = @{
                    "DisplayString" = "Pass";
                    "Details" = "Details"
                }
                $Config = [PSCustomObject]@{
                    "AnnotatePolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Comment" = "Example comment";
                            "RemediationDate" = "2024-01-02"
                        }
                    }
                }
                $Result = Add-Annotation $Result $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be "Details<span class='comment-heading'>User comment</span>`"Example comment`"<span class='comment-heading'>Anticipated remediation date</span>`"2024-01-02`""
                Should -Invoke -CommandName Write-Warning -Exactly -Times 0
            }
            It 'Warns if date is malformed' {
                $Result = @{
                    "DisplayString" = "Fail";
                    "Details" = "Details"
                }
                $Config = [PSCustomObject]@{
                    "AnnotatePolicy" = [PSCustomObject]@{
                        "MS.DEFENDER.1.1v1" = [PSCustomObject]@{
                            "Comment" = "Example comment";
                            "RemediationDate" = "2025-99-02"
                        }
                    }
                }
                $Result = Add-Annotation $Result $Config "MS.DEFENDER.1.1v1"
                $Result | Should -Be "Details<span class='comment-heading'>User comment</span>`"Example comment`"<span class='comment-heading'>Anticipated remediation date</span>`"2025-99-02`""
                Should -Invoke -CommandName Write-Warning -Exactly -Times 1
            }
        }
    }

    AfterAll {
        Remove-Module CreateReport -ErrorAction SilentlyContinue
    }
}
