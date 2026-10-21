[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Supply the MSAL app cache used by the function under test.')]
param()
Import-Module (Join-Path $PSScriptRoot '..\..\..\..\Modules\Connection\ConnectHelpers.psm1') -Force

InModuleScope ConnectHelpers {
    Describe 'Get-MsalAccessToken browser discovery' {
        BeforeEach {
            Mock Initialize-Msal {}
            Mock Start-Sleep {}
            Mock New-ScubaMsalBrowserRequest {
                $BrowserRequest = $MsalApp.AcquireTokenInteractive($Scope).WithUseEmbeddedWebView($false)
                if ($Tenant -notin @('common', 'organizations')) {
                    $BrowserRequest = $BrowserRequest.WithTenantId($Tenant)
                }
                return $BrowserRequest
            }
            $Global:ScubaGearState.Session = $null
            $script:TokenResult = [pscustomobject]@{
                AccessToken = 'test-token'
                TenantId = '305102d0-7ccc-4007-83bb-ac1f44f8d620'
                Account = [pscustomobject]@{ Environment = 'login.microsoftonline.us' }
            }
            $script:TokenTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:TokenTask.SetResult($script:TokenResult)
            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetResult(@())
            $script:Request = [pscustomobject]@{ Embedded = $null; Tenant = $null; ForceRefresh = $false }
            $script:Request | Add-Member ScriptMethod WithForceRefresh {
                param($Enabled)
                $this.ForceRefresh = $Enabled
                return $this
            }
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
                'PUB:test-client' = $script:App
            }
        }

        AfterEach {
            Disconnect-ScubaGraph
        }

        It 'returns discovery metadata and uses the system browser' {
            $Result = Get-MsalAccessToken -ClientId test-client -Tenant organizations -M365Environment commercial `
                -Scope @('Organization.Read.All') -ForCloudDiscovery -PassThru
            $Result.TenantId | Should -Be $script:TokenResult.TenantId
            $Result.Account.Environment | Should -Be 'login.microsoftonline.us'
            $script:Request.Embedded | Should -BeFalse
            $script:App.InteractiveCalls | Should -Be 1
        }

        It 'reuses the discovery application for a tenant request and forced refresh in <Environment>' -TestCases @(
            @{ Environment = 'commercial'; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcc'; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcchigh'; HostName = 'login.microsoftonline.us' },
            @{ Environment = 'dod'; HostName = 'login.microsoftonline.us' }
        ) {
            param($Environment, $HostName)
            $Global:ScubaGearState.MsalAppCache = @{}
            $script:TokenResult.Account.Environment = $HostName
            Mock New-ScubaMsalPublicClient { $script:App }
            $Params = @{
                ClientId = 'test-client'; Scope = @('Organization.Read.All')
            }

            $null = Get-MsalAccessToken @Params -Tenant organizations -M365Environment commercial -ForCloudDiscovery
            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetResult(@($script:TokenResult.Account))
            Get-MsalAccessToken @Params -Tenant $script:TokenResult.TenantId -M365Environment $Environment |
                Should -Be 'test-token'
            Get-MsalAccessToken @Params -Tenant $script:TokenResult.TenantId -M365Environment $Environment -ForceRefresh |
                Should -Be 'test-token'

            $Global:ScubaGearState.MsalAppCache.Count | Should -Be 1
            [object]::ReferenceEquals($Global:ScubaGearState.MsalAppCache['PUB:test-client'], $script:App) | Should -BeTrue
            $script:App.InteractiveCalls | Should -Be 1
            $script:App.SilentCalls | Should -Be 2
            $script:Request.Tenant | Should -Be $script:TokenResult.TenantId
            $script:Request.ForceRefresh | Should -BeTrue
            Should -Invoke New-ScubaMsalPublicClient -Times 1 -Exactly -ParameterFilter {
                $ForCloudDiscovery -and $Authority -eq 'https://login.microsoftonline.com/organizations'
            }
        }

        It 'tells the user a browser sign-in is starting only when it is needed' {
            Mock Write-Information {}
            $null = Get-MsalAccessToken -ClientId test-client -Tenant organizations -M365Environment commercial `
                -Scope @('Organization.Read.All') -ForCloudDiscovery -PassThru
            Should -Invoke Write-Information -Times 1 -Exactly -ParameterFilter { $MessageData -like '*browser*sign in*' }

            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetResult(@($script:TokenResult.Account))
            $null = Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                -M365Environment gcchigh -Scope @('Organization.Read.All')
            Should -Invoke Write-Information -Times 1 -Exactly -ParameterFilter { $MessageData -like '*browser*sign in*' }
        }

        It 'retains the explicit application configuration when discovery is requested later in <Environment>' -TestCases @(
            @{ Environment = 'commercial'; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcc'; HostName = 'login.microsoftonline.com' },
            @{ Environment = 'gcchigh'; HostName = 'login.microsoftonline.us' },
            @{ Environment = 'dod'; HostName = 'login.microsoftonline.us' }
        ) {
            param($Environment, $HostName)
            $Global:ScubaGearState.MsalAppCache = @{}
            $script:TokenResult.Account.Environment = $HostName
            Mock New-ScubaMsalPublicClient { $script:App }
            $Params = @{ ClientId = 'test-client'; Scope = @('Organization.Read.All') }

            $null = Get-MsalAccessToken @Params -Tenant $script:TokenResult.TenantId -M365Environment $Environment
            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetResult(@($script:TokenResult.Account))
            $null = Get-MsalAccessToken @Params -Tenant organizations -M365Environment commercial -ForCloudDiscovery
            $null = Get-MsalAccessToken @Params -Tenant $script:TokenResult.TenantId -M365Environment $Environment -ForceRefresh

            $Global:ScubaGearState.MsalAppCache.Count | Should -Be 1
            [object]::ReferenceEquals($Global:ScubaGearState.MsalAppCache['PUB:test-client'], $script:App) | Should -BeTrue
            $script:App.InteractiveCalls | Should -Be 1
            $script:App.SilentCalls | Should -Be 2
            $script:Request.ForceRefresh | Should -BeTrue
            Should -Invoke New-ScubaMsalPublicClient -Times 1 -Exactly -ParameterFilter {
                -not $ForCloudDiscovery -and $Authority -eq "https://$HostName/$($script:TokenResult.TenantId)"
            }
        }

        It 'keeps certificate tokens separate from delegated tokens in <Environment>' -TestCases @(
            @{ Environment = 'commercial' },
            @{ Environment = 'gcchigh' }
        ) {
            param($Environment)
            Mock Get-ChildItem { [pscustomobject]@{ Thumbprint = 'test-thumbprint' } }
            $CertificateApp = [pscustomobject]@{ Calls = 0 }
            $CertificateApp | Add-Member ScriptMethod AcquireTokenForClient {
                $this.Calls++
                return $script:Request
            }
            $CertificateKey = 'SP:test-client'
            $Global:ScubaGearState.MsalAppCache[$CertificateKey] = $CertificateApp

            Get-MsalAccessToken -AppID test-client -CertificateThumbprint test-thumbprint `
                -Tenant $script:TokenResult.TenantId -M365Environment $Environment -Scope 'https://graph.microsoft.com/.default' |
                Should -Be 'test-token'
            Get-MsalAccessToken -AppID test-client -CertificateThumbprint test-thumbprint `
                -Tenant $script:TokenResult.TenantId -M365Environment $Environment -Scope 'https://graph.microsoft.com/.default' -ForceRefresh |
                Should -Be 'test-token'

            $CertificateApp.Calls | Should -Be 2
            $script:App.SilentCalls | Should -Be 0
            $script:App.InteractiveCalls | Should -Be 0
            $script:Request.ForceRefresh | Should -BeTrue
            $Global:ScubaGearState.MsalAppCache.Count | Should -Be 2
            [object]::ReferenceEquals($Global:ScubaGearState.MsalAppCache[$CertificateKey], $CertificateApp) | Should -BeTrue
            Should -Invoke New-ScubaMsalBrowserRequest -Times 0 -Exactly
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

        It 'forces a silent refresh without dropping the cached account' {
            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetResult(@($script:TokenResult.Account))
            Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                -M365Environment gcchigh -Scope @('Organization.Read.All') -ForceRefresh | Should -Be 'test-token'
            $script:Request.ForceRefresh | Should -BeTrue
            $script:App.InteractiveCalls | Should -Be 0
        }

        It 'uses the selected Graph account silently when this client lists no accounts' {
            $Global:ScubaGearState.Session = @{ Account = $script:TokenResult.Account }
            Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                -M365Environment gcchigh -Scope @('Organization.Read.All') | Should -Be 'test-token'
            $script:App.SilentCalls | Should -Be 1
            $script:App.InteractiveCalls | Should -Be 0
            Should -Invoke New-ScubaMsalBrowserRequest -Times 0 -Exactly
        }

        It 'uses browser SSO only after silent acquisition with the Graph account fails' {
            $Global:ScubaGearState.Session = @{ Account = $script:TokenResult.Account }
            $script:App | Add-Member ScriptMethod AcquireTokenSilent {
                $Failure = [System.InvalidOperationException]::new('No usable refresh token')
                # Model the SDK exception without loading MSAL assemblies into the unit-test process.
                $Failure.PSTypeNames.Insert(0, 'Microsoft.Identity.Client.MsalUiRequiredException')
                $Failure | Add-Member NoteProperty ErrorCode 'no_tokens_found'
                throw $Failure
            } -Force
            $Output = @(Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                -M365Environment gcchigh -Scope @('Organization.Read.All') -Verbose 4>&1)
            $Output | Should -Contain 'test-token'
            @($Output | Where-Object {
                $_ -is [System.Management.Automation.VerboseRecord] -and $_.Message -like '*[[]no_tokens_found[]]*'
            }).Count | Should -Be 1
            Should -Invoke New-ScubaMsalBrowserRequest -Times 1 -Exactly -ParameterFilter {
                [object]::ReferenceEquals($Account, $script:TokenResult.Account)
            }
        }

        It 'supplies a cached account to browser SSO when MSAL requires consent or MFA' {
            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetResult(@($script:TokenResult.Account))
            $script:App | Add-Member ScriptMethod AcquireTokenSilent {
                $Failure = [System.InvalidOperationException]::new('Interaction required')
                $Failure.PSTypeNames.Insert(0, 'Microsoft.Identity.Client.MsalUiRequiredException')
                $Failure | Add-Member NoteProperty ErrorCode 'invalid_grant'
                throw $Failure
            } -Force
            $null = Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                -M365Environment gcchigh -Scope @('Organization.Read.All')
            Should -Invoke New-ScubaMsalBrowserRequest -Times 1 -Exactly -ParameterFilter {
                [object]::ReferenceEquals($Account, $script:TokenResult.Account)
            }
        }

        It 'retries a transient network failure during silent acquisition without opening the browser' {
            $Global:ScubaGearState.Session = @{ Account = $script:TokenResult.Account }
            $Failure = [System.Net.WebException]::new('Silent acquisition failed', [System.Net.WebExceptionStatus]::ConnectFailure)
            # GetAwaiter().GetResult() and PowerShell wrap a faulted SDK task.
            $script:TokenTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:TokenTask.SetException($Failure)

            {
                Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                    -M365Environment gcchigh -Scope @('Organization.Read.All') -WarningAction SilentlyContinue
            } | Should -Throw '*Silent acquisition failed*'

            $script:App.SilentCalls | Should -Be 3
            $script:App.InteractiveCalls | Should -Be 0
            Should -Invoke New-ScubaMsalBrowserRequest -Times 0 -Exactly
            Should -Invoke Start-Sleep -Times 2 -Exactly -ParameterFilter { $Seconds -eq 5 }
        }

        It 'does not retry a <FailureKind> during silent acquisition and does not open the browser' -TestCases @(
            @{ FailureKind = 'programming error' },
            @{ FailureKind = 'non-UI MSAL error with no_tokens_found' }
        ) {
            param($FailureKind)
            $Global:ScubaGearState.Session = @{ Account = $script:TokenResult.Account }
            $Failure = [System.InvalidOperationException]::new('Silent acquisition failed')
            if ($FailureKind -eq 'non-UI MSAL error with no_tokens_found') {
                $Failure.PSTypeNames.Insert(0, 'Microsoft.Identity.Client.MsalClientException')
                $Failure | Add-Member NoteProperty ErrorCode 'no_tokens_found'
            }
            $script:TokenTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:TokenTask.SetException($Failure)

            {
                Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                    -M365Environment gcchigh -Scope @('Organization.Read.All') -WarningAction SilentlyContinue
            } | Should -Throw '*Silent acquisition failed*'

            $script:App.SilentCalls | Should -Be 1
            $script:App.InteractiveCalls | Should -Be 0
            Should -Invoke New-ScubaMsalBrowserRequest -Times 0 -Exactly
            Should -Invoke Start-Sleep -Times 0 -Exactly
        }

        It 'does not retry an interactive sign-in that fails with <Scenario>' -TestCases @(
            @{ Scenario = 'a cancelled sign-in'; Code = 'authentication_canceled'; Message = 'User canceled authentication'; Hint = '*cancelled or timed out*' },
            @{ Scenario = 'a consent the user cannot grant'; Code = 'invalid_grant'; Message = 'AADSTS65001: The user or administrator has not consented'; Hint = '*Global Administrator*' },
            @{ Scenario = 'a wrong password'; Code = 'invalid_grant'; Message = 'AADSTS50126: Error validating credentials'; Hint = '*credentials*' }
        ) {
            $Failure = [System.InvalidOperationException]::new($Message)
            $Failure.PSTypeNames.Insert(0, 'Microsoft.Identity.Client.MsalException')
            $Failure | Add-Member NoteProperty ErrorCode $Code
            $script:TokenTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:TokenTask.SetException($Failure)

            Mock Write-Warning {}
            {
                Get-MsalAccessToken -ClientId test-client -Tenant organizations -M365Environment commercial `
                    -Scope @('Organization.Read.All')
            } | Should -Throw "*$Message*"

            $script:App.InteractiveCalls | Should -Be 1
            Should -Invoke Start-Sleep -Times 0 -Exactly
            Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter { $Message -like $Hint }
        }

        It 'retries an interactive sign-in only for a transient service failure' {
            $Failure = [System.InvalidOperationException]::new('Service unavailable')
            $Failure.PSTypeNames.Insert(0, 'Microsoft.Identity.Client.MsalException')
            $Failure | Add-Member NoteProperty ErrorCode 'service_not_available'
            $script:TokenTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:TokenTask.SetException($Failure)

            {
                Get-MsalAccessToken -ClientId test-client -Tenant organizations -M365Environment commercial `
                    -Scope @('Organization.Read.All') -WarningAction SilentlyContinue
            } | Should -Throw '*Service unavailable*'

            $script:App.InteractiveCalls | Should -Be 3
            Should -Invoke Start-Sleep -Times 2 -Exactly -ParameterFilter { $Seconds -eq 5 }
        }

        It 'passes the interactive sign-in timeout to the request' {
            Mock Invoke-ScubaMsalRequest { $script:TokenResult }
            $null = Get-MsalAccessToken -ClientId test-client -Tenant organizations -M365Environment commercial `
                -Scope @('Organization.Read.All')
            Should -Invoke Invoke-ScubaMsalRequest -Times 1 -Exactly -ParameterFilter { $TimeoutSeconds -eq 300 }
        }

        It 'does not open the browser when account enumeration fails' {
            $Global:ScubaGearState.Session = $null
            $script:AccountsTask = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
            $script:AccountsTask.SetException([System.InvalidOperationException]::new('Account enumeration failed'))

            {
                Get-MsalAccessToken -ClientId test-client -Tenant $script:TokenResult.TenantId `
                    -M365Environment gcchigh -Scope @('Organization.Read.All') -WarningAction SilentlyContinue
            } | Should -Throw '*Account enumeration failed*'

            $script:App.SilentCalls | Should -Be 0
            $script:App.InteractiveCalls | Should -Be 0
            Should -Invoke New-ScubaMsalBrowserRequest -Times 0 -Exactly
        }

        It 'rejects discovery against a tenanted or non-public authority' -TestCases @(
            @{ Tenant = 'tenant-id'; Environment = 'commercial' },
            @{ Tenant = 'organizations'; Environment = 'gcchigh' }
        ) {
            param($Tenant, $Environment)
            $null = $Tenant, $Environment
            { Get-MsalAccessToken -ClientId test-client -Tenant $Tenant -M365Environment $Environment `
                -Scope @('Organization.Read.All') -ForCloudDiscovery } | Should -Throw '*public common or organizations authority*'
            $script:App.InteractiveCalls | Should -Be 0
        }
    }

    Describe 'Initialize-Msal' {
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
            Mock Test-ScubaMsalLibrary { $false }
            Initialize-Msal -LibraryPath 'TestDrive:\msal'
            Should -Invoke Test-ScubaMsalLibrary -Times 1 -Exactly
            Should -Invoke Install-ScubaMsalDependency -Times 1 -Exactly
            Should -Invoke Write-Information -Times 1 -Exactly -ParameterFilter { $MessageData -like '*downloading*No sign-in is required*' }
            Should -Invoke Write-Information -Times 1 -Exactly -ParameterFilter { $MessageData -like 'Setup complete*' }
        }

        It 'stays quiet when the libraries are already installed' {
            Mock Test-ScubaMsalLibrary { $true }
            Initialize-Msal -LibraryPath 'TestDrive:\msal'
            Should -Invoke Test-ScubaMsalLibrary -Times 1 -Exactly
            Should -Invoke Install-ScubaMsalDependency -Times 0 -Exactly
            Should -Invoke Write-Information -Times 0 -Exactly
        }

        It 'does no further setup work after successful initialization' {
            Mock Test-ScubaMsalLibrary { $true }
            Initialize-Msal -LibraryPath 'TestDrive:\msal'
            $Global:ScubaGearState.MsalValidated | Should -BeTrue
            $Global:ScubaGearState.MsalLibraryPath | Should -Be 'TestDrive:\msal'

            Initialize-Msal

            Should -Invoke Get-ScubaMsalManifest -Times 1 -Exactly
            Should -Invoke Test-ScubaMsalLibrary -Times 1 -Exactly
            Should -Invoke Install-ScubaMsalDependency -Times 0 -Exactly
        }

        It 'leaves initialization incomplete after a load failure and allows a retry' {
            Mock Test-ScubaMsalLibrary { $true }
            $script:Manifest.LoadOrder = @('Microsoft.Identity.ScubaMissingTest.dll')

            { Initialize-Msal -LibraryPath 'TestDrive:\msal' } | Should -Throw

            $Global:ScubaGearState.MsalValidated | Should -BeFalse
            $Global:ScubaGearState.MsalLibraryPath | Should -BeNullOrEmpty
            $script:Manifest.LoadOrder = @()

            Initialize-Msal -LibraryPath 'TestDrive:\msal'

            $Global:ScubaGearState.MsalValidated | Should -BeTrue
            Should -Invoke Test-ScubaMsalLibrary -Times 2 -Exactly
        }
    }
}

AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
