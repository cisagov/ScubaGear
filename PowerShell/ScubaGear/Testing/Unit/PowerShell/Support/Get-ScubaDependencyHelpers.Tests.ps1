Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Support')

InModuleScope 'Support' {
    Describe "ScubaGear dependency helper functions" {
        BeforeAll {
            # Load the actual RequiredVersions.ps1 data for testing
            $RequiredVersionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\..\RequiredVersions.ps1"
            if (Test-Path -Path $RequiredVersionsPath) {
                . $RequiredVersionsPath
                $script:RealModuleList = $ModuleList
            } else {
                throw "Could not find RequiredVersions.ps1 at expected path: $RequiredVersionsPath"
            }
        }

        Context "Get-ScubaRequiredModuleList" {
            It "Should return the list of required modules from RequiredVersions.ps1" {
                $result = Get-ScubaRequiredModuleList
                $result.Count | Should -Be $script:RealModuleList.Count
                foreach ($module in $script:RealModuleList) {
                    ($result | Where-Object { $_.ModuleName -eq $module.ModuleName }) | Should -Not -BeNullOrEmpty
                }
            }

            It "Should prepend PowerShellGet when -IncludePowerShellGet is set" {
                $result = Get-ScubaRequiredModuleList -IncludePowerShellGet
                $result.Count | Should -Be ($script:RealModuleList.Count + 1)
                $result[0].ModuleName | Should -Be 'PowerShellGet'
            }
        }

        Context "Get-ScubaModuleDependencyStatus" {
            It "Should report a missing module when none is installed" {
                $status = Get-ScubaModuleDependencyStatus -ModuleName 'powershell-yaml' -MinimumVersion '0.4.2' -MaximumVersion '0.4.12' -InstalledModules $null

                $status.Installed | Should -BeFalse
                $status.Action | Should -Be "Install"
                $status.HighestVersionStatus | Should -Be "MISSING"
            }

            It "Should report a single in-range version as requiring no action" {
                $installed = @(
                    [PSCustomObject]@{
                        Name = 'powershell-yaml'
                        Version = [version]'0.4.7'
                        ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\powershell-yaml\0.4.7"
                    }
                )

                $status = Get-ScubaModuleDependencyStatus -ModuleName 'powershell-yaml' -MinimumVersion '0.4.2' -MaximumVersion '0.4.12' -InstalledModules $installed

                $status.Installed | Should -BeTrue
                $status.Action | Should -Be "None"
                $status.HighestVersionStatus | Should -Be "OK"
                $status.BestVersionToKeep | Should -Be ([version]'0.4.7')
                $status.VersionCount | Should -Be 1
            }

            It "Should flag a version above the maximum as requiring an update" {
                $installed = @(
                    [PSCustomObject]@{
                        Name = 'powershell-yaml'
                        Version = [version]'9.9.9'
                        ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\powershell-yaml\9.9.9"
                    }
                )

                $status = Get-ScubaModuleDependencyStatus -ModuleName 'powershell-yaml' -MinimumVersion '0.4.2' -MaximumVersion '0.4.12' -InstalledModules $installed

                $status.Action | Should -Be "Update"
                $status.HighestVersionStatus | Should -Be "ABOVE MAX"
                $status.VersionsInRange.Count | Should -Be 0
                $status.VersionsAboveMaximum | Should -Contain ([version]'9.9.9')
                $status.VersionsToRemove | Should -Contain ([version]'9.9.9')
            }

            It "Should recommend cleanup when multiple versions exist and one is in range" {
                $installed = @(
                    [PSCustomObject]@{
                        Name = 'powershell-yaml'
                        Version = [version]'0.4.5'
                        ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\powershell-yaml\0.4.5"
                    },
                    [PSCustomObject]@{
                        Name = 'powershell-yaml'
                        Version = [version]'0.4.7'
                        ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\powershell-yaml\0.4.7"
                    }
                )

                $status = Get-ScubaModuleDependencyStatus -ModuleName 'powershell-yaml' -MinimumVersion '0.4.2' -MaximumVersion '0.4.12' -InstalledModules $installed

                $status.Action | Should -Be "Cleanup"
                $status.VersionCount | Should -Be 2
                $status.BestVersionToKeep | Should -Be ([version]'0.4.7')
                $status.VersionsToRemove | Should -Contain ([version]'0.4.5')
                $status.VersionsToRemove | Should -Not -Contain ([version]'0.4.7')
            }
        }

        Context "Get-ScubaGearDependencyStatus" {
            BeforeEach {
                # Deterministic OPA status so these tests do not touch the filesystem or network.
                Mock Get-ScubaOpaDependencyStatus {
                    [PSCustomObject]@{
                        PSTypeName           = 'ScubaGear.DependencyStatus'
                        ModuleName           = 'OPA'
                        Installed            = $true
                        VersionCount         = 1
                        HighestVersion       = '1.18.2'
                        HighestVersionStatus = 'OK'
                        Action               = 'None'
                        Modules              = @()
                        InstalledVersions    = @()
                        VersionsInRange      = @()
                        VersionsBelowMinimum = @()
                        VersionsAboveMaximum = @()
                        VersionsOutOfRange   = @()
                        BestVersionToKeep    = '1.18.2'
                        VersionsToRemove     = @()
                        InProgramFiles       = $false
                        MinimumVersion       = $null
                        MaximumVersion       = $null
                    }
                }
            }

            It "Should return a status object for every module plus OPA" {
                Mock Get-Module { return $null }

                $statuses = Get-ScubaGearDependencyStatus -ModuleList $script:RealModuleList

                $statuses.Count | Should -Be ($script:RealModuleList.Count + 1)
                foreach ($module in $script:RealModuleList) {
                    ($statuses | Where-Object { $_.ModuleName -eq $module.ModuleName }) | Should -Not -BeNullOrEmpty
                }
                ($statuses | Where-Object { $_.ModuleName -eq 'OPA' }) | Should -Not -BeNullOrEmpty
            }

            It "Should load the module list itself when none is provided" {
                Mock Get-Module { return $null }

                $statuses = Get-ScubaGearDependencyStatus

                $statuses.Count | Should -Be ($script:RealModuleList.Count + 1)
            }

            It "Should exclude OPA when -ExcludeOpa is specified" {
                Mock Get-Module { return $null }

                $statuses = Get-ScubaGearDependencyStatus -ModuleList $script:RealModuleList -ExcludeOpa

                $statuses.Count | Should -Be $script:RealModuleList.Count
                ($statuses | Where-Object { $_.ModuleName -eq 'OPA' }) | Should -BeNullOrEmpty
                Should -Invoke -CommandName Get-ScubaOpaDependencyStatus -Times 0
            }

            It "Should advise Install-ScubaDependencies when a dependency is missing" {
                Mock Get-Module { return $null }  # all modules missing -> install needed
                Mock Write-Information { }

                $null = Get-ScubaGearDependencyStatus -ModuleList $script:RealModuleList

                Should -Invoke -CommandName Write-Information -ParameterFilter {
                    $MessageData -like "*Install-ScubaDependencies*"
                }
                Should -Invoke -CommandName Write-Information -Times 0 -ParameterFilter {
                    $MessageData -like "*Reset-ScubaGearDependencies*"
                }
            }

            It "Should advise Reset-ScubaGearDependencies when a module needs update or cleanup" {
                # Return an above-maximum version for every requested module -> Action 'Update'
                Mock Get-Module {
                    param($Name)
                    @($Name) | ForEach-Object {
                        [PSCustomObject]@{
                            Name = $_
                            Version = [version]'99.0.0'
                            ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\$_\99.0.0"
                        }
                    }
                }
                Mock Write-Information { }

                $null = Get-ScubaGearDependencyStatus -ModuleList $script:RealModuleList

                Should -Invoke -CommandName Write-Information -ParameterFilter {
                    $MessageData -like "*Reset-ScubaGearDependencies*"
                }
                Should -Invoke -CommandName Write-Information -Times 0 -ParameterFilter {
                    $MessageData -like "*Install-ScubaDependencies*"
                }
            }

            It "Should recommend only Reset-ScubaGearDependencies when both install and cleanup are needed" {
                # One module missing (needs install) + others out of range (need reset).
                # Reset handles everything, so Install should NOT also be recommended.
                Mock Get-Module {
                    param($Name)
                    @($Name) | Where-Object { $_ -ne 'MicrosoftTeams' } | ForEach-Object {
                        [PSCustomObject]@{
                            Name = $_
                            Version = [version]'99.0.0'
                            ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\$_\99.0.0"
                        }
                    }
                }
                Mock Write-Information { }

                $null = Get-ScubaGearDependencyStatus -ModuleList $script:RealModuleList

                Should -Invoke -CommandName Write-Information -ParameterFilter {
                    $MessageData -like "*Reset-ScubaGearDependencies*"
                }
                Should -Invoke -CommandName Write-Information -Times 0 -ParameterFilter {
                    $MessageData -like "*Install-ScubaDependencies*"
                }
            }

            It "Should not advise when all dependencies are optimal" {
                Mock Get-Module {
                    param($Name)
                    @($Name) | ForEach-Object {
                        $reqName = $_
                        $match = $script:RealModuleList | Where-Object { $_.ModuleName -eq $reqName } | Select-Object -First 1
                        if ($match) {
                            [PSCustomObject]@{
                                Name = $reqName
                                Version = $match.ModuleVersion
                                ModuleBase = "$env:USERPROFILE\Documents\PowerShell\Modules\$reqName\$($match.ModuleVersion)"
                            }
                        }
                    }
                }
                Mock Write-Information { }

                $null = Get-ScubaGearDependencyStatus -ModuleList $script:RealModuleList

                Should -Invoke -CommandName Write-Information -Times 0 -ParameterFilter {
                    $MessageData -like "*Install-ScubaDependencies*" -or $MessageData -like "*Reset-ScubaGearDependencies*"
                }
            }
        }

        Context "Get-ScubaOpaDependencyStatus" {
            It "Should report OPA as missing (Install) when the executable does not exist" {
                Mock Test-Path { return $false }

                $status = Get-ScubaOpaDependencyStatus

                $status.ModuleName | Should -Be 'OPA'
                $status.Installed | Should -BeFalse
                $status.Action | Should -Be 'Install'
                $status.HighestVersionStatus | Should -Be 'MISSING'
            }

            It "Should report OPA as OK (None) when the executable exists and the hash matches" {
                Mock Test-Path { return $true }
                Mock Get-ExeHash -ModuleName Support { return 'AABBCCDD' }
                Mock Get-FileHash { return [PSCustomObject]@{ Hash = 'AABBCCDD' } }

                $status = Get-ScubaOpaDependencyStatus

                $status.Installed | Should -BeTrue
                $status.Action | Should -Be 'None'
                $status.HighestVersionStatus | Should -Be 'OK'
            }

            It "Should flag OPA for update (MISMATCH) when the hash does not match" {
                Mock Test-Path { return $true }
                Mock Get-ExeHash -ModuleName Support { return 'AABBCCDD' }
                Mock Get-FileHash { return [PSCustomObject]@{ Hash = 'DIFFERENT' } }

                $status = Get-ScubaOpaDependencyStatus

                $status.Installed | Should -BeTrue
                $status.Action | Should -Be 'Update'
                $status.HighestVersionStatus | Should -Be 'MISMATCH'
            }

            It "Should skip the hash download when -SkipHashVerification is used" {
                Mock Test-Path { return $true }
                Mock Get-ExeHash -ModuleName Support { return 'AABBCCDD' }
                Mock Get-FileHash { return [PSCustomObject]@{ Hash = 'AABBCCDD' } }

                $status = Get-ScubaOpaDependencyStatus -SkipHashVerification

                $status.Installed | Should -BeTrue
                $status.Action | Should -Be 'None'
                $status.HighestVersionStatus | Should -Be 'UNVERIFIED'
                Should -Invoke -CommandName Get-ExeHash -Times 0
                Should -Invoke -CommandName Get-FileHash -Times 0
            }
        }

        Context "Install-ScubaDependencies alias" {
            It "Should expose Install-ScubaDependencies as a function" {
                Get-Command -Name 'Install-ScubaDependencies' -CommandType Function | Should -Not -BeNullOrEmpty
            }

            It "Should retain Initialize-SCuBA as an alias for Install-ScubaDependencies" {
                $alias = Get-Alias -Name 'Initialize-SCuBA' -ErrorAction SilentlyContinue
                $alias | Should -Not -BeNullOrEmpty
                $alias.ResolvedCommandName | Should -Be 'Install-ScubaDependencies'
            }
        }
    }
}
