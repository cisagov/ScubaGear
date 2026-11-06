$ModulesPath = "../../../../Modules"
$ServicePrincipalModule = "$($ModulesPath)/Support/ServicePrincipal.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ServicePrincipalModule)

InModuleScope ServicePrincipal {
    # Graph returns key credential dates as ISO text under Windows PowerShell 5.1, not as DateTime values.
    # These commands send the app's existing certificates back to Graph, so they must format those dates themselves.
    Describe -Tag 'ServicePrincipal' -Name 'App certificate commands with certificates already on the app' {
        BeforeAll {
            $AppId = '02af5c78-f1aa-492b-a20e-6a94473c48d2'
            $KeepThumbprint = '6C7E18C48C7C3FD1CF3A4683CF6EE1EB6824DC2C'
            $RemoveThumbprint = '9898C8EBC3A85EBB294154FB810DBD9B61EF4C2F'

            $KeepKey = [PSCustomObject]@{
                customKeyIdentifier = $KeepThumbprint
                displayName         = 'CN=Existing'
                keyId               = '11111111-1111-1111-1111-111111111111'
                type                = 'AsymmetricX509Cert'
                usage               = 'Verify'
                startDateTime       = '2026-10-05T08:45:47Z'
                endDateTime         = '2027-10-05T08:45:47Z'
            }
            $RemoveKey = [PSCustomObject]@{
                customKeyIdentifier = $RemoveThumbprint
                displayName         = 'CN=ToRemove'
                keyId               = '22222222-2222-2222-2222-222222222222'
                type                = 'AsymmetricX509Cert'
                usage               = 'Verify'
                startDateTime       = '2026-10-06T08:45:47Z'
                endDateTime         = '2027-10-06T08:45:47Z'
            }
            $App = [PSCustomObject]@{
                Id             = '33333333-3333-3333-3333-333333333333'
                AppId          = $AppId
                DisplayName    = 'ScubaGear Application'
                keyCredentials = @($KeepKey, $RemoveKey)
            }

            Mock -CommandName Connect-GraphHelper -MockWith { return $null }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                if ($Commandlet -eq 'Get-MgBetaApplication') {
                    return [PSCustomObject]@{ Value = @($App) }
                }
                return $null
            }
            Mock -CommandName New-SelfSignedCertificate -MockWith {
                return [PSCustomObject]@{
                    RawData    = [byte[]]@(1, 2, 3)
                    NotAfter   = [datetime]'2027-11-01T00:00:00Z'
                    NotBefore  = [datetime]'2026-10-29T00:00:00Z'
                    Thumbprint = 'A' * 40
                }
            }
        }

        Context 'New-ScubaGearAppCert' {
            It 'Keeps the existing certificates, with their dates formatted for Graph, and adds the new one' {
                $Result = New-ScubaGearAppCert -AppID $AppId -M365Environment commercial -CertName 'Repro' -CertValidityMonths 1

                $Result.Thumbprint | Should -Be ('A' * 40)
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Update-MgApplication' -and
                    @($Body.keyCredentials).Count -eq 3 -and
                    $Body.keyCredentials[0].startDateTime -eq '2026-10-05T08:45:47Z' -and
                    $Body.keyCredentials[0].endDateTime -eq '2027-10-05T08:45:47Z' -and
                    $Body.keyCredentials[1].endDateTime -eq '2027-10-06T08:45:47Z' -and
                    $Body.keyCredentials[2].displayName -eq 'CN=Repro'
                }
            }
        }

        Context 'Remove-ScubaGearAppCert' {
            It 'Sends back only the remaining certificates, with their dates formatted for Graph' {
                Remove-ScubaGearAppCert -AppID $AppId -CertThumbprint $RemoveThumbprint -M365Environment commercial -Confirm:$false | Out-Null

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Update-MgApplication' -and
                    @($Body.keyCredentials).Count -eq 1 -and
                    $Body.keyCredentials[0].customKeyIdentifier -eq '6C7E18C48C7C3FD1CF3A4683CF6EE1EB6824DC2C' -and
                    $Body.keyCredentials[0].startDateTime -eq '2026-10-05T08:45:47Z' -and
                    $Body.keyCredentials[0].endDateTime -eq '2027-10-05T08:45:47Z'
                }
            }
        }
    }
}
