BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Function 'Connect-DefenderHelper' -Force  
}

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-DefenderHelper' {
        BeforeAll {
            Mock Connect-IPPSSession {}
        }
        context 'Without Service Principal'{
            It 'Invalid M365nvironment parameter' {
                {Connect-DefenderHelper -M365Environment 'invalid_parameter'} | Should -Throw
            }
            It 'Invokes for commercial environment' {
                Connect-DefenderHelper -M365Environment 'commercial'
                Should -Invoke -CommandName Connect-IPPSSession -Times 1 -ParameterFilter {$ErrorAction -eq 'Stop' -And $CertificateThumbprint -eq $null}
            }
            It 'Invokes for gcc enviorment' {
                Connect-DefenderHelper -M365Environment 'gcc'
                Should -Invoke -CommandName Connect-IPPSSession -Times 1 -ParameterFilter {$ErrorAction -eq 'Stop' -And $CertificateThumbprint -eq $null}
            }
            It 'Invokes for gcchigh environment' {
                Connect-DefenderHelper -M365Environment 'gcchigh'
                Should -Invoke -CommandName Connect-IPPSSession -Times 1 `
                -ParameterFilter {
                    $ErrorAction -eq 'Stop' -And
                    $CertificateThumbprint -eq $null -And
                    $ConnectionUri -eq 'https://ps.compliance.protection.office365.us/powershell-liveid' -and
                    $AzureADAuthorizationEndpointUri -eq 'https://login.microsoftonline.us/common'
                }
            }
            It 'Invokes for dod environment' {
                Connect-DefenderHelper -M365Environment 'dod'
                Should -Invoke -CommandName Connect-IPPSSession -Times 1 `
                -ParameterFilter {
                    $ErrorAction -eq 'Stop' -And
                    $CertificateThumbprint -eq $null -And
                    $ConnectionUri -eq 'https://l5.ps.compliance.protection.office365.us/powershell-liveid' -and
                    $AzureADAuthorizationEndpointUri -eq 'https://login.microsoftonline.us/common'
                }
            }
        }
        context 'With Service Principal'{
            It 'Invoke with Service Principal parameters'{
                $sp = @{
                    CertThumbprintParams = @{
                        CertificateThumbprint = 'A thumbprint';
                        AppID = 'My Id';
                        Organization = 'My Organization';
                    }
                }
                Connect-DefenderHelper -M365Environment 'commercial' -ServicePrincipalParams $sp
                Should -Invoke -CommandName Connect-IPPSSession -Times 1 -ParameterFilter {$ErrorAction -eq 'Stop' -And   $CertificateThumbprint -eq 'A thumbprint'}
            }
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
