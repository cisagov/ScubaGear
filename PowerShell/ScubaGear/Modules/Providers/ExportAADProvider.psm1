Import-Module -Name $PSScriptRoot/../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable, Invoke-GraphBatchRequest

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
    Import-Module $PSScriptRoot/ProviderHelpers/LicenseHelper.psm1
    $Tracker = Get-CommandTracker

    # The below cmdlet covers ~ 9 policy checks that inspect conditional access policies, GraphDirect specifies that this will retrieve information from the Graph API directly (Invoke-GraphDirectly) and not use the cmdlet. The cmdlet is used as a reference, it looks up API details within the Permissions JSON file.
    $AllPolicies = $Tracker.TryCommand("Get-MgBetaIdentityConditionalAccessPolicy", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})

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

    $SubscribedSku = $Tracker.TryCommand("Get-MgBetaSubscribedSku", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})

    # Determine tenant license state based on subscribed SKUs/service plans
    $LicenseStateObj = Get-AADLicenseState -SubscribedSku $SubscribedSku
    $LicenseState = ConvertTo-Json -Depth 4 @($LicenseStateObj)

    # Get a list of the tenant's provisioned service plans - used to see if the tenant has AAD premium p2 license required for some checks
    # The Rego looks at the service_plans in the JSON
    $ServicePlans = $SubscribedSku.ServicePlans | Where-Object -Property ProvisioningStatus -eq -Value "Success"

    #Obtains license information for tenant and total number of active users
    $LicenseInfo = $SubscribedSku | Select-Object -Property Sku*, ConsumedUnits, PrepaidUnits | ConvertTo-Json -Depth 3

    if ($ServicePlans) {
        # The RequiredServicePlan variable is used so that PIM Cmdlets are only executed if the tenant has the premium license
        $RequiredServicePlan = $ServicePlans | Where-Object -Property ServicePlanName -eq -Value "AAD_PREMIUM_P2"

        if ($RequiredServicePlan) {
            # If the tenant has the premium license then we also include calls to PIM APIs
            $PrivilegedObjects = $Tracker.TryCommand("Get-PrivilegedUser", @{"TenantHasPremiumLicense"=$true; "M365Environment"=$M365Environment})
        }
        else {
            $PrivilegedObjects = $Tracker.TryCommand("Get-PrivilegedUser", @{"TenantHasPremiumLicense"=$false; "M365Environment"=$M365Environment})
        }

        # # Split the objects into users and service principals
        $PrivilegedUsers = @{}
        $PrivilegedServicePrincipals = @{}

        if ($PrivilegedObjects.Count -gt 0 -and $null -ne $PrivilegedObjects[0].Keys) {

            #PrivilegedObjects is an array because of the tracker.trycommand, and so the first index is the hashtable
            foreach ($key in $PrivilegedObjects[0].Keys) {

                # Check if it has ServicePrincipalId property instead of AppId
                if ($null -ne $PrivilegedObjects[0][$key].ServicePrincipalId) {
                    $PrivilegedServicePrincipals[$key] = $PrivilegedObjects[0][$key]
                }
                else {
                    $PrivilegedUsers[$key] = $PrivilegedObjects[0][$key]
                }
            }
        }
        $PrivilegedUsers = ConvertTo-Json $PrivilegedUsers
        $PrivilegedServicePrincipals = ConvertTo-Json $PrivilegedServicePrincipals

        # While ConvertTo-Json won't mess up a dict as described in the above comment,
        # on error, $TryCommand returns an empty list, not a dictionary.
        $PrivilegedUsers = if ($null -eq $PrivilegedUsers) {"{}"} else {$PrivilegedUsers}
        $PrivilegedServicePrincipals = if ($null -eq $PrivilegedServicePrincipals) {"{}"} else {$PrivilegedServicePrincipals}

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

    # Retrieve tenant user count for both enabled/disabled accounts utilizing (Invoke-GraphDirectly) and not use the cmdlet. The cmdlet is used as a reference, it looks up API details within the Permissions JSON file.
    $UserCount = $Tracker.TryCommand("Get-MgBetaUserCount", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})
    # Ensure we successfully got a count of users
    if(-Not $UserCount -is [int]) {
        $UserCount = "NaN"
    }

    # Provides data for policies such as user consent and guest user access, GraphDirect specifies that this will retrieve information from the Graph API directly (Invoke-GraphDirectly) and not use the cmdlet. The cmdlet is used as a reference, it looks up API details within the Permissions JSON file.
    $AuthZPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaPolicyAuthorizationPolicy", @{"M365Environment"=$M365Environment; "GraphDirect"=$true}))

    # Provides data for admin consent workflow
    $DirectorySettings = ConvertTo-Json -Depth 10 @($Tracker.TryCommand("Get-MgBetaDirectorySetting", @{"M365Environment"=$M365Environment; "GraphDirect"=$true}))

    # This block supports policies that need data on the tenant's authentication methods, GraphDirect specifies that this will retrieve information from the Graph API (Invoke-GraphDirectly) and not use the cmdlet. The cmdlet is used as a reference, it looks up API details within the Permissions JSON file.
    $AuthenticationMethodPolicyRootObject = $Tracker.TryCommand("Get-MgBetaPolicyAuthenticationMethodPolicy", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})

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
    $DomainSettings = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaDomain", @{"M365Environment"=$M365Environment; "GraphDirect"=$true}))

    ##### This block gathers information on risky API permissions related to application/service principal objects
    Import-Module $PSScriptRoot/ProviderHelpers/AADRiskyPermissionsHelper.psm1

    # Microsoft does not provide a commandlet to retrieve the display name of delegated permissions out of the box.
    # Each resource application, e.g. Microsoft Graph, Exchange Online, etc., can be queried to retrieve its application/delegated API scopes
    # This cache is used to store the scopes for each resource application to avoid redundant calls to the Graph API for the same resource application.
    $ResourcePermissionCache = @{}

    $RiskyApps = $Tracker.TryCommand("Get-ApplicationsWithRiskyPermissions", @{
        "M365Environment"=$M365Environment;
        "ResourcePermissionCache"=$ResourcePermissionCache
    })
    $RiskySPs = $Tracker.TryCommand("Get-ServicePrincipalsWithRiskyPermissions", @{
        "M365Environment"=$M365Environment;
        "ResourcePermissionCache"=$ResourcePermissionCache
    })

    $RiskyApps = if ($null -eq $RiskyApps -or @($RiskyApps).Count -eq 0) { @() } else { $RiskyApps }
    $RiskySPs = if ($null -eq $RiskySPs -or @($RiskySPs).Count -eq 0) { @() } else { $RiskySPs }

    # There are four cases that can occur
    # 1. Both risky apps and risky 3rd party SPs exist
    # 2. Neither risky apps or risky 3rd party SPs exist
    # 3. No risky apps exist but risky 3rd party SPs exist
    # 4. Risky apps exist but no risky 3rd party SPs exist

    # "Format-RiskyApplications" will match app registrations with and without a corresponding service principal object.
    # If an app registration does not have a service principal object, only app registration data will be displayed.
    # If an app registration has a matching service principal object, app registration and service principal data will be aggregated together.
    $AggregateRiskyApps = ConvertTo-Json -Depth 3 @(
        if (@($RiskyApps).Count -gt 0 -and @($RiskySPs).Count -gt 0) {
            $Tracker.TryCommand("Format-RiskyApplications", @{
                "RiskyApps"=$RiskyApps;
                "RiskySPs"=$RiskySPs
            })
        }
    )

    # "Format-RiskyThirdPartyServicePrincipals" does NOT return service principals created in its home tenant.
    # It only returns risky service principals owned by external tenants.
    $RiskyThirdPartySPs = ConvertTo-Json -Depth 3 @(
        if (@($RiskySPs).Count -gt 0) {
            $Tracker.TryCommand("Format-RiskyThirdPartyServicePrincipals", @{
                "RiskySPs"=$RiskySPs;
                "M365Environment"=$M365Environment
            })
        }
    )
    ##### End block

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "conditional_access_policies": $AllPolicies,
    "cap_table_data": $CapTableData,
    "authorization_policies": $AuthZPolicies,
    "privileged_users": $PrivilegedUsers,
    "privileged_service_principals": $PrivilegedServicePrincipals,
    "privileged_roles": $PrivilegedRoles,
    "service_plans": $ServicePlans,
    "directory_settings": $DirectorySettings,
    "authentication_method": $AuthenticationMethod,
    "domain_settings": $DomainSettings,
    "license_information": $LicenseInfo,
    "license_state": $LicenseState,
    "total_user_count": $UserCount,
    "risky_applications": $AggregateRiskyApps,
    "risky_third_party_service_principals": $RiskyThirdPartySPs,
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
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )
    try {
        # Retrieve tenant details using GraphDirectly to reduce reliance on the cmdlet. The cmdlet is used as a reference, it looks up API details within the Permissions JSON file.
        $OrgInfo = (Invoke-GraphDirectly -Commandlet "Get-MgBetaOrganization" -M365Environment $M365Environment).Value
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
        $AADTenantInfo = ConvertTo-Json @($AADTenantInfo) -Depth 10
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
    $AADRoles = (Invoke-GraphDirectly -Commandlet "Get-MgBetaDirectoryRole" -M365Environment $M365Environment).Value | Where-Object { $_.DisplayName -in $PrivilegedRoles }

    # Construct a list of privileged users based on the Active role assignments
    foreach ($Role in $AADRoles) {

        # Get a list of all the users and groups Actively assigned to this role
        $UsersAssignedRole = (Invoke-GraphDirectly -Commandlet "Get-MgBetaDirectoryRoleMember" -M365Environment $M365Environment -Id $Role.Id).Value

        foreach ($User in $UsersAssignedRole) {
            $Objecttype = $User."@odata.type" -replace "#microsoft.graph."

                if ($Objecttype -eq "user") {
                    LoadObjectDataIntoPrivilegedUserHashtable -RoleName $Role.DisplayName -PrivilegedUsers $PrivilegedUsers -ObjectId $User.Id -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment -Objecttype "user"
                }
                elseif ($Objecttype -eq "servicePrincipal") {
                    LoadObjectDataIntoPrivilegedUserHashtable -RoleName $Role.DisplayName -PrivilegedUsers $PrivilegedUsers -ObjectId $User.Id -TenantHasPremiumLicense $TenantHasPremiumLicense -M365Environment $M365Environment -Objecttype "serviceprincipal"
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
        # Get a list of all the users and groups that have Eligible assignments, this will retrieve information from the Graph API directly and not use the cmdlet.
        $AllPIMRoleAssignments = (Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" -M365Environment $M365Environment).Value

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
            $DirectoryObject = Invoke-GraphDirectly -Commandlet "Get-MgBetaDirectoryObject" -M365Environment $M365Environment -id $ObjectId
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
        $Objecttype = $DirectoryObject."@odata.type" -replace "#microsoft.graph."
    }

    if ($Objecttype -eq "user") {
        # If the user's data has not been fetched from graph, go get it and add it to the hashtable
        if (-Not $PrivilegedUsers.ContainsKey($ObjectId)) {
            # This will retrieve information from the Graph API directly and not use the cmdlet. API information is contained within the Permissions JSON file.
            $AADUser = Invoke-GraphDirectly -Commandlet "Get-MgBetaUser" -M365Environment $M365Environment -id $ObjectId
            $PrivilegedUsers[$ObjectId] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
        }
        # If the current role has not already been added to the user's roles array then add the role
        if ($PrivilegedUsers[$ObjectId].roles -notcontains $RoleName) {
            $PrivilegedUsers[$ObjectId].roles += $RoleName
        }
    }

    elseif ($Objecttype -eq "serviceprincipal") {

        # In this section we need to add the service principal information to the "service principal" hashtable
        if (-Not $PrivilegedUsers.ContainsKey($ObjectId)) {
            $AADServicePrincipal = Invoke-GraphDirectly -Commandlet "Get-MgBetaServicePrincipal" -M365Environment $M365Environment -id $ObjectId
            $PrivilegedUsers[$ObjectId] = @{
                "DisplayName" = $AADServicePrincipal.DisplayName
                "ServicePrincipalId" = $AADServicePrincipal.Id
                "AppId" = $AADServicePrincipal.AppId
                "roles" = @()
            }
        }
        if ($PrivilegedUsers[$ObjectId].roles -notcontains $RoleName) {
            $PrivilegedUsers[$ObjectId].roles += $RoleName
        }
    }

    elseif ($Objecttype -eq "group") {
        # In this context $ObjectId is a group identifier so we need to iterate the group members
        $GroupId = $ObjectId
        # Get all of the group members that are transitively assigned to the current role via group membership, this will retrieve information from the Graph API directly and not use the cmdlet. API information is contained within the Permissions JSON file.
        $GroupMembers = (Invoke-GraphDirectly -Commandlet "Get-MgBetaGroupMember" -M365Environment $M365Environment -id $GroupId).Value

        foreach ($GroupMember in $GroupMembers) {
            $Membertype = $GroupMember."@odata.type" -replace "#microsoft.graph."
            if ($Membertype -eq "user") {
                # If the user's data has not been fetched from graph, go get it and add it to the hashtable
                if (-Not $PrivilegedUsers.ContainsKey($GroupMember.Id)) {
                    # This will retrieve information from the Graph API directly and not use the cmdlet. API information is contained within the Permissions JSON file.
                    $AADUser = Invoke-GraphDirectly -Commandlet "Get-MgBetaUser" -M365Environment $M365Environment -id $GroupMember.Id
                    $PrivilegedUsers[$GroupMember.Id] = @{"DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
                }
                # If the current role has not already been added to the user's roles array then add the role
                if ($PrivilegedUsers[$GroupMember.Id].roles -notcontains $RoleName) {
                    $PrivilegedUsers[$GroupMember.Id].roles += $RoleName
                }
            }
            elseif ($Membertype -eq "serviceprincipal") {

                # In this section we need to add the service principal information to the "service principal" hashtable
                if (-Not $PrivilegedUsers.ContainsKey($GroupMember.Id)) {
                    $AADServicePrincipal = Invoke-GraphDirectly -Commandlet "Get-MgBetaServicePrincipal" -M365Environment $M365Environment -id $GroupMember.Id
                    $PrivilegedUsers[$GroupMember.Id] = @{
                        "DisplayName" = $AADServicePrincipal.DisplayName
                        "ServicePrincipalId" = $AADServicePrincipal.Id
                        "AppId" = $AADServicePrincipal.AppId
                        "roles" = @()
                    }
                }
                if ($PrivilegedUsers[$GroupMember.Id].roles -notcontains $RoleName) {
                    $PrivilegedUsers[$GroupMember.Id].roles += $RoleName
                }
            }
        }

        # Since this is a group, we need to also process assignments in PIM in case it is in PIM for Groups
        # If the premium license for PIM is there, process the users that are "member" of the PIM group as Eligible
        if ($TenantHasPremiumLicense) {
            # Get the users that are assigned to the PIM group as Eligible members
            # This will retrieve information from the Graph API directly and not use the cmdlet. API information is contained within the Permissions JSON file.
            $PIMGroupMembers = (Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance" -M365Environment $M365Environment -Id $GroupId).Value

            foreach ($GroupMember in $PIMGroupMembers) {

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
    <#
    .SYNOPSIS
        Gets PIM configurations for groups using PIM v3 API with batch optimization.

    .DESCRIPTION
        Migrated from deprecated privilegedAccess API to roleManagementPolicyAssignments API.
        Uses batch requests to efficiently check multiple principals for PIM enrollment.

    #>
    param (
        [ValidateNotNullOrEmpty()]
        [array]$PrivilegedRoleArray,

        [ValidateNotNullOrEmpty()]
        [array]$AllRoleAssignments,

        [ValidateNotNullOrEmpty()]
        [string]$M365Environment
    )

    # Collect unique principal IDs from privileged role assignments
    Write-Verbose "Collecting unique principal IDs from role assignments"
    # Initialize an empty array to store unique principal IDs
    $UniquePrincipalIds = @()

    # Build a list of unique principals that need to be checked for PIM group enrollment
    # Sort and filter role assignments to minimize API calls - we only want to check principals that are assigned to privileged roles and haven't been checked yet
    $UniquePrincipalIds = ($AllRoleAssignments | Sort-Object -Property PrincipalId, RoleDefinitionId -Unique) |
        Where-Object {
            # Only include assignments to privileged roles (by matching RoleDefinitionId against known privileged role template IDs)
            $PrivilegedRoleArray.RoleTemplateId -contains $_.RoleDefinitionId -and
            # Only include principals we haven't already checked (not in the cache)
            $null -eq [GroupTypeCache]::CheckedGroups[$_.PrincipalId]
        } | Select-Object -ExpandProperty PrincipalId -Unique

    if ($UniquePrincipalIds.Count -eq 0) {
        Write-Verbose "No new principals to check for PIM group enrollment"
        return
    }

    Write-Verbose "Found $($UniquePrincipalIds.Count) unique principals to check"

    # Batch check principals for PIM policy assignments (v3 API) for groups
    Write-Verbose "Batch checking principals for PIM enrollment using v3 API checking for PIM group policy assignments"
    $PolicyAssignmentRequests = @()
    foreach ($PrincipalId in $UniquePrincipalIds) {
        $PolicyAssignmentRequests += @{
            id     = $PrincipalId
            method = "GET"
            url    = "/policies/roleManagementPolicyAssignments?`$filter=scopeId eq '$PrincipalId' and scopeType eq 'Group' and roleDefinitionId eq 'member'"
        }
    }

    try {
        $PolicyResults = Invoke-GraphBatchRequest -Requests $PolicyAssignmentRequests -M365Environment $M365Environment -ApiVersion "beta"
    }
    catch {
        Write-Warning "Failed to batch check PIM policy assignments: $($_.Exception.Message)"
        return
    }

    # Extract confirmed PIM group IDs (status 200, successful response)
    $PIMGroupsIDs = @()
    foreach ($PrincipalId in $UniquePrincipalIds) {
        $response = $PolicyResults[$PrincipalId]
        if ($response.status -eq 200 -and $null -ne $response.body.value -and $response.body.value.Count -gt 0) {
            # Add to list of confirmed PIM groups to process
            $PIMGroupsIDs += $PrincipalId
        }
        else {
            # Not a PIM group - mark as checked
            [GroupTypeCache]::CheckedGroups.Add($PrincipalId, $false)
        }
    }

    if ($PIMGroupsIDs.Count -eq 0) {
        Write-Verbose "No PIM groups found among the principals"
        return
    }

    Write-Verbose "Found $($PIMGroupsIDs.Count) PIM groups to process"

    # After identifying PIM groups, retrieve their display name and objectID using batch requests
    Write-Verbose "Batch fetching display names for PIM groups"
    $GroupDisplayNameRequests = @()
    foreach ($PrincipalId in $PIMGroupsIDs) {
        $GroupDisplayNameRequests += @{
            id     = $PrincipalId
            method = "GET"
            url    = "/groups/${PrincipalId}?`$select=id,displayName"
        }
    }

    try {
        $GroupDisplayNameResults = Invoke-GraphBatchRequest -Requests $GroupDisplayNameRequests -M365Environment $M365Environment -ApiVersion "beta"
    }
    catch {
        Write-Warning "Failed to batch fetch group display names: $($_.Exception.Message)"
        # Continue with group ObjectID as fallback in the event of failure
        $GroupDisplayNameResults = @{}
    }

    # Batch fetch policy rules for all PIM groups
    Write-Verbose "Batch fetching policy rules for PIM groups"
    $PolicyRulesRequests = @()

    foreach ($PrincipalId in $PIMGroupsIDs) {
        $PolicyAssignment = $PolicyResults[$PrincipalId].body.value[0]
        $PolicyId = $PolicyAssignment.policyId

        $PolicyRulesRequests += @{
            id     = $PolicyId
            method = "GET"
            url    = "/policies/roleManagementPolicies/$PolicyId/rules"
        }
    }

    try {
        # This batch request is for fetching the policy rules for each PIM group. Since multiple groups can be assigned the same policy, we only fetch each unique policy once to optimize API calls.
        $PolicyRulesResults = Invoke-GraphBatchRequest -Requests $PolicyRulesRequests -M365Environment $M365Environment -ApiVersion "beta"
    }
    catch {
        Write-Warning "Failed to batch fetch policy rules: $($_.Exception.Message)"
        $PolicyRulesResults = @{}
    }

    # Process each confirmed PIM group to get the rules and PIM Group displayName
    foreach ($PrincipalId in $PIMGroupsIDs) {
        # Mark as processed
        [GroupTypeCache]::CheckedGroups.Add($PrincipalId, $true)

        # Get policy assignment
        $PolicyAssignment = $PolicyResults[$PrincipalId].body.value[0]
        $PolicyId = $PolicyAssignment.policyId

        # Get the detailed configuration settings from batch results
        $policyRulesResponse = $PolicyRulesResults[$PolicyId]

        # Add each configuration rule to the array. There are usually about 17 configurations for a group.
        if ($null -ne $policyRulesResponse -and $policyRulesResponse.status -eq 200 -and $null -ne $policyRulesResponse.body.value) {
            # Convert batch response hashtables to PSCustomObjects (required for Add-Member operations)
            $MemberPolicyRules = @(ConvertFrom-GraphHashtable -GraphData $policyRulesResponse.body.value)
        }
        else {
            # Fallback to individual API call if batch retrieval failed
            Write-Warning "Failed to retrieve policy rules for policy $PolicyId from batch results. Using fallback API call."
            $MemberPolicyRules = (Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyRule" -M365Environment $M365Environment -Id $PolicyId).Value
        }

        # Get group display name from batch results
        $GroupDisplayName = $PrincipalId  # Default fallback to objectID if batch fetch fails
        $displayNameResponse = $GroupDisplayNameResults[$PrincipalId]

        if ($null -ne $displayNameResponse -and $displayNameResponse.status -eq 200 -and $null -ne $displayNameResponse.body.displayName) {
            $GroupDisplayName = $displayNameResponse.body.displayName
            Write-Verbose "Successfully retrieved display name for group $PrincipalId : $GroupDisplayName"
        }
        else {
            Write-Warning "Failed to fetch display name for group $PrincipalId from batch results (Status: $($displayNameResponse.status), HasBody: $($null -ne $displayNameResponse.body), HasDisplayName: $($null -ne $displayNameResponse.body.displayName))"
        }

        # Add PIM Group display name
        AddRuleSource -Source $GroupDisplayName -SourceType "PIM Group" -Rules $MemberPolicyRules

        # Attach rules to All roles this group is assigned to
        $RoleAssignmentsForGroup = $AllRoleAssignments | Where-Object { $_.PrincipalId -eq $PrincipalId }

        foreach ($RoleAssignment in $RoleAssignmentsForGroup) {
            $Role = $PrivilegedRoleArray | Where-Object RoleTemplateId -EQ $RoleAssignment.RoleDefinitionId

            if ($Role) {
                $RoleRules = $Role.psobject.Properties | Where-Object { $_.Name -eq 'Rules' }
                if ($RoleRules) {
                    $Role.Rules += $MemberPolicyRules
                }
                else {
                    $Role | Add-Member -Name "Rules" -Value $MemberPolicyRules -MemberType NoteProperty
                }
                Write-Verbose "Added rules from PIM Group '$GroupDisplayName' to role '$($Role.DisplayName)'"
            }
        }
    }

    Write-Verbose "Completed processing $($PIMGroupsIDs.Count) PIM groups"
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

    # Get all the configuration settings (aka rules) for all the roles in the tenant. API information is contained within the Permissions JSON file, however the filter is being defined here since ScubaGear uses this API in other areas that require a different filter.
    $RolePolicyAssignments = (Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyAssignment" -M365Environment $M365Environment -queryParams @{'$filter' = "scopeId eq '/' and scopeType eq 'DirectoryRole'"}).Value

    foreach ($Role in $PrivilegedRoleArray) {
        $RolePolicies = @()
        $RoleTemplateId = $Role.RoleTemplateId

        # Get a list of the configuration rules assigned to this role
        $PolicyAssignment = $RolePolicyAssignments | Where-Object -Property RoleDefinitionId -eq -Value $RoleTemplateId

        # Get the detailed configuration settings, API information is contained within the Permissions JSON file.
        $RolePolicies = (Invoke-GraphDirectly -Commandlet "Get-MgBetaPolicyRoleManagementPolicyRule" -M365Environment $M365Environment -Id $PolicyAssignment.PolicyId).Value

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
    $PrivilegedRoleArray = (Invoke-GraphDirectly -Commandlet "Get-MgBetaDirectoryRoleTemplate" -M365Environment $M365Environment).Value | Where-Object { $_.DisplayName -in $PrivilegedRoles } | Select-Object "DisplayName", @{Name='RoleTemplateId'; Expression={$_.Id}}

    # If the tenant has the premium license then you can access the PIM service to get the role configuration policies and the active role assigments
    if ($TenantHasPremiumLicense) {
        # Clear the cache of already processed PIM groups because this is a static variable
        [GroupTypeCache]::CheckedGroups.Clear()

        # Get ALL the roles and users actively assigned to them, API information is contained within the Permissions JSON file.
        $AllRoleAssignments = (Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment $M365Environment).Value

        # Each of the helper functions below add configuration settings (aka rules) to the role array.
        # Get the PIM configurations for the roles
        GetConfigurationsForRoles -PrivilegedRoleArray $PrivilegedRoleArray -AllRoleAssignments $AllRoleAssignments
        # Get the PIM configurations for the groups
        GetConfigurationsForPimGroups -PrivilegedRoleArray $PrivilegedRoleArray -AllRoleAssignments $AllRoleAssignments -M365Environment $M365Environment
    }

    # Return the array
    $PrivilegedRoleArray
}