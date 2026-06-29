Import-Module -Name $PSScriptRoot/../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable, Invoke-GraphBatchRequest

function Export-AADProvider {
    <#
    .SYNOPSIS
        Exports the Entra ID (Azure AD) configuration relevant to the ScubaGear AAD baselines.
    .DESCRIPTION
        Gets the Azure Active Directory (AAD) settings that are relevant
        to the SCuBA AAD baselines using a subset of the modules under the
        overall Microsoft Graph PowerShell Module. Returns a string of comma
        separated JSON name/value pairs that are merged into the ScubaGear
        provider settings output.
    .PARAMETER M365Environment
        The M365 environment to run against (for example commercial, gcc, gcchigh, or dod).
        It selects the Graph endpoints used when retrieving the tenant configuration.
    .FUNCTIONALITY
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

    # The below cmdlet covers numerous policy checks that inspect conditional access policies, GraphDirect specifies that this will retrieve information from the Graph API directly (Invoke-GraphDirectly) and not use the cmdlet. The cmdlet is used as a reference, it looks up API details within the Permissions JSON file.
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

    # Retrieve tenant user count for both enabled/disabled accounts.
    $UserCount = $Tracker.TryCommand("Get-MgBetaUserCount", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})
    # Return value is an array of objects and the first item in the array is a string containing the user count.
    if ($UserCount -is [array] -and $UserCount.Count -gt 0 -and [int]::TryParse($UserCount[0], [ref]$null)) {
        $UserCount = $UserCount[0]
    }
    else {
        Write-Warning "Error retrieving user count, invalid data received: $($UserCount | ConvertTo-Json)"
        $UserCount = -1
    }

    # Provides data for policies such as user consent and guest user access.
    $AuthZPolicies = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaPolicyAuthorizationPolicy", @{"M365Environment"=$M365Environment; "GraphDirect"=$true}))

    # Provides data for admin consent workflow
    $DirectorySettings = ConvertTo-Json -Depth 10 @($Tracker.TryCommand("Get-MgBetaDirectorySetting", @{"M365Environment"=$M365Environment; "GraphDirect"=$true}))

    #####  This block gets data on the tenant's authentication methods
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
    ##### End authentication methods block

    # Provides data on the password expiration policy
    $DomainSettings = ConvertTo-Json @($Tracker.TryCommand("Get-MgBetaDomain", @{"M365Environment"=$M365Environment; "GraphDirect"=$true}))

    # The RiskyDelegatedPermissionClassifications is for user consent policy 5.2 to determine if any delegated permission classifications considered risky by Scuba are classified as low risk in the tenant
    $RiskyDelegatedPermissionClassifications = ConvertTo-Json @($Tracker.TryCommand("Get-ServicePrincipalsWithRiskyDelegatedPermissionClassifications", @{"M365Environment"=$M365Environment}))

    ##### Retrieve application management policies - MS.AAD.5.5v1, MS.AAD.5.6v1, MS.AAD.5.7v1
    # GraphDirect specifies that this will retrieve information from the Graph API directly (Invoke-GraphDirectly). The cmdlet is used as a reference; it looks up API details within the Permissions JSON file.
    $DefaultAppManagementPolicy = ConvertTo-Json -Depth 5 @($Tracker.TryCommand("Get-MgBetaPolicyDefaultAppManagementPolicy", @{"M365Environment"=$M365Environment; "GraphDirect"=$true}))
    $AppPolicies = $Tracker.TryCommand("Get-MgBetaPolicyAppManagementPolicy", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})

    # Enrich each policy with its appliesTo list (apps/SPs the policy targets) for report output
    Import-Module $PSScriptRoot/ProviderHelpers/AADAppManagementPolicyHelper.psm1
    if ($null -eq $AppPolicies -or @($AppPolicies).Count -eq 0) {
        $AppManagementPolicies = ConvertTo-Json @()
    }
    else {
        # $AppManagementPolicies = ConvertTo-Json -Depth 10 @(Get-AppManagementPolicies -AppPolicies @($AppPolicies) -M365Environment $M365Environment)
        $AppManagementPolicies = $Tracker.TryCommand("Get-AppManagementPolicies", @{"M365Environment"=$M365Environment; "AppPolicies"=@($AppPolicies)})
        if ($AppManagementPolicies.count -gt 0) {
            $AppManagementPolicies = ConvertTo-Json -Depth 10 @($AppManagementPolicies[0])
        }
        else {
            $AppManagementPolicies = ConvertTo-Json @()
        }
    }
    ##### End application management policies

    ##### This block contains the slowest functions so that they execute last in the order of operations.
    #####
    Write-Information "INFO: Starting execution of functions that typically take longer" -InformationAction Continue

    # Check of there are service plans with a ProvisioningStatus of Success
    if ($ServicePlans) {
        # The $TenantHasPremiumLicense variable is used so that PIM Cmdlets are only executed if the tenant has the premium license
        $RequiredServicePlan = $ServicePlans | Where-Object -Property ServicePlanName -eq -Value "AAD_PREMIUM_P2"
        $TenantHasPremiumLicense = if ($RequiredServicePlan) { $true } else { $false }

        # Retrieve an array of privileged users and service principals
        $PrivilegedObjects = $Tracker.TryCommand("Get-PrivilegedUser", @{"TenantHasPremiumLicense"=$TenantHasPremiumLicense; "M365Environment"=$M365Environment})

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
        $PrivilegedUsers = if ($null -eq $PrivilegedUsers) {"{}"} else {$PrivilegedUsers}

        # Get-PrivilegedRole provides a list of security configurations for each privileged role and information about Active user assignments
        $PrivilegedRoles = $Tracker.TryCommand("Get-PrivilegedRole", @{"TenantHasPremiumLicense"=$TenantHasPremiumLicense; "M365Environment"=$M365Environment})
        $PrivilegedRoles = ConvertTo-Json -Depth 10 @($PrivilegedRoles) # Depth required to get policy rule object details
    }
    else {
        Write-Warning "Omitting calls to Get-PrivilegedRole and Get-PrivilegedUser."
        $PrivilegedUsers = ConvertTo-Json @()
        $PrivilegedRoles = ConvertTo-Json @()
        $Tracker.AddUnSuccessfulCommand("Get-PrivilegedRole")
        $Tracker.AddUnSuccessfulCommand("Get-PrivilegedUser")
        $PrivilegedServicePrincipals = @{}
    }

    ##### This block gathers information on risky API permissions related to application/service principal objects
    Import-Module $PSScriptRoot/ProviderHelpers/AADRiskyPermissionsHelper.psm1

    # Export severity score weights at the provider level so the data can be used for processing in the Entra ID HTML report.
    $SeverityScoreWeights = ConvertTo-Json -Depth 5 (Get-SeverityScoreWeights)

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
    $AggregateRiskyAppsRaw = @(
        if (@($RiskyApps).Count -gt 0 -and @($RiskySPs).Count -gt 0) {
            $Tracker.TryCommand("Format-RiskyApplications", @{
                "RiskyApps"=$RiskyApps;
                "RiskySPs"=$RiskySPs
            })
        }
    )
    # We need the raw data from "Format-RiskyApplications", convert $AggregateRiskyAppsRaw to JSON format after this operation is complete.
    $AggregateRiskyApps = ConvertTo-Json -Depth 4 @($AggregateRiskyAppsRaw)

    # "Format-RiskyThirdPartyServicePrincipals" does NOT return service principals created in its home tenant.
    # It only returns risky service principals owned by external tenants.
    $RiskyThirdPartySPs = ConvertTo-Json -Depth 4 @(
        if (@($RiskySPs).Count -gt 0) {
            $Tracker.TryCommand("Format-RiskyThirdPartyServicePrincipals", @{
                "RiskySPs"=$RiskySPs;
                "M365Environment"=$M365Environment;
                "PrivilegedServicePrincipals"=$PrivilegedServicePrincipals
            })
        }
    )
    ##### End Risky Apps and Service Principals block

    ##### This block gathers information for reporting on risks related to Exchange hybrid application
    Import-Module $PSScriptRoot/ProviderHelpers/AADHybridExchangeHelper.psm1

    # Check if the first-party Office 365 Exchange Online service principal is configured with credentials.
    # This is an indicator of compromise if keyCredentials are present. The organization has not completed
    # remediation per Microsoft's guidance to remove remaining key credentials after migrating to the new
    # dedicated hybrid application, or they are still in the legacy hybrid configuration.
    $LegacyExchangeSP =  ConvertTo-Json -Depth 4 @(
        $Tracker.TryCommand("Get-LegacyExchangeServicePrincipal", @{
            "M365Environment"=$M365Environment
        })
    )

    $DedicatedExchangeHybridApps = ConvertTo-Json -Depth 4 @(
        $Tracker.TryCommand("Get-DedicatedExchangeHybridApplications", @{
            "AggregateRiskyAppsRaw"=$AggregateRiskyAppsRaw
        })
    )
    ##### End Exchange hybrid application block

    #####
    ##### End slowest functions block

    # PrivilegedServicePrincipals is converted to JSON here because it is a PowerShell Hashtable.
    $PrivilegedServicePrincipalsJson = ConvertTo-Json $PrivilegedServicePrincipals -Depth 5

    # This conversion to JSON needs to be last because other blocks above here rely on the $ServicePlans object in its PowerShell form.
    $ServicePlans = ConvertTo-Json -Depth 3 @($ServicePlans)

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "conditional_access_policies": $AllPolicies,
    "cap_table_data": $CapTableData,
    "authorization_policies": $AuthZPolicies,
    "privileged_users": $PrivilegedUsers,
    "privileged_service_principals": $PrivilegedServicePrincipalsJson,
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
    "severity_score_weights": $SeverityScoreWeights,
    "risky_delegated_permission_classifications": $RiskyDelegatedPermissionClassifications,
    "legacy_exchange_service_principal": $LegacyExchangeSP,
    "dedicated_exchange_hybrid_applications": $DedicatedExchangeHybridApps,
    "default_app_management_policy": $DefaultAppManagementPolicy,
    "app_management_policies": $AppManagementPolicies,
    "aad_successful_commands": $SuccessfulCommands,
    "aad_unsuccessful_commands": $UnSuccessfulCommands,
"@

    $json
}

function Get-AADTenantDetail {
    <#
    .SYNOPSIS
        Returns identifying details about the connected Entra ID (Azure AD) tenant.
    .DESCRIPTION
        Gets the tenant details using the Microsoft Graph PowerShell Module. Returns a JSON
        string with the tenant display name, initial domain name, and tenant id. If the
        lookup fails the function returns placeholder error values instead of throwing so
        that the rest of the export can continue.
    .PARAMETER M365Environment
        The M365 environment to run against (for example commercial, gcc, gcchigh, or dod).
        It selects the Graph endpoint used to read the organization details.
    .FUNCTIONALITY
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
    .SYNOPSIS
        Builds the set of users and service principals that hold privileged Entra ID roles.
    .DESCRIPTION
        Returns a hashtable of privileged users and their respective roles. The hashtable is
        keyed by object id and includes users and service principals that are Actively
        assigned to a privileged role, members reached transitively through assigned groups,
        and, when the tenant has the required premium license, principals that hold Eligible
        (PIM) assignments.
    .PARAMETER TenantHasPremiumLicense
        Indicates whether the tenant has the Entra ID premium (P2) license. When true the
        function also processes Eligible PIM role assignments in addition to Active ones.
    .PARAMETER M365Environment
        The M365 environment to run against (for example commercial, gcc, gcchigh, or dod).
        It selects the Graph endpoints used to enumerate roles and their members.
    .FUNCTIONALITY
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
    # We set LogErrors to false because we handle errors locally
    Trace-ScubaFunction -FunctionName "Get-PrivilegedUser Active assignments" -LogErrors $false -ScriptBlock {
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
    }

    # Process the Eligible role assignments if the premium license for PIM is there
    if ($TenantHasPremiumLicense) {
        # We set LogErrors to false because we handle errors locally
        Trace-ScubaFunction -FunctionName "Get-PrivilegedUser Eligible assignments" -LogErrors $false -ScriptBlock {
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
    }

    $PrivilegedUsers
}

function LoadObjectDataIntoPrivilegedUserHashtable {
    <#
    .SYNOPSIS
        Loads metadata for a privileged directory object into the privileged user hashtable.
    .DESCRIPTION
        Takes an object Id (either a user or group) and loads metadata about the object in the provided privileged user hashtable.
        If the object is a group, this function will iterate the group members and load metadata about each member. Group nesting
        is followed up to two levels deep, which also guards against infinite loops caused by circular PIM group assignments.
    .PARAMETER RoleName
        The display name of the privileged role to record against the object (and any of its members) in the hashtable.
    .PARAMETER PrivilegedUsers
        The hashtable that accumulates privileged user and service principal metadata. It is updated in place by this function.
    .PARAMETER ObjectId
        The Entra Id unique identifier for an object (either a user or a group) in the directory.
        Metadata about this object will be loaded into the PrivilegedUsers hashtable which is passed as a parameter.
    .PARAMETER TenantHasPremiumLicense
        Indicates whether the tenant has the Entra ID premium (P2) license. When true, Eligible members of a PIM for Groups
        group are also processed.
    .PARAMETER M365Environment
        The M365 environment to run against (for example commercial, gcc, gcchigh, or dod).
        It selects the Graph endpoints used to read the object and any group members.
    .PARAMETER Objecttype
        The type of Entra Id object that the ObjectId parameter references. Valid values are "user", "serviceprincipal", and
        "group". If this is not passed, the function calls Graph to dynamically determine the object type.
    .PARAMETER Recursioncount
        The current group nesting depth. Used internally when the function recurses into nested PIM groups; callers normally
        leave it at the default of 0.
    .FUNCTIONALITY
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
            $PrivilegedUsers[$ObjectId] = @{"id"=$ObjectId; "DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
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
                    $PrivilegedUsers[$GroupMember.Id] = @{"id"=$GroupMember.Id; "DisplayName"=$AADUser.DisplayName; "OnPremisesImmutableId"=$AADUser.OnPremisesImmutableId; "roles"=@()}
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
    .SYNOPSIS
        Tags policy rules with the source that contributed them, for reporting purposes.
    .DESCRIPTION
        Internal helper function that adds a source to policy rules for reporting purposes. Each rule receives a RuleSource
        and a RuleSourceType note property. The source should be either a PIM Group name or a Role name.
    .PARAMETER Source
        The name of the source that contributed the rules, typically a PIM Group name or a directory Role name.
    .PARAMETER SourceType
        A label describing what kind of source the rules came from. Defaults to "Directory Role".
    .PARAMETER Rules
        The array of policy rule objects to annotate. Each rule is updated in place with the RuleSource and RuleSourceType
        note properties.
    .FUNCTIONALITY
        Internal
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

function GetConfigurationsForPimGroups{
    <#
    .SYNOPSIS
        Gets PIM configurations for groups using batch optimization.

    .DESCRIPTION
        Retrieves all groups enrolled in PIM for Groups management using the
        privilegedAccess groups API, batch fetches display names, batch fetches
        policy assignments to get policyIds, then batch fetches all policy rules.
        The resulting rules are attached to the matching roles in the privileged
        role array.
    .PARAMETER PrivilegedRoleArray
        The array of privileged role objects to enrich. Policy rules for PIM groups are added to the roles those groups
        are assigned to, in place.
    .PARAMETER AllRoleAssignments
        The combined set of role assignment objects (Active and Eligible) used to map each PIM group to the roles it is
        assigned to.
    .PARAMETER M365Environment
        The M365 environment to run against (for example commercial, gcc, gcchigh, or dod).
        It selects the Graph endpoints used for the PIM group, policy assignment, and policy rule lookups.
    .FUNCTIONALITY
        Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [array]$PrivilegedRoleArray,

        [ValidateNotNullOrEmpty()]
        [array]$AllRoleAssignments,

        [ValidateNotNullOrEmpty()]
        [string]$M365Environment
    )

    # Get all groups enrolled in PIM for Groups management in the tenant. This only returns the ObjectID of the PIM Group as ID.
    # This will retrieve information from the Graph API directly and not use the cmdlet. API information is contained within the Permissions JSON file.
    $AllPIMGroups = (Invoke-GraphDirectly -Commandlet "Get-MgBetaIdentityGovernancePrivilegedAccessGroup" -M365Environment $M365Environment).Value
    if ($null -eq $AllPIMGroups -or $AllPIMGroups.Count -eq 0) {
        return
    }

    # Filter to retain only the PIM groups assigned to Scuba privileged roles
    $PIMGroups = @($AllPIMGroups | Where-Object { $_.Id -in $AllRoleAssignments.PrincipalId })
    if ($PIMGroups.Count -eq 0) {
        return
    }

    # Batch fetch PIM group names ($PIMGroups only returns Id, not DisplayName)
    $GroupDisplayNameResults = Invoke-GraphBatchRequest -InputObject $PIMGroups `
        -UrlScript { "/groups/$($_.Id)?`$select=displayName" } `
        -M365Environment $M365Environment -ApiVersion "beta"

    # Write a note to the log about PIM groups that no longer exist in the Entra directory
    $PhantomPIMGroups = $PIMGroups | Where-Object { $resp = $GroupDisplayNameResults[$_.Id]; $resp.status -eq 404; }
    $PhantomPIMGroups | ForEach-Object { Write-ScubaLog -Message "Skipping phantom PIM group: $($_.Id)" -Level Info -Source "GetConfigurationsForPimGroups" }

    # Filter out phantom groups from $PIMGroups
    $PIMGroups = @($PIMGroups | Where-Object { $PhantomPIMGroups.Id -notcontains $_.Id })

    # Add display names to the PIM group objects for easier access later
    foreach ($Group in $PIMGroups) {
        $displayNameResponse = $GroupDisplayNameResults[$Group.Id]
        if ($displayNameResponse.status -eq 200) {
            $Group | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $displayNameResponse.body.displayName
        }
        # If there was an errors fetching the group name, write to log and use the group ID instead of the name.
        else {
            $GroupNameFetchError = "Failed to fetch display name for group $($Group.Id) from batch results. Status: $($displayNameResponse.status). Body: $(($displayNameResponse.body | ConvertTo-Json -Depth 10))"
            Write-ScubaLog -Message $GroupNameFetchError -Level Info -Source "GetConfigurationsForPimGroups"
            $Group | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value "$($Group.Id)"
        }
    }

    # Batch fetch policy assignments for all PIM groups to retrieve the policyId for each group
    $PolicyResults = Invoke-GraphBatchRequest -InputObject $PIMGroups `
        -UrlScript { "/policies/roleManagementPolicyAssignments?`$filter=scopeId eq '$($_.Id)' and scopeType eq 'Group' and roleDefinitionId eq 'member'" } `
        -M365Environment $M365Environment -ApiVersion "beta"

    # If there were any errors batch fetching the PIM group policy assignments, abort execution with the details of the error.
    foreach ($PolicyResultsResponse in $PolicyResults.Values) {
        if ($PolicyResultsResponse.status -ne 200) {
            throw "Failed to fetch policy assignment for a PIM group from batch results. Status: $($PolicyResultsResponse.status). Body: $(($PolicyResultsResponse.body | ConvertTo-Json -Depth 10))"
        }
    }

    # Extract the distinct policyIds from the batch results to use in the next batch request to get the policy rules (aka configurations)
    $PolicyRulesInput = $PIMGroups | Select-Object @{n='PolicyId'; e={ $PolicyResults[$_.Id].body.value[0].policyId }}
    # Batch fetch policy rules (aka configurations) for all PIM groups
    $PolicyRulesResults = Invoke-GraphBatchRequest -InputObject $PolicyRulesInput `
        -IdScript { $_.PolicyId } `
        -UrlScript { "/policies/roleManagementPolicies/$($_.PolicyId)/rules" } `
        -M365Environment $M365Environment -ApiVersion "beta"

    # If there were any errors batch fetching the PIM group policy configurations, abort execution with the details of the error.
    foreach ($PolicyRulesResponse in $PolicyRulesResults.Values) {
        if ($PolicyRulesResponse.status -ne 200) {
            throw "Failed to fetch policy rules for a PIM group from batch results. Status: $($PolicyRulesResponse.status). Body: $(($PolicyRulesResponse.body | ConvertTo-Json -Depth 10))"
        }
    }

    # Process each PIM group and attach its policy rules to the privileged roles it is assigned to
    foreach ($Group in $PIMGroups) {
        # Get the policyId from the batch policy assignment results
        $PolicyId = $PolicyResults[$Group.Id].body.value[0].policyId

        # Convert batch response hashtables to PSCustomObjects (required for Add-Member operations)
        $PIMGroupsPolicyRules = @(ConvertFrom-GraphHashtable -GraphData $PolicyRulesResults[$PolicyId].body.value)

        # Add PIM Group display name (already fetched and stored on the $Group object)
        AddRuleSource -Source $Group.DisplayName -SourceType "PIM Group" -Rules $PIMGroupsPolicyRules

        # Filter all the role assignments for this group
        $RoleAssignmentsForGroup = $AllRoleAssignments | Where-Object { $_.PrincipalId -eq $Group.Id }

        # Attach rules (aka configurations) to the privileged roles this group is assigned to
        foreach ($RoleAssignment in $RoleAssignmentsForGroup) {
            $Role = $PrivilegedRoleArray | Where-Object RoleTemplateId -EQ $RoleAssignment.RoleDefinitionId

            if ($Role) {
                $RoleRules = $Role.psobject.Properties | Where-Object { $_.Name -eq 'Rules' }
                if ($RoleRules) {
                    $Role.Rules += $PIMGroupsPolicyRules
                }
                else {
                    $Role | Add-Member -Name "Rules" -Value $PIMGroupsPolicyRules -MemberType NoteProperty
                }
            }
        }
    }
}

function GetConfigurationsForRoles{
    <#
    .SYNOPSIS
        Attaches per-role PIM configuration settings and assignments to the privileged role array.
    .DESCRIPTION
        Gets the role management policy assignments and policy rules (aka configurations) for each directory role in the
        privileged role array, along with the user and group assignments for that role. The assignments and rules are
        added to each role object in place for later reporting.
    .PARAMETER PrivilegedRoleArray
        The array of privileged role objects to enrich. Assignments and configuration rules are added to each role in place.
    .PARAMETER AllRoleAssignments
        The set of role assignment objects used to determine which users and groups are assigned to each role.
    .FUNCTIONALITY
        Internal
    #>
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
    .SYNOPSIS
        Builds the array of highly privileged Entra ID roles with their assignments and PIM configurations.
    .DESCRIPTION
        Returns an array of the highly privileged roles along with the users actively assigned to the role and the security
        configurations applied to the role. When the tenant has the required premium license, the array is also enriched with
        the PIM role management policy rules for the roles and for any PIM for Groups groups assigned to them.
    .PARAMETER TenantHasPremiumLicense
        Indicates whether the tenant has the Entra ID premium (P2) license. When true the function reads PIM role and group
        configurations and the active role assignments; when false only the base role list is returned.
    .PARAMETER M365Environment
        The M365 environment to run against (for example commercial, gcc, gcchigh, or dod).
        It selects the Graph endpoints used to enumerate the roles, assignments, and policy rules.
    .FUNCTIONALITY
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
        # In this block We set LogErrors to false when calling Trace-ScubaFunction because we handle errors locally

        # Get ALL the roles and users actively assigned to them, API information is contained within the Permissions JSON file.
        $AllRoleAssignments = Trace-ScubaFunction -FunctionName "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -LogErrors $false -ScriptBlock {
            (Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleAssignmentScheduleInstance" -M365Environment $M365Environment).Value
        }
        $AllEligibleRoleAssignments = Trace-ScubaFunction -FunctionName "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" -LogErrors $false -ScriptBlock {
            (Invoke-GraphDirectly -Commandlet "Get-MgBetaRoleManagementDirectoryRoleEligibilityScheduleInstance" -M365Environment $M365Environment).Value
        }

        # Each of the helper functions below add configuration settings (aka rules) to the role array.
        # Get the PIM configurations for the roles
        Trace-ScubaFunction -FunctionName "GetConfigurationsForRoles" -LogErrors $false -ScriptBlock {
            GetConfigurationsForRoles -PrivilegedRoleArray $PrivilegedRoleArray -AllRoleAssignments $AllRoleAssignments
        }
        # Get the PIM configurations for the groups
        $AllRoleAssignments += $AllEligibleRoleAssignments # Add eligible only for PIM groups
        Trace-ScubaFunction -FunctionName "GetConfigurationsForPimGroups" -LogErrors $false -ScriptBlock {
            GetConfigurationsForPimGroups -PrivilegedRoleArray $PrivilegedRoleArray -AllRoleAssignments $AllRoleAssignments -M365Environment $M365Environment
        }
    }

    # Return the array
    $PrivilegedRoleArray
}