BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Function 'Connect-GraphHelper' -Force
}

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-GraphHelper' {
        BeforeAll {
            function Connect-MgGraph {throw 'this will be mocked'}
            Mock -ModuleName ConnectHelpers Connect-MgGraph {Write-Debug "M365Environment: $M365Environment"}
        }
        context 'Without Service Principal'{
            It 'Invalid M365Environment parameter' {
                {Connect-GraphHelper -M365Environment 'invalid_parameter'} | Should -Throw
            }
            It 'Invokes for commercial environment' {
                Connect-GraphHelper -M365Environment 'commercial'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-MgGraph -Times 1
            }
            It 'Invokes for gcc environment' {
                Connect-GraphHelper -M365Environment 'gcc'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-MgGraph -Times 1
            }
            It 'Invokes for gcchigh environment' {
                Connect-GraphHelper -M365Environment 'gcchigh'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-MgGraph -Times 1
            }
            It 'Invokes for dod environment' {
                Connect-GraphHelper -M365Environment 'dod'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-MgGraph -Times 1
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
                Connect-GraphHelper -M365Environment 'commercial' -ServicePrincipalParams $sp
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-MgGraph -Times 1
            }
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
