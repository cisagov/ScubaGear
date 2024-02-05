BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules\Connection' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ConnectHelpers.psm1') -Function 'Connect-DefenderHelper' -Force
}

InModuleScope ConnectHelpers {
    Describe -Tag 'Connection' -Name 'Connect-DefenderHelper' {
        BeforeAll {
            function Connect-IPPSSession {throw 'this will be mocked'}
            Mock -ModuleName ConnectHelpers Connect-IPPSSession {Write-Debug "M365Environment: $M365Environment"}
        }
        context 'Without Service Principal'{
            It 'Invalid M365nvironment parameter' {
                {Connect-DefenderHelper -M365Environment 'invalid_parameter'} | Should -Throw
            }
            It 'Invokes for commercial environment' {
                Connect-DefenderHelper -M365Environment 'commercial'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-IPPSSession -Times 1
            }
            It 'Invokes for gcc enviorment' {
                Connect-DefenderHelper -M365Environment 'gcc'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-IPPSSession -Times 1
            }
            It 'Invokes for gcchigh environment' {
                Connect-DefenderHelper -M365Environment 'gcchigh'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-IPPSSession -Times 1
            }
            It 'Invokes for dod environment' {
                Connect-DefenderHelper -M365Environment 'dod'
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-IPPSSession -Times 1
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
                Should -Invoke -ModuleName ConnectHelpers -CommandName Connect-IPPSSession -Times 1
            }
        }
    }
}
AfterAll {
    Remove-Module ConnectHelpers -ErrorAction SilentlyContinue
}
