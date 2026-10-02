[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
param()

Describe -Tag 'Analyzer' -Name 'ScubaConfigAnalyzerGraphHelper (MSAL, no Microsoft.Graph.Authentication)' {
    BeforeAll {
        $script:scubaGearRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $script:configAppRoot = Join-Path $script:scubaGearRoot 'Modules\ScubaConfigApp'
        $script:graphHelperPath = Join-Path $script:configAppRoot 'ScubaConfigAnalyzerHelpers\ScubaConfigAnalyzerGraphHelper.psm1'
        $script:schemaHelperPath = Join-Path $script:configAppRoot 'ScubaConfigAnalyzerHelpers\ScubaConfigAnalyzerSchemaHelper.psm1'
        $script:analyzerControlPath = Join-Path $script:configAppRoot 'ScubaConfigAnalyzer_Control_en-US.json'
        $script:apiCatalogPath = Join-Path $script:scubaGearRoot 'schemas\ScubaGearApiCatalog.json'

        # Fake stand-in for ScubaGear's real Connection\ConnectHelpers.psm1. Connect-ScubaAnalyzerGraph,
        # Invoke-ScubaGraphGet, and Get-ScubaTenantGraphData each do their own
        # `Import-Module $syncHash.ConnectHelpersPath -Force` at call time (matching how the analyzer
        # resolves it in production), so pointing $syncHash.ConnectHelpersPath at this double lets the
        # tests run hermetically (no MSAL assemblies, no network) without a Pester Mock being clobbered
        # by that re-import.
        $script:FakeConnectHelpersPath = Join-Path $TestDrive 'FakeConnectHelpers.psm1'
        @'
function Connect-GraphHelper {
    param([string]$M365Environment, [string[]]$Scopes, [hashtable]$ServicePrincipalParams)
    $Global:FakeConnectHelpersLog.Add([pscustomobject]@{ Function = "Connect-GraphHelper"; M365Environment = $M365Environment; Scopes = $Scopes; ServicePrincipalParams = $ServicePrincipalParams }) | Out-Null
    if ($Global:FakeConnectHelpersConfig.ConnectThrows) { throw $Global:FakeConnectHelpersConfig.ConnectThrows }
}
function Get-ScubaGearContext {
    $Global:FakeConnectHelpersLog.Add([pscustomobject]@{ Function = "Get-ScubaGearContext" }) | Out-Null
    return $Global:FakeConnectHelpersConfig.ContextResult
}
function Invoke-ScubaGraphRequest {
    param([string]$Uri, [string]$Method = "GET", $Body, $Headers, $ContentType, $OutputType, $MaxRetries)
    $Global:FakeConnectHelpersLog.Add([pscustomobject]@{ Function = "Invoke-ScubaGraphRequest"; Uri = $Uri; Method = $Method }) | Out-Null
    & $Global:FakeConnectHelpersConfig.GraphRequestHandler $Uri $Method
}
'@ | Set-Content -Path $script:FakeConnectHelpersPath -Encoding UTF8

        Import-Module $script:schemaHelperPath -Force
        Import-Module $script:graphHelperPath -Force
    }

    BeforeEach {
        $Global:FakeConnectHelpersLog = [System.Collections.Generic.List[object]]::new()
        $Global:FakeConnectHelpersConfig = @{
            ContextResult = [pscustomobject]@{ Account = 'admin@contoso.onmicrosoft.com'; TenantId = 'ctx-tenant-guid'; ClientId = 'client-id'; AuthType = 'Delegated' }
            ConnectThrows = $null
            GraphRequestHandler = { param($Uri) throw "No handler configured for '$Uri'" }
        }
        $Global:syncHash = @{
            ConnectHelpersPath = $script:FakeConnectHelpersPath
            ScAApiOperations = @{}
            ScACaRules = $null
            ScAApiCatalog = @{}
            ScAExclusionDefinitions = @{}
            ScAActivitySink = $null
        }
    }

    AfterAll {
        Remove-Item Variable:\FakeConnectHelpersLog -ErrorAction SilentlyContinue
        Remove-Item Variable:\FakeConnectHelpersConfig -ErrorAction SilentlyContinue
        Remove-Item Variable:\syncHash -ErrorAction SilentlyContinue
        Remove-Module ScubaConfigAnalyzerGraphHelper -ErrorAction SilentlyContinue
        Remove-Module ScubaConfigAnalyzerSchemaHelper -ErrorAction SilentlyContinue
    }

    Context 'Connect-ScubaAnalyzerGraph' {
        It 'connects interactively with the requested scopes and returns Get-ScubaGearContext' {
            $result = Connect-ScubaAnalyzerGraph -Scopes @('Directory.Read.All') -M365Environment 'commercial'

            $result.Account | Should -Be 'admin@contoso.onmicrosoft.com'
            $calls = @($Global:FakeConnectHelpersLog | Where-Object Function -eq 'Connect-GraphHelper')
            $calls.Count | Should -Be 1
            $calls[0].M365Environment | Should -Be 'commercial'
            $calls[0].Scopes | Should -Be @('Directory.Read.All')
            $calls[0].ServicePrincipalParams | Should -BeNullOrEmpty
            @($Global:FakeConnectHelpersLog | Where-Object Function -eq 'Get-ScubaGearContext').Count | Should -Be 1
        }

        It 'connects app-only with certificate params when AppId + CertificateThumbprint are supplied' {
            $result = Connect-ScubaAnalyzerGraph -M365Environment 'gcchigh' -AppId 'app-id' -CertificateThumbprint 'ABCD' -Organization 'contoso.onmicrosoft.com'

            $result.Account | Should -Be 'admin@contoso.onmicrosoft.com'
            $calls = @($Global:FakeConnectHelpersLog | Where-Object Function -eq 'Connect-GraphHelper')
            $calls[0].M365Environment | Should -Be 'gcchigh'
            $calls[0].ServicePrincipalParams.CertThumbprintParams.CertificateThumbprint | Should -Be 'ABCD'
            $calls[0].ServicePrincipalParams.CertThumbprintParams.AppID | Should -Be 'app-id'
            $calls[0].ServicePrincipalParams.CertThumbprintParams.Organization | Should -Be 'contoso.onmicrosoft.com'
        }

        It 'propagates a Connect-GraphHelper failure instead of silently continuing' {
            $Global:FakeConnectHelpersConfig.ConnectThrows = 'Sign-in failed'
            { Connect-ScubaAnalyzerGraph -Scopes @('Directory.Read.All') -M365Environment 'commercial' } | Should -Throw 'Sign-in failed'
        }
    }

    Context 'Invoke-ScubaGraphGet' {
        It 'returns a single non-collection object wrapped in an array' {
            $Global:FakeConnectHelpersConfig.GraphRequestHandler = { [pscustomobject]@{ id = 'abc'; displayName = 'Contoso' } }

            $result = @(Invoke-ScubaGraphGet -Uri '/v1.0/organization/abc')

            $result.Count | Should -Be 1
            $result[0].displayName | Should -Be 'Contoso'
        }

        It 'returns the already-aggregated .value collection from Invoke-ScubaGraphRequest' {
            $Global:FakeConnectHelpersConfig.GraphRequestHandler = { [pscustomobject]@{ value = @([pscustomobject]@{ id = '1' }, [pscustomobject]@{ id = '2' }) } }

            $result = @(Invoke-ScubaGraphGet -Uri '/v1.0/identity/conditionalAccess/policies')

            $result.Count | Should -Be 2
            @($result.id) | Should -Be @('1', '2')
        }

        It 'returns an empty array when Invoke-ScubaGraphRequest returns nothing' {
            $Global:FakeConnectHelpersConfig.GraphRequestHandler = { $null }

            $result = @(Invoke-ScubaGraphGet -Uri '/v1.0/organization')

            $result.Count | Should -Be 0
        }
    }

    Context 'Get-ScubaTenantGraphData' {
        It 'resolves TenantId, OrgDisplayName, and the primary domain via Graph REST' {
            $Global:FakeConnectHelpersConfig.GraphRequestHandler = {
                param($Uri)
                if ($Uri -like '*organization*') {
                    return [pscustomobject]@{
                        value = @([pscustomobject]@{
                            id = 'org-tenant-guid'
                            displayName = 'Contoso'
                            verifiedDomains = @(
                                [pscustomobject]@{ name = 'contoso.onmicrosoft.com'; isInitial = $true; isDefault = $false }
                                [pscustomobject]@{ name = 'contoso.com'; isInitial = $false; isDefault = $true }
                            )
                        })
                    }
                }
                throw "Unexpected Uri: $Uri"
            }
            # No baselineValidations entry for 'aad' -> $controls stays empty, so only the tenant
            # identity + organization block runs (the CA-policy / exclusion-fetch blocks are skipped).
            $baselineSchema = [pscustomobject]@{ baselineValidations = [pscustomobject]@{} }

            $data = Get-ScubaTenantGraphData -Product 'aad' -BaselineSchema $baselineSchema -ApiCatalogPath $script:apiCatalogPath -AnalyzerControlPath $script:analyzerControlPath

            $data.TenantId | Should -Be 'ctx-tenant-guid'
            $data.OrgDisplayName | Should -Be 'Contoso'
            $data.Organization | Should -Be 'contoso.com'
        }

        It 'does not throw when the organization lookup fails' {
            $Global:FakeConnectHelpersConfig.GraphRequestHandler = { throw 'Insufficient privileges' }
            $baselineSchema = [pscustomobject]@{ baselineValidations = [pscustomobject]@{} }

            { Get-ScubaTenantGraphData -Product 'aad' -BaselineSchema $baselineSchema -ApiCatalogPath $script:apiCatalogPath -AnalyzerControlPath $script:analyzerControlPath } | Should -Not -Throw
        }
    }
}
