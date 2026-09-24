$HelperPath = '../../../../../Modules/Providers/ProviderHelpers/EXORestHelper.psm1'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $HelperPath) -Function 'Invoke-EXORestMethod', 'Get-ComplianceApiEndpoint', 'Get-ExchangeOnlineApiEndpoint' -Force

InModuleScope EXORestHelper {
    Describe -Tag 'EXORestHelper' -Name 'Invoke-EXORestMethod' {
        Context 'Delegation to Invoke-ScubaRestMethod' {
            It 'Passes the expected parameters and returns the value property of the response' {
                Mock -ModuleName EXORestHelper Invoke-ScubaRestMethod {
                    return [pscustomobject]@{ value = @(@{ Name = 'Test Domain' }) }
                }
                $Result = Invoke-EXORestMethod -CmdletName 'Get-RemoteDomain' -ApiEndpoint 'https://outlook.office365.com/adminapi/beta/tenant123/InvokeCommand' -AccessToken 'tok'
                @($Result)[0].Name | Should -Be 'Test Domain'
                Should -Invoke -ModuleName EXORestHelper Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                    $BaseUrl -eq 'https://outlook.office365.com/adminapi/beta/tenant123/InvokeCommand' -and
                    $Endpoint -eq '' -and
                    $AccessToken -eq 'tok' -and
                    $Method -eq 'POST' -and
                    $TimeoutSec -eq 30 -and
                    $MaxRetries -eq 3 -and
                    $RetryDelaySeconds -eq 5 -and
                    $AdditionalHeaders['Prefer'] -eq 'odata.maxpagesize=1000' -and
                    $AdditionalHeaders['X-ResponseFormat'] -eq 'json' -and
                    $AdditionalHeaders['User-Agent'] -eq 'ScubaGear' -and
                    ($Body | ConvertFrom-Json).CmdletInput.CmdletName -eq 'Get-RemoteDomain'
                }
            }

            It 'Passes the Parameters hashtable through in the request body' {
                Mock -ModuleName EXORestHelper Invoke-ScubaRestMethod {
                    return [pscustomobject]@{ value = @() }
                }
                $null = Invoke-EXORestMethod -CmdletName 'Get-Something' -ApiEndpoint 'https://outlook.office365.com/adminapi/beta/tenant123/InvokeCommand' `
                    -AccessToken 'tok' -Parameters @{ Identity = 'test' }
                Should -Invoke -ModuleName EXORestHelper Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                    ($Body | ConvertFrom-Json).CmdletInput.Parameters.Identity -eq 'test'
                }
            }

            It 'Wraps failures with a descriptive error message' {
                Mock -ModuleName EXORestHelper Invoke-ScubaRestMethod { throw "Simulated failure" }
                { Invoke-EXORestMethod -CmdletName 'Get-RemoteDomain' -ApiEndpoint 'https://outlook.office365.com/adminapi/beta/tenant123/InvokeCommand' -AccessToken 'tok' } |
                    Should -Throw "*Exchange Online API call 'Get-RemoteDomain' failed*"
            }
        }
    }

    Describe -Tag 'EXORestHelper', 'Network' -Name 'Resolve-ScubaFrontDoorEndpoint (via Get-ComplianceApiEndpoint / Get-ExchangeOnlineApiEndpoint)' {
        Context 'Front-door does not redirect (falls back to default endpoint)' {
            It 'Get-ExchangeOnlineApiEndpoint falls back to the default InvokeCommand endpoint' {
                Mock -ModuleName EXORestHelper Get-ScubaGearPermissions { return 'https://httpbin.org' }
                $Endpoint = Get-ExchangeOnlineApiEndpoint -TenantId 'tenant123' -TenantDomain 'contoso.onmicrosoft.com' `
                    -M365Environment 'commercial' -AccessToken 'tok'
                $Endpoint | Should -Be 'https://httpbin.org/adminapi/beta/tenant123/InvokeCommand'
            }

            It 'Get-ComplianceApiEndpoint falls back to the default InvokeCommand endpoint without throwing' {
                Mock -ModuleName EXORestHelper Get-ScubaGearPermissions { return 'https://httpbin.org' }
                $Endpoint = Get-ComplianceApiEndpoint -TenantId 'tenant123' -TenantDomain 'contoso.onmicrosoft.com' `
                    -M365Environment 'commercial' -AccessToken 'tok'
                $Endpoint | Should -Be 'https://httpbin.org/adminapi/beta/tenant123/InvokeCommand'
            }
        }

        Context 'Discovery call fails outright' {
            It 'Get-ExchangeOnlineApiEndpoint throws' {
                Mock -ModuleName EXORestHelper Get-ScubaGearPermissions { return 'https://this-host-does-not-exist-scubagear-test.invalid' }
                { Get-ExchangeOnlineApiEndpoint -TenantId 'tenant123' -TenantDomain 'contoso.onmicrosoft.com' `
                        -M365Environment 'commercial' -AccessToken 'tok' } | Should -Throw
            }

            It 'Get-ComplianceApiEndpoint does not throw and falls back to the default endpoint' {
                Mock -ModuleName EXORestHelper Get-ScubaGearPermissions { return 'https://this-host-does-not-exist-scubagear-test.invalid' }
                $Endpoint = Get-ComplianceApiEndpoint -TenantId 'tenant123' -TenantDomain 'contoso.onmicrosoft.com' `
                    -M365Environment 'commercial' -AccessToken 'tok' -WarningAction SilentlyContinue
                $Endpoint | Should -Be 'https://this-host-does-not-exist-scubagear-test.invalid/adminapi/beta/tenant123/InvokeCommand'
            }
        }
    }
}
