# Many of the commandlets can be replaced with direct API access, but we are starting the transition with the ones
# below because they have slow imports that affect performance more than the others. Some commandlets are fast
# and there is no obvoius performance advantage to using the API beyond maybe batching.
$GraphEndpoints = @{
    "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" = "/beta/roleManagement/directory/roleEligibilityScheduleInstances"
    "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" = "/beta/roleManagement/directory/roleAssignmentScheduleInstances"
    "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" = "/beta/identityGovernance/privilegedAccess/group/eligibilityScheduleInstances"
    "Get-MgBetaPrivilegedAccessResource" = "/beta/privilegedAccess/aadGroups/resources"
}

function Invoke-GraphDirectly {
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $commandlet,

        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [System.Collections.Hashtable]
        $queryParams
    )

    Write-Debug "Replacing Cmdlet: $commandlet"
    try {
        $endpoint = $GraphEndpoints[$commandlet]
    } catch {
        Write-Error "The commandlet $commandlet can't be used with the Invoke-GraphDirectly function yet."
    }

    if ($M365Environment -eq "gcchigh") {
        $endpoint = "https://graph.microsoft.us" + $endpoint
    }
    elseif ($M365Environment -eq "dod") {
        $endpoint = "https://dod-graph.microsoft.us" + $endpoint
    }
    else {
        $endpoint = "https://graph.microsoft.com" + $endpoint
    }

    if ($queryParams) {
        # If query params are passed in, we augment the endpoint URI to include the params.
        $q = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)
        foreach ($item in $queryParams.GetEnumerator()) {
            $q.Add($item.Key, $item.Value)
        }
        $uri = [System.UriBuilder]::new("", "", 443, $endpoint)
        $uri.Query = $q.ToString()
        $endpoint = $uri.ToString()
    }
    Write-Debug "Graph Api direct: $endpoint"

    $resp = Invoke-MgGraphRequest -ErrorAction Stop -Uri $endpoint
    return $resp.Value
}

function Export-AADProvider {
    <#
    .Description
    Gets the Azure Active Directory (AAD) settings that are relevant
    to the SCuBA AAD baselines using a subset of the modules under the
    overall Microsoft Graph PowerShell Module
    .Functionality
    Internal
    #>

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    Import-Module $PSScriptRoot/ProviderHelpers/CommandTracker.psm1
    $Tracker = Get-CommandTracker

    # The below cmdlet covers ~ 8 policy checks that inspect conditional access policies
    $AllPolicies = $Tracker.TryCommand("Get-MgBetaIdentityConditionalAccessPolicy")

    Import-Module $PSScriptRoot/ProviderHelpers/AADConditionalAccessHelper.psm1
    $CapHelper = Get-CapTracker
    $CapTableData = $CapHelper.ExportCapPolicies($AllPolicies) # Used in generating the CAP html in the report

    if ($CapTableData -eq "") {
        # Sanity check, did ExportCapPolicies return something?
        Write-Warning "Error parsing CAP data, empty json returned from ExportCapPolicies."
        $CapTableData = "[]"
    }
    try {
        # Final sanity check, did ExportCapPolicies return valid json?
        ConvertFrom-Json $CapTableData -ErrorAction "Stop" | Out-Null
    }
    catch {
        # Display error message but do not stop execution
        Write-Warning "ConvertFrom-Json failed to parse CAP data received from ExportCapPolicies: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
        $CapTableData = "[]"
    }

    $AllPolicies = ConvertTo-Json -Depth 10 @($AllPolicies)

    $SubscribedSku = $Tracker.TryCommand("Get-MgBetaSubscribedSku")

    # Get a list of the tenant's provisioned service plans - used to see if the tenant has AAD premium p2 license required for some checks
    # The Rego looks at the service_plans in the JSON
    $ServicePlans = $SubscribedSku.ServicePlans | Where-Object -Property ProvisioningStatus -eq -Value "Success"

    #Obtains license information for tenant and total number of active users
    $LicenseInfo = $SubscribedSku | Select-Object -Property Sku*, ConsumedUnits, PrepaidUnits | ConvertTo-Json -Depth 3

    if ($ServicePlans) {
        # The RequiredServicePlan variable is used so that PIM Cmdlets are only executed if the tenant has the premium license
        $RequiredServicePlan = $ServicePlans | Where-Object -Property ServicePlanName -eq -Value "AAD_PREMIUM_P2"

        # Get-PrivilegedUser provides a list of privileged users and their role assignments.
        if ($RequiredServicePlan) {
            # If the tenant has the premium license then we also include calls to PIM APIs
            $PrivilegedUsers = $Tracker.TryCommand("Get-PrivilegedUser", @{"TenantHasPremiumLicense"=$true; "M365Environment"=$M365Environment})
        }
        else{
            $PrivilegedUsers = $Tracker.TryCommand("Get-PrivilegedUser", @{"TenantHasPremiumLicense"=$false; "M365Environment"=$M365Environment})
        }
        # The Converto-Json call below doesn't need to have the input wrapped in an
        # array (e.g, "ConvertTo-Json (@PrivilegedUsers)") because $PrivilegedUsers is
        # a dictionary, not an array, and ConvertTo-Json doesn't mess up dictionaries like it does arrays
        $PrivilegedUsers = $PrivilegedUsers | ConvertTo-Json
        # While ConvertTo-Json won't mess up a dict as described in the above comment,
        # on error, $TryCommand returns an empty list, not a dictionary.
        $PrivilegedUsers = if ($null -eq $PrivilegedUsers) {"{}"} else {$PrivilegedUsers}

        # Get-PrivilegedRole provides a list of security configurations for each privileged role and information about Active user assignments
        if ($RequiredServicePlan){
            # If the tenant has the premium license then we also include calls to PIM APIs
            $PrivilegedRoles = $Tracker.TryCommand("Get-PrivilegedRole", @{"TenantHasPremiumLicense"=$true; "M365Environment"=$M365Environment})
        }
        else {
            $PrivilegedRoles = $Tracker.TryCommand("Get-PrivilegedRole", @{"TenantHasPremiumLicense"=$false; "M365Environment"=$M365Environment})
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

    $UserCount = $Tracker.TryCommand("Get-MgBetaUserCount", @{"ConsistencyLevel"='eventual'})
    # Ensure we successfully got a count of users
    if(-Not $UserCount -is [int]) {
        $UserCount = "NaN"
    }

    # Provides data for policies such as user consent and guest user access
    $AuthZPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaPolicyAuthorizationPolicy"))

    # Provides data for admin consent workflow
    $DirectorySettings = ConvertTo-Json -Depth 10 @($Tracker.TryCommand("Get-MgBetaDirectorySetting"))

    ##### This block supports policies that need data on the tenant's authentication methods
    $AuthenticationMethodPolicyRootObject = $Tracker.TryCommand("Get-MgBetaPolicyAuthenticationMethodPolicy")

    $AuthenticationMethodFeatureSettings = @($AuthenticationMethodPolicyRootObject.AuthenticationMethodConfigurations | Where-Object { $_.Id})

    # Exclude the AuthenticationMethodConfigurations so we do not duplicate it in the JSON
    $AuthenticationMethodPolicy = $AuthenticationMethodPolicyRootObject | ForEach-Object {
        $_ | Select-Object * -ExcludeProperty AuthenticationMethodConfigurations
    }

    $AuthenticationMethodObjects = @{
        authentication_method_policy = $AuthenticationMethodPolicy
        authentication_method_feature_settings = $AuthenticationMethodFeatureSettings
    }

    $AuthenticationMethod = ConvertTo-Json -Depth 10 @($AuthenticationMethodObjects)
    ##### End block

    # Provides data on the password expiration policy
    $DomainSettings = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaDomain"))

    ##### This block gathers information on application/service principal API permissions

    ##### End block

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
    "authentication_method": $AuthenticationMethod,
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
        Write-Warning "Error retrieving Tenant details using Get-AADTenantDetail: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
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
    Returns a hashtable of privileged users and their respective roles
    .Functionality
    Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [bool]
        $TenantHasPremiumLicense,

        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    # A hashtable of privileged users
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
                LoadObjectDataIntoPrivilegedUserHashtable -RoleName $Role.DisplayName -PrivilegedUsers $PrivilegedUsers -ObjectId $User.Id -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment -Objecttype "user"
            }
            elseif ($Objecttype -eq "group") {
                # In this context $User.Id is a group identifier
                $GroupId = $User.Id

                # Process all of the group members that are transitively assigned to the current role as Active via group membership
                LoadObjectDataIntoPrivilegedUserHashtable -RoleName $Role.DisplayName -PrivilegedUsers $PrivilegedUsers -ObjectId $GroupId -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment -Objecttype "group"
            }
        }
    }

    # Process the Eligible role assignments if the premium license for PIM is there
    if ($TenantHasPremiumLicense) {
        # Get a list of all the users and groups that have Eligible assignments
        $graphArgs = @{
            "commandlet" = "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance"
            "M365Environment" = $M365Environment }
        $AllPIMRoleAssignments = Invoke-GraphDirectly @graphArgs

        # Add to the list of privileged users based on Eligible assignments
        foreach ($Role in $AADRoles) {
            $PrivRoleId = $Role.RoleTemplateId
            # Get a list of all the users and groups Eligible assigned to this role
            $PIMRoleAssignments = $AllPIMRoleAssignments | Where-Object { $_.RoleDefinitionId -eq $PrivRoleId }

            foreach ($PIMRoleAssignment in $PIMRoleAssignments) {
                $UserObjectId = $PIMRoleAssignment.PrincipalId
                LoadObjectDataIntoPrivilegedUserHashtable -RoleName $Role.DisplayName -PrivilegedUsers $PrivilegedUsers -ObjectId $UserObjectId -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment
            }
        }
    }

    $PrivilegedUsers
}

function LoadObjectDataIntoPrivilegedUserHashtable {
    <#
    .Description
    Takes an object Id (either a user or group) and loads metadata about the object in the provided privileged user hashtable.
    If the object is a group, this function will iterate the group members and load metadata about each member.
    .Functionality
    Internal
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$RoleName,

        [Parameter(Mandatory=$true)]
        [hashtable]$PrivilegedUsers,

        # The Entra Id unique identifiter for an object (either a user or a group) in the directory.
        # Metadata about this object will be loaded into the PrivilegedUsers hashtable which is passed as a parameter.
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ObjectId,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [bool]$TenantHasPremiumLicense,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$M365Environment,

        # This describes the type of Entra Id object that the parameter ObjectId is referencing.
        # Valid values are "user", "group". If this is not passed, the function will call Graph to dynamically determine the object type.
        [Parameter()]
        [string]$Objecttype = "",

        [Parameter()]
        [int]$Recursioncount = 0
    )
    # Write-Warning "Recursion level: $recursioncount"

    # We support group nesting up to 2 levels deep (stops after processing levels 0 and 1).
    # Safeguard: Also protects against infinite loops if there is a circular group assignment in PIM.
    if ($recursioncount -ge 2) {
        return
    }

    # If the object type was not supplied we need to determine whether it is a user or a group.
    if ($Objecttype -eq "") {
        try {
            $DirectoryObject = Get-MgBetaDirectoryObject -ErrorAction Stop -DirectoryObjectId $ObjectId
        } catch {
            # If the object was probably recently deleted from the directory we ignore it. Otherwise an unhandled 404 causes the tool to crash.
            if ($_.Exception.Message -match "Request_ResourceNotFound") {
                Write-Warning "Processing privileged users. Resource $ObjectId may have been recently deleted from the directory because it was not found."
                return  # Exit the function to ignore this resource and keep the flow going.
            }
            # If it is a different error, rethrow the error to let the calling function handle it.
            else {
                throw $_
            }
        }

        # Extract what type of object this is.
        $Objecttype = $DirectoryObject.AdditionalProperties."@odata.type" -replace "#microsoft.graph."
    }

    if ($Objecttype -eq "user") {
        # If the user's data has not been fetched from graph, go get it and add it to the hashtable
        if (-Not $PrivilegedUsers.ContainsKey($ObjectId)) {
            $AADUser = Get-MgBetaUser -ErrorAction Stop -UserId $ObjectId
            $PrivilegedUsers[$ObjectId] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
            # Write-Warning "Processing role: $($RoleName) User: $($AADUser.DisplayName)"
        }
        # If the current role has not already been added to the user's roles array then add the role
        if ($PrivilegedUsers[$ObjectId].roles -notcontains $RoleName) {
            $PrivilegedUsers[$ObjectId].roles += $RoleName
        }
    }

    elseif ($Objecttype -eq "group") {
        # In this context $ObjectId is a group identifier so we need to iterate the group members
        $GroupId = $ObjectId
        # Get all of the group members that are transitively assigned to the current role via group membership
        $GroupMembers = Get-MgBetaGroupMember -All -ErrorAction Stop -GroupId $GroupId
        # Write-Warning "Processing role: $($RoleName) Group: $($GroupId)"

        foreach ($GroupMember in $GroupMembers) {
            $Membertype = $GroupMember.AdditionalProperties."@odata.type" -replace "#microsoft.graph."
            if ($Membertype -eq "user") {
                # If the user's data has not been fetched from graph, go get it and add it to the hashtable
                if (-Not $PrivilegedUsers.ContainsKey($GroupMember.Id)) {
                    $AADUser = Get-MgBetaUser -ErrorAction Stop -UserId $GroupMember.Id
                    $PrivilegedUsers[$GroupMember.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                }
                # If the current role has not already been added to the user's roles array then add the role
                if ($PrivilegedUsers[$GroupMember.Id].roles -notcontains $RoleName) {
                    $PrivilegedUsers[$GroupMember.Id].roles += $RoleName
                }
            }
        }

        # Since this is a group, we need to also process assignments in PIM in case it is in PIM for Groups
        # If the premium license for PIM is there, process the users that are "member" of the PIM group as Eligible
        if ($TenantHasPremiumLicense) {
            # Get the users that are assigned to the PIM group as Eligible members
            $graphArgs = @{
                "commandlet" = "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance"
                "queryParams" = @{'$filter' = "groupId eq '$GroupId'"}
                "M365Environment" = $M365Environment }
            $PIMGroupMembers = Invoke-GraphDirectly @graphArgs
            foreach ($GroupMember in $PIMGroupMembers) {
                # Write-Warning "Processing role: $($RoleName) PIM group Eligible member: $($GroupMember.PrincipalId)"

                # If the user is not a member of the PIM group (i.e. they are an owner) then skip them
                if ($GroupMember.AccessId -ne "member") { continue }
                $PIMEligibleUserId = $GroupMember.PrincipalId

                # Recursively call this function to process the group member that was found
                $LoopIterationRecursioncount = $Recursioncount + 1
                LoadObjectDataIntoPrivilegedUserHashtable -RoleName $RoleName -PrivilegedUsers $PrivilegedUsers -ObjectId $PIMEligibleUserId -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment -Recursioncount $LoopIterationRecursioncount
            }
        }
    }

}

function AddRuleSource{
    <#
        .NOTES
        Internal helper function to add a source to policy rule for reporting purposes.
        Source should be either PIM Group Name or Role Name
    #>
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $Source,

        [ValidateNotNullOrEmpty()]
        [string]
        $SourceType = "Directory Role",

        [ValidateNotNullOrEmpty()]
        [array]
        $Rules
    )

    foreach ($Rule in $Rules){
        $Rule | Add-Member -Name "RuleSource" -Value $Source -MemberType NoteProperty
        $Rule | Add-Member -Name "RuleSourceType" -Value $SourceType -MemberType NoteProperty
    }
}

# This cache keeps track of PIM groups that we've already processed
class GroupTypeCache{
    static [hashtable]$CheckedGroups = @{}
}

function GetConfigurationsForPimGroups{
    param (
        [ValidateNotNullOrEmpty()]
        [array]
        $PrivilegedRoleArray,

        [ValidateNotNullOrEmpty()]
        [array]
        $AllRoleAssignments,

        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    # Get a list of the groups that are enrolled in PIM - we want to ignore the others
    $graphArgs = @{
        "commandlet" = "Get-MgBetaPrivilegedAccessResource"
        "queryParams" = @{'$PrivilegedAccessId' = "aadGroups"}
        "M365Environment" = $M365Environment }
    $PIMGroups = Invoke-GraphDirectly @graphArgs

    foreach ($RoleAssignment in $AllRoleAssignments){

        # Check if the assignment in current loop iteration is assigned to a privileged role
        $Role = $PrivilegedRoleArray | Where-Object RoleTemplateId -EQ $($RoleAssignment.RoleDefinitionId)

        # If this is a privileged role
        if ($Role){
            # Store the Id of the object assigned to the role (could be user,group,service principal)
            $PrincipalId = $RoleAssignment.PrincipalId

            # If the current object is not a PIM group we skip it
            $FoundPIMGroup = $PIMGroups | Where-Object { $_.Id -eq $PrincipalId }
            if ($null -eq $FoundPIMGroup) {
                continue
            }

            # If we haven't processed the current group before, add it to the cache and proceed
            If ($null -eq [GroupTypeCache]::CheckedGroups[$PrincipalId]){
                [GroupTypeCache]::CheckedGroups.Add($PrincipalId, $true)
            }
            # If we have processed it before, then skip it to avoid unnecessary cycles
            else {
                continue
            }

            # Get all the configuration rules for the current PIM group - get member not owner configs
            $PolicyAssignment = Get-MgBetaPolicyRoleManagementPolicyAssignment -All -ErrorAction Stop -Filter "scopeId eq '$PrincipalId' and scopeType eq 'Group' and roleDefinitionId eq 'member'" |
                Select-Object -Property PolicyId

            # Add each configuration rule to the array. There are usually about 17 configurations for a group.
            # Get the detailed configuration settings
            $MemberPolicyRules = Get-MgBetaPolicyRoleManagementPolicyRule -All -ErrorAction Stop -UnifiedRoleManagementPolicyId $PolicyAssignment.PolicyId
            # Filter for the PIM group so we can grab its name
            $PIMGroup = $PIMGroups | Where-Object {$_.Id -eq $PrincipalId}
            # $SourceGroup = Get-MgBetaGroup -Filter "id eq '$PrincipalId' " | Select-Object -Property DisplayName
            AddRuleSource -Source $PIMGroup.DisplayName -SourceType "PIM Group" -Rules $MemberPolicyRules

            $RoleRules = $Role.psobject.Properties | Where-Object {$_.Name -eq 'Rules'}
            if ($RoleRules){
                # Appending rules
                $Role.Rules += $MemberPolicyRules
            }
            else {
                # Adding rules node if it is not already present
                $Role | Add-Member -Name "Rules" -Value $MemberPolicyRules -MemberType NoteProperty
            }
        }
    }
}

function GetConfigurationsForRoles{
    param (
        [ValidateNotNullOrEmpty()]
        [array]
        $PrivilegedRoleArray,

        [ValidateNotNullOrEmpty()]
        [array]
        $AllRoleAssignments
    )

    # Get all the configuration settings (aka rules) for all the roles in the tenant
    $RolePolicyAssignments = Get-MgBetaPolicyRoleManagementPolicyAssignment -All -ErrorAction Stop -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole'"

    foreach ($Role in $PrivilegedRoleArray) {
        $RolePolicies = @()
        $RoleTemplateId = $Role.RoleTemplateId

        # Get a list of the configuration rules assigned to this role
        $PolicyAssignment = $RolePolicyAssignments | Where-Object -Property RoleDefinitionId -eq -Value $RoleTemplateId

        # Get the detailed configuration settings
        $RolePolicies = Get-MgBetaPolicyRoleManagementPolicyRule -All -ErrorAction Stop -UnifiedRoleManagementPolicyId $PolicyAssignment.PolicyId

        # Get a list of the users / groups assigned to this role
        $RoleAssignments = @($AllRoleAssignments | Where-Object { $_.RoleDefinitionId -eq $RoleTemplateId })

        # Store the data that we retrieved in the Role object which is part of the privileged role array
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
    Returns an array of the highly privileged roles along with the users actively assigned to the role and the security configurations applied to the role
    .Functionality
    Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [bool]
        $TenantHasPremiumLicense,

        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    # This object contains an array of what Scuba considers the privileged roles
    $PrivilegedRoles = [ScubaConfig]::ScubaDefault('DefaultPrivilegedRoles')
    # Get a list of the RoleTemplateId values for the privileged roles in the list above.
    # The RoleTemplateId value is passed to other cmdlets to retrieve role/group security configuration rules and user/group assignments.
    $PrivilegedRoleArray = Get-MgBetaDirectoryRoleTemplate -All -ErrorAction Stop | Where-Object { $_.DisplayName -in $PrivilegedRoles } | Select-Object "DisplayName", @{Name='RoleTemplateId'; Expression={$_.Id}}

    # If the tenant has the premium license then you can access the PIM service to get the role configuration policies and the active role assigments
    if ($TenantHasPremiumLicense) {
        # Clear the cache of already processed PIM groups because this is a static variable
        [GroupTypeCache]::CheckedGroups.Clear()

        # Get ALL the roles and users actively assigned to them
        $graphArgs = @{
            "commandlet" = "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance"
            "M365Environment" = $M365Environment }
        $AllRoleAssignments = Invoke-GraphDirectly @graphArgs

        # Each of the helper functions below add configuration settings (aka rules) to the role array.
        # Get the PIM configurations for the roles
        GetConfigurationsForRoles -PrivilegedRoleArray $PrivilegedRoleArray -AllRoleAssignments $AllRoleAssignments
        # Get the PIM configurations for the groups
        GetConfigurationsForPimGroups -PrivilegedRoleArray $PrivilegedRoleArray -AllRoleAssignments $AllRoleAssignments -M365Environment $M365Environment
    }

    # Return the array
    $PrivilegedRoleArray
}

function Initialize-RiskyPermissions {
    <#
    .Description
    Returns an array of API permissions from either application/service principal which map
    to the list of permissions declared in the riskyPermissions.json file
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $json,

        [ValidateNotNullOrEmpty()]
        [Object[]]
        $map,

        [ValidateNotNullOrEmpty()]
        [string]
        $resource,

        [ValidateNotNullOrEmpty()]
        [string]
        $id
    )

    $riskyPermissions = $json.permissions.$resource.PSObject.Properties.Name
    if ($riskyPermissions -contains $id) {
        $map += $json.permissions.$resource.$id
    }

    $map
}

function Get-ValidCredentials {
    <#
    .Description
    Returns an array of valid credentials, expired credentials are excluded
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [Array[]]
        $credentials
    )

    $validCredentials = @()
    foreach ($credential in $credentials) {
        if ($credential.EndDateTime -gt (Get-Date)) { $validCredentials += $credential }
    }
    $validCredentials
}

function Get-ApplicationsWithRiskyPermissions {
    <#
    .Description
    Returns an array of applications where each item contains its Object ID, App ID, Display Name,
    Key/Password/Federated Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>

    try {
        $applications = Get-MgBetaApplication -All
        $applicationResults = @()
        foreach ($app in $applications) {
        
            # Map permissions assigned to application to risky permissions
            $mappedPermissions = @()
            foreach ($resource in $app.RequiredResourceAccess) {
                # Exclude delegated permissions with property Type="Scope"
                $roles = $resource.ResourceAccess | Where-Object { $_.Type -eq "Role" }
                $resourceAppId = $resource.ResourceAppId
            
                foreach($role in $roles) {
                    $resourceDisplayName = $permissionsJson.resources.$resourceAppId
                    $roleId = $role.Id
                    $mappedPermissions = Initialize-RiskyPermissions -json $permissionsJson -map $mappedPermissions -resource $resourceDisplayName -id $roleId
                }
            }
        
            # Get federated credentials
            $federatedCredentials = Get-MgBetaApplicationFederatedIdentityCredential -ApplicationId $app.Id -All
            $federatedCredentialsResults = @()
        
            # Reformat only if a credential exists
            if ($null -ne $federatedCredentials) {
                foreach ($federatedCredential in $federatedCredentials) {
                    $federatedCredentialsResults += [PSCustomObject]@{
                        'Id' = $federatedCredential.Id
                        'Name' = $federatedCredential.Name
                        'Description' = $federatedCredential.Description
                        'Issuer' = $federatedCredential.Issuer
                        'Subject' = $federatedCredential.Subject
                        'Audiences' = $federatedCredential.Audiences | Out-String
                    }
                }
            }
        
            # Disregard entries without risky permissions
            if ($mappedPermissions.Count -gt 0) {
                $applicationResults += [PSCustomObject]@{
                    'Object ID' = $app.Id
                    'App ID' = $app.AppId
                    'Display Name' = $app.DisplayName
                    'Key Credentials' = Get-ValidCredentials -credentials $app.KeyCredentials
                    'Password Credentials' = Get-ValidCredentials -credentials $app.PasswordCredentials
                    'Federated Credentials' = $federatedCredentials
                    'Risky Permissions' = $mappedPermissions
                }
            }
        }
    } catch {
        Write-Warning "An error occurred in Get-ApplicationsWithRiskyPermissions: $($_.Exception.Message)"
        Write-Warning "Stack trace: $($_.ScriptStackTrace)"
        throw $_
    }
    $applicationResults | ConvertTo-Json -Depth 3
}

