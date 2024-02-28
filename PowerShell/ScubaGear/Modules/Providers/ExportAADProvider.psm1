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
    # - 1.1
    # - 2.1
    # - 3.1
    # - 4.2
    # - 3.7
    $AllPolicies = $Tracker.TryCommand("Get-MgBetaIdentityConditionalAccessPolicy")

    Import-Module $PSScriptRoot/ProviderHelpers/AADConditionalAccessHelper.psm1
    $CapHelper = Get-CapTracker
    $CapTableData = $CapHelper.ExportCapPolicies($AllPolicies) # pre-processed version of the CAPs used in generating
    # the CAP html in the report

    if ($CapTableData -eq "") {
        # Quick sanity check, did ExportCapPolicies return something?
        Write-Warning "Error parsing CAP data, empty json returned from ExportCapPolicies."
        $CapTableData = "[]"
    }
    try {
        # Final sanity check, did ExportCapPolicies return valid json?
        ConvertFrom-Json $CapTableData -ErrorAction "Stop" | Out-Null
    }
    catch {
        Write-Warning "Error parsing CAP data, invalid json returned from ExportCapPolicies."
        $CapTableData = "[]"
    }

    $AllPolicies = ConvertTo-Json -Depth 10 @($AllPolicies)

    # Get a list of the tenant's provisioned service plans - used to see if the tenant has AAD premium p2 license required for some checks
    # The Rego looks at the service_plans in the JSON
    $ServicePlans = $Tracker.TryCommand("Get-MgBetaSubscribedSku").ServicePlans | Where-Object -Property ProvisioningStatus -eq -Value "Success"

    if ($ServicePlans) {
        # The RequiredServicePlan variable is used so that PIM Cmdlets are only executed if the tenant has the premium license
        $RequiredServicePlan = $ServicePlans | Where-Object -Property ServicePlanName -eq -Value "AAD_PREMIUM_P2"

        # Get-PrivilegedUser provides a list of privileged users and their role assignments. Used for 2.11 and 2.12
        if ($RequiredServicePlan) {
            # If the tenant has the premium license then we want to also include PIM Eligible role assignments - otherwise we don't to avoid an API error
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

        # Get-PrivilegedRole provides a list of privileged roles referenced in 2.13 when checking if MFA is required for those roles
        # Get-PrivilegedRole provides data for 2.14 - 2.16, policies that evaluate conditions related to Azure AD PIM
        if ($RequiredServicePlan){
            # If the tenant has the premium license then we want to also include PIM Eligible role assignments - otherwise we don't to avoid an API error
            $PrivilegedRoles = $Tracker.TryCommand("Get-PrivilegedRole", @{"TenantHasPremiumLicense"=$true})
        }
        else {
            $PrivilegedRoles = $Tracker.TryCommand("Get-PrivilegedRole")
        }
        $PrivilegedRoles = ConvertTo-Json -Depth 10 @($PrivilegedRoles) # Depth required to get policy rule object details
    }
    else {
        Write-Warning "Omitting calls to Get-PrivilegedRole and Get-PrivilegedUser."
        $PrivilegedUsers = ConvertTo-Json @()
        $PrivilegedRoles = ConvertTo-Json @()
        $Tracker.AddUnSuccessfulCommand("Get-PrivilegedRole")
        $Tracker.AddUnSuccessfulCommand("Get-PrivilegedUser")
    }
    $ServicePlans = ConvertTo-Json -Depth 3 @($ServicePlans)

    #Obtains license information for tenant and total number of active users
    $LicenseInfo = $Tracker.TryCommand("Get-MgBetaSubscribedSku") | Select-Object -Property Sku*, ConsumedUnits, PrepaidUnits | ConvertTo-Json -Depth 3

    # Checking to ensure command runs successfully
    $UserCount = $Tracker.TryCommand("Get-MgBetaUserCount", @{"ConsistencyLevel"='eventual'})

    if(-Not $UserCount -is [int]) {
        $UserCount = "NaN"
    }

    # 5.1, 5.2, 8.1 & 8.3
    $AuthZPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaPolicyAuthorizationPolicy"))

    # 5.3, 5.4
    $DirectorySettings = ConvertTo-Json -Depth 10 @($Tracker.TryCommand("Get-MgBetaDirectorySetting"))

    # Read the properties and relationships of an authentication method policy
    $AuthenticationMethodPolicy = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaPolicyAuthenticationMethodPolicy")) -Depth 5

    # 6.1
    $DomainSettings = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaDomain"))

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "conditional_access_policies": $AllPolicies,
    "cap_table_data": $CapTableData,
    "authorization_policies": $AuthZPolicies,
    "privileged_users": $PrivilegedUsers,
    "privileged_roles": $PrivilegedRoles,
    "service_plans": $ServicePlans,
    "directory_settings": $DirectorySettings,
    "authentication_method": $AuthenticationMethodPolicy,
    "domain_settings": $DomainSettings,
    "license_information": $LicenseInfo,
    "total_user_count": $UserCount,
    "aad_successful_commands": $SuccessfulCommands,
    "aad_unsuccessful_commands": $UnSuccessfulCommands,
"@

    $json
}

function Get-AADTenantDetail {
    <#
    .Description
    Gets the tenant details using the Microsoft Graph PowerShell Module
    .Functionality
    Internal
    #>
    try {
        $OrgInfo = Get-MgBetaOrganization -ErrorAction "Stop"
        $InitialDomain = $OrgInfo.VerifiedDomains | Where-Object {$_.isInitial}
        if (-not $InitialDomain) {
            $InitialDomain = "AAD: Domain Unretrievable"
        }
        $AADTenantInfo = @{
            "DisplayName" = $OrgInfo.DisplayName;
            "DomainName" = $InitialDomain.Name;
            "TenantId" = $OrgInfo.Id;
            "AADAdditionalData" = $OrgInfo;
        }
        $AADTenantInfo = ConvertTo-Json @($AADTenantInfo) -Depth 4
        $AADTenantInfo
    }
    catch {
        Write-Warning "Error retrieving Tenant details using Get-AADTenantDetail $($_)"
        $AADTenantInfo = @{
            "DisplayName" = "Error retrieving Display name";
            "DomainName" = "Error retrieving Domain name";
            "TenantId" = "Error retrieving Tenant ID";
            "AADAdditionalData" = "Error retrieving additional data";
        }
        $AADTenantInfo = ConvertTo-Json @($AADTenantInfo) -Depth 4
        $AADTenantInfo
    }
}

function Get-PrivilegedUser {
    <#
    .Description
    Gets the array of the highly privileged users
    .Functionality
    Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [switch]
        $TenantHasPremiumLicense
    )

    $PrivilegedUsers = @{}
    $PrivilegedRoles = [ScubaConfig]::ScubaDefault('DefaultPrivilegedRoles')
    # Get a list of the Id values for the privileged roles in the list above.
    # The Id value is passed to other cmdlets to construct a list of users assigned to privileged roles.
    $AADRoles = Get-MgBetaDirectoryRole -All -ErrorAction Stop | Where-Object { $_.DisplayName -in $PrivilegedRoles }

    # Construct a list of privileged users based on the Active role assignments
    foreach ($Role in $AADRoles) {

        # Get a list of all the users and groups Actively assigned to this role
        $UsersAssignedRole = Get-MgBetaDirectoryRoleMember -All -ErrorAction Stop -DirectoryRoleId $Role.Id

        foreach ($User in $UsersAssignedRole) {

            $Objecttype = $User.AdditionalProperties."@odata.type" -replace "#microsoft.graph."

            if ($Objecttype -eq "user") {
                # If the user's data has not been fetched from graph, go get it
                if (-Not $PrivilegedUsers.ContainsKey($User.Id)) {
                    $AADUser = Get-MgBetaUser -ErrorAction Stop -UserId $User.Id
                    $PrivilegedUsers[$AADUser.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                }
                # If the current role has not already been added to the user's roles array then add the role
                if ($PrivilegedUsers[$User.Id].roles -notcontains $Role.DisplayName) {
                    $PrivilegedUsers[$User.Id].roles += $Role.DisplayName
                }
            }

            elseif ($Objecttype -eq "group") {
                # In this context $User.Id is a group identifier
                $GroupId = $User.Id
                # Get all of the group members that are Active assigned to the current role
                $GroupMembers = Get-MgBetaGroupMember -All -ErrorAction Stop -GroupId $GroupId

                foreach ($GroupMember in $GroupMembers) {
                    $Membertype = $GroupMember.AdditionalProperties."@odata.type" -replace "#microsoft.graph."
                    if ($Membertype -eq "user") {
                        # If the user's data has not been fetched from graph, go get it
                        if (-Not $PrivilegedUsers.ContainsKey($GroupMember.Id)) {
                            $AADUser = Get-MgBetaUser -ErrorAction Stop -UserId $GroupMember.Id
                            $PrivilegedUsers[$AADUser.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                        }
                        # If the current role has not already been added to the user's roles array then add the role
                        if ($PrivilegedUsers[$GroupMember.Id].roles -notcontains $Role.DisplayName) {
                            $PrivilegedUsers[$GroupMember.Id].roles += $Role.DisplayName
                        }
                    }
                }

                # If the premium license for PIM is there, process the users that are "member" of the PIM group as Eligible
                if ($TenantHasPremiumLicense) {
                    # Get the users that are assigned to the PIM group as Eligible members
                    $PIMGroupMembers = Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance -All -ErrorAction Stop -Filter "groupId eq '$GroupId'"
                    foreach ($GroupMember in $PIMGroupMembers) {
                        # If the user is not a member of the PIM group (i.e. they are an owner) then skip them
                        if ($GroupMember.AccessId -ne "member") { continue }
                        $PIMEligibleUserId = $GroupMember.PrincipalId

                        # If the user's data has not been fetched from graph, go get it
                        if (-not $PrivilegedUsers.ContainsKey($PIMEligibleUserId)) {
                            $AADUser = Get-MgBetaUser -ErrorAction Stop -UserId $PIMEligibleUserId
                            $PrivilegedUsers[$PIMEligibleUserId] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                        }
                        # If the current role has not already been added to the user's roles array then add the role
                        if ($PrivilegedUsers[$PIMEligibleUserId].roles -notcontains $Role.DisplayName) {
                            $PrivilegedUsers[$PIMEligibleUserId].roles += $Role.DisplayName
                        }
                    }
                }
            }
        }
    }

    # Process the Eligible role assignments if the premium license for PIM is there
    if ($TenantHasPremiumLicense) {
        # Get a list of all the users and groups that have Eligible assignments
        $AllPIMRoleAssignments = Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance -All -ErrorAction Stop

        # Add to the list of privileged users based on Eligible assignments
        foreach ($Role in $AADRoles) {
            $PrivRoleId = $Role.RoleTemplateId
            # Get a list of all the users and groups Eligible assigned to this role
            $PIMRoleAssignments = $AllPIMRoleAssignments | Where-Object { $_.RoleDefinitionId -eq $PrivRoleId }

            foreach ($PIMRoleAssignment in $PIMRoleAssignments) {
                $UserObjectId = $PIMRoleAssignment.PrincipalId
                try {
                    $UserType = "user"

                    # If the user's data has not been fetched from graph, go get it
                    if (-Not $PrivilegedUsers.ContainsKey($UserObjectId)) {
                        $AADUser = Get-MgBetaUser -ErrorAction Stop -Filter "Id eq '$UserObjectId'"
                        $PrivilegedUsers[$AADUser.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                    }
                    # If the current role has not already been added to the user's roles array then add the role
                    if ($PrivilegedUsers[$UserObjectId].roles -notcontains $Role.DisplayName) {
                        $PrivilegedUsers[$UserObjectId].roles += $Role.DisplayName
                    }
                }
                # Catch the specific error which indicates Get-MgBetaUser does not find the user, therefore it is a group
                catch {
                    if ($_.FullyQualifiedErrorId.Contains("Request_ResourceNotFound")) {
                        $UserType = "group"
                    }
                    else {
                        throw $_
                    }
                }

                # This if statement handles when the object eligible assigned to the current role is a Group
                if ($UserType -eq "group") {
                    # Process the the users that are directly assigned to the group (not through PIM groups)
                    $GroupMembers = Get-MgBetaGroupMember -All -ErrorAction Stop -GroupId $UserObjectId
                    foreach ($GroupMember in $GroupMembers) {
                        $Membertype = $GroupMember.AdditionalProperties."@odata.type" -replace "#microsoft.graph."
                        if ($Membertype -eq "user") {
                            # If the user's data has not been fetched from graph, go get it
                            if (-Not $PrivilegedUsers.ContainsKey($GroupMember.Id)) {
                                $AADUser = Get-MgBetaUser -ErrorAction Stop -UserId $GroupMember.Id
                                $PrivilegedUsers[$AADUser.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                            }
                            # If the current role has not already been added to the user's roles array then add the role
                            if ($PrivilegedUsers[$GroupMember.Id].roles -notcontains $Role.DisplayName) {
                                $PrivilegedUsers[$GroupMember.Id].roles += $Role.DisplayName
                            }
                        }
                    }

                    # Get the users that are assigned to the PIM group as Eligible members
                    $PIMGroupMembers = Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance -All -ErrorAction Stop -Filter "groupId eq '$UserObjectId'"
                    foreach ($GroupMember in $PIMGroupMembers) {
                        # If the user is not a member of the PIM group (i.e. they are an owner) then skip them
                        if ($GroupMember.AccessId -ne "member") { continue }
                        $PIMEligibleUserId = $GroupMember.PrincipalId

                        # If the user's data has not been fetched from graph, go get it
                        if (-not $PrivilegedUsers.ContainsKey($PIMEligibleUserId)) {
                            $AADUser = Get-MgBetaUser -ErrorAction Stop -UserId $PIMEligibleUserId
                            $PrivilegedUsers[$PIMEligibleUserId] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                        }
                        # If the current role has not already been added to the user's roles array then add the role
                        if ($PrivilegedUsers[$PIMEligibleUserId].roles -notcontains $Role.DisplayName) {
                            $PrivilegedUsers[$PIMEligibleUserId].roles += $Role.DisplayName
                        }
                    }
                }
            }
        }
    }

    $PrivilegedUsers
}

function AddRuleSource{
    <#
        .NOTES
        Internal helper function to add a source to policy rule for reporting purposes.
        Source should be either PIM Group Name or Role Name
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Source,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceType = "Directory Role",

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [array]
        $Rules
    )

    foreach ($Rule in $Rules){
        $Rule | Add-Member -Name "RuleSource" -Value $Source -MemberType NoteProperty
        $Rule | Add-Member -Name "RuleSourceType" -Value $SourceType -MemberType NoteProperty
    }
}

function FindRulesForPimGroupsRoles{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [array]
        $AADRoles,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [array]
        $AllRoleAssignments
    )

    foreach ($RoleAssignment in $AllRoleAssignments){

        # AllRoleAssignments contain non-privileged roles as well. Check if this is a privileged role
        $Role = $AADRoles | Where-Object RoleTemplateId -EQ $($RoleAssignment.RoleDefinitionId)

        if ($Role){

            $PrincipalId = $RoleAssignment.PrincipalId

            # Need a way to determine if regular or PIM group.
            ($GroupEligibilitySchedule = Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilitySchedule -Filter "groupId eq '$PrincipalId'") *> $null
            if ($GroupEligibilitySchedule.Count -eq 0){
                continue
            }

            # Get policy assignments to member (not owner) role in PIM Group
            ($MemberPolicyIds = Get-MgBetaPolicyRoleManagementPolicyAssignment -Filter "scopeId eq '$PrincipalId' and scopeType eq 'Group' and roleDefinitionId eq 'member'" |
                Select-Object -Property PolicyId) *> $null

            foreach ($MemberPolicyId in $MemberPolicyIds){

                $MemberPolicyRules = Get-MgBetaPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $MemberPolicyId.PolicyId -All
                $SourceGroup = Get-MgBetaGroup -Filter "id eq '$PrincipalId' " | Select-Object -Property DisplayName
                AddRuleSource -Source $SourceGroup.DisplayName -SourceType "PIM Group" -Rules $MemberPolicyRules

                if ($Role){
                    $RoleRules = $Role.psobject.Properties | Where-Object {$_.Name -eq 'Rules'}
                    if ($RoleRules){
                        # Appending rules 
                        $Role.Rules += $MemberPolicyRules
                    }
                    else {
                        # Adding rules
                        $Role | Add-Member -Name "Rules" -Value $MemberPolicyRules -MemberType NoteProperty
                    }
                }
            }
        }
    }
}

function FindRulesForRoles{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [array]
        $AADRoles,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [array]
        $AllRoleAssignments
    )

    # Get all the roles and policies (rules) assigned to them
    $RolePolicyAssignments = Get-MgBetaPolicyRoleManagementPolicyAssignment -All -ErrorAction Stop -Filter "scopeId eq '/' and scopeType eq 'Directory'"

    foreach ($Role in $AADRoles) {
        $RolePolicies = @()
        $RoleTemplateId = $Role.RoleTemplateId

        # Get a list of the rules (aka policies) assigned to this role
        $PolicyAssignment = $RolePolicyAssignments | Where-Object -Property RoleDefinitionId -eq -Value $RoleTemplateId

        # Get the details of policy (rule)
        if ($PolicyAssignment.length -eq 1) {
            $RolePolicies = Get-MgBetaPolicyRoleManagementPolicyRule -All -ErrorAction Stop -UnifiedRoleManagementPolicyId $PolicyAssignment.PolicyId
        }
        elseif ($PolicyAssignment.length -gt 1) {
            $RolePolicies = "Too many policies found"
        }
        else {
            $RolePolicies = "No policies found"
        }

        # Get a list of the users / groups assigned to this role
        $RoleAssignments = @($AllRoleAssignments | Where-Object { $_.RoleDefinitionId -eq $RoleTemplateId })

        # Store the data that we retrieved in the Role object that will be returned from this function
        $Role | Add-Member -Name "Assignments" -Value $RoleAssignments -MemberType NoteProperty

        $RoleRules = $Role.psobject.Properties | Where-Object {$_.Name -eq 'Rules'}
        AddRuleSource -Source $Role.DisplayName  -SourceType "Directory Role" -Rules $RolePolicies

        if ($RoleRules){
            $Role.Rules += $RolePolicies
        }
        else {
            $Role | Add-Member -Name "Rules" -Value $RolePolicies -MemberType NoteProperty
        }
    }
}
function Get-PrivilegedRole {
    <#
    .Description
    Creates an array of the highly privileged roles along with the users assigned to the role and the security policies (aka rules) applied to it
    .Functionality
    Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [switch]
        $TenantHasPremiumLicense
    )

    $PrivilegedRoles = [ScubaConfig]::ScubaDefault('DefaultPrivilegedRoles')
    # Get a list of the RoleTemplateId values for the privileged roles in the list above.
    # The RoleTemplateId value is passed to other cmdlets to retrieve role security policies and user assignments.
    $AADRoles = Get-MgBetaDirectoryRoleTemplate -All -ErrorAction Stop | Where-Object { $_.DisplayName -in $PrivilegedRoles } | Select-Object "DisplayName", @{Name='RoleTemplateId'; Expression={$_.Id}}
    # Get ALL the roles and users actively assigned to them
    $AllRoleAssignments = Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance -All -ErrorAction Stop

    # If the tenant has the premium license then you can access the PIM service to get the role configuration policies and the active role assigments
    if ($TenantHasPremiumLicense) {
        FindRulesForRoles -AADRoles $AADRoles -AllRoleAssignments $AllRoleAssignments
        FindRulesForPimGroupsRoles -AADRoles $AADRoles -AllRoleAssignments $AllRoleAssignments
    }

    $AADRoles
}

