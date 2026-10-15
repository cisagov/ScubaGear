[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Supply the MSAL app cache used by the function under test.')]
param()
Import-Module (Join-Path $PSScriptRoot '..\..\..\..\Modules\Connection\ConnectHelpers.psm1') -Force

InModuleScope ConnectHelpers {
    Describe 'Get-MsalAccessToken browser discovery' {
        BeforeEach {
            Mock Initialize-Msal {}
            $script:TokenResult = [pscustomobject]@{
                AccessToken = 'test-token'
                TenantId = '305102d0-7ccc-4007-83bb-ac1f44f8d620'
                Account = [pscustomobject]@{ Environment = 'login.microsoftonline.us' }
            }
            $script:TokenTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:TokenTask.SetResult($script:TokenResult)
            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetResult(@())
            $script:Request = [pscustomobject]@{ Embedded = $null; Tenant = $null }
            $script:Request | Add-Member ScriptMethod WithUseEmbeddedWebView {
                param($Enabled)
                $this.Embedded = $Enabled
                return $this
            }
            $script:Request | Add-Member ScriptMethod WithTenantId {
                param($Tenant)
                $this.Tenant = $Tenant
                return $this
            }
            $script:Request | Add-Member ScriptMethod ExecuteAsync { return $script:TokenTask.Task }
            $script:App = [pscustomobject]@{ InteractiveCalls = 0; SilentCalls = 0 }
            $script:App | Add-Member ScriptMethod GetAccountsAsync { return $script:AccountsTask.Task }
            $script:App | Add-Member ScriptMethod AcquireTokenInteractive {
                $this.InteractiveCalls++
                return $script:Request
            }
            $script:App | Add-Member ScriptMethod AcquireTokenSilent {
                $this.SilentCalls++
                return $script:Request
            }
            $Global:ScubaGearState.MsalAppCache = @{
                'PUB:test-client|https://login.microsoftonline.com/organizations|multicloud' = $script:App
                'PUB:test-client|https://login.microsoftonline.us/305102d0-7ccc-4007-83bb-ac1f44f8d620' = $script:App
            }
        }

        AfterEach {
            Disconnect-ScubaGraph
        }

        It 'returns discovery metadata and uses the system browser' {
            $Result = Get-MsalAccessToken -ClientId test-client -Tenant organizations -M365Environment commercial `
                -Scope @('Organization.Read.All') -MultiCloudSupport -PassThru
            $Result.TenantId | Should -Be $script:TokenResult.TenantId
            $Result.Account.Environment | Should -Be 'login.microsoftonline.us'
            $script:Request.Embedded | Should -BeFalse
            $script:App.InteractiveCalls | Should -Be 1
        }

        It 'tells the user a browser sign-in is starting only when it is needed' {
            Mock Write-Information {}
            $null = Get-MsalAccessToken -ClientId test-client -Tenant organizations -M365Environment commercial `
                -Scope @('Organization.Read.All') -MultiCloudSupport -PassThru
            Should -Invoke Write-Information -Times 1 -Exactly -ParameterFilter { $MessageData -like '*browser*sign in*' }

            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetResult(@($script:TokenResult.Account))
            $null = Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                -M365Environment gcchigh -Scope @('Organization.Read.All')
            Should -Invoke Write-Information -Times 1 -Exactly -ParameterFilter { $MessageData -like '*browser*sign in*' }
        }

        It 'pins later browser requests to the discovered tenant and preserves token-only output' {
            $Result = Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                -M365Environment gcchigh -Scope @('Organization.Read.All')
            $Result | Should -Be 'test-token'
            $script:Request.Tenant | Should -Be $script:TokenResult.TenantId
            $script:Request.Embedded | Should -BeFalse
        }

        It 'reuses cached accounts without opening the browser' {
            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetResult(@($script:TokenResult.Account))
            $Result = Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                -M365Environment gcchigh -Scope @('Organization.Read.All')
            $Result | Should -Be 'test-token'
            $script:App.SilentCalls | Should -Be 1
            $script:App.InteractiveCalls | Should -Be 0
            $script:Request.Tenant | Should -Be $script:TokenResult.TenantId
        }

        It 'rejects discovery against a tenanted or non-public authority' -TestCases @(
            @{ Tenant = 'tenant-id'; Environment = 'commercial' },
            @{ Tenant = 'organizations'; Environment = 'gcchigh' }
        ) {
            param($Tenant, $Environment)
            $null = $Tenant, $Environment
            { Get-MsalAccessToken -ClientId test-client -Tenant $Tenant -M365Environment $Environment `
                -Scope @('Organization.Read.All') -MultiCloudSupport } | Should -Throw '*public common or organizations authority*'
            $script:App.InteractiveCalls | Should -Be 0
        }
    }

    Describe 'Initialize-Msal setup messages' {
        BeforeEach {
            $script:SavedValidated = $Global:ScubaGearState.MsalValidated
            $script:SavedLibraryPath = $Global:ScubaGearState.MsalLibraryPath
            $Global:ScubaGearState.MsalValidated = $false
            $Global:ScubaGearState.MsalLibraryPath = $null
            $Manifest = Get-ScubaMsalManifest
            $script:Manifest = @{ Version = $Manifest.Version; Files = @(@{ File = 'Placeholder.dll' }); LoadOrder = @() }
            Mock Get-ScubaMsalManifest { $script:Manifest }
            Mock Install-ScubaMsalDependency { $LibraryPath }
            Mock Write-Information {}
        }

        AfterEach {
            $Global:ScubaGearState.MsalValidated = $script:SavedValidated
            $Global:ScubaGearState.MsalLibraryPath = $script:SavedLibraryPath
        }

        It 'announces the download and then its completion when the libraries are missing' {
            $script:ValidationCalls = 0
            Mock Test-ScubaMsalLibrary { $script:ValidationCalls++; $script:ValidationCalls -gt 1 }
            Initialize-Msal -LibraryPath 'TestDrive:\msal'
            Should -Invoke Install-ScubaMsalDependency -Times 1 -Exactly
            Should -Invoke Write-Information -Times 1 -Exactly -ParameterFilter { $MessageData -like '*downloading*No sign-in is required*' }
            Should -Invoke Write-Information -Times 1 -Exactly -ParameterFilter { $MessageData -like 'Setup complete*' }
        }

        It 'stays quiet when the libraries are already installed' {
            Mock Test-ScubaMsalLibrary { $true }
            Initialize-Msal -LibraryPath 'TestDrive:\msal'
            Should -Invoke Install-ScubaMsalDependency -Times 0 -Exactly
            Should -Invoke Write-Information -Times 0 -Exactly
        }
    }
}

AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
