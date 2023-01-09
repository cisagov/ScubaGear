function Export-AADProvider {
    <#
    .Description
    Gets the Azure Active Directory (AAD) settings that are relevant
    to the SCuBA AAD baselines using a subset of the modules under the
    overall Microsoft Graph PowerShell Module
    .Functionality
    Internal
    #>

    Import-Module $PSScriptRoot/ProviderHelpers/CommandTracker.psm1
    $Tracker = Get-CommandTracker

    # The below cmdlet covers the following baselines
    # - 2.1
    # - 2.2
    # - 2.3 First Policy bullet
    # - 2.4 First Policy bullet
    # - 2.9
    # - 2.10
    # - 2.17 first part
    $AllPolicies = ConvertTo-Json -Depth 10 @($Tracker.TryCommand("Get-MgIdentityConditionalAccessPolicy"))

    # Get a list of the tenant's provisioned service plans - used to see if the tenant has AAD premium p2 license required for some checks
    # The Rego looks at the service_plans in the JSON
    $ServicePlans = $Tracker.TryCommand("Get-MgSubscribedSku").ServicePlans | Where-Object -Property ProvisioningStatus -eq -Value "Success" -ErrorAction Stop
    # The RequiredServicePlan variable is used so that PIM Cmdlets are only executed if the tenant has the premium license
    $RequiredServicePlan = $ServicePlans | Where-Object -Property ServicePlanName -eq -Value "AAD_PREMIUM_P2"
    $ServicePlans = ConvertTo-Json -Depth 3 @($ServicePlans)

    # A list of privileged users and their role assignments is used for 2.11 and 2.12
    # If the tenant has the premium license then we want to process PIM Eligible role assignments - otherwise we don't to avoid an error
    if ($RequiredServicePlan) {
        $PrivilegedUsers = $Tracker.TryCommand("Get-PrivilegedUser", @{"TenantHasPremiumLicense"=$true})
    }
    else{
        $PrivilegedUsers = $Tracker.TryCommand("Get-PrivilegedUser")
    }
    $PrivilegedUsers = $PrivilegedUsers | ConvertTo-Json
    # The above Converto-Json call doesn't need to have the input wrapped in an
    # array (e.g, "ConvertTo-Json (@PrivilegedUsers)") because $PrivilegedUsers is
    # a dictionary, not an array, and ConvertTo-Json doesn't mess up dictionaries
    # like it does arrays (just observe the difference in output between
    # "@{} | ConvertTo-Json" and
    # "@() | ConvertTo-Json" )
    $PrivilegedUsers = if ($null -eq $PrivilegedUsers) {"{}"} else {$PrivilegedUsers}
    # While ConvertTo-Json won't mess up a dict as described in the above comment,
    # on error, $TryCommand returns an empty list, not a dictionary. The if/else
    # above corrects the $null ConvertTo-Json would return in that case to an empty
    # dictionary

    # 2.13 support for role ID and display name mapping
    # 2.14 - 2.16 Azure AD PIM role settings
    if ($RequiredServicePlan){
        $PrivilegedRoles = $Tracker.TryCommand("Get-PrivilegedRole", @{"TenantHasPremiumLicense"=$true})
    }
    else{
        $PrivilegedRoles = $Tracker.TryCommand("Get-PrivilegedRole")
    }
    $PrivilegedRoles = ConvertTo-Json -Depth 10 @($PrivilegedRoles) # Depth required to get policy rule object details

    # 2.6, 2.7, & 2.18 1st/3rd Policy Bullets
    $AuthZPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-MgPolicyAuthorizationPolicy"))

    # 2.7 third bullet
    $DirectorySettings = ConvertTo-Json -Depth 10 @($Tracker.TryCommand("Get-MgDirectorySetting"))

    # 2.7 Policy Bullet 2]
    $AdminConsentReqPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-MgPolicyAdminConsentRequestPolicy"))

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "conditional_access_policies": $AllPolicies,
    "authorization_policies": $AuthZPolicies,
    "admin_consent_policies": $AdminConsentReqPolicies,
    "privileged_users": $PrivilegedUsers,
    "privileged_roles": $PrivilegedRoles,
    "service_plans": $ServicePlans,
    "directory_settings": $DirectorySettings,
    "aad_successful_commands": $SuccessfulCommands,
    "aad_unsuccessful_commands": $UnSuccessfulCommands,
"@

    # We need to remove the backslash characters from the
    # json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")

    $json
}

function Get-AADTenantDetail {
    <#
    .Description
    Gets the tenant details using the Microsoft Graph PowerShell Module
    .Functionality
    Internal
    #>
    $TenantInfo = @{}
    try {
        $OrgInfo = Get-MgOrganization -ErrorAction "Stop"
        $InitialDomain = $OrgInfo.VerifiedDomains | Where-Object {$_.isInitial}
        if (-not $InitialDomain) {
            $InitialDomain = "AAD: Domain Unretrievable"
        }
        $TenantInfo.DisplayName = $OrgInfo.DisplayName
        $TenantInfo.DomainName = $InitialDomain.name
        $TenantInfo.TenantId = $OrgInfo.Id
        $TenantInfo.AADAdditionalData = $OrgInfo
    }
    catch {
        $TenantInfo.DisplayName = "*Get-AADTenantDetail ERROR*"
        $TenantInfo.DisplayName = "*Get-AADTenantDetail ERROR*"
        $TenantInfo.DomainName = "*Get-AADTenantDetail ERROR*"
        $TenantInfo.TenantId = "*Get-AADTenantDetail ERROR*"
        $TenantInfo.AADAdditionalData = "*Get-AADTenantDetail ERROR*"
    }
    $TenantInfo = $TenantInfo | ConvertTo-Json -Depth 4
    $TenantInfo
}

function Get-PrivilegedUser {
    <#
    .Description
    Gets the array of the highly privileged users
    .Functionality
    Internal
    #>
    param (
        [switch]
        $TenantHasPremiumLicense
    )

    $PrivilegedUsers = @{}
    $PrivilegedRoles = @("Global Administrator", "Privileged Role Administrator", "User Administrator", "SharePoint Administrator", "Exchange Administrator", "Hybrid identity administrator", "Application Administrator", "Cloud Application Administrator")
    $AADRoles = Get-MgDirectoryRole -ErrorAction Stop | Where-Object { $_.DisplayName -in $PrivilegedRoles }

    # Process the Active role assignments
    foreach ($Role in $AADRoles) {

        $UsersAssignedRole = Get-MgDirectoryRoleMember -ErrorAction Stop -DirectoryRoleId $Role.Id

        foreach ($User in $UsersAssignedRole) {

            $Objecttype = $User.AdditionalProperties."@odata.type" -replace "#microsoft.graph."

            if ($Objecttype -eq "user") {
                $AADUser = Get-MgUser -ErrorAction Stop -UserId $User.Id

                if (-Not $PrivilegedUsers.ContainsKey($AADUser.Id)) {
                    $PrivilegedUsers[$AADUser.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                }
                $PrivilegedUsers[$AADUser.Id].roles += $Role.DisplayName
            }

            elseif ($Objecttype -eq "group") {
                $GroupMembers = Get-MgGroupMember -ErrorAction Stop -GroupId $User.Id
                foreach ($GroupMember in $GroupMembers) {
                    $Membertype = $GroupMember.AdditionalProperties."@odata.type" -replace "#microsoft.graph."
                    if ($Membertype -eq "user") {
                        $AADUser = Get-MgUser -ErrorAction Stop -UserId $GroupMember.Id

                        if (-Not $PrivilegedUsers.ContainsKey($AADUser.Id)) {
                            $PrivilegedUsers[$AADUser.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                        }
                        $PrivilegedUsers[$AADUser.Id].roles += $Role.DisplayName
                    }
                }
            }
        }
    }

    # Process the Eligible role assignments if the premium license for PIM is there
    if ($TenantHasPremiumLicense) {

        foreach ($Role in $AADRoles) {
            $PrivRoleId = $Role.RoleTemplateId
            $PIMRoleAssignments = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -ErrorAction Stop -Filter "roleDefinitionId eq '$PrivRoleId'"

            foreach ($PIMRoleAssignment in $PIMRoleAssignments) {
                $UserObjectId = $PIMRoleAssignment.PrincipalId
                try {
                    $AADUser = Get-MgUser -ErrorAction Stop -Filter "Id eq '$UserObjectId'"
                    $UserType = "user"

                    if (-Not $PrivilegedUsers.ContainsKey($AADUser.Id)) {
                        $PrivilegedUsers[$AADUser.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                    }
                    $PrivilegedUsers[$AADUser.Id].roles += $Role.DisplayName
                }
                catch {
                    $UserType = "unknown"
                }

                if ($UserType -eq "unknown") {
                    try {
                        $GroupMembers = Get-MgGroupMember -ErrorAction Stop -GroupId $UserObjectId
                        $UserType = "group"
                        foreach ($GroupMember in $GroupMembers) {
                            $Membertype = $GroupMember.AdditionalProperties."@odata.type" -replace "#microsoft.graph."
                            if ($Membertype -eq "user") {
                                $AADUser = Get-MgUser -ErrorAction Stop -UserId $GroupMember.Id
                                if (-Not $PrivilegedUsers.ContainsKey($AADUser.Id)) {
                                    $PrivilegedUsers[$AADUser.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                                }
                                $PrivilegedUsers[$AADUser.Id].roles += $Role.DisplayName
                            }
                        }
                    }
                    catch {
                        $UserType = "unknown"
                    }
                }
            }
        }
    }

    $PrivilegedUsers
}

function Get-PrivilegedRole {
    <#
    .Description
    Gets the array of the highly privileged roles along with the users assigned to the role and the security policies applied to it
    .Functionality
    Internal
    #>
    param (
        [switch]
        $TenantHasPremiumLicense
    )

    $PrivilegedRoles = @("Global Administrator", "Privileged Role Administrator", "User Administrator", "SharePoint Administrator", "Exchange Administrator", "Hybrid identity administrator", "Application Administrator", "Cloud Application Administrator")
    $AADRoles = Get-MgDirectoryRoleTemplate -ErrorAction Stop | Where-Object { $_.DisplayName -in $PrivilegedRoles } | Select-Object "DisplayName", @{Name='RoleTemplateId'; Expression={$_.Id}}

    # If the tenant has the premium license then you can access the PIM service to get the role configuration policies and the eligible / active role assigments
    if ($TenantHasPremiumLicense) {
        $RolePolicyAssignments = Get-MgPolicyRoleManagementPolicyAssignment -ErrorAction Stop -Filter "scopeId eq '/' and scopeType eq 'Directory'"

        # Create an array of the highly privileged roles along with the users assigned to the role and the security policies applied to it

        foreach ($Role in $AADRoles) {
            $RolePolicies = @()
            $RoleTemplateId = $Role.RoleTemplateId

            # Get role policy assignments
            # Note: Each role can only be assigned a single policy at most
            $PolicyAssignment = $RolePolicyAssignments | Where-Object -Property RoleDefinitionId -eq -Value $RoleTemplateId
            $RoleAssignments = @(Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -ErrorAction Stop -Filter "roleDefinitionId eq '$RoleTemplateId'")

            # Append each policy assignment to the role object
            if ($PolicyAssignment.length -eq 1) {
                $RolePolicies = Get-MgPolicyRoleManagementPolicyRule -ErrorAction Stop -UnifiedRoleManagementPolicyId $PolicyAssignment.PolicyId
            }
            elseif ($PolicyAssignment.length -gt 1) {
                $RolePolicies = "Too many policies found"
            }
            else {
                $RolePolicies = "No policies found"
            }

            $Role | Add-Member -Name "Rules" -Value $RolePolicies -MemberType NoteProperty
            $Role | Add-Member -Name "Assignments" -Value $RoleAssignments -MemberType NoteProperty
        }
    }

    $AADRoles
}
