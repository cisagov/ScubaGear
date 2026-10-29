$OrchestratorPath = '../../../../Modules/Orchestrator.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $OrchestratorPath) -Function 'Invoke-SCuBA' -Force

InModuleScope Orchestrator {
    Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba' {
        BeforeAll {
            Mock -ModuleName Orchestrator Invoke-Connection { @() }
            function Get-TenantDetail {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($M365Environment)
                throw 'this will be mocked'
            }
            Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
            function Invoke-ProviderList {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Mock signature must match the command parameters.')]
                param($ScubaConfig, $TenantDetails, $ModuleVersion, $OutFolderPath, $Guid, $ConnectionResult)
                throw 'this will be mocked'
            }
            Mock -ModuleName Orchestrator Invoke-ProviderList {}
            function Invoke-RunRego {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Invoke-RunRego {}

            Mock -ModuleName Orchestrator Invoke-ReportCreation {}
            Mock -ModuleName Orchestrator Merge-JsonOutput {}
            function Disconnect-SCuBATenant {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Disconnect-SCuBATenant {}

            function Get-ScubaDefault {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Get-ScubaDefault {"."}

            function Merge-JsonOutput {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Merge-JsonOutput {}

            function ConvertTo-ResultsCsv {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator ConvertTo-ResultsCsv {}
            function ConvertTo-RiskyAppsCsv {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator ConvertTo-RiskyAppsCsv {}

            Mock -CommandName New-Item {}
            Mock -CommandName Copy-Item {}
            function Initialize-ScubaLogging {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Initialize-ScubaLogging {}

            function Write-ScubaLog {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Write-ScubaLog {}

            function Write-ScubaRunDetails {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Write-ScubaRunDetails {}

            function Trace-ScubaFunction {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
                param(
                    [string] $FunctionName,
                    [hashtable] $Parameters,
                    [switch] $LogReturnValue,
                    [scriptblock] $ScriptBlock
                )

                throw 'this will be mocked'
            }
            Mock -ModuleName Orchestrator Trace-ScubaFunction {
                $scriptBlockToInvoke = $args |
                    Where-Object { $_ -is [scriptblock] } |
                    Select-Object -First 1

                & $scriptBlockToInvoke
            }

            function Get-M365EnvironmentByDomain {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Get-M365EnvironmentByDomain {}

            function Get-ServicePrincipalParams {throw 'this will be mocked'}
            Mock -ModuleName Orchestrator Get-ServicePrincipalParams { @{CertThumbprintParams = @{AppID="a"; CertificateThumbprint="b"; Organization="c"}} }
        }
        Context 'Interactive environment discovery' {
            It 'uses the detected environment for tenant details and providers' {
                Mock Invoke-Connection { @{ DetectedM365Environment = 'gcchigh'; ProdAuthFailed = @() } }
                Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings
                Should -Invoke Invoke-Connection -Times 1 -Exactly
                Should -Invoke Get-TenantDetail -Times 1 -Exactly -ParameterFilter { $M365Environment -eq 'gcchigh' }
                Should -Invoke Invoke-ProviderList -Times 1 -Exactly -ParameterFilter { $ScubaConfig.M365Environment -eq 'gcchigh' }
            }

            It 'uses the discovered environment even when an environment was explicitly provided' {
                Mock Invoke-Connection { @{ DetectedM365Environment = 'gcchigh'; ProdAuthFailed = @() } }
                Invoke-SCuBA -ProductNames aad -M365Environment dod -Quiet -SilenceBODWarnings
                Should -Invoke Get-TenantDetail -Times 1 -Exactly -ParameterFilter { $M365Environment -eq 'gcchigh' }
                Should -Invoke Invoke-ProviderList -Times 1 -Exactly -ParameterFilter { $ScubaConfig.M365Environment -eq 'gcchigh' }
            }
        }
        Context 'Disconnect on exit' {
            BeforeEach {
                Mock Invoke-Connection { @{ ProdAuthFailed = @() } }
            }

            It 'disconnects by default when the scan completes' {
                Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings
                Should -Invoke Disconnect-SCuBATenant -Times 1 -Exactly -ParameterFilter { -not $ProductNames }
            }

            It 'disconnects when -DisconnectOnExit is supplied' {
                Invoke-SCuBA -ProductNames aad -DisconnectOnExit -Quiet -SilenceBODWarnings
                Should -Invoke Disconnect-SCuBATenant -Times 1 -Exactly
            }

            It 'keeps the session when -DisconnectOnExit:$false is supplied' {
                Invoke-SCuBA -ProductNames aad -DisconnectOnExit:$false -Quiet -SilenceBODWarnings
                Should -Invoke Disconnect-SCuBATenant -Times 0 -Exactly
            }

            It 'disconnects when sign-in fails' {
                Mock Invoke-Connection { throw 'sign-in failed' }
                { Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings } | Should -Throw '*sign-in failed*'
                Should -Invoke Disconnect-SCuBATenant -Times 1 -Exactly
            }

            It 'disconnects when the tenant lookup fails' {
                Mock Get-TenantDetail { throw 'tenant lookup failed' }
                { Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings } | Should -Throw '*tenant lookup failed*'
                Should -Invoke Disconnect-SCuBATenant -Times 1 -Exactly
            }

            It 'disconnects when every product fails authentication' {
                Mock Invoke-Connection { @{ ProdAuthFailed = @('aad') } }
                Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings
                Should -Invoke Invoke-ProviderList -Times 0 -Exactly
                Should -Invoke Disconnect-SCuBATenant -Times 1 -Exactly
            }

            It 'disconnects when provider collection fails' {
                Mock Invoke-ProviderList { throw 'provider failed' }
                { Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings } | Should -Throw '*provider failed*'
                Should -Invoke Disconnect-SCuBATenant -Times 1 -Exactly
            }

            It 'keeps the session after a failure when -DisconnectOnExit:$false is supplied' {
                Mock Invoke-Connection { throw 'sign-in failed' }
                { Invoke-SCuBA -ProductNames aad -DisconnectOnExit:$false -Quiet -SilenceBODWarnings } | Should -Throw '*sign-in failed*'
                Should -Invoke Disconnect-SCuBATenant -Times 0 -Exactly
            }
        }
        Context 'Run identity' {
            BeforeEach {
                Mock Invoke-Connection { @{ ProdAuthFailed = @() } }
                Mock Write-Information {}
                Mock Write-Host {}
                Mock Get-ScubaGearRunIdentity {
                    [pscustomobject]@{ AuthType = 'Delegated'; Account = 'jane.doe@contoso.com'; AppId = '11111111-2222-3333-4444-555555555555'; Tenant = 'tenant-guid'; Environment = 'commercial' }
                }
            }

            # Screenshots of the console end up in public bug reports; Get-ScubaGearContext is how a user asks for this.
            It 'does not print the account, app or tenant the run signed in with' {
                Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings
                Should -Invoke Write-Information -Times 0 -Exactly -ParameterFilter { "$MessageData" -match 'jane\.doe|tenant-guid|11111111-2222' }
                Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { "$Object" -match 'jane\.doe|tenant-guid|11111111-2222' }
            }

            It 'points the user to Get-ScubaGearContext once, when the run signed in' {
                Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings
                Should -Invoke Write-Information -Times 1 -Exactly -ParameterFilter { "$MessageData" -like '*Get-ScubaGearContext*' }
            }

            It 'says nothing about Get-ScubaGearContext when there is no sign-in' {
                Mock Get-ScubaGearRunIdentity { }
                Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings
                Should -Invoke Write-Information -Times 0 -Exactly -ParameterFilter { "$MessageData" -like '*Get-ScubaGearContext*' }
            }

            It 'does not mention it when every product fails authentication' {
                Mock Invoke-Connection { @{ ProdAuthFailed = @('aad') } }
                Invoke-SCuBA -ProductNames aad -Quiet -SilenceBODWarnings
                Should -Invoke Write-Information -Times 0 -Exactly -ParameterFilter { "$MessageData" -like '*Get-ScubaGearContext*' }
            }
        }
        Context 'When checking the conformance of commercial tenants' {
            BeforeAll {
                [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'SplatParams')]
                $SplatParams = @{
                    M365Environment = 'commercial';
                    KeepIndividualJSON = $true;
                }
            }
            It 'Do it quietly (Do not automatically show report)' {
                {Invoke-Scuba -Quiet -SilenceBODWarnings} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-ReportCreation -Exactly -Times 1 -ParameterFilter {$Quiet -eq $true}
            }
            It 'Show report' {
                {Invoke-Scuba -SilenceBODWarnings} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-ReportCreation -Exactly -Times 1 -ParameterFilter {$Quiet -eq $false}
            }
            It 'Given -ProductNames aad should not throw' {
                $SplatParams += @{
                    ProductNames = @("aad")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames securitysuite should not throw' {
                $SplatParams += @{
                    ProductNames = @("securitysuite")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames exo should not throw' {
                $SplatParams += @{
                    ProductNames = @("exo")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames powerplatform should not throw' {
                $SplatParams += @{
                    ProductNames = @("powerplatform")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames teams should not throw' {
                $SplatParams += @{
                    ProductNames = @("teams")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -ProductNames * and -DisconnectOnExit should not throw' {
                $SplatParams += @{
                    ProductNames = @("*")
                    DisconnectOnExit = $true
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Should only run each baseline once if provider names contains duplicates' {
                {Invoke-Scuba -ProductNames aad,aad -SilenceBODWarnings} | Should -Not -Throw
                # After refactor, -ProductNames are consolidated into ScubaConfig and duplicates removed
                # Validate only a single invocation and that consolidated ProductNames contains exactly one 'aad'
                Should -Invoke Invoke-ReportCreation -ParameterFilter {$ScubaConfig.ProductNames -eq 'aad'}
            }
        }
        Context 'Service Principal provided'{
            It 'All items given as not null or empty'{
                $SplatParams += @{
                    AppID = "a"
                    CertificateThumbprint = "b"
                    Organization = "c"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
                Should -Invoke -CommandName Invoke-Connection -Exactly -Times 1 -ParameterFilter {$ScubaConfig.AppID -eq 'a'}
            }
            It 'Items given as empty string'{
                $SplatParams += @{
                    AppID = ""
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Throw
            }
            It 'Items given as null'{
                $SplatParams += @{
                    AppID = $null
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Throw
            }
        }
        Context 'When checking module version' {
            It 'Given -Version should not throw' {
                {Invoke-Scuba -Version} | Should -Not -Throw
            }
        }
        Context 'When modifying the CSV output files names' {
            It 'Given -OutCsvFileName should not throw' {
                $SplatParams += @{
                    OutCsvFileName = "a"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -OutActionPlanFileName should not throw' {
                $SplatParams += @{
                    OutActionPlanFileName = "a"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given both -OutCsvFileName and -OutActionPlanFileName should not throw' {
                $SplatParams += @{
                    OutCsvFileName = "a"
                    OutActionPlanFileName = "b"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Not -Throw
            }
            It 'Given -OutCsvFileName and -OutActionPlanFileName equal should throw' {
                $SplatParams += @{
                    OutCsvFileName = "a"
                    OutActionPlanFileName = "a"
                    SilenceBODWarnings = $true
                }
                {Invoke-Scuba @SplatParams} | Should -Throw
            }
        }
    }
}
AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
}
