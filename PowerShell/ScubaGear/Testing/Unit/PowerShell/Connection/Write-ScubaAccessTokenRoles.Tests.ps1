[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Tests preserve and restore the shared Graph session when checking environment selection.')]
param()

BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot '../../../../Modules/Connection/ConnectHelpers.psm1')
}

InModuleScope ConnectHelpers {
    Describe 'Write-ScubaAccessTokenRoles' {
        BeforeAll {
            Import-Module (Join-Path $PSScriptRoot '../../../../Modules/Utility/Utility.psm1') -Function Invoke-GraphDirectly

            function New-TestRoleHttpError {
                param ([int]$StatusCode)
                $Exception = [System.Exception]::new("HTTP $StatusCode")
                $Exception | Add-Member -NotePropertyName Response -NotePropertyValue ([pscustomobject]@{
                    StatusCode = [System.Net.HttpStatusCode]$StatusCode
                })
                $Exception
            }
        }

        BeforeEach {
            $script:SavedRoleSession = $Global:ScubaGearState.Session
            $Global:ScubaGearState.Session = @{ M365Environment = 'gcc' }
            Mock Invoke-GraphDirectly { [pscustomobject]@{ displayName = "Role $ID" } }
        }

        AfterEach {
            $Global:ScubaGearState.Session = $script:SavedRoleSession
        }

        It 'prints one ordered array after looking up every wid, including a missing role' {
            $First = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'
            $Missing = '00000000-0000-0000-0000-000000000000'
            $Last = 'f28a1f50-f6e7-4571-818b-6a12f2af6b6c'
            $Payload = [pscustomobject]@{ wids = @($First, $Missing, $Last) }
            $script:RoleRequests = [System.Collections.Generic.List[string]]::new()
            Mock Invoke-GraphDirectly {
                $script:RoleRequests.Add($ID)
                if ($ID -eq '00000000-0000-0000-0000-000000000000') {
                    throw (New-TestRoleHttpError -StatusCode 404)
                }
                [pscustomobject]@{ displayName = "Role $ID" }
            }
            Mock Write-Information {
                $script:RequestCountWhenPrinted = $script:RoleRequests.Count
                $script:RoleMessage = $MessageData
            }

            $Result = @(Write-ScubaAccessTokenRoles -DecodedToken $Payload -Label '[aad] Microsoft Graph')

            $Result.Count | Should -Be 0
            $script:RequestCountWhenPrinted | Should -Be 3
            $script:RoleMessage | Should -Match '^\[aad\] Microsoft Graph directory roles \(wids\):'
            $Roles = ($script:RoleMessage -split "`n", 2)[1] | ConvertFrom-Json
            $Roles | Should -Be @("Role $First", 'Cannot find role', "Role $Last")
            Should -Invoke Write-Information -Times 1 -Exactly
            Should -Invoke Invoke-GraphDirectly -Times 3 -Exactly -ParameterFilter {
                $Commandlet -eq 'Get-MgBetaDirectoryRoleTemplate' -and $M365Environment -eq 'gcc' -and
                $ID -in @('f2ef992c-3afb-46b9-b7cf-a126ee74c451', '00000000-0000-0000-0000-000000000000', 'f28a1f50-f6e7-4571-818b-6a12f2af6b6c')
            }
        }

        It 'keeps a single role as a JSON array and accepts a hashtable payload' {
            Write-ScubaAccessTokenRoles -DecodedToken @{ wids = @('role-id') } -InformationVariable RoleInformation

            $RoleInformation.Count | Should -Be 1
            $Json = ($RoleInformation[0].MessageData -split "`n", 2)[1]
            $Json.TrimStart().StartsWith('[') | Should -BeTrue
            ($Json | ConvertFrom-Json) | Should -Be @('Role role-id')
        }

        It 'uses an explicit cloud instead of the connected session cloud' {
            Write-ScubaAccessTokenRoles -DecodedToken @{ wids = @('role-id') } -M365Environment dod

            Should -Invoke Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                $M365Environment -eq 'dod' -and $ID -eq 'role-id'
            }
        }

        It 'handles a response without a displayName' {
            Mock Invoke-GraphDirectly { $null }

            Write-ScubaAccessTokenRoles -DecodedToken @{ wids = @('role-id') } -InformationVariable RoleInformation

            (($RoleInformation[0].MessageData -split "`n", 2)[1] | ConvertFrom-Json) | Should -Be @('Cannot find role')
        }

        It 'does not call Graph or print a role list for <Scenario>' -TestCases @(
            @{ Scenario = 'a missing claim'; Payload = @{ aud = 'api' } }
            @{ Scenario = 'an empty claim'; Payload = @{ wids = @() } }
            @{ Scenario = 'a null payload'; Payload = $null }
        ) {
            param ($Payload)

            $Result = @(Write-ScubaAccessTokenRoles -DecodedToken $Payload -InformationVariable RoleInformation)

            $Result.Count | Should -Be 0
            $RoleInformation.Count | Should -Be 0
            Should -Invoke Invoke-GraphDirectly -Times 0 -Exactly
        }

        It 'propagates HTTP <Status> instead of labeling it as a missing role' -TestCases @(
            @{ Status = 403 }
            @{ Status = 500 }
        ) {
            param ($Status)
            $script:RoleErrorStatus = $Status
            Mock Invoke-GraphDirectly { throw (New-TestRoleHttpError -StatusCode $script:RoleErrorStatus) }

            { Write-ScubaAccessTokenRoles -DecodedToken @{ wids = @('role-id') } } | Should -Throw "*HTTP $Status*"
        }

        It 'prints resolved roles after the decoded payload and preserves the original wids claim' {
            $Encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"aud":"api","wids":["role-one","role-two"]}')).TrimEnd('=').Replace('+', '-').Replace('/', '_')

            $Result = @(Write-ScubaAccessTokenPayload -AccessToken "header.$Encoded.signature" -Label '[aad] Microsoft Graph' -InformationVariable TokenInformation)

            $Result.Count | Should -Be 0
            $TokenInformation.Count | Should -Be 2
            $TokenInformation[0].MessageData | Should -Match 'decoded access token payload:'
            $Claims = ($TokenInformation[0].MessageData -split "`n", 2)[1] | ConvertFrom-Json
            $Claims.wids | Should -Be @('role-one', 'role-two')
            $TokenInformation[1].MessageData | Should -Match 'directory roles \(wids\):'
            (($TokenInformation[1].MessageData -split "`n", 2)[1] | ConvertFrom-Json) | Should -Be @('Role role-one', 'Role role-two')
        }

        It 'keeps token diagnostics from failing authentication when Graph denies the lookup' {
            Mock Invoke-GraphDirectly { throw (New-TestRoleHttpError -StatusCode 403) }
            $Encoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('{"wids":["role-id"]}')).TrimEnd('=')

            $Result = @(Write-ScubaAccessTokenPayload -AccessToken "header.$Encoded.signature" -WarningVariable RoleWarnings -WarningAction SilentlyContinue -ErrorAction Stop)

            $Result.Count | Should -Be 0
            $RoleWarnings.Count | Should -Be 1
            $RoleWarnings[0].Message | Should -Match 'directory role lookup failed:.*HTTP 403'
        }
    }
}
