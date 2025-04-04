$Tracker = @()

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

    $SubscribedSku = $Tracker.TryCommand("Get-MgBetaSubscribedSku")

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

    $UserCount = $Tracker.TryCommand("Get-MgBetaUserCount", @{"M365Environment"=$M365Environment; "GraphDirect"=$true; "apiHeader"=$true})
    # Ensure we successfully got a count of users
    if(-Not $UserCount -is [int]) {
        $UserCount = "NaN"
    }

    # Provides data for policies such as user consent and guest user access
    $AuthZPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaPolicyAuthorizationPolicy", @{"M365Environment"=$M365Environment; "GraphDirect"=$true}))

    # Provides data for admin consent workflow
    $DirectorySettings = ConvertTo-Json -Depth 10 @($Tracker.TryCommand("Get-MgBetaDirectorySetting"))

    ##### This block supports policies that need data on the tenant's authentication methods
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
    $DomainSettings = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaDomain"))

    ##### This block gathers information on risky API permissions related to application/service principal objects
    Import-Module $PSScriptRoot/ProviderHelpers/AADRiskyPermissionsHelper.psm1

    $RiskyApps = $Tracker.TryCommand("Get-ApplicationsWithRiskyPermissions")
    $RiskySPs = $Tracker.TryCommand("Get-ServicePrincipalsWithRiskyPermissions", @{"M365Environment"=$M365Environment})

    $RiskyApps = if ($null -eq $RiskyApps -or $RiskyApps.Count -eq 0) { $null } else { $RiskyApps }
    $RiskySPs = if ($null -eq $RiskySPs -or $RiskySPs.Count -eq 0) { $null } else { $RiskySPs }

    if ($RiskyApps -and $RiskySPs) {
        $AggregateRiskyApps = ConvertTo-Json -Depth 3 $Tracker.TryCommand("Format-RiskyApplications", @{"RiskyApps"=$RiskyApps; "RiskySPs"=$RiskySPs})
        $RiskyThirdPartySPs = ConvertTo-Json -Depth 3 $Tracker.TryCommand("Format-RiskyThirdPartyServicePrincipals", @{"RiskyApps"=$RiskyApps; "RiskySPs"=$RiskySPs})
    }
    else {
        $AggregateRiskyApps = "{}"
        $RiskyThirdPartySPs = "{}"
    }
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
    $PIMGroups = $Tracker.TryCommand("Get-MgBetaPrivilegedAccessResource", @{"M365Environment"=$M365Environment; "GraphDirect"=$true; "ID"="aadGroups"}) # This will return the groups that are enrolled in PIM for group management

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
            $PolicyAssignment = ($Tracker.TryCommand("Get-MgBetaPolicyRoleManagementPolicyAssignment", @{"M365Environment"=$M365Environment; "GraphDirect"=$true; "queryParams" = @{'$filter' = "scopeId eq '$PrincipalId' and scopeType eq 'Group' and roleDefinitionId eq 'member'"}})).policyId

            # Add each configuration rule to the array. There are usually about 17 configurations for a group.
            # Get the detailed configuration settings
            $MemberPolicyRules = $Tracker.TryCommand("Get-MgBetaPolicyRoleManagementPolicyRule", @{"M365Environment"=$M365Environment; "GraphDirect"=$true; "Id"=$PolicyAssignment})
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
    $RolePolicyAssignments = $Tracker.TryCommand("Get-MgBetaPolicyRoleManagementPolicyAssignment", @{"GraphDirect"=$true; "M365Environment"=$M365Environment; "queryParams" = @{'$filter' = "scopeId eq '/' and scopeType eq 'DirectoryRole'"}})

    foreach ($Role in $PrivilegedRoleArray) {
        $RolePolicies = @()
        $RoleTemplateId = $Role.RoleTemplateId

        # Get a list of the configuration rules assigned to this role
        $PolicyAssignment = $RolePolicyAssignments | Where-Object -Property RoleDefinitionId -eq -Value $RoleTemplateId

        # Get the detailed configuration settings
        $RolePolicies = $Tracker.TryCommand("Get-MgBetaPolicyRoleManagementPolicyRule", @{"GraphDirect"=$true; "M365Environment"=$M365Environment; "Id"=$PolicyAssignment.PolicyId}) # Required changes to REGO since additionalProperties is not present in the response and REGO was lowercase

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
        $AllRoleAssignments = $Tracker.TryCommand("Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})

        # Each of the helper functions below add configuration settings (aka rules) to the role array.
        # Get the PIM configurations for the roles
        GetConfigurationsForRoles -PrivilegedRoleArray $PrivilegedRoleArray -AllRoleAssignments $AllRoleAssignments
        # Get the PIM configurations for the groups
        GetConfigurationsForPimGroups -PrivilegedRoleArray $PrivilegedRoleArray -AllRoleAssignments $AllRoleAssignments -M365Environment $M365Environment
    }

    # Return the array
    $PrivilegedRoleArray
}