[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

Describe -Tag 'Analyzer' -Name 'ScubaConfigAnalyzerExchangeHelper (MSAL, no Get-MgContext/Invoke-MgGraphRequest)' {
    BeforeAll {
        $script:scubaGearRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $script:configAppRoot = Join-Path $script:scubaGearRoot 'Modules\ScubaConfigApp'
        $script:exchangeHelperPath = Join-Path $script:configAppRoot 'ScubaConfigAnalyzerHelpers\ScubaConfigAnalyzerExchangeHelper.psm1'

        # Fake stand-ins for ScubaGear's real Connection\ConnectHelpers.psm1 and
        # Providers\ProviderHelpers\EXORestHelper.psm1. Connect-ScubaAnalyzerExchange imports both
        # via $syncHash.*Path -Force at call time, so pointing those paths at these doubles keeps the
        # tests hermetic (no MSAL assemblies, no network) without a Mock being clobbered by re-import.
        $script:FakeConnectHelpersPath = Join-Path $TestDrive 'FakeConnectHelpers.psm1'
        @'
function Get-MsalAccessToken {
    param($Scope, $CertificateThumbprint, $AppID, $ClientId, $Tenant, $M365Environment)
    $Global:FakeExchangeLog.Add([pscustomobject]@{
        Function = "Get-MsalAccessToken"; Scope = $Scope; CertificateThumbprint = $CertificateThumbprint
        AppID = $AppID; ClientId = $ClientId; Tenant = $Tenant; M365Environment = $M365Environment
    }) | Out-Null
    return "fake-exo-token"
}
function Invoke-ScubaGraphRequest {
    param([string]$Uri, [string]$Method = "GET", $Body, $Headers, $ContentType, $OutputType, $MaxRetries)
    $Global:FakeExchangeLog.Add([pscustomobject]@{ Function = "Invoke-ScubaGraphRequest"; Uri = $Uri }) | Out-Null
    & $Global:FakeExchangeConfig.GraphRequestHandler $Uri
}
'@ | Set-Content -Path $script:FakeConnectHelpersPath -Encoding UTF8

        $script:FakeEXORestHelperPath = Join-Path $TestDrive 'FakeEXORestHelper.psm1'
        @'
function Get-ExchangeOnlineScope {
    param([string]$M365Environment)
    return "https://outlook.office365.com/.default"
}
function Get-ExchangeOnlineApiEndpoint {
    param([string]$TenantId, [string]$TenantDomain, [string]$M365Environment, [string]$AccessToken)
    $Global:FakeExchangeLog.Add([pscustomobject]@{
        Function = "Get-ExchangeOnlineApiEndpoint"; TenantId = $TenantId; TenantDomain = $TenantDomain
    }) | Out-Null
    return "https://outlook.office365.com/adminapi/beta/$TenantId/InvokeCommand"
}
'@ | Set-Content -Path $script:FakeEXORestHelperPath -Encoding UTF8

        Import-Module $script:exchangeHelperPath -Force

        # Production imports every *.psm1 in the helpers folder into the same runspace, so
        # Write-ScubaAnalyzerLog (defined in ScubaConfigAnalyzerUIHelper.psm1) is always available to
        # Connect-ScubaAnalyzerExchange's catch blocks. Stub it here rather than importing the full
        # WPF-dependent UI helper module.
        function Global:Write-ScubaAnalyzerLog {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'No-op logging stub for tests; parameters intentionally unused.')]
            param([string]$Message, [string]$Level = 'Info')
        }
    }

    BeforeEach {
        $Global:FakeExchangeLog = [System.Collections.Generic.List[object]]::new()
        $Global:FakeExchangeConfig = @{
            GraphRequestHandler = {
                [pscustomobject]@{
                    value = @([pscustomobject]@{
                        id = 'org-tenant-guid'
                        verifiedDomains = @([pscustomobject]@{ name = 'contoso.onmicrosoft.com'; isInitial = $true })
                    })
                }
            }
        }
        $Global:syncHash = @{
            ConnectHelpersPath = $script:FakeConnectHelpersPath
            EXORestHelperPath  = $script:FakeEXORestHelperPath
        }
    }

    AfterAll {
        Remove-Item Variable:\FakeExchangeLog -ErrorAction SilentlyContinue
        Remove-Item Variable:\FakeExchangeConfig -ErrorAction SilentlyContinue
        Remove-Item Variable:\syncHash -ErrorAction SilentlyContinue
        Remove-Item Function:\Write-ScubaAnalyzerLog -ErrorAction SilentlyContinue
        Remove-Module ScubaConfigAnalyzerExchangeHelper -ErrorAction SilentlyContinue
    }

    Context 'Connect-ScubaAnalyzerExchange' {
        It 'resolves the tenant id/domain via Graph REST and acquires a delegated EXO token' {
            $result = Connect-ScubaAnalyzerExchange -M365Environment 'commercial' -Organization 'contoso.onmicrosoft.com'

            $result | Should -BeTrue
            $Global:syncHash.EXOAccessToken | Should -Be 'fake-exo-token'
            $Global:syncHash.EXOApiEndpoint | Should -Be 'https://outlook.office365.com/adminapi/beta/org-tenant-guid/InvokeCommand'

            $tokenCall = @($Global:FakeExchangeLog | Where-Object Function -eq 'Get-MsalAccessToken')[0]
            $tokenCall.ClientId | Should -Be 'fb78d390-0c51-40cd-8e17-fdbfab77341b'
            $tokenCall.CertificateThumbprint | Should -BeNullOrEmpty
            $tokenCall.Tenant | Should -Be 'contoso.onmicrosoft.com'
        }

        It 'acquires an app-only EXO token via certificate auth when AppId + CertificateThumbprint are supplied' {
            $result = Connect-ScubaAnalyzerExchange -M365Environment 'commercial' -Organization 'contoso.onmicrosoft.com' -AppId 'app-id' -CertificateThumbprint 'ABCD'

            $result | Should -BeTrue
            $tokenCall = @($Global:FakeExchangeLog | Where-Object Function -eq 'Get-MsalAccessToken')[0]
            $tokenCall.CertificateThumbprint | Should -Be 'ABCD'
            $tokenCall.AppID | Should -Be 'app-id'
        }

        It 'throws a clear error when no tenant id can be resolved' {
            $Global:FakeExchangeConfig.GraphRequestHandler = { throw 'Insufficient privileges' }

            { Connect-ScubaAnalyzerExchange -M365Environment 'commercial' } | Should -Throw '*no Graph tenant context*'
        }
    }
}
