BeforeAll {
    $ClassPath = (Join-Path -Path $PSScriptRoot -ChildPath "./../../../../../PowerShell/ScubaGear/Modules/Providers/ProviderHelpers/AADConditionalAccessHelper.psm1")
    Import-Module $ClassPath
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'CapHelper')]
    $CapHelper = Get-CapTracker
}

Describe "GetIncludedUsers" {
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Cap')]
        $Cap = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "./CapSnippets/Users.json") | ConvertFrom-Json
    }
    It "returns 'None' when no users are included" {
        $Cap.Conditions.Users.IncludeUsers += "None"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "None"
    }

    It "handles including single users" {
        $Cap.Conditions.Users.IncludeUsers += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific user"
    }

    It "handles including multiple users" {
        $Cap.Conditions.Users.IncludeUsers += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.IncludeUsers += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "2 specific users"
    }

    It "handles including single groups" {
        $Cap.Conditions.Users.IncludeGroups += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific group"
    }

    It "handles including multiple groups" {
        $Cap.Conditions.Users.IncludeGroups += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.IncludeGroups += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "2 specific groups"
    }

    It "handles including single roles" {
        $Cap.Conditions.Users.IncludeRoles += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific role"
    }

    It "handles including multiple roles" {
        $Cap.Conditions.Users.IncludeRoles += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.IncludeRoles += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "2 specific roles"
    }

    It "handles including users, groups, and roles simultaneously" {
        $Cap.Conditions.Users.IncludeUsers += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.IncludeRoles += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.IncludeRoles += "caaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.IncludeGroups += "daaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.IncludeGroups += "eaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.IncludeGroups += "faaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific user, 2 specific roles, 3 specific groups"
    }

    It "returns 'All' when all users are included" {
        $Cap.Conditions.Users.IncludeUsers += "all"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "All"
    }

    It "handles including single type of external user" {
        $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.ExternalTenants.MembershipKind = "all"
        $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes = "internalGuest"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "Local guest users"
    }

    It "handles including all types of guest users" {
        $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.ExternalTenants.MembershipKind = "all"
        $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes = "b2bCollaborationGuest,b2bCollaborationMember,b2bDirectConnectUser,internalGuest,serviceProvider,otherExternalUser"
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "B2B collaboration guest users, B2B collaboration member users, B2B direct connect users, Local guest users, Service provider users, Other external users"
    }

    It "handles empty input" {
        $Cap = @{}
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap) 3>$null) -Join ", " # 3>$null to surpress the warning
        # message as it is expected in this case
        $UsersIncluded | Should -Be ""
    }
}

Describe "GetExcludedUsers" {
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Cap')]
        $Cap = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "./CapSnippets/Users.json") | ConvertFrom-Json
    }
    It "returns 'None' when no users are included" {
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "None"
    }

    It "handles excluding single users" {
        $Cap.Conditions.Users.ExcludeUsers += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "1 specific user"
    }

    It "handles excluding multiple users" {
        $Cap.Conditions.Users.ExcludeUsers += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.ExcludeUsers += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "2 specific users"
    }

    It "handles excluding single groups" {
        $Cap.Conditions.Users.ExcludeGroups += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "1 specific group"
    }

    It "handles excluding multiple groups" {
        $Cap.Conditions.Users.ExcludeGroups += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.ExcludeGroups += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "2 specific groups"
    }

    It "handles excluding single roles" {
        $Cap.Conditions.Users.ExcludeRoles += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "1 specific role"
    }

    It "handles excluding multiple roles" {
        $Cap.Conditions.Users.ExcludeRoles += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.ExcludeRoles += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "2 specific roles"
    }

    It "handles excluding users, groups, and roles simultaneously" {
        $Cap.Conditions.Users.ExcludeUsers += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.ExcludeRoles += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.ExcludeRoles += "caaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.ExcludeGroups += "daaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.ExcludeGroups += "eaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Users.ExcludeGroups += "faaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "1 specific user, 2 specific roles, 3 specific groups"
    }

    It "handles excluding all types of external users" {
        $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.ExternalTenants.MembershipKind = "all"
        $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.GuestOrExternalUserTypes = "b2bCollaborationGuest,b2bCollaborationMember,b2bDirectConnectUser,internalGuest,serviceProvider,otherExternalUser"
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "B2B collaboration guest users, B2B collaboration member users, B2B direct connect users, Local guest users, Service provider users, Other external users"
    }

    It "handles excluding a single type of external user" {
        $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.ExternalTenants.MembershipKind = "all"
        $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.GuestOrExternalUserTypes = "serviceProvider"
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "Service provider users"
    }

    It "handles empty input" {
        $Cap = @{}
        $UsersExcluded = $($CapHelper.GetExcludedUsers($Cap) 3>$null) -Join ", " # 3>$null to surpress the warning
        # message as it is expected in this case
        $UsersExcluded | Should -Be ""
    }
}

Describe "GetApplications" {
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Cap')]
        $Cap = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "./CapSnippets/Apps.json") | ConvertFrom-Json
    }
    It "handles including all apps" {
        $Cap.Conditions.Applications.IncludeApplications += "All"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: All"
        $Apps[2] | Should -Be "Apps excluded: None"
    }

    It "handles including/excluding no apps" {
        $Cap.Conditions.Applications.IncludeApplications += "None"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: None"
        $Apps[2] | Should -Be "Apps excluded: None"
    }

    It "handles including/excluding single specific apps" {
        $Cap.Conditions.Applications.IncludeApplications += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Applications.ExcludeApplications += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: 1 specific app"
        $Apps[2] | Should -Be "Apps excluded: 1 specific app"
    }

    It "handles including/excluding multiple specific apps" {
        $Cap.Conditions.Applications.IncludeApplications += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Applications.IncludeApplications += "baaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Applications.IncludeApplications += "caaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Applications.ExcludeApplications += "daaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Cap.Conditions.Applications.ExcludeApplications += "eaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: 3 specific apps"
        $Apps[2] | Should -Be "Apps excluded: 2 specific apps"
    }

    It "handles app filter in include mode" {
        $Cap.Conditions.Applications.ApplicationFilter.Mode = "include"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: custom application filter"
        $Apps[2] | Should -Be "Apps excluded: None"
    }

    It "handles app filter in exclude mode" {
        $Cap.Conditions.Applications.ApplicationFilter.Mode = "exclude"
        $Cap.Conditions.Applications.IncludeApplications += "All"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: All"
        $Apps[2] | Should -Be "Apps excluded: custom application filter"
    }

    It "handles including app filter and specific apps" {
        $Cap.Conditions.Applications.ApplicationFilter.Mode = "include"
        $Cap.Conditions.Applications.IncludeApplications += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: 1 specific app"
        $Apps[2] | Should -Be "Apps included: custom application filter"
        $Apps[3] | Should -Be "Apps excluded: None"
    }

    It "handles excluding app filter and specific apps" {
        $Cap.Conditions.Applications.ApplicationFilter.Mode = "exclude"
        $Cap.Conditions.Applications.IncludeApplications += "All"
        $Cap.Conditions.Applications.ExcludeApplications += "aaaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: All"
        $Apps[2] | Should -Be "Apps excluded: 1 specific app"
        $Apps[3] | Should -Be "Apps excluded: custom application filter"
    }

    It "handles registering a device" {
        $Cap.Conditions.Applications.IncludeUserActions += "urn:user:registerdevice"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: actions"
        $Apps[1] | Should -Be "User action: Register or join devices"
    }

    It "handles registering security info" {
        $Cap.Conditions.Applications.IncludeUserActions += "urn:user:registersecurityinfo"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: actions"
        $Apps[1] | Should -Be "User action: Register security info"
    }

    It "handles registering security info" {
        $Cap.Conditions.Applications.IncludeAuthenticationContextClassReferences += "c1"
        $Cap.Conditions.Applications.IncludeAuthenticationContextClassReferences += "c3"
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps | Should -Be "Policy applies to: 2 authentication contexts"
    }

    It "handles empty input" {
        $Cap = @{}
        $Apps = $($CapHelper.GetApplications($Cap) 3>$null) -Join ", " # 3>$null to surpress the warning
        # message as it is expected in this case
        $Apps | Should -Be ""
    }
}

Describe "GetConditions" {
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Cap')]
        $Cap = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "./CapSnippets/Conditions.json") | ConvertFrom-Json
    }
    It "handles user risk levels" {
        $Cap.Conditions.UserRiskLevels += "high"
        $Cap.Conditions.UserRiskLevels += "medium"
        $Cap.Conditions.UserRiskLevels += "low"
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "User risk levels: high, medium, low"
    }

    It "handles sign-in risk levels" {
        $Cap.Conditions.SignInRiskLevels += "low"
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Sign-in risk levels: low"
    }

    It "handles including all device platforms" {
        $Cap.Conditions.Platforms.ExcludePlatforms = @()
        $Cap.Conditions.Platforms.IncludePlatforms = @("all")
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Device platforms included: all"
        $Conditions[1] | Should -Be "Device platforms excluded: none"
    }

    It "handles including/excluding specific device platforms" {
        $Cap.Conditions.Platforms.ExcludePlatforms = @("iOS", "macOS", "linux")
        $Cap.Conditions.Platforms.IncludePlatforms = @("android")
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Device platforms included: android"
        $Conditions[1] | Should -Be "Device platforms excluded: iOS, macOS, linux"
    }

    It "handles including all locations" {
        $Cap.Conditions.Locations.ExcludeLocations = @()
        $Cap.Conditions.Locations.IncludeLocations = @("All")
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: all locations"
        $Conditions[1] | Should -Be "Locations excluded: none"
    }

    It "handles excluding trusted locations" {
        $Cap.Conditions.Locations.ExcludeLocations = @("AllTrusted")
        $Cap.Conditions.Locations.IncludeLocations = @("All")
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: all locations"
        $Conditions[1] | Should -Be "Locations excluded: all trusted locations"
    }

    It "handles including/excluding single custom locations" {
        $Cap.Conditions.Locations.ExcludeLocations = @("00000000-0000-0000-0000-000000000000")
        $Cap.Conditions.Locations.IncludeLocations = @("10000000-0000-0000-0000-000000000000")
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: 1 specific location"
        $Conditions[1] | Should -Be "Locations excluded: 1 specific location"
    }

    It "handles including/excluding multiple custom locations" {
        $Cap.Conditions.Locations.ExcludeLocations = @()
        $Cap.Conditions.Locations.ExcludeLocations += @("00000000-0000-0000-0000-000000000000")
        $Cap.Conditions.Locations.ExcludeLocations += @("10000000-0000-0000-0000-000000000000")
        $Cap.Conditions.Locations.ExcludeLocations += @("20000000-0000-0000-0000-000000000000")
        $Cap.Conditions.Locations.IncludeLocations = @()
        $Cap.Conditions.Locations.IncludeLocations += @("30000000-0000-0000-0000-000000000000")
        $Cap.Conditions.Locations.IncludeLocations += @("40000000-0000-0000-0000-000000000000")
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: 2 specific locations"
        $Conditions[1] | Should -Be "Locations excluded: 3 specific locations"
    }

    It "handles including trusted locations" {
        $Cap.Conditions.Locations.IncludeLocations = @("AllTrusted")
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: all trusted locations"
        $Conditions[1] | Should -Be "Locations excluded: none"
    }

    It "handles including all client apps" {
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions | Should -Be "Client apps included: all"
    }

    It "handles including specific client apps" {
        $Cap.Conditions.ClientAppTypes = @("exchangeActiveSync", "browser",
            "mobileAppsAndDesktopClients", "other")
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions | Should -Be "Client apps included: Exchange ActiveSync Clients, Browser, Mobile apps and desktop clients, Other clients"
    }

    It "handles custom client app filter in include mode" {
        $Cap.Conditions.Devices.DeviceFilter.Mode = "include"
        $Cap.Conditions.Devices.DeviceFilter.Rule = "device.manufacturer -eq 'helloworld'"
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[1] | Should -Be "Custom device filter in include mode active"
    }

    It "handles custom client app filter in exclude mode" {
        $Cap.Conditions.Devices.DeviceFilter.Mode = "exclude"
        $Cap.Conditions.Devices.DeviceFilter.Rule = "device.manufacturer -eq 'helloworld'"
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[1] | Should -Be "Custom device filter in exclude mode active"
    }

    It "handles many conditions simultaneously" {
        $Cap.Conditions.UserRiskLevels += "low"
        $Cap.Conditions.SignInRiskLevels += "high"
        $Cap.Conditions.Platforms.ExcludePlatforms = @("android", "iOS", "macOS", "linux")
        $Cap.Conditions.Platforms.IncludePlatforms = @("all")
        $Cap.Conditions.Locations.IncludeLocations = @("AllTrusted")
        $Cap.Conditions.Locations.ExcludeLocations = @()
        $Cap.Conditions.ClientAppTypes = @("exchangeActiveSync")
        $Cap.Conditions.Devices.DeviceFilter.Mode = "exclude"
        $Cap.Conditions.Devices.DeviceFilter.Rule = "device.manufacturer -eq 'helloworld'"
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "User risk levels: low"
        $Conditions[1] | Should -Be "Sign-in risk levels: high"
        $Conditions[2] | Should -Be "Device platforms included: all"
        $Conditions[3] | Should -Be "Device platforms excluded: android, iOS, macOS, linux"
        $Conditions[4] | Should -Be "Locations included: all trusted locations"
        $Conditions[5] | Should -Be "Locations excluded: none"
        $Conditions[6] | Should -Be "Client apps included: Exchange ActiveSync Clients"
        $Conditions[7] | Should -Be "Custom device filter in exclude mode active"
    }

    It "handles empty input" {
        $Cap = @{}
        $Conditions = $($CapHelper.GetConditions($Cap) 3>$null) -Join ", " # 3>$null to surpress the warning
        # message as it is expected in this case
        $Conditions | Should -Be ""
    }
}

Describe "GetAccessControls" {
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Cap')]
        $Cap = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "./CapSnippets/AccessControls.json") | ConvertFrom-Json
    }
    It "handles blocking access" {
        $Cap.GrantControls.BuiltInControls = @("block")
        $Controls = $($CapHelper.GetAccessControls($Cap))
        $Controls | Should -Be "Block access"
    }

    It "handles requiring single control" {
        $Cap.GrantControls.BuiltInControls = @("mfa")
        $Controls = $($CapHelper.GetAccessControls($Cap))
        $Controls | Should -Be "Allow access but require multifactor authentication"
    }

    It "handles requiring multiple controls in AND mode" {
        $Cap.GrantControls.BuiltInControls = @("mfa", "compliantDevice", "domainJoinedDevice",
            "approvedApplication", "compliantApplication", "passwordChange")
        $Cap.GrantControls.Operator = "AND"
        $Controls = $($CapHelper.GetAccessControls($Cap))
        $Controls | Should -Be "Allow access but require multifactor authentication, device to be marked compliant, Hybrid Azure AD joined device, approved client app, app protection policy, AND password change"
    }

    It "handles requiring multiple controls in OR mode" {
        $Cap.GrantControls.BuiltInControls = @("mfa", "compliantDevice", "domainJoinedDevice",
            "approvedApplication", "compliantApplication", "passwordChange")
        $Cap.GrantControls.Operator = "OR"
        $Controls = $($CapHelper.GetAccessControls($Cap))
        $Controls | Should -Be "Allow access but require multifactor authentication, device to be marked compliant, Hybrid Azure AD joined device, approved client app, app protection policy, OR password change"
    }

    It "handles using authentication strength (phishing resistant MFA)" {
        $Cap.GrantControls.AuthenticationStrength.DisplayName = "Phishing resistant MFA"
        $Controls = $($CapHelper.GetAccessControls($Cap))
        $Controls | Should -Be "Allow access but require authentication strength (Phishing resistant MFA)"
    }

    It "handles using both authentication strength and a traditional control" {
        $Cap.GrantControls.AuthenticationStrength.DisplayName = "Multi-factor authentication"
        $Cap.GrantControls.BuiltInControls = @("passwordChange")
        $Cap.GrantControls.Operator = "AND"
        $Controls = $($CapHelper.GetAccessControls($Cap))
        $Controls | Should -Be "Allow access but require password change, AND authentication strength (Multi-factor authentication)"
    }

    It "handles using no access controls" {
        $Cap.GrantControls.BuiltInControls = $null
        $Controls = $($CapHelper.GetAccessControls($Cap))
        $Controls | Should -Be "None"
    }

    It "handles empty input" {
        $Cap = @{}
        $Controls = $($CapHelper.GetAccessControls($Cap) 3>$null) -Join ", " # 3>$null to surpress the warning
        # message as it is expected in this case
        $Controls | Should -Be ""
    }
}

Describe "GetSessionControls" {
    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'Cap')]
        $Cap = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "./CapSnippets/SessionControls.json") | ConvertFrom-Json
    }
    It "handles using no session controls" {
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "None"
    }

    It "handles using app enforced restrictions" {
        $Cap.SessionControls.ApplicationEnforcedRestrictions.IsEnabled = $true
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "Use app enforced restrictions"
    }

    It "handles using conditional access app control with custom policy" {
        $Cap.SessionControls.CloudAppSecurity.CloudAppSecurityType = "mcasConfigured"
        $Cap.SessionControls.CloudAppSecurity.IsEnabled = $true
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "Use Conditional Access App Control (Use custom policy)"
    }

    It "handles using conditional access app control in monitor mode" {
        $Cap.SessionControls.CloudAppSecurity.CloudAppSecurityType = "monitorOnly"
        $Cap.SessionControls.CloudAppSecurity.IsEnabled = $true
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "Use Conditional Access App Control (Monitor only)"
    }

    It "handles using conditional access app control in block mode" {
        $Cap.SessionControls.CloudAppSecurity.CloudAppSecurityType = "blockDownloads"
        $Cap.SessionControls.CloudAppSecurity.IsEnabled = $true
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "Use Conditional Access App Control (Block downloads)"
    }

    It "handles using sign-in frequency every time" {
        $Cap.SessionControls.SignInFrequency.FrequencyInterval = "everyTime"
        $Cap.SessionControls.SignInFrequency.IsEnabled = $true
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "Sign-in frequency (every time)"
    }

    It "handles using sign-in frequency time based" {
        $Cap.SessionControls.SignInFrequency.FrequencyInterval = "timeBased"
        $Cap.SessionControls.SignInFrequency.Type = "days"
        $Cap.SessionControls.SignInFrequency.Value = 10
        $Cap.SessionControls.SignInFrequency.IsEnabled = $true
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "Sign-in frequency (every 10 days)"
    }

    It "handles using persistent browser session" {
        $Cap.SessionControls.PersistentBrowser.IsEnabled = $true
        $Cap.SessionControls.PersistentBrowser.Mode = "never"
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "Persistent browser session (never persistent)"
    }

    It "handles using customized continuous access evaluation" {
        $Cap.SessionControls.ContinuousAccessEvaluation.Mode = "disabled"
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "Customize continuous access evaluation"
    }

    It "handles disabling resilience defaults" {
        $Cap.SessionControls.DisableResilienceDefaults = $true
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls | Should -Be "Disable resilience defaults"
    }

    It "handles multiple controls simultaneously" {
        $Cap.SessionControls.PersistentBrowser.IsEnabled = $true
        $Cap.SessionControls.PersistentBrowser.Mode = "never"
        $Cap.SessionControls.DisableResilienceDefaults = $true
        $Controls = $($CapHelper.GetSessionControls($Cap))
        $Controls[0] | Should -Be "Persistent browser session (never persistent)"
        $Controls[1] | Should -Be "Disable resilience defaults"
    }

    It "handles empty input" {
        $Cap = @{}
        $Controls = $($CapHelper.GetSessionControls($Cap) 3>$null) -Join ", " # 3>$null to surpress the warning
        # message as it is expected in this case
        $Controls | Should -Be ""
    }
}