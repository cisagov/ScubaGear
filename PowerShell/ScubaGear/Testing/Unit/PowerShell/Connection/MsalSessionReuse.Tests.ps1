[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Exercise the shared MSAL session used by consecutive scans.')]
param()
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../Modules/Connection/Connection.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot '../../../../Modules/Permissions/PermissionsHelper.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot '../../../../Modules/Utility/Utility.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot '../../../../Modules/Utility/ScubaLogging.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot '../../../../Modules/Providers/ProviderHelpers/EXORestHelper.psm1') -Force
}

Describe 'MSAL session reuse across scans' {
    BeforeEach {
        InModuleScope Connection {
            # Only the SDK boundary is simulated. All connection/token/discovery code is real.
            function New-TestMsalApp {
                param([string]$ClientId)
                $Cache = [pscustomobject]@{ Accounts = @(); Clients = @() }
                $App = [pscustomobject]@{
                    ClientId = $ClientId; UserTokenCache = $Cache
                    InteractiveCalls = 0; SilentCalls = 0; LastAccountId = $null; BrowserAccountId = $null
                    ExposeAccounts = $true; AccountEnvironment = 'login.microsoftonline.com'
                    OriginalAuthority = $null; ForCloudDiscovery = $false; CreationCount = 0
                }
                $Request = [pscustomobject]@{ App = $App; Interactive = $false; Tenant = $null; ForceRefresh = $false }
                $Request | Add-Member ScriptMethod WithUseEmbeddedWebView { return $this }
                $Request | Add-Member ScriptMethod WithTenantId {
                    param($Tenant)
                    $this.Tenant = $Tenant
                    return $this
                }
                $Request | Add-Member ScriptMethod WithForceRefresh {
                    param($Enabled)
                    $this.ForceRefresh = $Enabled
                    return $this
                }
                $Request | Add-Member ScriptMethod ExecuteAsync {
                    $Cache = $this.App.UserTokenCache
                    if (-not $this.Interactive -and $this.App.ClientId -notin $Cache.Clients) {
                        $Failure = [System.InvalidOperationException]::new('Interaction required: no usable refresh token')
                        $Failure.PSTypeNames.Insert(0, 'Microsoft.Identity.Client.MsalUiRequiredException')
                        $Failure | Add-Member NoteProperty ErrorCode 'no_tokens_found'
                        throw $Failure
                    }
                    $Account = [pscustomobject]@{
                        Environment = $this.App.AccountEnvironment
                        HomeAccountId = [pscustomobject]@{ Identifier = 'test-user.home-tenant' }
                    }
                    $Cache.Accounts = @($Account)
                    if ($this.App.ClientId -notin $Cache.Clients) { $Cache.Clients += $this.App.ClientId }
                    $Completion = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
                    $Completion.SetResult([pscustomobject]@{
                        AccessToken = 'test-token'
                        TenantId = '305102d0-7ccc-4007-83bb-ac1f44f8d620'
                        Account = $Account
                    })
                    return $Completion.Task
                }
                $App | Add-Member NoteProperty Request $Request
                $App | Add-Member ScriptMethod GetAccountsAsync {
                    $Completion = [System.Threading.Tasks.TaskCompletionSource[object]]::new()
                    $Accounts = @()
                    if ($this.ExposeAccounts) { $Accounts = @($this.UserTokenCache.Accounts) }
                    $Completion.SetResult($Accounts)
                    return $Completion.Task
                }
                $App | Add-Member ScriptMethod AcquireTokenInteractive {
                    $this.InteractiveCalls++
                    $this.Request.Interactive = $true
                    return $this.Request
                }
                $App | Add-Member ScriptMethod AcquireTokenSilent {
                    param($Scopes, $Account)
                    $null = $Scopes
                    $this.LastAccountId = $Account.HomeAccountId.Identifier
                    $this.SilentCalls++
                    $this.Request.Interactive = $false
                    return $this.Request
                }
                return $App
            }

            Mock Initialize-Msal {}
            Mock Initialize-Msal {} -ModuleName ConnectHelpers
            Mock Start-Sleep {} -ModuleName ConnectHelpers
            Mock Write-Progress {}
            Mock Write-ScubaLog {}
            Mock Get-M365EnvironmentByDomain { 'commercial' } -ModuleName ConnectHelpers
            Mock Get-ExchangeOnlineApiEndpoint { 'https://outlook.office365.com/adminapi' }
            Mock Get-ComplianceApiEndpoint { 'https://ps.compliance.protection.outlook.com/adminapi' }
            Mock Invoke-GraphDirectly {
                if ($Commandlet -eq 'Get-MgBetaOrganization') {
                    return [pscustomobject]@{ Value = [pscustomobject]@{
                        Id = '305102d0-7ccc-4007-83bb-ac1f44f8d620'
                        VerifiedDomains = @([pscustomobject]@{ isInitial = $true; Name = 'contoso.onmicrosoft.com' })
                    } }
                }
                return [pscustomobject]@{ Value = @([pscustomobject]@{
                    ServicePlans = @([pscustomobject]@{ ProvisioningStatus = 'Success'; ServicePlanName = 'POWER_BI_STANDARD' })
                }) }
            }

            Disconnect-ScubaGraph
            $script:Apps = @{}
            $GraphClient = '14d82eec-204b-4c2f-b7e8-296a70dab67e'
            foreach ($Client in @(
                $GraphClient,
                'fb78d390-0c51-40cd-8e17-fdbfab77341b',
                '1950a258-227b-4e31-a9cf-717495945fc2',
                '9bc3ab49-b65d-410a-85ad-de819febfddc',
                '12128f48-ec9e-42f0-b203-ea49fb6af367'
            )) {
                $script:Apps[$Client] = New-TestMsalApp $Client
            }
            InModuleScope ConnectHelpers -Parameters @{ Apps = $script:Apps } {
                param($Apps)
                $script:TestApps = $Apps
                Mock New-ScubaMsalPublicClient {
                    if (-not $script:TestApps.ContainsKey($ClientId)) { throw "Unexpected test client: $ClientId" }
                    $App = $script:TestApps[$ClientId]
                    $App.CreationCount++
                    if ($App.CreationCount -gt 1) { throw "Application rebuilt for client: $ClientId" }
                    $App.OriginalAuthority = $Authority
                    $App.ForCloudDiscovery = $ForCloudDiscovery.IsPresent
                    return $App
                }
                Mock New-ScubaMsalBrowserRequest {
                    $MsalApp.BrowserAccountId = $Account.HomeAccountId.Identifier
                    return $MsalApp.AcquireTokenInteractive($Scope)
                }
            }
        }
    }

    AfterEach {
        InModuleScope Connection { Disconnect-SCuBATenant }
    }

    It 'retains each client cache on a second scan with <Mode> environment selection' -TestCases @(
        @{ Mode = 'explicit'; Parameters = @{ M365Environment = 'commercial' } },
        @{ Mode = 'automatic'; Parameters = @{} }
    ) {
        param($Mode, $Parameters)
        $null = $Mode
        InModuleScope Connection -Parameters @{ Parameters = $Parameters } {
            param($Parameters)
            $Products = @('aad', 'exo', 'powerbi', 'powerplatform', 'securitysuite', 'sharepoint', 'teams')
            $First = Connect-Tenant -ProductNames $Products @Parameters
            $First.ProdAuthFailed | Should -BeNullOrEmpty
            $First.PBILicenseFound | Should -BeTrue
            $Global:ScubaGearState.MsalAppCache.Count | Should -Be 5
            ($script:Apps.Values | Measure-Object InteractiveCalls -Sum).Sum | Should -Be 5
            $UsedApps = @($script:Apps.Values | Where-Object { $_.InteractiveCalls + $_.SilentCalls -gt 0 })
            foreach ($App in $UsedApps) { $App.SilentCalls = 0 }
            $Session = $Global:ScubaGearState.Session

            $Second = Connect-Tenant -ProductNames $Products @Parameters
            $Second.ProdAuthFailed | Should -BeNullOrEmpty
            [object]::ReferenceEquals($Global:ScubaGearState.Session, $Session) | Should -BeTrue
            foreach ($Token in @('EXOAccessToken', 'ComplianceAccessToken', 'PBIAccessToken', 'PPAccessToken', 'SPOAccessToken', 'TeamsAccessToken', 'TeamsUnifiedAccessToken')) {
                $Second[$Token] | Should -Be 'test-token'
            }
            ($script:Apps.Values | Measure-Object InteractiveCalls -Sum).Sum | Should -Be 5
            foreach ($App in @($UsedApps | Where-Object { $_.ClientId -ne '14d82eec-204b-4c2f-b7e8-296a70dab67e' })) {
                $App.SilentCalls | Should -BeGreaterThan 0
                $App.LastAccountId | Should -Be 'test-user.home-tenant'
            }
            foreach ($App in @($UsedApps | Where-Object { $_.ClientId -eq '14d82eec-204b-4c2f-b7e8-296a70dab67e' })) {
                $App.SilentCalls | Should -Be 0
            }

            Disconnect-SCuBATenant
            $Global:ScubaGearState.Session | Should -BeNullOrEmpty
            $Global:ScubaGearState.MsalAppCache.Count | Should -Be 0
        }
    }

    It 'preserves token diagnostics across the discovery and Graph module boundaries' {
        InModuleScope Connection {
            $Messages = @(Connect-Tenant -ProductNames aad -Verbose 4>&1)
            $Diagnostics = @($Messages | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })
            @($Diagnostics.Message | Where-Object { $_ -like 'No cached MSAL account*' }).Count | Should -Be 1
            @($Diagnostics.Message | Where-Object { $_ -like 'Acquired token silently*' }).Count | Should -Be 1
        }
    }

    It 'retains the Graph application across <Entry> entry and later requests in <Environment>' -TestCases @(
        @{ Entry = 'discovery-first'; Environment = 'commercial'; HostName = 'login.microsoftonline.com' },
        @{ Entry = 'discovery-first'; Environment = 'gcc'; HostName = 'login.microsoftonline.com' },
        @{ Entry = 'discovery-first'; Environment = 'gcchigh'; HostName = 'login.microsoftonline.us' },
        @{ Entry = 'discovery-first'; Environment = 'dod'; HostName = 'login.microsoftonline.us' },
        @{ Entry = 'explicit-first'; Environment = 'commercial'; HostName = 'login.microsoftonline.com' },
        @{ Entry = 'explicit-first'; Environment = 'gcc'; HostName = 'login.microsoftonline.com' },
        @{ Entry = 'explicit-first'; Environment = 'gcchigh'; HostName = 'login.microsoftonline.us' },
        @{ Entry = 'explicit-first'; Environment = 'dod'; HostName = 'login.microsoftonline.us' }
    ) {
        param($Entry, $Environment, $HostName)
        InModuleScope Connection -Parameters @{ Entry = $Entry; Environment = $Environment; HostName = $HostName } {
            param($Entry, $Environment, $HostName)
            $Graph = $script:Apps['14d82eec-204b-4c2f-b7e8-296a70dab67e']
            $Graph.AccountEnvironment = $HostName
            InModuleScope ConnectHelpers -Parameters @{ Environment = $Environment } {
                param($Environment)
                $script:TestEnvironment = $Environment
                Mock Get-M365EnvironmentByDomain { $script:TestEnvironment }
            }
            if ($Entry -eq 'discovery-first') {
                Connect-GraphHelper -Discovery -Scopes @('Organization.Read.All')
            }
            else {
                # Match ServicePrincipal.psm1's explicit connection without a tenant hint.
                Connect-GraphHelper -M365Environment $Environment -Scopes @('Application.Read.All')
            }
            $OriginalApp = $Global:ScubaGearState.MsalAppCache['PUB:14d82eec-204b-4c2f-b7e8-296a70dab67e']
            $ExpectedAuthority = if ($Entry -eq 'discovery-first') {
                'https://login.microsoftonline.com/organizations'
            } else { "https://$HostName/organizations" }

            $Result = Connect-Tenant -ProductNames aad

            $Result.ProdAuthFailed | Should -BeNullOrEmpty
            $Result.DetectedM365Environment | Should -Be $Environment
            InModuleScope ConnectHelpers -Parameters @{ Environment = $Environment } {
                param($Environment)
                Connect-GraphHelper -M365Environment $Environment -Scopes @('Organization.Read.All')
                Mock Invoke-RestMethod { [pscustomobject]@{ id = 'organization' } }
                (Invoke-ScubaGraphRequest -Uri '/v1.0/organization').id | Should -Be 'organization'
                $Params = $Global:ScubaGearState.Session.TokenParameters.Clone()
                Get-MsalAccessToken @Params -ForceRefresh | Should -Be 'test-token'
            }

            [object]::ReferenceEquals($Global:ScubaGearState.MsalAppCache['PUB:14d82eec-204b-4c2f-b7e8-296a70dab67e'], $OriginalApp) | Should -BeTrue
            $Graph.CreationCount | Should -Be 1
            $Graph.OriginalAuthority | Should -Be $ExpectedAuthority
            $Graph.ForCloudDiscovery | Should -Be ($Entry -eq 'discovery-first')
            $Graph.InteractiveCalls | Should -Be 1
            $Graph.Request.ForceRefresh | Should -BeTrue
            $Global:ScubaGearState.MsalAppCache.Count | Should -Be 1
        }
    }

    It 'selects the Graph account for first-run browser SSO when new clients enumerate no accounts' {
        InModuleScope Connection {
            foreach ($App in $script:Apps.Values) { $App.ExposeAccounts = $false }
            # Bootstrap and tenanted Graph still discover the account as in a normal scan.
            foreach ($Key in $script:Apps.Keys) {
                if ($Key -like '14d82eec-*') { $script:Apps[$Key].ExposeAccounts = $true }
            }
            $Result = Connect-Tenant -ProductNames aad,exo,powerbi,powerplatform,securitysuite,sharepoint,teams
            $Result.ProdAuthFailed | Should -BeNullOrEmpty
            ($script:Apps.Values | Measure-Object InteractiveCalls -Sum).Sum | Should -Be 5
            foreach ($App in $script:Apps.Values | Where-Object { -not $_.ExposeAccounts }) {
                $App.SilentCalls | Should -BeGreaterThan 0
                $App.LastAccountId | Should -Be 'test-user.home-tenant'
                $App.InteractiveCalls | Should -Be 1
                $App.BrowserAccountId | Should -Be 'test-user.home-tenant'
            }
        }
    }

    It 'falls back to the browser for a new client and retains its own refresh credentials' {
        InModuleScope Connection {
            $SPO = $script:Apps['9bc3ab49-b65d-410a-85ad-de819febfddc']
            $First = Connect-Tenant -ProductNames aad,sharepoint -M365Environment commercial
            $First.ProdAuthFailed | Should -BeNullOrEmpty
            $SPO.SilentCalls | Should -Be 1
            $SPO.InteractiveCalls | Should -Be 1
            $SPO.BrowserAccountId | Should -Be 'test-user.home-tenant'
            $Second = Connect-Tenant -ProductNames aad,sharepoint -M365Environment commercial
            $Second.ProdAuthFailed | Should -BeNullOrEmpty
            $SPO.SilentCalls | Should -Be 2
            $SPO.InteractiveCalls | Should -Be 1
        }
    }

    It 'keeps product credentials in their own caches and retains the discovery application for Graph requests' {
        InModuleScope Connection {
            $null = Connect-Tenant -ProductNames aad,sharepoint -M365Environment commercial
            $Graph = $script:Apps['14d82eec-204b-4c2f-b7e8-296a70dab67e']
            $Graph.InteractiveCalls | Should -Be 1
            $Graph.SilentCalls | Should -Be 1
            [object]::ReferenceEquals($Global:ScubaGearState.MsalAppCache['PUB:14d82eec-204b-4c2f-b7e8-296a70dab67e'], $Graph) | Should -BeTrue
            $Graph.UserTokenCache.Clients | Should -Not -Contain '9bc3ab49-b65d-410a-85ad-de819febfddc'
            $null = Connect-Tenant -ProductNames aad -M365Environment commercial
            # A retained session obtains a token when Graph is actually called, rather than reconnecting.
            InModuleScope ConnectHelpers {
                Mock Invoke-RestMethod { [pscustomobject]@{ value = @() } }
                $null = Invoke-ScubaGraphRequest -Uri '/v1.0/organization'
            }
            $Graph.UserTokenCache.Clients | Should -Not -Contain '9bc3ab49-b65d-410a-85ad-de819febfddc'
            $Graph.SilentCalls | Should -Be 2
            $Graph.CreationCount | Should -Be 1
        }
    }

    It 'uses the Graph account when another account appears first in the product cache' {
        InModuleScope Connection {
            $null = Connect-Tenant -ProductNames aad -M365Environment commercial
            $SPO = $script:Apps['9bc3ab49-b65d-410a-85ad-de819febfddc']
            $OtherAccount = [pscustomobject]@{ HomeAccountId = [pscustomobject]@{ Identifier = 'other-user.home-tenant' } }
            $SPO.UserTokenCache.Accounts = @($OtherAccount)
            Get-MsalAccessToken -ClientId '9bc3ab49-b65d-410a-85ad-de819febfddc' -Tenant contoso.onmicrosoft.com `
                -Scope 'https://contoso-admin.sharepoint.com/.default' -M365Environment commercial | Should -Be 'test-token'
            $SPO = $script:Apps['9bc3ab49-b65d-410a-85ad-de819febfddc']
            $SPO.LastAccountId | Should -Be 'test-user.home-tenant'
            $SPO.InteractiveCalls | Should -Be 1
            $SPO.BrowserAccountId | Should -Be 'test-user.home-tenant'
        }
    }

    It 'skips discovery and preserves the existing session on a later automatic scan' {
        InModuleScope Connection {
            $null = Connect-Tenant -ProductNames aad -M365Environment commercial
            $Session = $Global:ScubaGearState.Session
            Mock Connect-GraphHelper { throw 'Discovery failed' }
            $Result = Connect-Tenant -ProductNames aad
            $Result.ProdAuthFailed | Should -BeNullOrEmpty
            $Result.DetectedM365Environment | Should -Be 'commercial'
            [object]::ReferenceEquals($Global:ScubaGearState.Session, $Session) | Should -BeTrue
            Should -Invoke Connect-GraphHelper -Times 0 -Exactly
            $Global:ScubaGearState.MsalAppCache.Count | Should -BeGreaterThan 0
        }
    }

    It 'acquires additional Graph scopes when aad is added to a later scan' {
        InModuleScope Connection {
            $null = Connect-Tenant -ProductNames sharepoint
            $Session = $Global:ScubaGearState.Session
            $Session.TokenParameters.Scope | Should -Be @('Organization.Read.All')
            $Graph = $script:Apps['14d82eec-204b-4c2f-b7e8-296a70dab67e']
            $InitialCalls = $Graph.SilentCalls

            $Result = Connect-Tenant -ProductNames aad

            $Result.ProdAuthFailed | Should -BeNullOrEmpty
            [object]::ReferenceEquals($Global:ScubaGearState.Session, $Session) | Should -BeTrue
            foreach ($Scope in @(Get-ScubaGearEntraMinimumPermissions)) {
                $Session.TokenParameters.Scope | Should -Contain $Scope
            }
            $Session.TokenParameters.Tenant | Should -Be '305102d0-7ccc-4007-83bb-ac1f44f8d620'
            $Graph.SilentCalls | Should -Be ($InitialCalls + 1)
            ($script:Apps.Values | Measure-Object InteractiveCalls -Sum).Sum | Should -Be 2
        }
    }

    It 'resolves organization metadata only once when <FirstProduct> runs before Exchange' -TestCases @(
        @{ FirstProduct = 'exo' },
        @{ FirstProduct = 'powerplatform' },
        @{ FirstProduct = 'sharepoint' },
        @{ FirstProduct = 'powerbi' },
        @{ FirstProduct = 'teams' }
    ) {
        param($FirstProduct)
        InModuleScope Connection -Parameters @{ FirstProduct = $FirstProduct } {
            param($FirstProduct)
            $Products = @(@($FirstProduct) + @('exo', 'securitysuite', 'powerplatform', 'sharepoint', 'powerbi', 'teams') | Select-Object -Unique)

            $Result = Connect-Tenant -ProductNames $Products

            $Result.ProdAuthFailed | Should -BeNullOrEmpty
            Should -Invoke Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                $Commandlet -eq 'Get-MgBetaOrganization'
            }
            Should -Invoke Get-ExchangeOnlineApiEndpoint -Times 1 -Exactly -ParameterFilter {
                $TenantId -eq '305102d0-7ccc-4007-83bb-ac1f44f8d620' -and $TenantDomain -eq 'contoso.onmicrosoft.com'
            }
            Should -Invoke Get-ComplianceApiEndpoint -Times 1 -Exactly -ParameterFilter {
                $TenantId -eq '305102d0-7ccc-4007-83bb-ac1f44f8d620' -and $TenantDomain -eq 'contoso.onmicrosoft.com'
            }
        }
    }

    It 'retains the established session and scopes if additional Graph authorization fails' {
        InModuleScope Connection {
            $null = Connect-Tenant -ProductNames sharepoint
            $Session = $Global:ScubaGearState.Session
            $TokenParameters = $Session.TokenParameters
            Mock Get-MsalAccessToken { throw 'Additional consent required' }

            $Result = Connect-Tenant -ProductNames aad -WarningAction SilentlyContinue

            $Result.ProdAuthFailed | Should -Be @('aad')
            [object]::ReferenceEquals($Global:ScubaGearState.Session, $Session) | Should -BeTrue
            [object]::ReferenceEquals($Session.TokenParameters, $TokenParameters) | Should -BeTrue
            $Session.TokenParameters.Scope | Should -Be @('Organization.Read.All')
        }
    }
}

AfterAll {
    Remove-Module Connection, ConnectHelpers, PermissionsHelper -ErrorAction SilentlyContinue
}
