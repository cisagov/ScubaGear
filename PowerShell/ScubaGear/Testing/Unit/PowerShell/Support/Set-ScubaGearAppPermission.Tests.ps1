$ModulesPath = "../../../../Modules"
$ServicePrincipalModule = "$($ModulesPath)/Support/ServicePrincipal.psm1"
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath $ServicePrincipalModule)

InModuleScope ServicePrincipal {
    Describe "Get-ServicePrincipalMemberGroupIds" {
        It "batches membership checks into requests of at most 20 group IDs" {
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Uri, $Method, $Body)
                $RequestBody = $Body | ConvertFrom-Json
                if ($Method -ne 'POST' -or
                    $Uri -ne 'https://graph.microsoft.us/v1.0/servicePrincipals/service-principal-id/checkMemberGroups' -or
                    @($RequestBody.groupIds).Count -gt 20) {
                    throw "Unexpected checkMemberGroups request."
                }
                return @{ value = @($RequestBody.groupIds) }
            }

            $GroupIds = @(1..21 | ForEach-Object { "group-$_" })
            $MatchedGroupIds = @(Get-ServicePrincipalMemberGroupIds -ServicePrincipalID 'service-principal-id' `
                -GroupIds $GroupIds -M365Environment gcchigh)

            $MatchedGroupIds.Count | Should -Be 21
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 2 -Exactly
        }

        It "throws when the Graph response does not contain membership results" {
            Mock -CommandName Invoke-GraphDirectly -MockWith { return @{ unexpected = @() } }

            {
                Get-ServicePrincipalMemberGroupIds -ServicePrincipalID 'service-principal-id' `
                    -GroupIds @('group-id') -M365Environment commercial
            } | Should -Throw '*checkMemberGroups response did not contain a valid value*'
        }

        It "accepts an empty membership result" {
            Mock -CommandName Invoke-GraphDirectly -MockWith { return [PSCustomObject]@{ value = @() } }

            $MatchedGroupIds = @(Get-ServicePrincipalMemberGroupIds -ServicePrincipalID 'service-principal-id' `
                -GroupIds @('group-id') -M365Environment commercial)

            $MatchedGroupIds.Count | Should -Be 0
        }

        It "propagates a Graph request failure" {
            Mock -CommandName Invoke-GraphDirectly -MockWith { throw 'Network unreachable' }

            {
                Get-ServicePrincipalMemberGroupIds -ServicePrincipalID 'service-principal-id' `
                    -GroupIds @('group-id') -M365Environment commercial
            } | Should -Throw '*Network unreachable*'
        }
    }

    Describe "Set-PowerBIAppRegistration catalog endpoints" {
        BeforeAll {
            $script:PowerBITestAppId = '11111111-1111-1111-1111-111111111111'
            $script:PowerBITestSpId = '22222222-2222-2222-2222-222222222222'
            $script:PowerBITestGroupId = '33333333-3333-3333-3333-333333333333'
            $script:PowerBITestMissingGroupId = '44444444-4444-4444-4444-444444444444'
            $script:PowerBITestNewGroupId = '55555555-5555-5555-5555-555555555555'
            $script:PowerBITestOtherMissingGroupId = '66666666-6666-6666-6666-666666666666'
            $script:PowerBITestExcludedGroupId = '77777777-7777-7777-7777-777777777777'

            function New-PowerBITestHttpError {
                param([int]$StatusCode)
                $failure = [System.Exception]::new("Simulated HTTP $StatusCode")
                $failure | Add-Member -NotePropertyName Response -NotePropertyValue ([PSCustomObject]@{ StatusCode = $StatusCode })
                return $failure
            }
        }

        BeforeEach {
            $script:PowerBITestSettingEnabled = $true
            $script:PowerBITestGroups = @([PSCustomObject]@{
                graphId = $script:PowerBITestGroupId
                name = 'Test group'
            })
            Mock -CommandName Get-PowerBIAdminToken -MockWith {
                return [PSCustomObject]@{ BaseUrl = 'https://example.test'; AccessToken = 'token' }
            }
            Mock -CommandName Get-PowerBITenantSettingsRest -MockWith {
                return [PSCustomObject]@{
                    tenantSettings = @([PSCustomObject]@{
                        settingName = 'AllowServicePrincipalsUseReadAdminAPIs'
                        enabled = $script:PowerBITestSettingEnabled
                        enabledSecurityGroups = @($script:PowerBITestGroups)
                        excludedSecurityGroups = @([PSCustomObject]@{ graphId = $script:PowerBITestExcludedGroupId; name = 'Excluded group' })
                        properties = @([PSCustomObject]@{ name = 'ExistingProperty'; value = 'true'; type = 'Boolean' })
                        delegateToCapacity = $false
                        delegateToDomain = $true
                        delegateToWorkspace = $false
                    })
                }
            }
        }

        It "uses the catalog path with both IDs and the reference suffix when removing membership" {
            $script:PowerBITestCheckCount = 0
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith {
                $script:PowerBITestCheckCount++
                if ($script:PowerBITestCheckCount -eq 1) { return $script:PowerBITestGroupId }
            }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet, $Method)
                if ($Commandlet -eq 'Get-MgBetaGroupMember') {
                    return [PSCustomObject]@{
                        Value = @([PSCustomObject]@{ Id = $script:PowerBITestSpId })
                    }
                }
                if ($Method -ne 'DELETE') { throw 'Unexpected Graph request.' }
            }

            Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId -ServicePrincipalID $script:PowerBITestSpId `
                -TenantId 'tenant-id' -M365Environment commercial -Remove -Confirm:$false

            Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'DELETE' -and
                $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestGroupId)/members/$($script:PowerBITestSpId)/`$ref"
            }
        }

        It "skips a deleted allowed group and removes membership from live groups" {
            $script:PowerBITestGroups = @(
                [PSCustomObject]@{ graphId = $script:PowerBITestGroupId; name = 'Live group' }
                [PSCustomObject]@{ graphId = $script:PowerBITestMissingGroupId; name = 'Deleted group' }
            )
            $script:PowerBICheckedRemovalGroupIds = @()
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith {
                $script:PowerBICheckedRemovalGroupIds += ,@($GroupIds)
                return @()
            }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet, $ID, $Method)
                if ($Commandlet -eq 'Get-MgBetaGroupMember') {
                    if ($ID -eq $script:PowerBITestMissingGroupId) {
                        throw (New-PowerBITestHttpError -StatusCode 404)
                    }
                    return [PSCustomObject]@{
                        Value = @([PSCustomObject]@{ Id = $script:PowerBITestSpId })
                    }
                }
                if ($Method -ne 'DELETE') { throw 'Unexpected Graph request.' }
            }

            Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId -ServicePrincipalID $script:PowerBITestSpId `
                -TenantId 'tenant-id' -M365Environment commercial -Remove -Confirm:$false `
                -WarningVariable RemovalWarnings -WarningAction SilentlyContinue

            ($RemovalWarnings -join "`n") | Should -Match "Deleted group.*$($script:PowerBITestMissingGroupId).*Skipping"
            $script:PowerBICheckedRemovalGroupIds.Count | Should -Be 2
            foreach ($checkedGroupIds in $script:PowerBICheckedRemovalGroupIds) {
                $checkedGroupIds | Should -HaveCount 1
                $checkedGroupIds[0] | Should -Be $script:PowerBITestGroupId
            }
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'DELETE' -and
                $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestGroupId)/members/$($script:PowerBITestSpId)/`$ref"
            }
        }

        It "does not remove any membership when a live allowed-group lookup fails" {
            $script:PowerBITestGroups = @(
                [PSCustomObject]@{ graphId = $script:PowerBITestGroupId; name = 'Live group' }
                [PSCustomObject]@{ graphId = $script:PowerBITestMissingGroupId; name = 'Unreadable group' }
            )
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($ID)
                if ($ID -eq $script:PowerBITestGroupId) {
                    return [PSCustomObject]@{
                        Value = @([PSCustomObject]@{ Id = $script:PowerBITestSpId })
                    }
                }
                throw (New-PowerBITestHttpError -StatusCode 403)
            }

            {
                Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId -ServicePrincipalID $script:PowerBITestSpId `
                    -TenantId 'tenant-id' -M365Environment commercial -Remove -Confirm:$false
            } | Should -Throw '*Unable to inspect Power BI allowed group*'

            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Method -eq 'DELETE' }
        }

        It "does not make changes when allowed-group membership cannot be checked" {
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { throw 'Network unreachable' }
            Mock -CommandName Invoke-GraphDirectly -MockWith {}

            {
                Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId -ServicePrincipalID $script:PowerBITestSpId `
                    -TenantId 'tenant-id' -M365Environment commercial -Force -Confirm:$false
            } | Should -Throw '*Unable to verify Power BI allowed-group membership*'

            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
        }

        It "displays interactive group choices on the information stream, not the success stream" {
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                [PSCustomObject]@{ Value = @() }
            } -ParameterFilter { $Commandlet -eq 'Get-MgBetaGroupMember' }
            Mock -CommandName Read-Host -MockWith { '1' }

            $Output = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -WhatIf -InformationVariable MenuInformation

            $MenuText = @($MenuInformation | ForEach-Object { $_.MessageData }) -join "`n"
            $MenuText | Should -Match "Power BI tenant setting 'Service principals can access read-only admin APIs'"
            $MenuText | Should -Match 'Test group \(ID: 33333333-3333-3333-3333-333333333333\)'
            $MenuText | Should -Match 'Create a new dedicated security group'
            ($Output -join "`n") | Should -Not -Match "currently enabled for the following security group|  \[1\] Test group \(ID:"
            ($Output -join "`n") | Should -Not -Match "Create a new dedicated security group and append it"
            Should -Invoke -CommandName Read-Host -Times 1 -Exactly
        }

        It "omits a missing dedicated group when selecting <Selection>" -ForEach @(
            @{ Selection = 'an existing group'; Choice = '1'; MissingFirst = $true; ExpectedAction = "existing allowed group 'Test group'" }
            @{ Selection = 'the default replacement'; Choice = ''; MissingFirst = $false; ExpectedAction = "Create/use group 'ScubaGear PowerBI Service Principals'" }
        ) {
            $missingGroup = [PSCustomObject]@{
                graphId = $script:PowerBITestMissingGroupId
                name = 'ScubaGear PowerBI Service Principals'
            }
            if ($MissingFirst) {
                $script:PowerBITestGroups = @($missingGroup) + @($script:PowerBITestGroups)
            } else {
                $script:PowerBITestGroups += $missingGroup
            }
            $script:PowerBITestSelection = $Choice
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                if ($ID -eq $script:PowerBITestMissingGroupId) {
                    throw (New-PowerBITestHttpError -StatusCode 404)
                }
                return [PSCustomObject]@{ Value = @() }
            }
            Mock -CommandName Read-Host -MockWith { $script:PowerBITestSelection }

            $Output = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -WhatIf -WarningVariable GroupWarnings `
                -WarningAction SilentlyContinue -InformationVariable MenuInformation

            $MenuText = @($MenuInformation | ForEach-Object { $_.MessageData }) -join "`n"
            $GroupWarnings | Should -Match $script:PowerBITestMissingGroupId
            $GroupWarnings | Should -Match 'was not found'
            $MenuText | Should -Match 'Test group \(ID: 33333333-3333-3333-3333-333333333333\)'
            $MenuText | Should -Not -Match $script:PowerBITestMissingGroupId
            $MenuText | Should -Match '\[2\] Create a new dedicated security group'
            ($Output -join "`n") | Should -Match $ExpectedAction
            ($Output -join "`n") | Should -Match 'remove stale Power BI allowed-group reference'
            Should -Invoke -CommandName Read-Host -Times 1 -Exactly -ParameterFilter {
                $Prompt -eq 'Select an option [1-2] (Default: 2)'
            }
            Should -Invoke -CommandName Read-Host -Times 0 -ParameterFilter { $Prompt -like 'Remove stale*' }
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Method -eq 'POST' }
        }

        It "prompts by object ID when duplicate dedicated groups are already allowed" {
            $script:PowerBITestGroups = @(
                [PSCustomObject]@{ graphId = $script:PowerBITestGroupId; name = 'ScubaGear PowerBI Service Principals' }
                [PSCustomObject]@{ graphId = $script:PowerBITestNewGroupId; name = 'ScubaGear PowerBI Service Principals' }
            )
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet, $Uri, $Method)
                if ($Commandlet -eq 'Get-MgBetaGroupMember') {
                    return [PSCustomObject]@{ Value = @() }
                }
                if ($Method -eq 'POST' -and $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestNewGroupId)/members/`$ref") {
                    return
                }
                throw 'Unexpected Graph request.'
            }
            Mock -CommandName Read-Host -MockWith { '2' }

            $Output = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -Confirm:$false -InformationVariable MenuInformation

            $MenuText = @($MenuInformation | ForEach-Object { $_.MessageData }) -join "`n"
            $MenuText | Should -Match $script:PowerBITestGroupId
            $MenuText | Should -Match $script:PowerBITestNewGroupId
            $MenuText | Should -Match 'select using the displayed object IDs'
            ($Output -join "`n") | Should -Match "Successfully added service principal.*group 'ScubaGear PowerBI Service Principals'"
            Should -Invoke -CommandName Read-Host -Times 1 -Exactly -ParameterFilter { $Prompt -match 'required; C to cancel' }
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'POST' -and
                $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestNewGroupId)/members/`$ref"
            }
        }

        It "selects a matching Entra group by object ID when names are duplicated" {
            $script:PowerBITestGroups = @()
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet, $ID, $Uri, $Method)
                if ($Commandlet -eq 'Get-MgBetaGroup') {
                    return [PSCustomObject]@{ Value = @(
                        [PSCustomObject]@{ Id = $script:PowerBITestGroupId; DisplayName = 'ScubaGear PowerBI Service Principals' }
                        [PSCustomObject]@{ Id = $script:PowerBITestNewGroupId; DisplayName = 'ScubaGear PowerBI Service Principals' }
                    ) }
                }
                if ($Commandlet -eq 'Get-MgBetaGroupMember' -and $ID -eq $script:PowerBITestNewGroupId) {
                    return [PSCustomObject]@{ Value = @() }
                }
                if ($Method -eq 'POST' -and $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestNewGroupId)/members/`$ref") {
                    return
                }
                throw 'Unexpected Graph request.'
            }
            Mock -CommandName Read-Host -MockWith { '2' }
            Mock -CommandName Invoke-ScubaRestMethod -MockWith {
                $script:PowerBIUpdatedSetting = $Body | ConvertFrom-Json
            }

            Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -Confirm:$false -InformationVariable GroupInformation

            $GroupText = @($GroupInformation | ForEach-Object { $_.MessageData }) -join "`n"
            $GroupText | Should -Match $script:PowerBITestGroupId
            $GroupText | Should -Match $script:PowerBITestNewGroupId
            Should -Invoke -CommandName Read-Host -Times 1 -Exactly -ParameterFilter {
                $Prompt -eq 'Select a group [1-2], or C to cancel'
            }
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'POST' -and
                $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestNewGroupId)/members/`$ref"
            }
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter {
                $Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/groups'
            }
            @($script:PowerBIUpdatedSetting.enabledSecurityGroups).Count | Should -Be 1
            $script:PowerBIUpdatedSetting.enabledSecurityGroups[0].graphId | Should -Be $script:PowerBITestNewGroupId
        }

        It "fails without changes when Force encounters duplicate Entra groups" {
            $script:PowerBITestGroups = @()
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet)
                if ($Commandlet -eq 'Get-MgBetaGroup') {
                    return [PSCustomObject]@{ Value = @(
                        [PSCustomObject]@{ Id = $script:PowerBITestGroupId; DisplayName = 'ScubaGear PowerBI Service Principals' }
                        [PSCustomObject]@{ Id = $script:PowerBITestNewGroupId; DisplayName = 'ScubaGear PowerBI Service Principals' }
                    ) }
                }
                throw 'Unexpected Graph request.'
            }
            Mock -CommandName Read-Host -MockWith { throw 'Force must not prompt.' }
            Mock -CommandName Invoke-ScubaRestMethod -MockWith {}

            {
                Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                    -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                    -M365Environment commercial -Force -Confirm:$false
            } | Should -Throw '*Multiple Entra groups are named*'

            Should -Invoke -CommandName Read-Host -Times 0
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Method -eq 'POST' }
            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 0
        }

        It "confirms stale-reference cleanup and creates a replacement with <Scenario>" -ForEach @(
            @{ Scenario = 'another allowed group'; IncludeValidGroup = $true; MultipleMissing = $false }
            @{ Scenario = 'only the missing group'; IncludeValidGroup = $false; MultipleMissing = $false }
            @{ Scenario = 'multiple missing groups'; IncludeValidGroup = $true; MultipleMissing = $true }
        ) {
            if (-not $IncludeValidGroup) { $script:PowerBITestGroups = @() }
            $script:PowerBITestGroups += [PSCustomObject]@{
                graphId = $script:PowerBITestMissingGroupId
                name = 'ScubaGear PowerBI Service Principals'
            }
            if ($MultipleMissing) {
                $script:PowerBITestGroups += [PSCustomObject]@{
                    id = $script:PowerBITestOtherMissingGroupId
                    name = 'Other deleted group'
                }
            }
            $script:PowerBIUpdatedSetting = $null

            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet, $ID, $Uri, $Method)
                if ($Commandlet -eq 'Get-MgBetaGroupMember') {
                    if ($ID -in @($script:PowerBITestMissingGroupId, $script:PowerBITestOtherMissingGroupId)) {
                        throw (New-PowerBITestHttpError -StatusCode 404)
                    }
                    return [PSCustomObject]@{ Value = @() }
                }
                if ($Commandlet -eq 'Get-MgBetaGroup') {
                    return [PSCustomObject]@{ Value = @() }
                }
                if ($Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/groups') {
                    return [PSCustomObject]@{ id = $script:PowerBITestNewGroupId }
                }
                if ($Method -eq 'POST' -and $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestNewGroupId)/members/`$ref") {
                    return
                }
                throw 'Unexpected Graph request.'
            }
            Mock -CommandName Invoke-ScubaRestMethod -MockWith {
                $script:PowerBIUpdatedSetting = $Body | ConvertFrom-Json
            }
            Mock -CommandName Read-Host -MockWith {
                if ($Prompt -like 'Remove stale*') { return 'y' }
                return ''
            }

            $null = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -Confirm:$false -WarningAction SilentlyContinue

            $updatedGroupIds = @($script:PowerBIUpdatedSetting.enabledSecurityGroups | ForEach-Object { $_.graphId })
            $updatedGroupIds.Count | Should -Be (1 + [int]$IncludeValidGroup)
            $updatedGroupIds | Should -Not -Contain $script:PowerBITestMissingGroupId
            $updatedGroupIds | Should -Not -Contain $script:PowerBITestOtherMissingGroupId
            $updatedGroupIds | Should -Contain $script:PowerBITestNewGroupId
            if ($IncludeValidGroup) { $updatedGroupIds | Should -Contain $script:PowerBITestGroupId }
            $script:PowerBIUpdatedSetting.excludedSecurityGroups[0].graphId | Should -Be $script:PowerBITestExcludedGroupId
            $script:PowerBIUpdatedSetting.properties[0].name | Should -Be 'ExistingProperty'
            $script:PowerBIUpdatedSetting.properties[0].value | Should -Be 'true'
            $script:PowerBIUpdatedSetting.delegateToCapacity | Should -BeFalse
            $script:PowerBIUpdatedSetting.delegateToDomain | Should -BeTrue
            $script:PowerBIUpdatedSetting.delegateToWorkspace | Should -BeFalse
            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly
            Should -Invoke -CommandName Read-Host -Times 1 -Exactly -ParameterFilter { $Prompt -like 'Remove stale*' }
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Method -eq 'DELETE' }
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'POST' -and
                $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestNewGroupId)/members/`$ref"
            }
        }

        It "uses a valid dedicated group when another allowed group is missing" {
            $script:PowerBITestGroups = @(
                [PSCustomObject]@{ graphId = $script:PowerBITestGroupId; name = 'ScubaGear PowerBI Service Principals' }
                [PSCustomObject]@{ graphId = $script:PowerBITestMissingGroupId; name = 'Deleted group' }
            )
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                param($Commandlet, $ID, $Uri, $Method)
                if ($Commandlet -eq 'Get-MgBetaGroupMember') {
                    if ($ID -eq $script:PowerBITestMissingGroupId) {
                        throw (New-PowerBITestHttpError -StatusCode 404)
                    }
                    return [PSCustomObject]@{ Value = @() }
                }
                if ($Method -eq 'POST' -and $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestGroupId)/members/`$ref") {
                    return
                }
                throw 'Unexpected Graph request.'
            }
            $script:PowerBIUpdatedSetting = $null
            Mock -CommandName Invoke-ScubaRestMethod -MockWith {
                $script:PowerBIUpdatedSetting = $Body | ConvertFrom-Json
            }
            Mock -CommandName Read-Host -MockWith {
                if ($Prompt -like 'Remove stale*') { return 'yes' }
                return ''
            }

            $null = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -Confirm:$false -WarningAction SilentlyContinue

            Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'POST' -and
                $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestGroupId)/members/`$ref"
            }
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Commandlet -eq 'Get-MgBetaGroup' }
            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly
            @($script:PowerBIUpdatedSetting.enabledSecurityGroups).Count | Should -Be 1
            $script:PowerBIUpdatedSetting.enabledSecurityGroups[0].graphId | Should -Be $script:PowerBITestGroupId
            Should -Invoke -CommandName Read-Host -Times 1 -Exactly -ParameterFilter { $Prompt -like 'Remove stale*' }
        }

        Context "Stale-reference confirmation" {
            BeforeEach {
                $script:PowerBITestGroups += [PSCustomObject]@{
                    graphId = $script:PowerBITestMissingGroupId
                    name = 'ScubaGear PowerBI Service Principals'
                }
                $script:PowerBIUpdatedSetting = $null
                Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $ID, $Uri, $Method)
                    if ($Commandlet -eq 'Get-MgBetaGroupMember') {
                        if ($ID -eq $script:PowerBITestMissingGroupId) {
                            throw (New-PowerBITestHttpError -StatusCode 404)
                        }
                        return [PSCustomObject]@{ Value = @() }
                    }
                    if ($Method -eq 'POST' -and $Uri -eq "https://graph.microsoft.com/v1.0/groups/$($script:PowerBITestGroupId)/members/`$ref") {
                        return
                    }
                    throw 'Unexpected Graph request.'
                }
                Mock -CommandName Invoke-ScubaRestMethod -MockWith {
                    $script:PowerBIUpdatedSetting = $Body | ConvertFrom-Json
                }
            }

            It "stops without writes when cleanup is declined with '<Response>'" -ForEach @(
                @{ Response = 'n' }
                @{ Response = '' }
            ) {
                $script:PowerBITestCleanupResponse = $Response
                Mock -CommandName Read-Host -MockWith { $script:PowerBITestCleanupResponse }

                {
                    Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                        -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                        -M365Environment commercial -Confirm:$false -WarningAction SilentlyContinue
                } | Should -Throw '*cleanup was not confirmed*'

                Should -Invoke -CommandName Read-Host -Times 1 -Exactly
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Method -eq 'POST' }
                Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 0
            }

            It "does not let Force approve stale-reference removal" {
                Mock -CommandName Read-Host -MockWith { throw 'Unexpected prompt.' }

                {
                    Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                        -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                        -M365Environment commercial -Force -Confirm:$false -WarningAction SilentlyContinue
                } | Should -Throw '*requires interactive confirmation*'

                Should -Invoke -CommandName Read-Host -Times 0
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Method -eq 'POST' }
                Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 0
            }

            It "previews cleanup without confirmation or writes under Force and WhatIf" {
                Mock -CommandName Read-Host -MockWith { throw 'Unexpected prompt.' }

                $Output = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                    -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                    -M365Environment commercial -Force -WhatIf -WarningAction SilentlyContinue

                ($Output -join "`n") | Should -Match 'remove stale Power BI allowed-group reference'
                ($Output -join "`n") | Should -Match $script:PowerBITestMissingGroupId
                Should -Invoke -CommandName Read-Host -Times 0
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Method -eq 'POST' }
                Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 0
            }

            It "reprompts for invalid cleanup input then updates an existing allowed group once" {
                $script:PowerBITestCleanupPromptCount = 0
                Mock -CommandName Read-Host -MockWith {
                    if ($Prompt -like 'Remove stale*') {
                        $script:PowerBITestCleanupPromptCount++
                        if ($script:PowerBITestCleanupPromptCount -eq 1) { return 'invalid' }
                        return 'Y'
                    }
                    return '1'
                }

                $null = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                    -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                    -M365Environment commercial -Confirm:$false -WarningVariable CleanupWarnings -WarningAction SilentlyContinue

                ($CleanupWarnings -join "`n") | Should -Match 'Enter Y or N'
                Should -Invoke -CommandName Read-Host -Times 2 -Exactly -ParameterFilter { $Prompt -like 'Remove stale*' }
                Should -Invoke -CommandName Read-Host -Times 1 -Exactly -ParameterFilter { $Prompt -like 'Select an option*' }
                Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly
                @($script:PowerBIUpdatedSetting.enabledSecurityGroups).Count | Should -Be 1
                $script:PowerBIUpdatedSetting.enabledSecurityGroups[0].graphId | Should -Be $script:PowerBITestGroupId
                $script:PowerBIUpdatedSetting.excludedSecurityGroups[0].graphId | Should -Be $script:PowerBITestExcludedGroupId
            }

            It "does not skip confirmed cleanup after finding existing direct membership" {
                $script:PowerBITestGroups = @($script:PowerBITestGroups[1], $script:PowerBITestGroups[0])
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    [PSCustomObject]@{ Value = @([PSCustomObject]@{ Id = $script:PowerBITestSpId }) }
                } -ParameterFilter { $Commandlet -eq 'Get-MgBetaGroupMember' -and $ID -eq $script:PowerBITestGroupId }
                Mock -CommandName Read-Host -MockWith {
                    if ($Prompt -like 'Remove stale*') { return 'y' }
                    return '1'
                }

                $null = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                    -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                    -M365Environment commercial -Confirm:$false -WarningAction SilentlyContinue

                Should -Invoke -CommandName Read-Host -Times 1 -Exactly -ParameterFilter { $Prompt -like 'Remove stale*' }
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Method -eq 'POST' }
                Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly
                @($script:PowerBIUpdatedSetting.enabledSecurityGroups).Count | Should -Be 1
                $script:PowerBIUpdatedSetting.enabledSecurityGroups[0].graphId | Should -Be $script:PowerBITestGroupId
            }
        }

        It "validates group choices when the setting is disabled and membership already matches" {
            $script:PowerBITestSettingEnabled = $false
            $script:PowerBITestGroups = @(
                [PSCustomObject]@{ graphId = $script:PowerBITestGroupId; name = 'ScubaGear PowerBI Service Principals' }
                [PSCustomObject]@{ graphId = $script:PowerBITestMissingGroupId; name = 'Deleted group' }
            )
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { $script:PowerBITestGroupId }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                if ($ID -eq $script:PowerBITestMissingGroupId) {
                    throw (New-PowerBITestHttpError -StatusCode 404)
                }
                return [PSCustomObject]@{ Value = @() }
            }
            Mock -CommandName Read-Host -MockWith { '' }

            $Output = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -WhatIf -WarningAction SilentlyContinue `
                -InformationVariable MenuInformation

            $MenuText = @($MenuInformation | ForEach-Object { $_.MessageData }) -join "`n"
            $MenuText | Should -Match $script:PowerBITestGroupId
            $MenuText | Should -Not -Match $script:PowerBITestMissingGroupId
            $MenuText | Should -Not -Match 'Create a new dedicated security group'
            ($Output -join "`n") | Should -Match "existing allowed group 'ScubaGear PowerBI Service Principals'"
        }

        It "fails without changes when group inspection encounters <Failure>" -ForEach @(
            @{ Failure = 'HTTP 403'; StatusCode = 403; Message = 'Simulated HTTP 403' }
            @{ Failure = 'a network error'; StatusCode = 0; Message = 'Network unreachable' }
        ) {
            $script:PowerBITestFailureStatus = $StatusCode
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { @() }
            Mock -CommandName Invoke-GraphDirectly -MockWith {
                if ($script:PowerBITestFailureStatus) {
                    throw (New-PowerBITestHttpError -StatusCode $script:PowerBITestFailureStatus)
                }
                throw [System.Net.WebException]::new('Network unreachable')
            }
            Mock -CommandName Invoke-ScubaRestMethod -MockWith {}
            Mock -CommandName Read-Host -MockWith {}

            {
                Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId -ServicePrincipalID $script:PowerBITestSpId `
                    -TenantId 'tenant-id' -M365Environment commercial -Force -Confirm:$false -WarningAction SilentlyContinue
            } | Should -Throw "*Unable to inspect members of Power BI allowed group*$Message*"

            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 0
            Should -Invoke -CommandName Read-Host -Times 0
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0 -ParameterFilter { $Method -eq 'POST' }
        }

        It "warns and omits an allowed group without an object ID" {
            $script:PowerBITestGroups = @([PSCustomObject]@{ name = 'Group without ID' })
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith {}
            Mock -CommandName Invoke-GraphDirectly -MockWith {}
            Mock -CommandName Read-Host -MockWith {}

            $Output = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -WhatIf -WarningVariable GroupWarnings -WarningAction SilentlyContinue

            $GroupWarnings | Should -Match 'has no object ID'
            ($Output -join "`n") | Should -Match "Create/use group 'ScubaGear PowerBI Service Principals'"
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
            Should -Invoke -CommandName Read-Host -Times 0
        }

        Context "Power BI tenant-setting update errors" {
            BeforeEach {
                $script:PowerBITestSettingEnabled = $false
                $script:PowerBITestUpdateError = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new('Simulated HTTP 403'),
                    'PowerBITenantUpdateFailed',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
                $script:PowerBITestUpdateError.ErrorDetails = [System.Management.Automation.ErrorDetails]::new(
                    '{"errorCode":"FeatureNotAvailable"}'
                )
                Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { $script:PowerBITestGroupId }
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    if ($Commandlet -ne 'Get-MgBetaGroupMember') { throw 'Unexpected Graph request.' }
                    return [PSCustomObject]@{ Value = @([PSCustomObject]@{ Id = $script:PowerBITestSpId }) }
                }
                Mock -CommandName Invoke-ScubaRestMethod -MockWith { throw $script:PowerBITestUpdateError }
                Mock -CommandName Write-Warning -MockWith {}
            }

            It "shows manual guidance for <Environment> and <ErrorBody>" -ForEach @(
                @{ Environment = 'gcchigh'; ErrorBody = '{"errorCode":"FeatureNotAvailable"}'; Expected = 1 }
                @{ Environment = 'gcchigh'; ErrorBody = "{`n  `"errorCode`": `"FeatureNotAvailable`"`n}"; Expected = 1 }
                @{ Environment = 'gcchigh'; ErrorBody = '{"errorCode":"Forbidden","message":"FeatureNotAvailable"}'; Expected = 0 }
                @{ Environment = 'gcchigh'; ErrorBody = '{"errorCode":"FeatureNotAvailableOther"}'; Expected = 0 }
                @{ Environment = 'gcchigh'; ErrorBody = $null; Expected = 0 }
                @{ Environment = 'commercial'; ErrorBody = '{"errorCode":"FeatureNotAvailable"}'; Expected = 0 }
                @{ Environment = 'gcc'; ErrorBody = '{"errorCode":"FeatureNotAvailable"}'; Expected = 0 }
                @{ Environment = 'dod'; ErrorBody = '{"errorCode":"FeatureNotAvailable"}'; Expected = 0 }
            ) {
                $script:PowerBITestUpdateError.ErrorDetails = if ($null -ne $ErrorBody) {
                    [System.Management.Automation.ErrorDetails]::new($ErrorBody)
                } else { $null }

                {
                    Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                        -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                        -M365Environment $Environment -GroupName 'Test group' -Force -Confirm:$false
                } | Should -Throw '*Simulated HTTP 403*'

                Should -Invoke -CommandName Write-Warning -Times $Expected -Exactly -ParameterFilter {
                    $Message -match 'Power BI admin portal'
                }
                if ($Expected -eq 1) {
                    Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
                        $Message -match 'FeatureNotAvailable' -and
                        $Message -match 'GCC High' -and
                        $Message -match 'Test group' -and
                        $Message -match $script:PowerBITestGroupId -and
                        $Message -match 'Get-ScubaGearAppPermission' -and
                        $Message -notmatch 'stale allowed-group reference'
                    }
                }
                Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly
            }

            Context "response headers without ErrorDetails (<HeaderType>)" -ForEach @(
                @{ HeaderType = 'WebHeaderCollection' }
                @{ HeaderType = 'HttpResponseHeaders' }
            ) {
                BeforeAll {
                    Add-Type -AssemblyName System.Net.Http
                }

                It "shows manual guidance only for GCC High FeatureNotAvailable (<Environment>, <HeaderCode>)" -ForEach @(
                    @{ Environment = 'gcchigh'; HeaderCode = 'FeatureNotAvailable'; Expected = 1 }
                    @{ Environment = 'gcchigh'; HeaderCode = 'Forbidden'; Expected = 0 }
                    @{ Environment = 'gcchigh'; HeaderCode = 'FeatureNotAvailableOther'; Expected = 0 }
                    @{ Environment = 'gcchigh'; HeaderCode = $null; Expected = 0 }
                    @{ Environment = 'commercial'; HeaderCode = 'FeatureNotAvailable'; Expected = 0 }
                    @{ Environment = 'gcc'; HeaderCode = 'FeatureNotAvailable'; Expected = 0 }
                    @{ Environment = 'dod'; HeaderCode = 'FeatureNotAvailable'; Expected = 0 }
                ) {
                    $Response = if ($HeaderType -eq 'WebHeaderCollection') {
                        [PSCustomObject]@{
                            StatusCode = 403
                            Headers = [System.Net.WebHeaderCollection]::new()
                        }
                    } else {
                        [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::Forbidden)
                    }
                    try {
                        if ($HeaderCode) {
                            $Response.Headers.Add('x-ms-public-api-error-code', $HeaderCode)
                        }
                        $script:PowerBITestUpdateError.ErrorDetails = $null
                        $script:PowerBITestUpdateError.Exception | Add-Member -NotePropertyName Response -NotePropertyValue $Response

                        {
                            Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                                -M365Environment $Environment -GroupName 'Test group' -Force -Confirm:$false
                        } | Should -Throw '*Simulated HTTP 403*'

                        Should -Invoke -CommandName Write-Warning -Times $Expected -Exactly -ParameterFilter {
                            $Message -match 'Power BI admin portal' -and
                            $Message -match 'FeatureNotAvailable' -and
                            $Message -match $script:PowerBITestGroupId
                        }
                        Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly
                    }
                    finally {
                        if ($Response -is [System.IDisposable]) {
                            $Response.Dispose()
                        }
                    }
                }
            }

            It "reports the new group ID when the tenant-setting update fails" {
                $script:PowerBITestSettingEnabled = $true
                $script:PowerBITestGroups = @()
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    if ($Commandlet -eq 'Get-MgBetaGroup' -or $Commandlet -eq 'Get-MgBetaGroupMember') {
                        return [PSCustomObject]@{ Value = @() }
                    }
                    if ($Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.us/v1.0/groups') {
                        return [PSCustomObject]@{ id = $script:PowerBITestNewGroupId }
                    }
                    if ($Method -eq 'POST' -and $Uri -eq "https://graph.microsoft.us/v1.0/groups/$($script:PowerBITestNewGroupId)/members/`$ref") {
                        return
                    }
                    throw 'Unexpected Graph request.'
                }

                {
                    Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                        -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                        -M365Environment gcchigh -GroupName 'Test group' -Force -Confirm:$false
                } | Should -Throw '*Simulated HTTP 403*'

                Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
                    $Message -match 'Power BI admin portal' -and
                    $Message -match 'Test group' -and
                    $Message -match $script:PowerBITestNewGroupId
                }
            }

            It "includes confirmed stale references that still need manual removal" {
                $script:PowerBITestGroups += [PSCustomObject]@{
                    graphId = $script:PowerBITestMissingGroupId
                    name = 'Deleted group'
                }
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    if ($ID -eq $script:PowerBITestMissingGroupId) {
                        throw (New-PowerBITestHttpError -StatusCode 404)
                    }
                    return [PSCustomObject]@{ Value = @([PSCustomObject]@{ Id = $script:PowerBITestSpId }) }
                }
                Mock -CommandName Read-Host -MockWith {
                    if ($Prompt -like 'Remove stale*') { return 'y' }
                    return '1'
                }

                {
                    Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                        -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                        -M365Environment gcchigh -GroupName 'Test group' -Confirm:$false
                } | Should -Throw '*Simulated HTTP 403*'

                Should -Invoke -CommandName Write-Warning -Times 1 -Exactly -ParameterFilter {
                    $Message -match 'Power BI admin portal' -and
                    $Message -match $script:PowerBITestGroupId -and
                    $Message -match 'Remove stale allowed-group reference' -and
                    $Message -match 'Deleted group' -and
                    $Message -match $script:PowerBITestMissingGroupId
                }
                Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly
            }

            It "does not suggest a manual tenant update when reading settings fails" {
                Mock -CommandName Get-PowerBITenantSettingsRest -MockWith { throw $script:PowerBITestUpdateError }

                {
                    Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                        -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                        -M365Environment gcchigh -GroupName 'Test group' -Force -Confirm:$false
                } | Should -Throw '*Simulated HTTP 403*'

                Should -Invoke -CommandName Write-Warning -Times 0 -ParameterFilter { $Message -match 'Power BI admin portal' }
                Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 0
            }
        }

        It "does not inspect groups when access is already configured" {
            Mock -CommandName Get-ServicePrincipalMemberGroupIds -MockWith { $script:PowerBITestGroupId }
            Mock -CommandName Invoke-GraphDirectly -MockWith { throw 'Unexpected Graph request.' }

            $Output = Set-PowerBIAppRegistration -AppID $script:PowerBITestAppId `
                -ServicePrincipalID $script:PowerBITestSpId -TenantId 'tenant-id' `
                -M365Environment commercial -Force -Confirm:$false

            $Output | Should -Match 'already an authorized member'
            Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
        }
    }

    Describe "Power Platform registration catalog endpoints" {
        BeforeEach {
            Mock -CommandName Get-PowerPlatformAdminToken -MockWith {
                return [PSCustomObject]@{ BaseUrl = 'https://example.test'; AccessToken = 'token' }
            }
        }

        It "uses the catalog path for registration and removal" {
            Mock -CommandName Invoke-ScubaRestMethod -MockWith {}
            $AppId = '11111111-1111-1111-1111-111111111111'

            Set-PowerPlatformAppRegistration -AppID $AppId -TenantId 'tenant-id' -M365Environment commercial
            Set-PowerPlatformAppRegistration -AppID $AppId -TenantId 'tenant-id' -M365Environment commercial -Remove

            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'PUT' -and $Endpoint -eq '/providers/Microsoft.BusinessAppPlatform/adminApplications/11111111-1111-1111-1111-111111111111?api-version=2020-10-01'
            }
            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'DELETE' -and $Endpoint -eq '/providers/Microsoft.BusinessAppPlatform/adminApplications/11111111-1111-1111-1111-111111111111?api-version=2020-10-01'
            }
        }

        It "uses the catalog path when checking registrations" {
            Mock -CommandName Invoke-ScubaRestMethod -MockWith {
                return [PSCustomObject]@{ value = @([PSCustomObject]@{
                    applicationId = '11111111-1111-1111-1111-111111111111'
                }) }
            }

            Test-PowerPlatformAppRegistration -AppID '11111111-1111-1111-1111-111111111111' `
                -TenantId 'tenant-id' -M365Environment commercial | Should -BeTrue

            Should -Invoke -CommandName Invoke-ScubaRestMethod -Times 1 -Exactly -ParameterFilter {
                $Endpoint -eq '/providers/Microsoft.BusinessAppPlatform/adminApplications?api-version=2020-10-01'
            }
        }
    }

    Describe "Set-ScubaGearAppPermission" {
        BeforeAll {
            Mock -CommandName Connect-GraphHelper -MockWith {
                return $null
            }
        }

        It "Verify no changes are needed for optimal permissions" {
            $OptimalInputObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockOptimalPermissions.json") | ConvertFrom-Json
            $Optimal = $OptimalInputObject | Set-ScubaGearAppPermission -WhatIf
            $Optimal | Should -Be "No changes needed - service principal is already configured correctly."
        }

        It "Verify changes would be made if missing permissions are detected" {
            $MissingPermissionObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockMissingPermission.json") | ConvertFrom-Json
            $MissingPermissionObject.MissingPermissions.Permission = 'Policy.Read.All'
            $Result = $MissingPermissionObject | Set-ScubaGearAppPermission -WhatIf
            $Result[0] | Should -Be 'WhatIf: Would add missing permissions: Policy.Read.All'
        }

        Context "No Current Permissions Tests" {
            BeforeAll {
                # Mock Get-ScubaGearPermissions for delegated permissions removal
                Mock -CommandName Get-ScubaGearPermissions -MockWith {
                    param($outAs, $id)
                    if ($outAs -eq 'api') {
                        return "https://graph.microsoft.com/v1.0/servicePrincipals/$id/oauth2PermissionGrants"
                    }
                    return $null
                }

                # Mock Invoke-GraphDirectly for role definition lookup (if MissingRoles exists)
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $queryParams)

                    if ($Commandlet -eq 'Get-MgRoleManagementDirectoryRoleDefinition' -and $queryParams) {
                        return [PSCustomObject]@{
                            Value = @(
                                [PSCustomObject]@{
                                    IsBuiltIn = $true
                                    DisplayName = "Global Reader"
                                    TemplateId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                    Id = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                }
                            )
                        }
                    }
                    return $null
                }
            }

            It "Verify needed permissions would be added, unneeded delegated permissions removed, Global Reader role added, and power platform registered" {
                $NoCurrentPermissionsObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockNoCurrentPermissions.json") | ConvertFrom-Json
                $Result = $NoCurrentPermissionsObject | Set-ScubaGearAppPermission -WhatIf

                # Verify the message contains expected delegated permissions removal
                $Result[0] | Should -Be "WhatIf: Would remove delegated permissions: User.Read"

                # Verify the message contains expected missing permissions
                $Result[1] | Should -Be "WhatIf: Would add missing permissions: Policy.Read.All, PrivilegedEligibilitySchedule.Read.AzureADGroup, RoleManagementPolicy.Read.AzureADGroup, Directory.Read.All, RoleManagement.Read.Directory, User.Read.All, Exchange.ManageAsApp, Sites.FullControl.All"

                # Verify the correct role is assigned
                $Result[2] | Should -Be "WhatIf: Would assign directory role 'Global Reader' to 00000000-0000-0000-0000-000000000001"

                # Verify that Power Platform registration is handled
                $Result[3] | Should -Be "WhatIf: Would register application with Power Platform"
            }
        }

        Context "Missing Roles Tests" {
            BeforeAll {
                # Mock only the functions needed for role assignment tests
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $queryParams)

                    if ($Commandlet -eq 'Get-MgRoleManagementDirectoryRoleDefinition' -and $queryParams) {
                        # Mock role definition lookup - return structure that matches Graph API
                        # The real API returns an object with a Value property containing an array
                        return [PSCustomObject]@{
                            Value = @(
                                [PSCustomObject]@{
                                    IsBuiltIn = $true
                                    DisplayName = "Global Reader"
                                    TemplateId = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                    RolePermissions = @(@{
                                        Condition = $null
                                        AllowedResourceActions = @()
                                    })
                                    Version = "1"
                                    Id = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                    Description = ""
                                    IsEnabled = $true
                                    InheritsPermissionsFrom = @(@{Id = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b"})
                                    ResourceScopes = @("/")
                                }
                            )
                        }
                    }
                    return $null
                }
            }

            It "Verify changes would be made if missing roles are detected" {
                $MissingRoleObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockMissingRole.json") | ConvertFrom-Json
                $MissingRoleObject.MissingRoles = 'Global Reader'
                $Result = $MissingRoleObject | Set-ScubaGearAppPermission -WhatIf
                $Result[0] | Should -Match "WhatIf: Would assign directory role 'Global Reader' to 00000000-0000-0000-0000-000000000001"
            }
        }

        Context "Unneeded directory role assignment tests" {
            BeforeEach {
                $script:UnneededRoleInput = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformUnneeded.json") | ConvertFrom-Json
                $script:UnneededRoleInput.ProductNames = @('aad')
                $script:UnneededRoleInput.MissingRoles = $false
                $script:UnneededRoleInput.PowerPlatformRegistered = $false
                $script:UnneededRoleInput | Add-Member -MemberType NoteProperty -Name PowerBIRegistered -Value $false -Force
                $script:UnneededRoleInput | Add-Member -MemberType NoteProperty -Name PowerBIGroupMembership -Value $false -Force
                $script:UnneededRoleInput | Add-Member -MemberType NoteProperty -Name ExtraRoles -Value @([PSCustomObject]@{
                    RoleName = 'Global Reader'
                    RoleDefinitionId = 'global-reader-role-id'
                    AssignmentId = 'global-reader-assignment-id'
                }) -Force
            }

            It "previews <RoleName> removal without issuing a Graph delete under WhatIf" -ForEach @(
                @{ RoleName = 'Global Reader' }
                @{ RoleName = 'Global Administrator' }
                @{ RoleName = 'Custom Audit Role' }
            ) {
                param($RoleName)
                $script:UnneededRoleInput.ExtraRoles[0].RoleName = $RoleName
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw "WhatIf must not issue a Graph request."
                }

                $result = $script:UnneededRoleInput | Set-ScubaGearAppPermission -WhatIf

                $result | Should -Contain "WhatIf: Would remove unneeded directory role '$RoleName' from 00000000-0000-0000-0000-000000000001"
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
            }

            It "deletes the <RoleName> assignment through the catalog-backed Graph command" -ForEach @(
                @{ RoleName = 'Global Reader' }
                @{ RoleName = 'Global Administrator' }
                @{ RoleName = 'Custom Audit Role' }
            ) {
                param($RoleName)
                $script:UnneededRoleInput.ExtraRoles[0].RoleName = $RoleName
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $id, $M365Environment)
                    if ($Commandlet -ne 'Remove-MgRoleManagementDirectoryRoleAssignment' -or
                        $id -ne 'global-reader-assignment-id' -or
                        $M365Environment -ne 'commercial') {
                        throw "Unexpected Graph request."
                    }
                }

                $result = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and
                    $id -eq 'global-reader-assignment-id' -and
                    $M365Environment -eq 'commercial'
                }
                $result | Should -Contain "Removed unneeded directory role assignment: $RoleName"
            }

            It "preserves Global Reader when a selected product still requires it" {
                $script:UnneededRoleInput.ProductNames = @('aad', 'exo')
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw "Global Reader is still required and must not be deleted."
                }

                $result = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
                $result | Should -Not -Contain 'Removed unneeded directory role assignment: Global Reader'
            }

            It "deletes each unneeded Global Reader assignment by its own assignment ID" {
                $script:UnneededRoleInput.ExtraRoles = @(
                    [PSCustomObject]@{
                        RoleName = 'Global Reader'
                        RoleDefinitionId = 'global-reader-role-id'
                        AssignmentId = 'first-assignment-id'
                    }
                    [PSCustomObject]@{
                        RoleName = 'Global Reader'
                        RoleDefinitionId = 'global-reader-role-id'
                        AssignmentId = 'second-assignment-id'
                    }
                )
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $id)
                    if ($Commandlet -ne 'Remove-MgRoleManagementDirectoryRoleAssignment' -or
                        $id -notin @('first-assignment-id', 'second-assignment-id')) {
                        throw 'Unexpected Graph request.'
                    }
                }

                $null = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and $id -eq 'first-assignment-id'
                }
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and $id -eq 'second-assignment-id'
                }
            }

            It "removes unneeded roles while preserving a required role in the same input" {
                $script:UnneededRoleInput.ProductNames = @('aad', 'exo')
                $script:UnneededRoleInput.ExtraRoles = @(
                    [PSCustomObject]@{
                        RoleName = 'Global Reader'
                        AssignmentId = 'reader-assignment-id'
                    }
                    [PSCustomObject]@{
                        RoleName = 'Global Administrator'
                        AssignmentId = 'admin-assignment-id'
                    }
                    [PSCustomObject]@{
                        RoleName = 'Custom Audit Role'
                        AssignmentId = 'custom-assignment-id'
                    }
                )
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $id)
                    if ($Commandlet -ne 'Remove-MgRoleManagementDirectoryRoleAssignment' -or
                        $id -notin @('admin-assignment-id', 'custom-assignment-id')) {
                        throw 'Unexpected Graph request.'
                    }
                }

                $result = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 2 -Exactly
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and $id -eq 'admin-assignment-id'
                }
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Remove-MgRoleManagementDirectoryRoleAssignment' -and $id -eq 'custom-assignment-id'
                }
                $result | Should -Not -Contain 'Removed unneeded directory role assignment: Global Reader'
            }

            It "preserves a required role other than Global Reader in stale pipeline data" {
                $script:UnneededRoleInput.ExtraRoles[0].RoleName = 'Custom Audit Role'
                Mock -CommandName Get-ScubaGearServicePrincipalRole -MockWith { 'Custom Audit Role' }
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw 'A required role must not be deleted.'
                }

                $null = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false

                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
            }

            It "warns and skips role removal when <PropertyName> is missing" -ForEach @(
                @{ PropertyName = 'RoleName' }
                @{ PropertyName = 'AssignmentId' }
            ) {
                param($PropertyName)
                $script:UnneededRoleInput.ExtraRoles[0].$PropertyName = $null
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw 'An incomplete role assignment must not be deleted.'
                }

                $null = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false `
                    -WarningVariable RemovalWarnings -WarningAction SilentlyContinue

                $RemovalWarnings | Should -Match 'role name or role-assignment ID is missing'
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
            }

            It "warns and skips role removal when product selection is missing" {
                $script:UnneededRoleInput.ProductNames = $null
                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    throw 'A role must not be deleted without determining product requirements.'
                }

                $null = $script:UnneededRoleInput | Set-ScubaGearAppPermission -Confirm:$false `
                    -WarningVariable RemovalWarnings -WarningAction SilentlyContinue

                $RemovalWarnings | Should -Match 'Cannot determine required directory roles without ProductNames'
                Should -Invoke -CommandName Invoke-GraphDirectly -Times 0
            }
        }

        Context "Extra Permissions Tests" {

            It "Verify changes would be made if extra permissions are detected" {
                $ExtraPermissionObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockExtraPermissions.json") | ConvertFrom-Json
                $ExtraPermissionInputObject = $ExtraPermissionObject
                $Result = $ExtraPermissionInputObject | Set-ScubaGearAppPermission -WhatIf
                $Result[0] | Should -Be "WhatIf: Would remove extra permissions: Acronym.Read.All"
            }
        }

        Context "Power Platform Registration Tests" {

            It "Verify Power Platform would be removed when registered but not needed" {
                $PowerPlatformUnneededObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformUnneeded.json") | ConvertFrom-Json
                $Result = $PowerPlatformUnneededObject | Set-ScubaGearAppPermission -WhatIf
                $Result[0] | Should -Be "WhatIf: Would remove Power Platform registration"
            }

            It "Verify Power Platform would be registered when needed but missing" {
                $PowerPlatformNeededObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformNeeded.json") | ConvertFrom-Json
                $Result = $PowerPlatformNeededObject | Set-ScubaGearAppPermission -WhatIf
                $Result[0] | Should -Be "WhatIf: Would register application with Power Platform"
            }

            # Get-MgContext no longer exists, and this session cannot read the organization, so the tenant has to come
            # from the service principal. The -WhatIf tests above never reach this code.
            It "Removes the Power Platform registration using the service principal's tenant" {
                $PowerPlatformUnneededObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformUnneeded.json") | ConvertFrom-Json
                Mock Invoke-GraphDirectly {
                    [pscustomobject]@{ Value = [pscustomobject]@{ AppOwnerOrganizationId = '11111111-1111-1111-1111-111111111111' } }
                } -ParameterFilter { $Commandlet -eq 'Get-MgServicePrincipal' }
                Mock Set-PowerPlatformAppRegistration {}

                $Result = $PowerPlatformUnneededObject | Set-ScubaGearAppPermission -Confirm:$false -WarningVariable RemovalWarnings -WarningAction SilentlyContinue

                Should -Invoke Set-PowerPlatformAppRegistration -Times 1 -Exactly -ParameterFilter {
                    $AppID -eq '00000000-0000-0000-0000-000000000001' -and
                    $TenantId -eq '11111111-1111-1111-1111-111111111111' -and
                    $M365Environment -eq 'commercial' -and
                    $Remove
                }
                Should -Invoke Invoke-GraphDirectly -Times 1 -Exactly -ParameterFilter {
                    $Commandlet -eq 'Get-MgServicePrincipal' -and $queryParams['$filter'] -eq "id eq '00000000-0000-0000-0000-000000000002'"
                }
                $Result | Should -Contain 'Successfully removed Power Platform registration'
                $RemovalWarnings | Should -BeNullOrEmpty
            }

            It "Warns and does not remove the registration when the tenant cannot be found" {
                $PowerPlatformUnneededObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockPowerPlatformUnneeded.json") | ConvertFrom-Json
                Mock Invoke-GraphDirectly { [pscustomobject]@{ Value = $null } } -ParameterFilter { $Commandlet -eq 'Get-MgServicePrincipal' }
                Mock Set-PowerPlatformAppRegistration {}

                $Result = $PowerPlatformUnneededObject | Set-ScubaGearAppPermission -Confirm:$false -WarningVariable RemovalWarnings -WarningAction SilentlyContinue

                Should -Invoke Set-PowerPlatformAppRegistration -Times 0
                $Result | Should -Not -Contain 'Successfully removed Power Platform registration'
                @($RemovalWarnings) -join ' ' | Should -BeLike '*Could not retrieve tenant ID*'
            }
        }

        Context "Multiple Issues Tests" {
            BeforeAll {
                $MultipleIssuesObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockMultipleIssues.json") | ConvertFrom-Json

                # Mock all functions needed for multiple issues scenario
                Mock -CommandName Get-ScubaGearPermissions -MockWith {
                    param($outAs, $id)
                    if ($outAs -eq 'api') {
                        return "https://graph.microsoft.com/v1.0/servicePrincipals/$id/appRoleAssignments"
                    }
                    return $null
                }

                Mock -CommandName Invoke-GraphDirectly -MockWith {
                    param($Commandlet, $queryParams)

                    if ($Commandlet -eq 'Get-MgBetaApplication') {
                        return $MultipleIssuesObject.ExtraPermissions
                    }
                    elseif ($Commandlet -eq 'Update-MgBetaApplication') {
                        return $null
                    }
                    elseif ($Commandlet -eq 'Get-MgRoleManagementDirectoryRoleDefinition' -and $queryParams) {
                        return [PSCustomObject]@{
                            Value = @(
                                [PSCustomObject]@{
                                    Id = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
                                    DisplayName = "Global Reader"
                                }
                            )
                        }
                    }
                    return $null
                }
            }

            It "Verify multiple issues are detected and reported" {
                $MultipleIssuesInputObject = $MultipleIssuesObject
                $Result = $MultipleIssuesInputObject | Set-ScubaGearAppPermission -WhatIf

                # Verify all expected messages are present
                $Result[0] | Should -Be "WhatIf: Would remove extra permissions: Acronym.Read.All"
                $Result[1] | Should -Be "WhatIf: Would add missing permissions: Policy.Read.All"
                $Result[2] | Should -Be "WhatIf: Would assign directory role 'Global Reader' to 00000000-0000-0000-0000-000000000001"
            }
        }

        Context "Handle permissions in App Registration Manifest that are not granted admin consent" {

            It "Verify permissions in manifest that only need to be granted admin consent" {
                $MissingAdminConsentPermissionsObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockManifestMissingAdminConsent.json") | ConvertFrom-Json
                $Result = $MissingAdminConsentPermissionsObject | Set-ScubaGearAppPermission -WhatIf

                # Verify expected message is present
                $Result[0] | Should -Be "WhatIf: Would add missing permissions: User.Read.All, Exchange.ManageAsApp"
            }
        }

        Context "Verify both exchange permissions are present in GCC High environments" {

            It "Verify Microsoft Exchange Online Protection Exchange.ManageAsApp permission is handled correctly in GCC High" {
                $MissingAdminConsentPermissionsObject = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "SetScubaGearAppPermissionData\MockMissingGCCHighExoPermission.json") | ConvertFrom-Json
                $Result = $MissingAdminConsentPermissionsObject | Set-ScubaGearAppPermission -WhatIf

                # Verify expected message is present
                $Result[0] | Should -Be "WhatIf: Would add missing permissions: Exchange.ManageAsApp"
            }
        }
    }
}

AfterAll {
    Remove-Module ServicePrincipal -Force -ErrorAction 'SilentlyContinue'
}