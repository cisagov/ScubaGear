BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Force
}

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Get-MsalDll' {
        BeforeAll {
            $FakeModuleRoot = Join-Path -Path $TestDrive -ChildPath 'Microsoft.Graph.Authentication\2.25.0'
            $CoreDir = Join-Path -Path $FakeModuleRoot -ChildPath 'Dependencies\Core'
            $DesktopDir = Join-Path -Path $FakeModuleRoot -ChildPath 'Dependencies\Desktop'
            New-Item -ItemType Directory -Path $CoreDir -Force | Out-Null
            New-Item -ItemType Directory -Path $DesktopDir -Force | Out-Null
            # Create Core first so a naive Select-Object -First 1 would pick the wrong runtime on Desktop
            New-Item -ItemType File -Path (Join-Path -Path $CoreDir -ChildPath 'Microsoft.Identity.Client.dll') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path -Path $DesktopDir -ChildPath 'Microsoft.Identity.Client.dll') -Force | Out-Null
        }

        It 'Selects the MSAL DLL matching the current PowerShell runtime' {
            $ExpectedFolder = if ($PSVersionTable.PSEdition -eq 'Core') { 'Core' } else { 'Desktop' }
            $Result = Get-MsalDll -ModulePath $FakeModuleRoot
            $Result | Should -Not -BeNullOrEmpty
            $Result.Directory.Name | Should -Be $ExpectedFolder
            $Result.Name | Should -Be 'Microsoft.Identity.Client.dll'
        }

        It 'Does not select the opposite runtime DLL' {
            $OppositeFolder = if ($PSVersionTable.PSEdition -eq 'Core') { 'Desktop' } else { 'Core' }
            $Result = Get-MsalDll -ModulePath $FakeModuleRoot
            $Result.Directory.Name | Should -Not -Be $OppositeFolder
        }

        It 'Throws when the runtime-specific DLL is missing' {
            $EmptyRoot = Join-Path -Path $TestDrive -ChildPath 'EmptyGraphAuth'
            New-Item -ItemType Directory -Path $EmptyRoot -Force | Out-Null
            { Get-MsalDll -ModulePath $EmptyRoot } | Should -Throw -ExpectedMessage '*Microsoft.Identity.Client.dll for runtime*'
        }

        It 'Throws when only the opposite runtime DLL is present' {
            $PartialRoot = Join-Path -Path $TestDrive -ChildPath 'PartialGraphAuth'
            $OppositeFolder = if ($PSVersionTable.PSEdition -eq 'Core') { 'Desktop' } else { 'Core' }
            $OppositeDir = Join-Path -Path $PartialRoot -ChildPath "Dependencies\$OppositeFolder"
            New-Item -ItemType Directory -Path $OppositeDir -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path -Path $OppositeDir -ChildPath 'Microsoft.Identity.Client.dll') -Force | Out-Null
            { Get-MsalDll -ModulePath $PartialRoot } | Should -Throw -ExpectedMessage '*Microsoft.Identity.Client.dll for runtime*'
        }
    }

    Describe -Tag 'Connection' -Name 'Initialize-Msal' {
        Context 'When MSAL types are not yet loaded' {
            It 'Throws when Microsoft.Graph.Authentication is not loaded' {
                $MsalType = [System.Management.Automation.PSTypeName]'Microsoft.Identity.Client.ConfidentialClientApplicationBuilder'
                if ($null -ne $MsalType.Type) {
                    Set-ItResult -Skipped -Because 'MSAL types are already loaded; Graph-missing path cannot be exercised'
                    return
                }

                Mock -ModuleName ConnectHelpers Get-Module { $null }
                { Initialize-Msal } | Should -Throw -ExpectedMessage '*Microsoft.Graph.Authentication module is not loaded*'
            }
        }

        Context 'When Microsoft.Graph.Authentication is available' {
            BeforeAll {
                Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
            }

            It 'Returns without error when MSAL types become resolvable after load' {
                # Force the load path if types are not yet present, then confirm Initialize-Msal is safe to call
                Initialize-Msal
                { Initialize-Msal } | Should -Not -Throw
                { $null = [Microsoft.Identity.Client.ConfidentialClientApplicationBuilder] } | Should -Not -Throw
            }

            It 'Get-MsalDll resolves the Desktop DLL for Windows PowerShell' {
                if ($PSVersionTable.PSEdition -eq 'Core') {
                    Set-ItResult -Skipped -Because 'This assertion is specific to Windows PowerShell Desktop'
                }
                $GraphModule = Get-Module Microsoft.Graph.Authentication
                $ModulePath = $GraphModule.Path | Split-Path
                $Result = Get-MsalDll -ModulePath $ModulePath
                $Result.Directory.Name | Should -Be 'Desktop'
                $Result.FullName | Should -Match '[\\/]Dependencies[\\/]Desktop[\\/]Microsoft\.Identity\.Client\.dll$'
            }
        }
    }
}

AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
