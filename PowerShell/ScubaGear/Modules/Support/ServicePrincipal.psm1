Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../Permissions/PermissionsHelper.psm1') -Force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../Connection/ConnectHelpers.psm1") -Function Connect-GraphHelper -force
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../Utility/Utility.psm1") -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable, Invoke-GraphBatchRequest -force

function Compare-ScubaGearRole {
    <#
    .SYNOPSIS
        Compares the service principal roles against the ScubaGearSPRole array.

    .DESCRIPTION
        This function will compare the service principal roles against the ScubaGearSPRole array. If the service principal is missing any roles, the function will return the missing roles.

    .PARAMETER ServicePrincipalID
        Used to define the AppID of the service principal that will be checked for roles.

    .PARAMETER Roles
        The roles that are required for the ScubaGear application.

    .PARAMETER M365Environment
        Used to define the environment that the application will be created in. The options are commercial, gcc, gcchigh, dod

    .PARAMETER SkipConnect
        Used to skip the connection to Microsoft Graph.

    .EXAMPLE
        Compare-ScubaGearRole -ServicePrincipalID "AppID" -Roles $ScubaGearSPRole -M365Environment commercial

        This example will compare the service principal roles against the ScubaGearSPRole array.

    .EXAMPLE
        Compare-ScubaGearRole -ServicePrincipalID "AppID" -Roles $ScubaGearSPRole -M365Environment commercial -SkipConnect

        This example will compare the service principal roles against the ScubaGearSPRole array and skip the connection to Microsoft Graph.

    .OUTPUTS
        PSCustomObject containing:
        - RoleName: Name of the role being checked
        - RoleID: ID of the role being checked
        - Missing: Boolean indicating if the role is missing

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServicePrincipalID,

        [Parameter(Mandatory = $true)]
        [string[]]$Roles,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment,

        # Add the SkipConnect parameter
        [Parameter(Mandatory = $false)]
        [switch]$SkipConnect
    )

    $M365Environment = $M365Environment.ToLower()

    # Only connect if not skipping connection
    if (-not $SkipConnect) {
        try {
            $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("RoleManagement.Read.Directory")
            Write-Verbose "Connected to Microsoft Graph in Compare-ScubaGearRole"
        } catch {
            Write-Warning "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        }
    } else {
        Write-Verbose "Skipping Microsoft Graph connection in Compare-ScubaGearRole"
    }

    $roleDefinition = @()

    # Assign the service principal to the directory roles
    $SPRoleAssignment = (Invoke-GraphDirectly -Commandlet Get-MgRoleManagementDirectoryRoleAssignment -M365Environment $M365Environment -queryParams @{
        '$filter' = "principalId eq '$ServicePrincipalID'"
    }).Value
    if($Null -ne $SPRoleAssignment){
        $ISGRRole = Invoke-GraphDirectly -Commandlet Get-MgRoleManagementDirectoryRoleDefinition -M365Environment $M365Environment -id $SPRoleAssignment.roleDefinitionId
    }

    # Initialize variables
    $RoleName = $null
    $Missing = $false

    if($Roles -notcontains $ISGRRole.DisplayName){
        # Role is missing
        ForEach ($Role in $Roles) {
            $RoleName = $Role
            $roleDefinition += (Invoke-GraphDirectly -Commandlet Get-MgRoleManagementDirectoryRoleDefinition -M365Environment $M365Environment -queryParams @{'$filter' = "displayName eq '$RoleName'"}).Value
        }
        $Missing = $True
    }

    # Return an object for the role name, ID, and Missing status
    $RoleObject = [PSCustomObject]@{
        RoleName = $RoleName
        RoleID = $roleDefinition.Id
        Missing = $Missing
    }

    return $RoleObject
}

function Compare-ScubaGearPermission {
    <#
    .SYNOPSIS
        Compares the service principal permissions against the required permissions.

    .DESCRIPTION
        This function will compare the service principal permissions against the required permissions. If the service principal is missing any permissions, the function will return the missing permissions.

    .PARAMETER ServicePrincipalID
        Used to define the AppID of the service principal that will be checked for permissions.

    .PARAMETER AppRoleIDs
        The AppRoleIDs that are required for the ScubaGear application. This can be obtained from the Get-ScubaGearEntraMinimumPermissions function.

    .PARAMETER M365Environment
        Used to define the environment that the application will be created in. The options are commercial, gcc, gcchigh, dod

    .PARAMETER SkipConnect
        Used to skip the connection to Microsoft Graph.

    .PARAMETER SPPerms
        Used to pass in the service principal permissions if already obtained. This can be used to skip the call to Microsoft Graph to get the service principal permissions.

    .PARAMETER ProductNames
        Used to filter the required permissions by product. This can be used to only check for permissions required by specific products. Valid values are "aad", "exo", "sharepoint", "teams", "powerPlatform", "defender", and "*". The default is to check for all permissions.

    .EXAMPLE
        Compare-ScubaGearPermission -ServicePrincipalID "AppID" -AppRoleIDs $AppRoleIDs -M365Environment commercial

        This example will compare the service principal permissions against the required permissions.

    .EXAMPLE
        Compare-ScubaGearPermission -ServicePrincipalID "AppID" -AppRoleIDs $AppRoleIDs -M365Environment commercial -SkipConnect

        This example will compare the service principal permissions against the required permissions and skip the connection to Microsoft Graph.

    .EXAMPLE
        Compare-ScubaGearPermission -ServicePrincipalID "AppID" -AppRoleIDs $AppRoleIDs -M365Environment commercial -ProductNames "aad","exo"

        This example will compare the service principal permissions against the required permissions for only Azure AD and Exchange Online.

    .OUTPUTS
        PSCustomObject containing:
        - MissingPermissions: Array of missing permissions
        - ExtraPermissions: Array of extra permissions
        - HasMissingPermissions: Boolean indicating if there are missing permissions
        - HasExtraPermissions: Boolean indicating if there are extra permissions

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
    #>
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ServicePrincipalID,

        [Parameter(Mandatory = $true)]
        [object]$AppRoleIDs,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment,

        [Parameter(Mandatory = $false)]
        [switch]$SkipConnect,

        [Parameter(Mandatory = $false)]
        [Object]$SPPerms,

        [Parameter(Mandatory = $false)]
        [ValidateSet("aad", "exo", "sharepoint", "teams", "powerPlatform", "defender", '*', IgnoreCase = $True)]
        [string[]]$ProductNames
    )

    $M365Environment = $M365Environment.ToLower()

    # Only connect if not skipping connection
    if (-not $SkipConnect) {
        try {
            $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("Application.Read.All")
            Write-Verbose "Connected to Microsoft Graph in Compare-ScubaGearPermission"

            # Check to see if the service principal is already assigned to the API permissions
            $SPPerms = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipalAppRoleAssignment -M365Environment $M365Environment -id $ServicePrincipalID).Value
        } catch {
            Write-Warning "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        }
    } else {
        Write-Verbose "Skipping Microsoft Graph connection in Compare-ScubaGearPermission"
    }

    $SPMissingPerms = @()
    $ExtraPerms = @()

    # FILTER AppRoleIDs to only include permissions for the specified products
    if ($ProductNames -and $ProductNames.Count -gt 0) {
        Write-Verbose "Filtering permissions for products: $($ProductNames -join ', ')"
        $FilteredAppRoleIDs = $AppRoleIDs | Where-Object {
            $permProduct = $_.Product
            # Check if any of the permission's products match the requested products
            $match = $false
            foreach ($product in $ProductNames) {
                if ($permProduct -contains $product) {
                    $match = $true
                    break
                }
            }
            $match
        }
    } else {
        # If no ProductNames specified, use all permissions
        $FilteredAppRoleIDs = $AppRoleIDs
    }

    # Handle case where NO application permissions are required (e.g., Defender - role-only)
    # Some products only require directory roles and no application permissions
    if ($null -eq $FilteredAppRoleIDs -or $FilteredAppRoleIDs.Count -eq 0) {
        Write-Verbose "No application permissions required for product(s): $($ProductNames -join ', ')"

        # Check if SP has any permissions - if so, they're ALL extra
        if ($null -ne $SPPerms -and $SPPerms.Count -gt 0) {
            Write-Output "Service Principal has $($SPPerms.Count) permissions, but none are required for $($ProductNames -join ', ') (role-only product)."

            # All current permissions are extra
            $ExtraPerms = @()

            # Collect all unique resource IDs
            $uniqueResourceIds = @{}
            foreach ($perm in $SPPerms) {
                $resourceId = if ($perm.resourceId) { $perm.resourceId } else { $perm.ResourceID }
                if ($resourceId -and -not $uniqueResourceIds.ContainsKey($resourceId)) {
                    $uniqueResourceIds[$resourceId] = $true
                }
            }

            # Fetch all service principals in one call
            if ($uniqueResourceIds.Keys.Count -gt 0) {
                $filterConditions = ($uniqueResourceIds.Keys | ForEach-Object { "id eq '$_'" }) -join " or "
                $servicePrincipalsResponse = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipal `
                                            -M365Environment $M365Environment `
                                            -queryParams @{ '$filter' = $filterConditions }).Value

                $spLookup = @{}
                foreach ($sp in $servicePrincipalsResponse) {
                    $spLookup[$sp.Id] = $sp
                }
            }

            # Process all current permissions as extra
            foreach ($perm in $SPPerms) {
                $resourceId = if ($perm.resourceId) { $perm.resourceId } else { $perm.ResourceID }
                $appRoleId = if ($perm.appRoleId) { $perm.appRoleId } else { $perm.AppRoleId }

                $graphServicePrincipal = $spLookup[$resourceId]
                if ($graphServicePrincipal) {
                    $APIPermission = $graphServicePrincipal.AppRoles | Where-Object { $_.Id -eq $appRoleId }
                    if ($APIPermission) {
                        $ExtraPerms += $APIPermission.Value
                    }
                }
            }
        } else {
            Write-Output "No application permissions found and none required for $($ProductNames -join ', ') (role-only product)."
        }

        # Return early with results
        $PermissionsObject = [PSCustomObject]@{
            MissingPermissions    = @()
            ExtraPermissions      = $ExtraPerms
            HasMissingPermissions = $false
            HasExtraPermissions   = ($ExtraPerms.Count -gt 0)
        }
        return $PermissionsObject
    }

    # Handle case where service principal has NO permissions at all
    if ($null -eq $SPPerms -or $SPPerms.Count -eq 0) {
        Write-Output "No service principal permissions found, all required permissions are missing."

        # All filtered permissions are missing
        foreach ($appRole in $FilteredAppRoleIDs) {
            $SPMissingPerms += [PSCustomObject]@{
                InputObject = $appRole.AppRoleID
                resourceAPIAppId = $appRole.resourceAPIAppId
                leastPermissions = $appRole.APIName
            }
        }
    } else {
        # Service principal HAS some permissions - do comparison
        Write-Verbose "Comparing $($FilteredAppRoleIDs.Count) required permissions against $($SPPerms.Count) current permissions"

        # Extract AppRoleID properties for comparison - using filtered list
        $AppRoleIDsList = $FilteredAppRoleIDs | Select-Object -ExpandProperty AppRoleID

        # Handle both camelCase (from batch API) and PascalCase (from SDK) property names
        $SPPermsList = $SPPerms | ForEach-Object {
            if ($_.appRoleId) { $_.appRoleId } else { $_.AppRoleId }
        }

        # Compare the AppRoleIDs array against the service principal permissions
        $Diff = Compare-Object -ReferenceObject $AppRoleIDsList -DifferenceObject $SPPermsList -IncludeEqual -ErrorAction SilentlyContinue

        # Determine if the service principal is missing any permissions
        $SPMissingPerms = $Diff | Where-Object {$_.SideIndicator -eq "<="}
        $SPMissingPerms = $SPMissingPerms | Select-Object InputObject -Unique

        if ($null -ne $FilteredAppRoleIDs -and $null -ne $SPMissingPerms) {
            ForEach ($SPMissingPerm in $SPMissingPerms) {
                # Find the matching object in $FilteredAppRoleIDs (not $AppRoleIDs)
                $matchingAppRole = $FilteredAppRoleIDs | Where-Object { $_.AppRoleID -eq $SPMissingPerm.InputObject } | Select-Object -Unique

                if ($matchingAppRole) {
                    $SPMissingPerm | Add-Member -MemberType NoteProperty -Name resourceAPIAppId -Value $matchingAppRole.resourceAPIAppId -Force
                    $SPMissingPerm | Add-Member -MemberType NoteProperty -Name leastPermissions -Value $matchingAppRole.APIName -Force
                }
            }
        }

        $missingPermsCount = $SPMissingPerms.leastPermissions.Count
        if($missingPermsCount -eq 0){
            Write-Output "Service Principal permissions comparison completed, no API permissions missing."
        }else{
            Write-Output "Service Principal permissions comparison completed, $missingPermsCount API permissions missing."
        }

        # Determine if the service principal has any extra permissions
        # ONLY flag as extra if they're NOT needed by ANY of the specified products
        $SPExtraPerms = $Diff | Where-Object {$_.SideIndicator -eq "=>"}

        # Collect all unique resource IDs - handle both property name cases
        $uniqueResourceIds = @{}
        foreach ($ExtraPerm in $SPExtraPerms) {
            $matchingPerm = $SPPerms | Where-Object {
                $appRoleId = if ($_.appRoleId) { $_.appRoleId } else { $_.AppRoleId }
                $appRoleId -eq $($ExtraPerm).InputObject
            }
            $resourceId = if ($matchingPerm.resourceId) { $matchingPerm.resourceId } else { $matchingPerm.ResourceID }
            if ($resourceId -and -not $uniqueResourceIds.ContainsKey($resourceId)) {
                $uniqueResourceIds[$resourceId] = $true
            }
        }

        # Fetch all service principals in one call
        if ($uniqueResourceIds.Keys.Count -gt 0) {
            $filterConditions = ($uniqueResourceIds.Keys | ForEach-Object { "id eq '$_'" }) -join " or "
            $servicePrincipalsResponse = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipal `
                                        -M365Environment $M365Environment `
                                        -queryParams @{ '$filter' = $filterConditions }).Value

            $spLookup = @{}
            foreach ($sp in $servicePrincipalsResponse) {
                $spLookup[$sp.Id] = $sp
            }
        }

        # Process extra permissions - only include if NOT needed by specified products
        foreach ($ExtraPerm in $SPExtraPerms) {
            $matchingPerm = $SPPerms | Where-Object {
                $appRoleId = if ($_.appRoleId) { $_.appRoleId } else { $_.AppRoleId }
                $appRoleId -eq $($ExtraPerm).InputObject
            }
            $ExtraSPPermsResourceID = if ($matchingPerm.resourceId) { $matchingPerm.resourceId } else { $matchingPerm.ResourceID }
            $graphServicePrincipal = $spLookup[$ExtraSPPermsResourceID]

            if ($graphServicePrincipal) {
                $APIPermission = $graphServicePrincipal.AppRoles | Where-Object { $_.Id -eq $ExtraPerm.InputObject }

                if ($APIPermission) {
                    $APIPermissionName = $APIPermission.Value

                    # Check if this "extra" permission is actually needed by one of the specified products
                    $neededByRequestedProduct = $false
                    if ($ProductNames -and $ProductNames.Count -gt 0) {
                        $permissionInAllProducts = $AppRoleIDs | Where-Object { $_.APIName -eq $APIPermissionName }
                        foreach ($permDef in $permissionInAllProducts) {
                            foreach ($product in $ProductNames) {
                                if ($permDef.Product -contains $product) {
                                    $neededByRequestedProduct = $true
                                    break
                                }
                            }
                            if ($neededByRequestedProduct) { break }
                        }
                    }

                    # Only add to ExtraPerms if NOT needed by any requested product
                    if (-not $neededByRequestedProduct) {
                        $ExtraPerms += $APIPermissionName
                    }
                }
            }
        }
    }

    # Before returning the results, restructure the object
    $formattedMissingPerms = @()
    foreach ($perm in $SPMissingPerms) {
        $matchingAppRole = $FilteredAppRoleIDs | Where-Object { $_.AppRoleID -eq $perm.InputObject }

        $formattedMissingPerms += [PSCustomObject]@{
            ResourceAPI = $perm.resourceAPIAppId
            Permission  = $perm.leastPermissions
            AppRoleID   = $perm.InputObject
            Product     = $matchingAppRole.Product
        }
    }

    $formattedExtraPerms = @()
    foreach ($perm in $ExtraPerms) {
        if ($perm) {
            $formattedExtraPerms += $perm
        }
    }

    $PermissionsObject = [PSCustomObject]@{
        MissingPermissions    = $formattedMissingPerms
        ExtraPermissions      = $formattedExtraPerms
        HasMissingPermissions = ($formattedMissingPerms.Count -gt 0)
        HasExtraPermissions   = ($formattedExtraPerms.Count -gt 0)
    }

    return $PermissionsObject
}

function Set-ScubaGearRole {
    [CmdletBinding(SupportsShouldProcess = $true)]
    <#
    .SYNOPSIS
        Assigns a service principal to the roles specified by the ScubaGearSPRole parameter.

    .DESCRIPTION
        This function will assign a service principal to the roles specified by the ScubaGearSPRole parameter.

    .PARAMETER ServicePrincipalID
        Used to define the AppID of the service principal that will be added to the roles specified by the ScubaGearSPRole parameter.

    .PARAMETER roleDefinitionID
        The role definition ID that is required for the ScubaGear application. Current roles are defined in the ScubaGearPermissions.json file.

    .PARAMETER M365Environment
        Used to define the environment that the application will be created in. The options are commercial, gcc, gcchigh, dod

    .EXAMPLE
        Set-ScubaGearRole -ServicePrincipalID "AppID" -roleDefinitionID "RoleDefinitionID" -M365Environment commercial

        This example will assign the service principal to the roles specified by the roleDefinitionID parameter.

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServicePrincipalId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$roleDefinitionID,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment,

        [Parameter(Mandatory = $false)]
        [switch]$SkipConnect
    )

    $M365Environment = $M365Environment.ToLower()

    # Connect to Microsoft Graph
    if (-not $SkipConnect) {
        try {
            $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("RoleManagement.ReadWrite.Directory")
            Write-Verbose "Successfully connected to Microsoft Graph"
        } catch {
            Write-Warning "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        }
    }

    try {
        # Use PIM role assignment to ensure proper start date and compliance with ScubaGear requirements
        # This creates an active assignment with a defined start date instead of a permanent assignment with no start date
        $startDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

        $body = @{
            action = "adminAssign"
            justification = "ScubaGear service principal role assignment"
            roleDefinitionId = $roleDefinitionId
            directoryScopeId = "/"
            principalId = $ServicePrincipalId
            scheduleInfo = @{
                startDateTime = $startDateTime
                expiration = @{
                    type = "noExpiration"
                }
            }
        }

        $target = "Service Principal [$ServicePrincipalId] to Role [$roleDefinitionId] in $M365Environment"

        if ($PSCmdlet.ShouldProcess($target, "Assign service principal to role")) {
            # Use PIM role assignment request to create an active assignment with proper start date
            $Null = Invoke-GraphDirectly -Commandlet New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -M365Environment $M365Environment -Body $body

            # Get the role definition name
            $RoleName = (Invoke-GraphDirectly -Commandlet Get-MgRoleManagementDirectoryRoleDefinition -M365Environment $M365Environment -id $roleDefinitionID).value.DisplayName
            Write-Output "Assigned service principal to role: $RoleName (Active assignment with start date)"
        }
    } catch {
        Write-Warning "Failed to assign service principal to role $roleDefinitionID : $($_.Exception.Message)"
    }
}

function Get-ScubaGearAppRoleID {
    <#
    .SYNOPSIS
        Retrieves the AppRole IDs for the permissions specified in the ScubaGearSPPermissions parameter.

    .DESCRIPTION
        This function will retrieve the AppRole IDs for the permissions specified in the ScubaGearSPPermissions parameter.

    .PARAMETER ScubaGearSPPermissions
        The permissions that are required for the ScubaGear application. Current permissions are defined in the ScubaGearPermissions.json file.

    .PARAMETER M365Environment
        Used to define the environment that the application will be created in. The options are commercial, gcc, gcchigh, dod

    .PARAMETER SkipConnect
        Used to skip the connection to Microsoft Graph.

    .EXAMPLE
        Get-ScubaGearAppRoleID -ScubaGearSPPermissions $ScubaGearSPPermissions -M365Environment commercial
        This example will retrieve the AppRole IDs for the permissions specified in the ScubaGearSPPermissions parameter.

    .EXAMPLE
        Get-ScubaGearAppRoleID -ScubaGearSPPermissions $ScubaGearSPPermissions -M365Environment commercial -SkipConnect
        This example will retrieve the AppRole IDs for the permissions specified in the ScubaGearSPPermissions parameter and skip the connection to Microsoft Graph.

    .OUTPUTS
        PSCustomObject[] - Array of permission objects, each containing:
        - resourceAPIAppId: The resource API application ID (e.g., Microsoft Graph API ID)
        - APIName: The permission name (e.g., 'Directory.Read.All')
        - AppRoleID: The unique GUID for the app role
        - Product: The ScubaGear product that requires this permission (e.g., 'aad', 'exo')

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later

    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object]$ScubaGearSPPermissions,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment,

        [Parameter(Mandatory = $false)]
        [switch]$SkipConnect
    )

    $M365Environment = $M365Environment.ToLower()

    # Only connect if not skipping connection
    if (-not $SkipConnect) {
        try {
            $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("RoleManagement.Read.Directory")
            Write-Verbose "Connected to Microsoft Graph in Get-ScubaGearAppRoleID"
        } catch {
            Write-Warning "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        }
    } else {
        Write-Verbose "Skipping Microsoft Graph connection in Get-ScubaGearAppRoleID"
    }

    $AppRoleIDs = @()

    # Group permissions by resourceAPIAppId to minimize API calls
    $groupedPermissions = $ScubaGearSPPermissions | Group-Object -Property resourceAPIAppId

    foreach ($group in $groupedPermissions) {
        $resourceAPIAppId = $group.Name

        try {
            # Fetch the service principal for this resource API
            Write-Verbose "Fetching service principal for $resourceAPIAppId"
            $ProductResource = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipal -M365Environment $M365Environment -queryParams @{
                '$filter' = "appId eq '$resourceAPIAppId'"
            }).Value

            if (-not $ProductResource) {
                Write-Warning "Service principal not found for resource API ID: $resourceAPIAppId"
                continue
            }

            # Get all permissions for this resource at once
            foreach ($permission in $group.Group) {
                $APIPermissionNames = $permission.leastPermissions
                $ProductName = $permission.scubaGearProduct  # CAPTURE THIS

                foreach ($ID in $APIPermissionNames) {
                    $AppRoleID = ($ProductResource.AppRoles | Where-Object { $_.Value -eq "$ID" }).id

                    if ($AppRoleID) {
                        # Create a new object for each permission
                        $AppRoleObject = [PSCustomObject]@{
                            resourceAPIAppId = $resourceAPIAppId
                            APIName          = $ID
                            AppRoleID        = $AppRoleID
                            Product          = $ProductName  # ADD THIS
                        }

                        # Add the object to the array
                        $AppRoleIDs += $AppRoleObject
                    } else {
                        Write-Warning "AppRole ID not found for permission: $ID in resource $resourceAPIAppId"
                    }
                }
            }
        } catch {
            Write-Warning "Failed to process permissions for resource API ID $resourceAPIAppId : $($_.Exception.Message)"
        }
    }

    return $AppRoleIDs
}

function Set-AppRegistrationPermission {
    <#
    .SYNOPSIS
        Updates the app registration with the required permissions.

    .DESCRIPTION
        This function will update the app registration with the required permissions. It will also create app role assignments for the service principal.

    .PARAMETER AppID
        Used to define the AppID of the service principal that will be updated with the required permissions.

    .PARAMETER ScubaGearSPPermissions
        The permissions that are required for the ScubaGear application. Current permissions are defined in the ScubaGearPermissions.json file.

    .PARAMETER M365Environment
        Used to define the environment that the application will be created in. The options are commercial, gcc, gcchigh, dod

    .EXAMPLE
        Set-AppRegistrationPermission -AppID "AppID" -ScubaGearSPPermissions $ScubaGearSPPermissions -M365Environment commercial

        This example will update the app registration with the required permissions.

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
    #>
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if ([guid]::TryParse($_, [ref][guid]::Empty)) {
                return $true
            }
            throw "AppID must be a valid GUID format: $($_)"
        })]
        [string]$AppID,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [array]$ScubaGearSPPermissions,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment,

        [Parameter(Mandatory = $false)]
        [switch]$SkipConnect
    )

    $M365Environment = $M365Environment.ToLower()

    # Connect to Microsoft Graph
    if (-not $SkipConnect) {
        try {
            $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All")
            Write-Verbose "Successfully connected to Microsoft Graph"
        }
        catch {
            Write-Warning "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        }
    } else {
        Write-Verbose "Skipping Microsoft Graph connection in Set-AppRegistrationPermission"
    }

    try {
        # Get the app registration
        $appResponse = (Invoke-GraphDirectly -Commandlet Get-MgBetaApplication -M365Environment $M365Environment -queryParams @{
            '$filter' = "appId eq '$AppID'"
        }).Value

        if ($appResponse) {
            # Build the requiredResourceAccess array
            $requiredResourceAccess = @()
            $resourceAppIds = @{}  # Track resources we've already processed

            # Process each API permission set (grouped by resource API)
            foreach ($permission in $ScubaGearSPPermissions) {
                $resourceAppId = $permission.resourceAPIAppId

                # Skip if we've already processed this resource API to avoid duplicates
                if ($resourceAppIds.ContainsKey($resourceAppId)) {
                    Write-Verbose "Resource API $resourceAppId already processed, combining permissions"
                    continue
                }

                # Mark this resource as processed
                $resourceAppIds[$resourceAppId] = $true

                # Get the service principal for this resource API
                $resourceSP = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipal -M365Environment $M365Environment -queryParams @{
                    '$filter' = "appId eq '$resourceAppId'"
                }).Value

                if (!$resourceSP) {
                    Write-Warning "Resource service principal for $resourceAppId not found. Skipping."
                    continue
                }

                # Get all permissions for this resource API across all entries in ScubaGearSPPermissions
                $allPermissionsForResource = $ScubaGearSPPermissions |
                                           Where-Object { $_.resourceAPIAppId -eq $resourceAppId } |
                                           ForEach-Object { $_.leastPermissions } |
                                           Sort-Object -Unique

                $resourceAccessEntries = @()

                # Process each permission for this resource API
                foreach ($permName in $allPermissionsForResource) {
                    # Find the corresponding app role in the resource service principal
                    $appRole = $resourceSP.AppRoles | Where-Object { $_.Value -eq $permName }

                    if ($appRole) {
                        # Add this permission to the resource access entries
                        $resourceAccessEntries += @{
                            id = $appRole.id
                            type = "Role"  # This is for application permissions
                        }
                        Write-Verbose "Added permission $permName for $($resourceSP.DisplayName)"
                    }
                    else {
                        Write-Warning "Permission $permName not found in $($resourceSP.DisplayName)"
                    }
                }

                # Add this resource API and its permissions to the required resource access array
                if ($resourceAccessEntries.Count -gt 0) {
                    $requiredResourceAccess += @{
                        resourceAppId = $resourceAppId
                        resourceAccess = $resourceAccessEntries
                    }
                }
            }

            # Make sure we have at least one item in requiredResourceAccess
            if ($requiredResourceAccess.Count -gt 0) {
                # Update the app registration with the new requiredResourceAccess
                $Body = @{
                    requiredResourceAccess = $requiredResourceAccess
                }

                # Invoke-GraphDirectly will use PATCH method and update the app registration with the new permissions
                Invoke-GraphDirectly -Commandlet Update-MgApplication -Body $Body -M365Environment $M365Environment -id $($appResponse.id)

                Write-Output "Updated app registration with required permissions configuration"

                # Get the service principal for the app registration
                $servicePrincipal = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipal -M365Environment $M365Environment -queryParams @{
                    '$filter' = "appId eq '$AppID'"
                }).Value

                # For each resource in requiredResourceAccess, create app role assignments
                foreach ($resource in $requiredResourceAccess) {
                    # Get the resource service principal
                    $resourceSP = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipal -M365Environment $M365Environment -queryParams @{
                        '$filter' = "appId eq '$($resource.resourceAppId)'"
                    }).Value

                    if (!$resourceSP) {
                        Write-Warning "Resource service principal for $($resource.resourceAppId) not found. Skipping consent."
                        continue
                    }

                    # For each permission, create an app role assignment
                    foreach ($permission in $resource.resourceAccess) {
                        if ($permission.type -eq "Role") {  # Application permissions only
                            $body = @{
                                principalId = $servicePrincipal.id
                                resourceId = $resourceSP.id
                                appRoleId = $permission.id
                            }

                            # Create the app role assignment
                            try {
                                Invoke-GraphDirectly -Commandlet New-MgServicePrincipalAppRoleAssignedTo -Body $body -M365Environment $M365Environment -id $($servicePrincipal.id)

                                $permName = ($resourceSP.AppRoles | Where-Object { $_.id -eq $permission.id }).Value
                                Write-Output "Granted admin consent for: $permName"
                            }
                            catch {
                                if ($_.Exception.Message -match "Permission entry already exists") {
                                    Write-Verbose "Permission already granted"
                                }
                                else {
                                    Write-Warning "Failed to grant permission: $_"
                                }
                            }
                        }
                    }
                }
                Write-Output "Completed granting admin consent for all permissions"
            }
            else {
                Write-Warning "No valid permissions found to configure. Please check your ScubaGearSPPermissions input."
            }
        }
        else {
            Write-Warning "App registration with AppID '$AppID' not found"
        }
    }
    catch {
        Write-Warning "Failed to update app registration permissions: $_"
        throw
    }
}

function Get-ScubaGearAppPermission {
    <#
    .SYNOPSIS
        Retrieves current permissions for a service principal and compares them to the ScubaGear permissions.

    .DESCRIPTION
        This function will retrieve the current permissions for a service principal and compare them to the ScubaGear permissions based on the specified ProductNames. Uses Graph API batching for optimal performance.

    .PARAMETER AppID
        Used to define the AppID of the service principal that will be checked for permissions. This is the Application (client) ID of the app registration.

    .PARAMETER M365Environment
        Used to define the environment that the application will be created in. The options are commercial, gcc, gcchigh, dod

    .PARAMETER ProductNames
        This allows you to define which products that the Service Principal will be assessing and only compare against those needed permissions.
        Valid options are: 'aad', 'exo', 'sharepoint', 'teams', 'powerPlatform', 'defender', '*' (which includes all products)

    .EXAMPLE
        Get-ScubaGearAppPermission -AppID "AppID" -M365Environment commercial -ProductNames 'aad'

    .EXAMPLE
        Get-ScubaGearAppPermission -AppID "AppID" -M365Environment gcchigh -ProductNames 'aad', 'exo'

    .EXAMPLE
        Get-ScubaGearAppPermission -AppID "AppID" -M365Environment dod -ProductNames '*'

    .OUTPUTS
        PSCustomObject with PSTypeName 'SCuBA.Permissions' containing:
        - AppID: The application ID
        - M365Environment: The environment
        - ProductNames: Products being assessed
        - MissingPermissions: Array of missing permissions
        - ExtraPermissions: Array of extra permissions
        - MissingRoles: Array of missing directory roles
        - DelegatedPermissions: Array of delegated permissions (if any)
        - PowerPlatformRegistered: Power Platform registration status
        - Status: Overall status message
        - FixPermissionIssues: Command to fix issues (if any exist)

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if ([guid]::TryParse($_, [ref][guid]::Empty)) {
                return $true
            }
            throw "AppID must be a valid GUID format: $($_)"
        })]
        [string]$AppID,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment,

        [Parameter(Mandatory = $true)]
        [ValidateSet("aad", "exo", "sharepoint", "teams", "powerPlatform", "defender", '*', IgnoreCase = $True)]
        [string[]]$ProductNames
    )

    $M365Environment = $M365Environment.ToLower()

    try {
        # Connect to Microsoft Graph
        $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("Application.Read.All", "RoleManagement.Read.Directory")
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
        return
    }

    if($ProductNames -contains '*'){
        # If wildcard is specified, include all products
        $ProductNames = @('aad', 'exo', 'sharepoint', 'teams', 'powerPlatform', 'defender')
    }

    # Check Power Platform registration - always check to report current status
    $PowerPlatformCheck = Test-PowerPlatformAppRegistration -AppID $AppID

    # Get permissions and roles (these are local operations)
    $ScubaGearSPPermissions = Get-ServicePrincipalPermissions -Environment $M365Environment
    $ScubaGearSPRole = Get-ScubaGearPermissions -OutAs role -Product $ProductNames

    # STEP 1: Get the service principal (needed to get its ID)
    $SP = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipal -M365Environment $M365Environment -queryParams @{
        '$filter' = "appId eq '$AppID'"
    }).Value

    if (-not $SP) {
        Write-Error "Service principal with AppID '$AppID' not found"
        return
    }

    # STEP 2: Get the application registration
    $appReg = (Invoke-GraphDirectly -Commandlet Get-MgBetaApplication -M365Environment $M365Environment -queryParams @{
        '$filter' = "appId eq '$AppID'"
    }).Value

    if (-not $appReg) {
        Write-Error "Application registration not found for AppID '$AppID'"
        return
    }

    # STEP 3: Get app role assignments
    $SPPermsApplication = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipalAppRoleAssignment -M365Environment $M365Environment -id $SP.Id).Value

    # STEP 4: Get OAuth2 permission grants
    $SPPermsDelegatedConsented = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipalOauth2PermissionGrant -M365Environment $M365Environment -id $SP.Id).Value

    # STEP 3: Collect unique resource IDs - OPTIMIZATION: Use hashtable for O(1) lookups
    Write-Verbose "Collecting unique resource IDs from app role assignments"
    $uniqueResourceIdsHash = @{}
    $uniqueAppIdsHash = @{}

    # Collect resource IDs from app role assignments
    foreach ($assignment in $SPPermsApplication) {
        # Batch API returns lowercase property names
        $resId = $assignment.ResourceId  # if ($assignment.resourceId) { $assignment.resourceId } else { $assignment.ResourceId }
        if ($resId -and -not $uniqueResourceIdsHash.ContainsKey($resId)) {
            $uniqueResourceIdsHash[$resId] = $true
        }
    }
    Write-Verbose "Found $($uniqueResourceIdsHash.Count) unique resource IDs"

    # Collect resource App IDs from app registration (for delegated permissions)
    $requiredAccess = if ($appReg.requiredResourceAccess) { $appReg.requiredResourceAccess } else { $appReg.RequiredResourceAccess }
    if ($requiredAccess) {
        Write-Verbose "Collecting unique App IDs from required resource access"
        foreach ($resource in $requiredAccess) {
            $resAppId = if ($resource.resourceAppId) { $resource.resourceAppId } else { $resource.ResourceAppId }
            if ($resAppId -and -not $uniqueAppIdsHash.ContainsKey($resAppId)) {
                $uniqueAppIdsHash[$resAppId] = $true
            }
        }
        Write-Verbose "Found $($uniqueAppIdsHash.Count) unique App IDs"
    }

    # Build batch request - OPTIMIZATION: Use ArrayList for better performance
    $resourceBatchRequests = [System.Collections.ArrayList]::new()

    # Add requests for service principals by ID - OPTIMIZATION: Use $select to reduce data transfer
    foreach ($resourceId in $uniqueResourceIdsHash.Keys) {
        [void]$resourceBatchRequests.Add(@{
            id = "spById_$resourceId"
            method = "GET"
            url = "/servicePrincipals/$resourceId`?`$select=id,appId,appRoles,oauth2PermissionScopes"
        })
    }

    # Add requests for service principals by AppId
    foreach ($Id in $uniqueAppIdsHash.Keys) {
        [void]$resourceBatchRequests.Add(@{
            id = "spByAppId_$Id"
            method = "GET"
            url = "/servicePrincipals?`$filter=appId eq '$Id'&`$select=id,appId,appRoles,oauth2PermissionScopes"
        })
    }

    # Execute batch request for resource service principals (if any)
    $resourceSPCache = @{}
    $resourceSPByAppIdCache = @{}

    if ($resourceBatchRequests.Count -gt 0) {
        Write-Verbose "Executing batch request for $($resourceBatchRequests.Count) resource service principals"
        $resourceResults = Invoke-GraphBatchRequest -Requests $resourceBatchRequests -M365Environment $M365Environment

        # Parse resource results and build caches - OPTIMIZATION: Keep as hashtables, no PSCustomObject conversion
        Write-Verbose "Parsing resource service principal results"
        foreach ($key in $resourceResults.Keys) {
            $result = $resourceResults[$key]

            if ($result.status -eq 200) {
                if ($key -like "spById_*") {
                    # Direct SP lookup by ID - keep as hashtable
                    $spId = $key -replace '^spById_', ''
                    $resourceSPCache[$spId] = $result.body
                }
                elseif ($key -like "spByAppId_*") {
                    # SP lookup by AppId (returns array) - keep as hashtable
                    $Id = $key -replace '^spByAppId_', ''
                    if ($result.body.value -and $result.body.value.Count -gt 0) {
                        $resourceSP = $result.body.value[0]
                        $resourceSPByAppIdCache[$Id] = $resourceSP
                        # Also add to ID cache
                        $spIdValue = if ($resourceSP.id) { $resourceSP.id } else { $resourceSP.Id }
                        if ($spIdValue) {
                            $resourceSPCache[$spIdValue] = $resourceSP
                        }
                    }
                }
            }
            else {
                Write-Warning "Failed to retrieve resource SP for request '$key': Status $($result.status)"
            }
        }
    }

    # Process delegated permissions - handle both property name cases
    $requiredResourceAccess = if ($appReg.requiredResourceAccess) { $appReg.requiredResourceAccess } else { $appReg.RequiredResourceAccess }

    $SPPermsDelegatedNotConsented = if ($requiredResourceAccess) {
        $requiredResourceAccess | ForEach-Object {
            $resourceAccess = if ($_.resourceAccess) { $_.resourceAccess } else { $_.ResourceAccess }
            $resourceAccess | Where-Object {
                $type = if ($_.type) { $_.type } else { $_.Type }
                $type -eq 'Scope'
            }
        }
    } else {
        @()
    }

    $SPPermsDelegated = @{
        Consented    = $SPPermsDelegatedConsented
        NotConsented = $SPPermsDelegatedNotConsented
    }

    # Create permissions object with SkipConnect to avoid redundant connections
    Write-Verbose "Getting ScubaGear app role IDs"
    $AppRoleIDs = Get-ScubaGearAppRoleID -ScubaGearSPPermissions $ScubaGearSPPermissions -M365Environment $M365Environment -SkipConnect

    # Compare permissions with SkipConnect and cached data
    Write-Verbose "Comparing service principal permissions"
    $SPComparePerms = Compare-ScubaGearPermission -AppRoleIDs $AppRoleIDs -M365Environment $M365Environment -SPPerms $SPPermsApplication -ProductNames $ProductNames -SkipConnect

    $SPMissingPerms = if ($SPComparePerms.HasMissingPermissions) { $SPComparePerms.MissingPermissions } else { $false }
    $SPExtraPerms   = if ($SPComparePerms.HasExtraPermissions)   { $SPComparePerms.ExtraPermissions   } else { $false }

    # Process delegated permissions using cached data
    $DelegatedPerms = $false
    if (($SPPermsDelegated.Consented.Id.Count -gt 0) -or ($SPPermsDelegated.NotConsented.Id.Count -gt 0)) {
    #if ($SPPermsDelegated.Consented.Id.Count -gt 0) {

        $scopeList = @()

        # Add scopes from consented grants - handle both property cases
        if ($SPPermsDelegated.Consented) {
            foreach ($grant in $SPPermsDelegated.Consented) {
                $scope = if ($grant.scope) { $grant.scope } else { $grant.Scope }
                if ($scope) {
                    $scopeList += $scope -split ' '
                }
            }
        }

        # Use cached resource SPs for delegated permissions
        if ($SPPermsDelegated.NotConsented.Id.Count -gt 0) {
            $requiredResourceAccess = if ($appReg.requiredResourceAccess) { $appReg.requiredResourceAccess } else { $appReg.RequiredResourceAccess }
            foreach ($resource in $requiredResourceAccess) {
                $resourceAccess = if ($resource.resourceAccess) { $resource.resourceAccess } else { $resource.ResourceAccess }
                $scopePermissions = $resourceAccess | Where-Object {
                    $type = if ($_.type) { $_.type } else { $_.Type }
                    $type -eq 'Scope'
                }

                if ($scopePermissions) {
                    # Use cached resource SP
                    $resAppId = if ($resource.resourceAppId) { $resource.resourceAppId } else { $resource.ResourceAppId }
                    $resourceSP = $resourceSPByAppIdCache[$resAppId]

                    if ($resourceSP) {
                        foreach ($scopePerm in $scopePermissions) {
                            $scopePermId = if ($scopePerm.id) { $scopePerm.id } else { $scopePerm.Id }
                            $oauth2Scopes = if ($resourceSP.oauth2PermissionScopes) { $resourceSP.oauth2PermissionScopes } else { $resourceSP.Oauth2PermissionScopes }
                            $permissionDetail = $oauth2Scopes | Where-Object {
                                $permId = if ($_.id) { $_.id } else { $_.Id }
                                $permId -eq $scopePermId
                            }
                            if ($permissionDetail) {
                                $value = if ($permissionDetail.value) { $permissionDetail.value } else { $permissionDetail.Value }
                                $scopeList += $value
                            }
                        }
                    }
                }
            }
        }

        $DelegatedPerms = ($scopeList | Select-Object -Unique)
    }

    # Process Service Principal for extra permissions
    $ExtraPermsWithDetails = @()
    if ($SPExtraPerms -ne $false -and @($SPExtraPerms).Count -gt 0) {
        foreach ($extraPermName in $SPExtraPerms) {
            foreach ($assignment in $SPPermsApplication) {
                # Use cached resource SP
                $resId = if ($assignment.resourceId) { $assignment.resourceId } else { $assignment.ResourceId }
                $resourceSP = $resourceSPCache[$resId]
                if ($resourceSP) {
                    $appRoles = if ($resourceSP.appRoles) { $resourceSP.appRoles } else { $resourceSP.AppRoles }
                    $assignmentAppRoleId = if ($assignment.appRoleId) { $assignment.appRoleId } else { $assignment.AppRoleId }

                    $appRole = $appRoles | Where-Object {
                        $roleId = if ($_.id) { $_.id } else { $_.Id }
                        $roleId -eq $assignmentAppRoleId
                    }

                    if ($appRole) {
                        $roleValue = if ($appRole.value) { $appRole.value } else { $appRole.Value }
                        if ($roleValue -eq $extraPermName) {
                            $assignmentId = if ($assignment.id) { $assignment.id } else { $assignment.Id }
                            $ExtraPermsWithDetails += [PSCustomObject]@{
                                PermissionName = $extraPermName
                                AssignmentId = $assignmentId
                                ResourceId = $resId
                                AppRoleId = $assignmentAppRoleId
                            }
                            break
                        }
                    }
                }
            }
        }
    }

    # Compare the service principal to the directory roles
    if($Null -ne $ScubaGearSPRole) {
        Write-Verbose "Comparing service principal roles"
        $SPRoleAssignment = Compare-ScubaGearRole -ServicePrincipalID $SP.Id -Roles $ScubaGearSPRole -M365Environment $M365Environment -SkipConnect
    }

    # Check if Power Platform is registered (only if it's in the product list)
    $powerPlatformOK = $true
    if ($ProductNames -contains 'powerPlatform' -and $PowerPlatformCheck -eq $false) {
        $powerPlatformOK = $false
    }
    # Also check if Power Platform is registered but not needed
    if ($PowerPlatformCheck -eq $true -and $ProductNames -notcontains 'powerPlatform') {
        $powerPlatformOK = $false
    }

    # Create Status based on all conditions with detailed information
    if (($SPMissingPerms -eq $false) -and ($SPExtraPerms -eq $false) -and ($DelegatedPerms -eq $false) -and (-not $SPRoleAssignment.Missing) -and ($powerPlatformOK -eq $true)) {
        $Status = "No action needed, service principal is setup correctly."
    } else {
        $statusParts = @()

        # Add missing permissions details
        if ($SPMissingPerms -ne $false -and @($SPMissingPerms).Count -gt 0) {
            $missingPermsList = ($SPMissingPerms | ForEach-Object { $_.Permission }) -join ', '
            $statusParts += "missing permissions [$missingPermsList]"
        }

        # Add extra permissions details
        if ($SPExtraPerms -ne $false -and @($SPExtraPerms).Count -gt 0) {
            $extraPermsList = $SPExtraPerms -join ', '
            $statusParts += "extra permissions [$extraPermsList]"
        }

        # Add delegated permissions warning - use friendly names for display
        if ($DelegatedPerms -ne $false -and @($DelegatedPerms).Count -gt 0) {
            $statusParts += "delegated permissions [$($DelegatedPerms -join ', ')]"
        }

        # Add missing roles details
        if ($SPRoleAssignment.Missing -eq $true -and $SPRoleAssignment.RoleName) {
            $statusParts += "missing role [$($SPRoleAssignment.RoleName)]"
        }

        # Add Power Platform registration status if it's registered but not in the product list
        if ($PowerPlatformCheck -eq $true -and $ProductNames -notcontains 'powerPlatform') {
            $statusParts += "Power Platform registered but not required for selected products"
        }
        elseif ($PowerPlatformCheck -eq $false -and $ProductNames -contains 'powerPlatform') {
            $statusParts += "Power Platform not registered"
        }

        # Combine all parts
        if ($statusParts.Count -gt 0) {
            $Status = "Action needed: you have " + ($statusParts -join ' and ') + ". See FixPermissionIssues for resolution."
        } else {
            $Status = "Action needed, see FixPermissionIssues"
        }
    }

    # Build output object for pipeline
    $InputObject = [PSCustomObject]@{
        PSTypeName               = 'SCuBA.Permissions'
        AppID                    = $AppID
        M365Environment          = $M365Environment
        ProductNames             = $ProductNames
        ServicePrincipalID       = $SP.Id
        MissingPermissions       = $SPMissingPerms
        ExtraPermissions         = $SPExtraPerms
        ExtraPermissionsDetails  = if ($ExtraPermsWithDetails.Count -gt 0) { $ExtraPermsWithDetails } else { $false }
        DelegatedPermissions     = $DelegatedPerms
        MissingRoles             = if ($SPRoleAssignment.Missing -eq $true) { @($SPRoleAssignment.RoleName) } else { $False }
        PowerPlatformRegistered  = $PowerPlatformCheck
        ScubaGearSPPermissions   = $ScubaGearSPPermissions
        CurrentPermissions       = $SPPermsApplication
        CurrentDelegatedPerms    = $SPPermsDelegated
        AppRoleIDs               = $AppRoleIDs
        Status                   = $Status
    }

    # Output the object for pipeline use
    if($InputObject.MissingPermissions -or $InputObject.ExtraPermissions -or $InputObject.MissingRoles -or $InputObject.DelegatedPermissions -or ($InputObject.PowerPlatformRegistered -eq $false -and $InputObject.ProductNames -contains 'powerPlatform') -or ($InputObject.PowerPlatformRegistered -eq $true -and $InputObject.ProductNames -notcontains 'powerPlatform')) {
        # Add new property to $InputObject for FixPermissionIssues
        $ProductNamesString = ($ProductNames | ForEach-Object { "'$_'" }) -join ', '
        $InputObject | Add-Member -MemberType NoteProperty -Name FixPermissionIssues -Value "Get-ScubaGearAppPermission -AppID $AppID -M365Environment $M365Environment -ProductNames $ProductNamesString | Set-ScubaGearAppPermission" -Force
        Update-TypeData -TypeName 'SCuBA.Permissions' -DefaultDisplayPropertySet 'AppID', 'M365Environment', 'MissingPermissions', 'ExtraPermissions', 'MissingRoles', 'DelegatedPermissions', 'PowerPlatformRegistered', 'FixPermissionIssues', 'Status' -Force
    } else {
        Update-TypeData -TypeName 'SCuBA.Permissions' -DefaultDisplayPropertySet 'AppID', 'M365Environment', 'MissingPermissions', 'ExtraPermissions', 'MissingRoles', 'DelegatedPermissions', 'PowerPlatformRegistered', 'Status' -Force
    }

    return $InputObject
}

function Set-ScubaGearAppPermission {
    <#
    .SYNOPSIS
        Applies missing permissions and roles to a service principal, based on piped input from Get-ScubaGearAppPermission.

    .DESCRIPTION
        This function takes the output object from Get-ScubaGearAppPermission (via pipeline or parameter) and applies any missing API permissions and directory roles to the specified service principal.

    .PARAMETER InputObject
        The object output from Get-ScubaGearAppPermission, containing AppID, M365Environment, MissingPermissions, and MissingRoles.

    .EXAMPLE
        Get-ScubaGearAppPermission -AppID "AppID" -M365Environment commercial -ProductNames "aad" | Set-ScubaGearAppPermission

    .EXAMPLE
        Get-ScubaGearAppPermission -AppID "AppID" -M365Environment commercial -ProductNames "aad", "exo" | Set-ScubaGearAppPermission

        Fixes missing permissions and roles for AAD and Exchange Online.

    .EXAMPLE
        Get-ScubaGearAppPermission -AppID "AppID" -M365Environment commercial -ProductNames '*' | Set-ScubaGearAppPermission -WhatIf

        Shows what changes would be made without actually applying them.

    .OUTPUTS
        None. Outputs status messages to the console.

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later

    #>
   [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [PSCustomObject]$InputObject
    )

    Begin {
        Write-Verbose "Starting Set-ScubaGearAppPermission process"
        $script:changesMade = $false
        $script:lastAppID = $null
    }

    process {
        # Lets set some variables
        $AppID = $InputObject.AppID
        $M365Environment = $InputObject.M365Environment
        $MissingPermissions = $InputObject.MissingPermissions
        $ExtraPermissions = $InputObject.ExtraPermissions
        $ExtraPermissionsDetails = $InputObject.ExtraPermissionsDetails  # NEW
        $delegatedPermissions = $InputObject.DelegatedPermissions
        $CurrentDelegatedPerms = $InputObject.CurrentDelegatedPerms
        $MissingRoles = $InputObject.MissingRoles
        $ServicePrincipalID = $InputObject.ServicePrincipalID
        $ScubaGearSPPermissions = $InputObject.ScubaGearSPPermissions
        $CurrentPermissions = $InputObject.CurrentPermissions
        $PowerPlatformRegistered = $InputObject.PowerPlatformRegistered

        if (-not $AppID -or -not $M365Environment) {
            Write-Warning "AppID and M365Environment are required."
            return
        }

        # Check if there's anything to fix - use @() to ensure Count works with single items
        $hasDelegatedPerms = ($CurrentDelegatedPerms.Consented.Id.Count -gt 0) -or ($CurrentDelegatedPerms.NotConsented.Id.Count -gt 0)
        $hasExtraPerms = ($ExtraPermissionsDetails -ne $false -and @($ExtraPermissionsDetails).Count -gt 0)
        $hasMissingPerms = ($MissingPermissions -ne $false -and @($MissingPermissions).Count -gt 0)
        $hasMissingRoles = ($MissingRoles -ne $false -and @($MissingRoles).Count -gt 0)
        $needsPowerPlatform = ($PowerPlatformRegistered -eq $false)
        $hasUnwantedPowerPlatform = ($PowerPlatformRegistered -eq $true -and $InputObject.ProductNames -notcontains 'powerPlatform')

        # Check if anything needs to be done
        $needsChanges = $hasDelegatedPerms -or $hasExtraPerms -or $hasMissingPerms -or $hasMissingRoles -or $needsPowerPlatform -or $hasUnwantedPowerPlatform

        if (-not $needsChanges) {
            Write-Output "No changes needed - service principal is already configured correctly."
            return
        }

        # Track that we're making changes
        $script:changesMade = $true
        $script:lastAppID = $AppID

        try {
            $allScopes = @("Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "RoleManagement.ReadWrite.Directory")
            $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes $allScopes
            Write-Verbose "Successfully connected to Microsoft Graph"
        } catch {
            Write-Warning "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
            return
        }

        $target = "Service Principal [$AppID] in $M365Environment"

        # STEP 1: Remove delegated permissions (both consented and not-consented)
        # Check if CurrentDelegatedPerms has either Consented or NotConsented items
        $hasDelegatedPerms = ($CurrentDelegatedPerms.Consented.Id.Count -gt 0) -or ($CurrentDelegatedPerms.NotConsented.Id.Count -gt 0)

        if ($delegatedPermissions -ne $false -and $hasDelegatedPerms) {
            if ($PSCmdlet.ShouldProcess($target, "Remove delegated permissions: $($delegatedPermissions -join ', ')")) {
                try {
                    Write-Verbose "Removing delegated permissions from service principal and app registration"

                    # PART A: Remove OAuth2 permission grants (CONSENTED delegated permissions)
                    if ($CurrentDelegatedPerms.Consented.Id.Count -gt 0) {
                        Write-Verbose "Removing $($CurrentDelegatedPerms.Consented.Id.Count) consented delegated permission grant(s)"

                        foreach ($grant in $CurrentDelegatedPerms.Consented) {
                            try {
                                $deleteUri = (Get-ScubaGearPermissions -CmdletName Remove-MgOauth2PermissionGrant -Environment $M365Environment -outAs api -id $grant.Id)
                                Invoke-MgGraphRequest -Method DELETE -Uri $deleteUri
                                Write-Verbose "Removed OAuth2 grant: $($grant.Id) with scopes: $($grant.Scope)"
                            } catch {
                                Write-Warning "Failed to remove OAuth2 grant $($grant.Id): $($_.Exception.Message)"
                            }
                        }
                        Write-Output "Removed consented delegated permissions"
                    }

                    # PART B: Remove Scope-type permissions from app registration manifest (NOT-CONSENTED)
                    if ($CurrentDelegatedPerms.NotConsented.Id.Count -gt 0) {
                        Write-Verbose "Removing $($CurrentDelegatedPerms.NotConsented.Id.Count) not-consented delegated permission(s) from manifest"

                        $appResponse = (Invoke-GraphDirectly -Commandlet Get-MgBetaApplication -M365Environment $M365Environment -queryParams @{
                            '$filter' = "appId eq '$AppID'"
                        }).Value

                        if ($appResponse -and $appResponse.requiredResourceAccess) {
                            $updatedResourceAccess = @()

                            foreach ($resource in $appResponse.requiredResourceAccess) {
                                # Keep only Role-type permissions, filter out ALL Scope-type
                                $filteredAccess = @($resource.resourceAccess | Where-Object { $_.type -eq 'Role' })

                                # Only include this resource if it still has Role permissions
                                if ($filteredAccess.Count -gt 0) {
                                    # Convert to simple array of hashtables
                                    $resourceAccessArray = @()
                                    foreach ($access in $filteredAccess) {
                                        $resourceAccessArray += @{
                                            id = $access.id
                                            type = $access.type
                                        }
                                    }

                                    $updatedResourceAccess += @{
                                        resourceAppId = $resource.resourceAppId
                                        resourceAccess = $resourceAccessArray
                                    }
                                }
                            }

                            $Body = @{
                                requiredResourceAccess = $updatedResourceAccess
                            }

                            Invoke-GraphDirectly -Commandlet Update-MgApplication -Body $Body -M365Environment $M365Environment -id $appResponse.id
                            Write-Output "Removed not-consented delegated permissions from app registration manifest"
                        }
                    }
                } catch {
                    Write-Warning "Failed to remove delegated permissions: $($_.Exception.Message)"
                }
            } else {
                Write-Output "WhatIf: Would remove delegated permissions: $($delegatedPermissions -join ', ')"
            }
        }

        # STEP 2a: Remove ONLY extra permissions if they exist - using data we already have
        if ($ExtraPermissionsDetails -ne $false -and @($ExtraPermissionsDetails).Count -gt 0) {
            if ($PSCmdlet.ShouldProcess($target, "Remove extra permissions: $($ExtraPermissions -join ', ')")) {
                try {
                    Write-Verbose "Removing only extra permissions from service principal"

                    # Part 1: Remove the app role assignments (admin consent)
                    foreach ($extraPerm in $ExtraPermissionsDetails) {
                        $deleteUri = (Get-ScubaGearPermissions -CmdletName Remove-MgServicePrincipalAppRoleAssignment -Environment $M365Environment -outAs api -id $ServicePrincipalID) + '/' + $extraPerm.AssignmentId
                        Invoke-MgGraphRequest -Method DELETE -Uri $deleteUri
                        Write-Output "Removed extra permission: $($extraPerm.PermissionName)"
                    }

                    # Part 2: Remove extra permissions from app registration manifest
                    Write-Verbose "Removing extra permissions from app registration manifest"
                    $appResponse = (Invoke-GraphDirectly -Commandlet Get-MgBetaApplication -M365Environment $M365Environment -queryParams @{
                        '$filter' = "appId eq '$AppID'"
                    }).Value

                    if ($appResponse -and $appResponse.requiredResourceAccess) {
                        $updatedResourceAccess = @()

                        # Collect the AppRoleIDs of extra permissions to remove
                        $extraAppRoleIds = $ExtraPermissionsDetails | ForEach-Object { $_.AppRoleId }

                        foreach ($resource in $appResponse.requiredResourceAccess) {
                            # Filter out the extra permissions (keep only Role-type that are NOT extra)
                            $filteredAccess = @($resource.resourceAccess | Where-Object {
                                $_.type -eq 'Role' -and $extraAppRoleIds -notcontains $_.id
                            })

                            # Only include this resource if it still has permissions
                            if ($filteredAccess.Count -gt 0) {
                                $resourceAccessArray = @()
                                foreach ($access in $filteredAccess) {
                                    $resourceAccessArray += @{
                                        id = $access.id
                                        type = $access.type
                                    }
                                }

                                $updatedResourceAccess += @{
                                    resourceAppId = $resource.resourceAppId
                                    resourceAccess = $resourceAccessArray
                                }
                            }
                        }

                        $Body = @{
                            requiredResourceAccess = $updatedResourceAccess
                        }

                        Invoke-GraphDirectly -Commandlet Update-MgApplication -Body $Body -M365Environment $M365Environment -id $appResponse.id
                        Write-Output "Removed extra permissions from app registration manifest"
                    }
                } catch {
                    Write-Warning "Failed to remove extra permissions: $($_.Exception.Message)"
                }
            } else {
                Write-Output "WhatIf: Would remove extra permissions: $($ExtraPermissions -join ', ')"
            }
        }

        # STEP 2b: Add ONLY missing permissions
        if ($MissingPermissions -ne $false -and @($MissingPermissions).Count -gt 0) {
            if ($PSCmdlet.ShouldProcess($target, "Add missing permissions: $($MissingPermissions.Permission -join ', ')")) {
                try {
                    Write-Verbose "Adding only missing permissions to service principal"

                    # STEP 1: Update the app registration manifest first
                    $appResponse = (Invoke-GraphDirectly -Commandlet Get-MgBetaApplication -M365Environment $M365Environment -queryParams @{
                        '$filter' = "appId eq '$AppID'"
                    }).Value

                    if ($appResponse) {
                        # Get existing requiredResourceAccess
                        $existingResourceAccess = $appResponse.requiredResourceAccess
                        $resourceAccessMap = @{}

                        # Build a map of existing permissions - using simple arrays
                        foreach ($resource in $existingResourceAccess) {
                            if (-not $resourceAccessMap.ContainsKey($resource.resourceAppId)) {
                                $resourceAccessMap[$resource.resourceAppId] = @{
                                    resourceAppId = $resource.resourceAppId
                                    resourceAccess = @()
                                }
                            }
                            foreach ($access in $resource.resourceAccess) {
                                $resourceAccessMap[$resource.resourceAppId].resourceAccess += @{
                                    id = $access.id
                                    type = $access.type
                                }
                            }
                        }

                        # Add missing permissions to the map
                        foreach ($missingPerm in $MissingPermissions) {
                            $resourceAPIAppId = $missingPerm.ResourceAPI

                            if (-not $resourceAccessMap.ContainsKey($resourceAPIAppId)) {
                                $resourceAccessMap[$resourceAPIAppId] = @{
                                    resourceAppId = $resourceAPIAppId
                                    resourceAccess = @()
                                }
                            }

                            # Check if it doesn't already exist in the manifest
                            $exists = $resourceAccessMap[$resourceAPIAppId].resourceAccess | Where-Object { $_.id -eq $missingPerm.AppRoleID }
                            if (-not $exists) {
                                # Add the missing permission using array addition
                                $resourceAccessMap[$resourceAPIAppId].resourceAccess += @{
                                    id = $missingPerm.AppRoleID
                                    type = "Role"
                                }
                                Write-Verbose "Added $($missingPerm.Permission) to app registration manifest"
                            }
                        }

                        # Convert map back to array
                        $updatedResourceAccess = @()
                        foreach ($key in $resourceAccessMap.Keys) {
                            $updatedResourceAccess += @{
                                resourceAppId = $resourceAccessMap[$key].resourceAppId
                                resourceAccess = $resourceAccessMap[$key].resourceAccess
                            }
                        }

                        # Update the app registration manifest
                        $Body = @{
                            requiredResourceAccess = $updatedResourceAccess
                        }

                        Invoke-GraphDirectly -Commandlet Update-MgApplication -Body $Body -M365Environment $M365Environment -id $appResponse.id
                        Write-Verbose "Updated app registration manifest with missing permissions"
                    }

                    # STEP 2: Now grant admin consent by creating the assignments
                    $groupedByResource = $MissingPermissions | Group-Object -Property ResourceAPI

                    foreach ($resourceGroup in $groupedByResource) {
                        $resourceAPIAppId = $resourceGroup.Name

                        # Get the resource service principal
                        $resourceSP = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipal -M365Environment $M365Environment -queryParams @{
                            '$filter' = "appId eq '$resourceAPIAppId'"
                        }).Value

                        if (!$resourceSP) {
                            Write-Warning "Resource service principal for $resourceAPIAppId not found. Skipping."
                            continue
                        }

                        # Add each missing permission for this resource
                        foreach ($missingPerm in $resourceGroup.Group) {
                            $body = @{
                                principalId = $ServicePrincipalID
                                resourceId = $resourceSP.Id
                                appRoleId = $missingPerm.AppRoleID
                            }

                            try {
                                Invoke-GraphDirectly -Commandlet New-MgServicePrincipalAppRoleAssignedTo -Body $body -M365Environment $M365Environment -id $ServicePrincipalID
                                Write-Output "Added missing permission: $($missingPerm.Permission)"
                            } catch {
                                if ($_.Exception.Message -match "Permission entry already exists") {
                                    Write-Verbose "Permission $($missingPerm.Permission) already exists"
                                } else {
                                    Write-Warning "Failed to add permission $($missingPerm.Permission): $_"
                                }
                            }
                        }
                    }
                } catch {
                    Write-Warning "Failed to add missing permissions: $($_.Exception.Message)"
                }
            } else {
                Write-Output "WhatIf: Would add missing permissions: $($MissingPermissions.Permission -join ', ')"
            }
        }

        # STEP 2c: Handle case where NO permissions exist at all (add all required)
        if ($CurrentPermissions.Count -eq 0 -and $MissingPermissions -eq $false) {
            if ($PSCmdlet.ShouldProcess($target, "Initialize permissions (no current permissions found)")) {
                Set-AppRegistrationPermission -AppID $AppID -ScubaGearSPPermissions $ScubaGearSPPermissions -M365Environment $M365Environment
            } else {
                Write-Output "WhatIf: Would initialize permissions for Application ID: $AppID"
            }
        }

        # STEP 3: Fix directory roles if missing
        if ($MissingRoles -ne $false -and @($MissingRoles).Count -gt 0) {
            foreach ($role in $MissingRoles) {
                $roleDef = (Invoke-GraphDirectly -Commandlet Get-MgRoleManagementDirectoryRoleDefinition -M365Environment $M365Environment -queryParams @{ '$filter' = "displayName eq '$role'" }).Value
                if ($roleDef) {
                    if ($PSCmdlet.ShouldProcess($target, "Assign directory role '$role'")) {
                        Set-ScubaGearRole -ServicePrincipalID $ServicePrincipalID -roleDefinitionID $roleDef.Id -M365Environment $M365Environment
                        Write-Output "Assigned service principal to role: $role"
                    } else {
                        Write-Output "WhatIf: Would assign directory role '$role' to $AppID"
                    }
                } else {
                    Write-Warning "Role definition not found for: $role"
                }
            }
        }

        # STEP 4a: Remove Power Platform registration if it's registered but not in ProductNames
        if ($PowerPlatformRegistered -eq $true -and $InputObject.ProductNames -notcontains 'powerPlatform') {
            if ($PSCmdlet.ShouldProcess($target, "Remove Power Platform registration (not required for selected products)")) {
                try {
                    Write-Verbose "Attempting to remove Power Platform registration"

                    # Get the management app
                    $managementApp = Get-PowerAppManagementApp -ApplicationId $AppID -ErrorAction SilentlyContinue

                    if ($managementApp) {
                        # Remove the management app
                        Remove-PowerAppManagementApp -ApplicationId $AppID -ErrorAction Stop
                        Write-Output "Successfully removed Power Platform registration"
                    } else {
                        Write-Verbose "Power Platform registration not found (may have been removed already)"
                    }
                } catch {
                    Write-Warning "Failed to remove Power Platform registration: $($_.Exception.Message)"
                }
            } else {
                Write-Output "WhatIf: Would remove Power Platform registration"
            }
        }

        # STEP 4b: Fix Power Platform registration if needed
        if ($InputObject.PSObject.Properties['PowerPlatformRegistered'] -and $InputObject.PowerPlatformRegistered -eq $false -and $InputObject.ProductNames -contains 'powerPlatform') {

            if ($PSCmdlet.ShouldProcess($target, "Register with Power Platform")) {
                try {
                    # Get tenant ID from the service principal
                    $sp = (Invoke-GraphDirectly -Commandlet Get-MgServicePrincipal -M365Environment $M365Environment -queryParams @{
                        '$filter' = "id eq '$ServicePrincipalID'"
                    }).Value

                    if ($sp) {
                        $TenantId = $sp.AppOwnerOrganizationId
                        Write-Verbose "Attempting to register with Power Platform"

                        $result = Connect-PowerPlatformApp -AppID $AppID -TenantId $TenantId -M365Environment $M365Environment

                        if ($result) {
                            Write-Output "Successfully registered with Power Platform"
                        } else {
                            Write-Warning "Power Platform registration returned false. Manual intervention may be required."
                        }
                    } else {
                        Write-Warning "Could not retrieve tenant ID for Power Platform registration"
                    }
                } catch {
                    Write-Warning "Failed to register with Power Platform: $($_.Exception.Message)"
                }
            } else {
                Write-Output "WhatIf: Would register application with Power Platform"
            }
        }
    }

    end {
        if ($script:changesMade) {
            Write-Output "Set-ScubaGearAppPermissions completed for AppID $script:lastAppID."
        }
    }
}

function Connect-PowerPlatformApp {
    <#
    .SYNOPSIS
        Sets up Power Platform for a service principal with automatic retry.

    .DESCRIPTION
        Attempts to set up Power Platform for a service principal, with one retry attempt if the initial connection fails.

    .PARAMETER AppId
        The application ID of the service principal to configure for Power Platform.

    .PARAMETER TenantId
        The tenant ID where the service principal exists.

    .PARAMETER M365Environment
        Used to define the environment that the application will be created in. The options are commercial, gcc, gcchigh, dod
        The function will automatically set the endpoint based on the provided environment.

    .EXAMPLE
        Connect-PowerPlatformApp -AppId "00000000-0000-0000-0000-000000000000" -TenantId "11111111-1111-1111-1111-111111111111" -M365Environment gcc

        This example connects the service principal with AppId "00000000-0000-0000-0000-000000000000" in the tenant "11111111-1111-1111-1111-111111111111" to the GCC environment of Power Platform.

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
                       PowerApps module installed (Microsoft.PowerApps.Administration.PowerShell and Microsoft.PowerApps.PowerShell)
                       The user running this command must have appropriate permissions to register applications in Power Platform.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if ([guid]::TryParse($_, [ref][guid]::Empty)) {
                return $true
            }
            throw "AppID must be a valid GUID format: $($_)"
        })]
        [string]$AppID,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $true)]
        [string]$M365Environment
    )

    $PowerAppsEndpoint = switch ($M365Environment) {
        "commercial" { "prod" }
        "gcc" { "usgov" }
        "gcchigh" { "usgovhigh" }
        "dod" { "dod" }
    }

    # Try to connect to Power Platform
    Write-Verbose "Attempting to connect to Power Platform for App ID: $AppId"
    try {
        # First attempt
        $null = Add-PowerAppsAccount -Endpoint $PowerAppsEndpoint -TenantID $TenantId -WarningAction SilentlyContinue
        $powerAppSetup = New-PowerAppManagementApp -ApplicationId $AppId -WarningAction SilentlyContinue

        if ($powerAppSetup) {
            Write-Output "Power Platform setup was successful!"
            return $true
        }

        # If the first attempt failed, try once more
        Write-Verbose "First Power Platform setup attempt failed. Retrying..."
        $null = Add-PowerAppsAccount -Endpoint $PowerAppsEndpoint -TenantID $TenantId -WarningAction SilentlyContinue
        $powerAppSetup = New-PowerAppManagementApp -ApplicationId $AppId -WarningAction SilentlyContinue

        if ($powerAppSetup) {
            Write-Output "Power Platform setup was successful on retry!"
            return $true
        } else {
            Write-Warning "Power Platform setup failed after retry attempt."
            return $false
        }
    }
    catch {
        Write-Warning "Failed to set up Power Platform: $($_.Exception.Message)"
        throw
    }
}

function Test-PowerPlatformAppRegistration {
    <#
    .SYNOPSIS
        Checks if a service principal is registered with Power Platform.

    .DESCRIPTION
        Verifies whether an application ID is registered as a management app in Power Platform.

    .PARAMETER AppId
        The application ID of the service principal to check.

    .EXAMPLE
        Test-PowerPlatformAppRegistration -AppId "00000000-0000-0000-0000-000000000000"

    .OUTPUTS
        Returns $true if the app is registered, $false otherwise.

    .NOTES
        Author: ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
                       PowerApps module installed (Microsoft.PowerApps.Administration.PowerShell)
                       The user running this command must have appropriate permissions to query applications in Power Platform.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if ([guid]::TryParse($_, [ref][guid]::Empty)) {
                return $true
            }
            throw "AppID must be a valid GUID format: $($_)"
        })]
        [string]$AppID
    )

    try {
        # Try to get the management app
        $managementApp = Get-PowerAppManagementApp -ApplicationId $AppId -ErrorAction SilentlyContinue

        # Check if the result is a valid PSCustomObject with applicationId property
        if ($managementApp -and
            $managementApp -is [PSCustomObject] -and
            $managementApp.PSObject.Properties['applicationId']) {

            Write-Verbose "Application $AppId is registered with Power Platform"
            return $true
        }
        # Check if we got an HttpWebResponse with NotFound status (not registered)
        elseif ($managementApp -and
                $managementApp -is [System.Net.HttpWebResponse] -and
                $managementApp.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) {

            Write-Verbose "Application $AppId is NOT registered with Power Platform (NotFound response)"
            return $false
        }
        else {
            Write-Verbose "Application $AppId is NOT registered with Power Platform (no valid response)"
            return $false
        }
    }
    catch {
        # If we get a 404 exception, the app is not registered
        if ($_.Exception.Message -like "*404*" -or $_.Exception.Message -like "*Not Found*") {
            Write-Verbose "Application $AppId is NOT registered with Power Platform (404 exception)"
            return $false
        }

        Write-Warning "Failed to check Power Platform registration: $($_.Exception.Message)"
        return $false
    }
}

function New-ScubaGearServicePrincipal {
    <#
    .SYNOPSIS
        This is used to Create the Scuba Application for use with ScubaGear.

    .DESCRIPTION
        This will create the necessary Application and Service Principal permissions to run ScubaGear in non-interactive mode.

    .PARAMETER CertName
        Used to define your certificate name that will be stored on your device and used to interface with the ScubaGear application created in this script. The default is "ScubaGearCert"

    .PARAMETER M365Environment
        Used to define the environment that the application will be created in. The options are commercial, gcc, gcchigh, dod

    .PARAMETER ProductNames
        This allows you to define which products that the Service Principal will be configured for and only apply those needed permissions.
        Valid options are: 'aad', 'exo', 'sharepoint', 'teams', 'powerPlatform', 'defender', '*' (which includes all products)

    .PARAMETER ServicePrincipalName
        Used to define the name of the Service Principal that will be created. The default is "ScubaGear Application"

    .PARAMETER CertValidityMonths
        Used to define the number of months that the certificate will be valid for. The default is 6 months. The maximum is 12 months.

    .EXAMPLE
        New-ScubaGearServicePrincipal -M365Environment commercial -ProductNames 'aad', 'exo'

        Creates a service principal with permissions for AAD and Exchange Online only.

    .EXAMPLE
        New-ScubaGearServicePrincipal -M365Environment commercial -ProductNames '*'

        Creates a service principal with permissions for all products.

    .EXAMPLE
        New-ScubaGearServicePrincipal -M365Environment gcchigh -ProductNames 'aad', 'exo', 'powerPlatform' -ServicePrincipalName "MyScubaGear"

        Creates a service principal named "MyScubaGear" with permissions for AAD, Exchange Online, and Power Platform in GCC High.

    .EXAMPLE
        New-ScubaGearServicePrincipal -M365Environment dod -ProductNames '*' -CertValidityMonths 12

        Creates a service principal with all product permissions and a certificate valid for 12 months in DOD environment.

    .EXAMPLE
        New-ScubaGearServicePrincipal -M365Environment commercial -ProductNames 'aad', 'sharepoint', 'teams' -CertName "MyCustomCert"

        Creates a service principal with a custom certificate name for specific products.

    .OUTPUTS
        PSCustomObject with PSTypeName 'SCuBA.ServicePrincipal' containing:
        - ServicePrincipalName: Display name of the service principal
        - AppId: Application (client) ID
        - ProductNames: Products configured
        - M365Environment: Target environment
        - CertName: Certificate name
        - CertExpiresOn: Certificate expiration date
        - CertThumbprint: Certificate thumbprint
        - PowerPlatformRegistered: Power Platform status (if applicable)

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory=$false)]
        [string]$CertName = "ScubaGearCert-$((Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss'))Z",

        [Parameter(Mandatory=$true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment,

        [Parameter(Mandatory=$true)]
        [ValidateSet("aad", "exo", "sharepoint", "teams", "powerPlatform", "defender", '*', IgnoreCase = $True)]
        [string[]]$ProductNames,

        [Parameter(Mandatory=$false)]
        [ValidateLength(0, 120)]
        [string]$ServicePrincipalName = "ScubaGear Application",

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 12)]
        [int]$CertValidityMonths = 6
    )

    Try {
        # Handle wildcard for ProductNames
        if($ProductNames -contains '*'){
            # If wildcard is specified, include all products
            $ProductNames = @('aad', 'exo', 'sharepoint', 'teams', 'powerPlatform', 'defender')
        }

        # Get permissions using the same approach as Get-ScubaGearAppPermission
        Write-Verbose "Getting permissions for products: $($ProductNames -join ', ')"

        # Get all service principal permissions (aad, exo, sharepoint)
        $allPermissions = Get-ServicePrincipalPermissions -Environment $M365Environment

        # Filter permissions based on selected products
        $filteredPermissions = $allPermissions | Where-Object { $_.scubaGearProduct -in $ProductNames }

        if ($(@($filteredPermissions).Count) -eq 0) {
            Write-Verbose "No API permissions needed for selected products (may require Entra role instead)"
            $filteredPermissions = @()
        } else {
            Write-Verbose "Found $(@($filteredPermissions).Count) API permissions for selected products"
        }

        # Note: There are Entra role requirements for certain products
        $PermissionFileRole = Get-ScubaGearPermissions -OutAs role -Product $ProductNames

        # Create an object to store output
        $AppInfo = @()

        # Display what will be created
        $whatIfMessage = @"
Creating new ScubaGear Service Principal with the following configuration:
  - Display Name: $ServicePrincipalName
  - Products: $($ProductNames -join ', ')
  - Certificate Name: $CertName
  - Certificate Validity: $CertValidityMonths months
  - API Permissions: $(@($filteredPermissions).Count) permission(s)
  - Directory Roles: $($PermissionFileRole -join ', ')
"@

        if ($ProductNames -contains 'powerPlatform') {
            $whatIfMessage += "`n  - Power Platform Registration: Yes"
        }

        if ($PSCmdlet.ShouldProcess($ServicePrincipalName, $whatIfMessage)) {
            try {
                # Connect to Microsoft Graph
                try {
                    $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("Application.ReadWrite.All", "RoleManagement.ReadWrite.Directory", "AppRoleAssignment.ReadWrite.All", "User.Read")
                    Write-Verbose "Successfully connected to Microsoft Graph"
                }
                catch {
                    Write-Warning "Failed to connect to Microsoft Graph: $($_.Exception.Message)"
                }

                $Body = @{
                    DisplayName = $ServicePrincipalName
                }
                $app = Invoke-GraphDirectly -Commandlet New-MgApplication -Body $Body -M365Environment $M365Environment

            # Entra doesn't always update immediately, make sure app exists before we try to update its config
            $appExists = $false
            $maxRetries = 10
            $retryCount = 0
            while (!$appExists -and $retryCount -lt $maxRetries) {
                Start-Sleep -Seconds 2
                $retryCount++
                $appExists = (Invoke-GraphDirectly -Commandlet Get-MgBetaApplication -M365Environment $M365Environment -queryParams @{
                    '$filter' = "appId eq '$($app.AppId)'"
                }).Value
            }
            Write-Verbose "App Registration Application (Client) ID: $($app.Id)"

            $Body = @{
                appId = $app.AppId
            }
            $sp = Invoke-GraphDirectly -Commandlet New-MgServicePrincipal -Body $Body -M365Environment $M365Environment

            # Only set API permissions if there are any
            if ($filteredPermissions.Count -gt 0) {
                try {
                    Write-Verbose "Setting up API permissions for the application"
                    $Null = Set-AppRegistrationPermission -AppID $app.AppId -ScubaGearSPPermissions $filteredPermissions -M365Environment $M365Environment -SkipConnect
                    Write-Verbose "Successfully assigned API permissions to the application"
                }
                catch {
                    Write-Warning "Failed to assign API permissions: $($_.Exception.Message)"
                    throw
                }
            } else {
                Write-Verbose "No API permissions to assign (Power Platform only)"
            }

            try {
                # Assign service principal to the required roles
                ForEach ($Role in $PermissionFileRole) {
                    $RoleName = $Role
                    $roleDefinition = (Invoke-GraphDirectly -Commandlet Get-MgRoleManagementDirectoryRoleDefinition -M365Environment $M365Environment -queryParams @{
                        '$filter' = "displayName eq '$($RoleName)'"
                    }).Value

                    if ($roleDefinition) {
                        # Use the existing Set-ScubaGearRole function
                        $Null = Set-ScubaGearRole -ServicePrincipalId $SP.Id -roleDefinitionID $roleDefinition.Id -M365Environment $M365Environment -SkipConnect
                    } else {
                        Write-Warning "Role definition not found for role: $RoleName"
                    }
                }
            } catch {
                Write-Warning "Failed to assign Service Principal to directory roles: $($_.Exception.Message)"
                throw
            }
        }
        catch {
            Write-Warning "Failed to create App Registration and Service Principal: $($_.Exception.Message)"
            throw
        }

        try{
            # Define Certificate settings
            $cert = New-SelfSignedCertificate -Subject "CN=$CertName" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 -NotAfter (Get-Date).AddMonths($CertValidityMonths)

            $base64Cert = [System.Convert]::ToBase64String($cert.RawData)

            # Define the Key Credentials Parameters
            $params = @{
                keyCredentials = @(
                    @{
                        endDateTime = $cert.NotAfter.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                        startDateTime = $cert.NotBefore.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                        type = "AsymmetricX509Cert"
                        usage = "Verify"
                        key = $base64Cert
                        displayName = "CN=$CertName"
                    }
                )
            }

            Write-Verbose "Successfully created certificate"
            Write-Verbose "Certficate expires on: $($cert.NotAfter)"
        } catch {
            Write-Warning "Failed to create certificate: $($_.Exception.Message)"
        }

        try {
            #Update the application above with the certificate.
            Invoke-GraphDirectly -Commandlet Update-MgApplication -Body $params -M365Environment $M365Environment -id $app.Id

            # Output the certificate information to AppInfo object
            $AppInfo = [PSCustomObject]@{
                PSTypeName = 'SCuBA.ServicePrincipal'
                ServicePrincipalName = $ServicePrincipalName
                AppId = $app.AppId
                ProductNames = $ProductNames
                M365Environment = $M365Environment
                CertName = $CertName
                CertExpiresOn = $cert.NotAfter
                CertThumbprint = $cert.Thumbprint
            }

            # Set default display properties
            Update-TypeData -TypeName 'SCuBA.ServicePrincipal' -DefaultDisplayPropertySet 'ServicePrincipalName', 'AppId', 'ProductNames', 'M365Environment', 'CertName', 'CertExpiresOn', 'CertThumbprint' -Force
        }
        catch {
            Write-Warning "Failed to update application with certificate: $($_.Exception.Message)"
        }

        # Set up Power Platform if it's in the ProductNames
        if($ProductNames -contains 'powerPlatform'){
            try {
                # https://github.com/cisagov/ScubaGear/blob/main/docs/prerequisites/noninteractive.md#power-platform
                $appId = ($SP).AppID
                $TenantID = ($SP).AppOwnerOrganizationID

                Write-Verbose "Setting up Power Platform for the service principal"
                $result = Connect-PowerPlatformApp -AppId $appId -TenantId $TenantID -M365Environment $M365Environment

                if ($result) {
                    Write-Verbose "Power Platform setup was successful"
                    $AppInfo | Add-Member -MemberType NoteProperty -Name "PowerPlatformRegistered" -Value $true -Force
                } else {
                    Write-Warning "Power Platform setup failed after retry attempts"
                    $AppInfo | Add-Member -MemberType NoteProperty -Name "PowerPlatformRegistered" -Value $false -Force
                }
            } catch {
                Write-Warning "Failed to perform Power Platform registration: $($_.Exception.Message)"
                $AppInfo | Add-Member -MemberType NoteProperty -Name "PowerPlatformRegistered" -Value $false -Force
            }
        }
            return $AppInfo
        } else {
            Write-Output "Operation cancelled by user."
        }
    }catch{
        Write-Warning "Failed to create ScubaGear Application: $($_.Exception.Message)"
    }
}

function Get-ScubaGearAppCert {
    <#
    .SYNOPSIS
        Lists the current certificates associated with a app registration.

    .DESCRIPTION
        This function retrieves and displays all certificates associated with a app registration identified by its Application ID.

    .PARAMETER AppID
        The Application (client) ID of the app registration.

    .PARAMETER M365Environment
        The Microsoft 365 environment where the app registration exists.
        Valid values are: commercial, gcc, gcchigh, dod

    .EXAMPLE
        Get-ScubaGearAppCert -AppID "00000000-0000-0000-0000-000000000000" -M365Environment "commercial"

        Lists all certificates for the specified application in the commercial environment.

    .OUTPUTS
        PSCustomObject with PSTypeName 'SCuBA.AppCertificate' containing:
        - AppID: The application ID
        - ApplicationName: App display name
        - M365Environment: The environment
        - CertificateCount: Number of certificates
        - Certificates: Array of certificate objects
        - HasCertificates: Boolean
        - HasExpiredCerts: Boolean
        - HasExpiringSoon: Boolean
        - CertificatesSummary: Formatted summary string

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if ([guid]::TryParse($_, [ref][guid]::Empty)) {
                return $true
            }
            throw "AppID must be a valid GUID format: $($_)"
        })]
        [string]$AppID,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment
    )

    try {
        $M365Environment = $M365Environment.ToLower()

        # Connect to Microsoft Graph with read-only permissions
        $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("Application.Read.All")
        Write-Verbose "Successfully connected to Microsoft Graph"

        # Find the application by AppID
        $app = (Invoke-GraphDirectly -Commandlet Get-MgBetaApplication -M365Environment $M365Environment -queryParams @{
            '$filter' = "appId eq '$AppID'"
        }).Value

        if (-not $app) {
            Write-Error "Application with AppID '$AppID' not found"
            return
        }

        # Check if certificates exist
        if (-not $app.keyCredentials -or $app.keyCredentials.Count -eq 0) {
            Write-Verbose "No certificates found for application: $($app.displayName)"

            $outputObject = [PSCustomObject]@{
                PSTypeName          = 'SCuBA.AppCertificate'
                AppID               = $AppID
                ApplicationName     = $app.displayName
                M365Environment     = $M365Environment
                CertificateCount    = 0
                Certificates        = @()
                CertificatesSummary = @()
                HasCertificates     = $false
                HasExpiredCerts     = $false
                HasExpiringSoon     = $false
            }

            Update-TypeData -TypeName 'SCuBA.AppCertificate' -DefaultDisplayPropertySet 'AppID', 'ApplicationName', 'CertificateCount', 'HasExpiredCerts', 'HasExpiringSoon' -Force
            return $outputObject
        }

        # Build certificate information array
        $certInfo = [System.Collections.ArrayList]::new()
        $summaryList = [System.Collections.ArrayList]::new()

        foreach ($cert in $app.keyCredentials) {
            $now = Get-Date
            $expiresOn = [DateTime]$cert.endDateTime
            $daysUntilExpiry = ($expiresOn - $now).Days

            $isExpired = $daysUntilExpiry -lt 0
            $isExpiringSoon = ($daysUntilExpiry -ge 0) -and ($daysUntilExpiry -le 30)

            # Convert byte array to hex string (PowerShell 5.1 compatible)
            $thumbprint = $cert.customKeyIdentifier

            # Add to certificate info array
            [void]$certInfo.Add([PSCustomObject]@{
                PSTypeName      = 'SCuBA.Certificate'
                DisplayName     = $cert.displayName
                Thumbprint      = $thumbprint
                ExpiresOn       = $expiresOn
                StartDate       = [DateTime]$cert.startDateTime
                DaysRemaining   = $daysUntilExpiry
                IsExpired       = $isExpired
                IsExpiringSoon  = $isExpiringSoon
            })

            # Build summary for this certificate
            $status = if ($isExpired) { "Expired" }
                     elseif ($isExpiringSoon) { "Expiring Soon" }
                     else { "Valid" }

            $expirationMessage = if ($isExpired) {
                "Expired: $($expiresOn.ToString('yyyy-MM-ddTHH:mm:ssZ')) ($([Math]::Abs($daysUntilExpiry)) days ago)"
            } elseif ($isExpiringSoon) {
                "Expires: $($expiresOn.ToString('yyyy-MM-ddTHH:mm:ssZ')) ($daysUntilExpiry days remaining)"
            } else {
                "Expires: $($expiresOn.ToString('yyyy-MM-ddTHH:mm:ssZ')) ($daysUntilExpiry days remaining)"
            }

            [void]$summaryList.Add([PSCustomObject]@{
                PSTypeName        = 'SCuBA.CertificateSummary'
                DisplayName       = $cert.displayName
                Status            = $status
                ExpirationMessage = $expirationMessage
                ExpiresOn         = $expiresOn.ToString('yyyy-MM-ddTHH:mm:ssZ')
                Thumbprint        = $thumbprint
            })
        }

        # Sort by expiration date and convert to array
        $certInfo = @($certInfo | Sort-Object -Property ExpiresOn)
        $summaryList = @($summaryList | Sort-Object -Property ExpiresOn)

        # Build output object with CertificatesSummary as a regular property
        $outputObject = [PSCustomObject]@{
            PSTypeName          = 'SCuBA.AppCertificate'
            AppID               = $AppID
            ApplicationName     = $app.displayName
            M365Environment     = $M365Environment
            CertificateCount    = $certInfo.Count
            Certificates        = $certInfo
            CertificatesSummary = $summaryList
            HasCertificates     = $true
            HasExpiredCerts     = @($certInfo | Where-Object { $_.IsExpired }).Count -gt 0
            HasExpiringSoon     = @($certInfo | Where-Object { $_.IsExpiringSoon }).Count -gt 0
        }

        # Set default display properties
        Update-TypeData -TypeName 'SCuBA.AppCertificate' -DefaultDisplayPropertySet 'AppID', 'ApplicationName', 'CertificateCount', 'HasExpiredCerts', 'HasExpiringSoon' -Force

        # Set default display for CertificateSummary type
        Update-TypeData -TypeName 'SCuBA.CertificateSummary' -DefaultDisplayPropertySet 'DisplayName', 'Status', 'ExpirationMessage', 'Thumbprint' -Force

        return $outputObject
    } catch {
        Write-Error "Failed to retrieve application certificates: $($_.Exception.Message)"
        throw
    }
}

function Remove-ScubaGearAppCert {
    <#
    .SYNOPSIS
        Removes a certificate from a ScubaGear app registration.

    .DESCRIPTION
        This function removes a certificate identified by its thumbprint from a app registration associated with a specified Application ID.

    .PARAMETER AppID
        The Application (client) ID of the app registration.

    .PARAMETER CertThumbprint
        The thumbprint of the certificate to be removed.

    .PARAMETER M365Environment
        The Microsoft 365 environment where the app registration exists.
        Valid values are: commercial, gcc, gcchigh, dod

    .EXAMPLE
        Remove-ScubaGearAppCert -AppID "00000000-0000-0000-0000-000000000000" -CertThumbprint "1234567890ABCDEF1234567890ABCDEF12345678" -M365Environment "commercial"

        Removes the certificate with the specified thumbprint from the application.

    .EXAMPLE
        Remove-ScubaGearAppCert -AppID "00000000-0000-0000-0000-000000000000" -CertThumbprint "1234567890ABCDEF1234567890ABCDEF12345678" -M365Environment "commercial" -WhatIf

        Shows what would happen if the command were to run without actually removing the certificate.

    .EXAMPLE
        Remove-ScubaGearAppCert -AppID "00000000-0000-0000-0000-000000000000" -CertThumbprint "1234567890ABCDEF1234567890ABCDEF12345678" -M365Environment "commercial" -Confirm:$false

        Removes the certificate without prompting for confirmation.

    .OUTPUTS
        None. Outputs status messages to the console. Returns $null if app not found.

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if ([guid]::TryParse($_, [ref][guid]::Empty)) {
                return $true
            }
            throw "AppID must be a valid GUID format: $($_)"
        })]
        [string]$AppID,

        [Parameter(Mandatory = $true)]
        [ValidatePattern("^[0-9A-F]{40}$")]
        [string]$CertThumbprint,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment
    )

    try {
        $M365Environment = $M365Environment.ToLower()

        # Connect to Microsoft Graph with write permissions
        $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("Application.ReadWrite.All")
        Write-Verbose "Successfully connected to Microsoft Graph"

        # Find the application by AppID
        $app = (Invoke-GraphDirectly -Commandlet Get-MgBetaApplication -M365Environment $M365Environment -queryParams @{
            '$filter' = "appId eq '$AppID'"
        }).Value

        if ($app) {
            # Get existing key credentials
            $existingKeyCredentials = $app.keyCredentials

            # Find the certificate to remove
            $certToRemove = $existingKeyCredentials | Where-Object { $_.CustomKeyIdentifier -eq $CertThumbprint }

            if ($certToRemove) {
                # Create descriptive target name for ShouldProcess
                $targetDescription = "Certificate '$($certToRemove.DisplayName)' with thumbprint '$CertThumbprint' from application '$($app.DisplayName)'"

                # Use ShouldProcess to support -WhatIf and -Confirm
                if ($PSCmdlet.ShouldProcess($targetDescription, "Remove")) {
                    # Prepare updated list of certificates (excluding the one to be removed)
                    $updatedKeyCredentials = @()

                    foreach ($existingKey in $existingKeyCredentials) {
                        if ($existingKey.CustomKeyIdentifier -ne $CertThumbprint) {
                            # Format the certificate data correctly
                            $formattedKey = @{
                                customKeyIdentifier = $existingKey.CustomKeyIdentifier
                                displayName = $existingKey.DisplayName
                                keyId = $existingKey.KeyId
                                type = $existingKey.Type
                                usage = $existingKey.Usage
                                startDateTime = $existingKey.StartDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                                endDateTime = $existingKey.EndDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                            }
                            $updatedKeyCredentials += $formattedKey
                        }
                    }

                    # Update the application with the remaining certificates
                    $params = @{
                        keyCredentials = $updatedKeyCredentials
                    }

                    Invoke-GraphDirectly -Commandlet Update-MgApplication -Body $params -M365Environment $M365Environment -id $app.Id

                    # Create result object
                    $result = [PSCustomObject]@{
                        Success = $true
                        RemovedCertificate = $certToRemove.DisplayName
                        Thumbprint = $CertThumbprint
                        AppName = $app.DisplayName
                        AppId = $AppID
                    }
                    Write-Output "Certificate '$($certToRemove.DisplayName)' with thumbprint '$CertThumbprint' successfully removed"
                    return $result
                }
                else {
                    # Return info about what would have been removed if -WhatIf was used
                    $whatIfResult = [PSCustomObject]@{
                        Operation = "WhatIf"
                        CertificateToRemove = $certToRemove.DisplayName
                        Thumbprint = $CertThumbprint
                        AppName = $app.DisplayName
                        AppId = $AppID
                    }
                    return $whatIfResult
                }
            } else {
                Write-Warning "Certificate with thumbprint '$CertThumbprint' not found in application"
                return $null
            }
        } else {
            Write-Warning "Application ID: $AppID not found"
            return $null
        }
    } catch {
        Write-Warning "Failed to remove certificate: $($_.Exception.Message)"
        throw
    }
}

function New-ScubaGearAppCert {
    <#
    .SYNOPSIS
        Creates and adds a new certificate to a ScubaGear app registration.

    .DESCRIPTION
        This function creates a new self-signed certificate and adds it to a app registration identified by its Application ID.

    .PARAMETER AppID
        The Application (client) ID of the app registration.

    .PARAMETER CertName
        The name for the new certificate. If not specified, a name with timestamp will be generated.

    .PARAMETER CertValidityMonths
        The number of months the certificate should be valid for. Default is 6, maximum is 12.

    .PARAMETER M365Environment
        The Microsoft 365 environment where the app registration exists.
        Valid values are: commercial, gcc, gcchigh, dod

    .EXAMPLE
        New-ScubaGearAppCert -AppID "00000000-0000-0000-0000-000000000000" -CertName "MyNewCert" -M365Environment "commercial"

        Creates a new certificate named "MyNewCert" valid for 6 months and adds it to the application.

    .EXAMPLE
        New-ScubaGearAppCert -AppID "00000000-0000-0000-0000-000000000000" -CertValidityMonths 12 -M365Environment "gcchigh"

        Creates a new certificate with an auto-generated name valid for 12 months and adds it to the application.

    .OUTPUTS
        PSCustomObject containing:
        - DisplayName: Certificate name
        - Thumbprint: Certificate thumbprint
        - ExpiresOn: Expiration date
        - CreatedOn: Creation date

    .NOTES
        Author       : ScubaGear Team
        Prerequisite : PowerShell 5.1 or later
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if ([guid]::TryParse($_, [ref][guid]::Empty)) {
                return $true
            }
            throw "AppID must be a valid GUID format: $($_)"
        })]
        [string]$AppID,

        [Parameter(Mandatory = $false)]
        [string]$CertName = "ScubaGearCert-$((Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss'))Z",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 12)]
        [int]$CertValidityMonths = 6,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment
    )

    try {
        $M365Environment = $M365Environment.ToLower()

        # Connect to Microsoft Graph with write permissions
        $Null = Connect-GraphHelper -M365Environment $M365Environment -Scopes @("Application.ReadWrite.All")
        Write-Verbose "Successfully connected to Microsoft Graph"

        # Find the application by AppID
        $app = (Invoke-GraphDirectly -Commandlet Get-MgBetaApplication -M365Environment $M365Environment -queryParams @{
            '$filter' = "appId eq '$AppID'"
        }).Value

        if ($app) {
            # Create the new certificate
            $cert = New-SelfSignedCertificate -Subject "CN=$CertName" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 -NotAfter (Get-Date).AddMonths($CertValidityMonths)
            $certBase64Value = [System.Convert]::ToBase64String($cert.RawData)

            # Format the new certificate
            $newKeyCredential = @{
                displayName = "CN=$CertName"
                endDateTime = $cert.NotAfter.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                key = $certBase64Value
                type = "AsymmetricX509Cert"
                usage = "Verify"
                startDateTime = $cert.NotBefore.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            }

            # Get existing certificates
            $existingKeyCredentials = $app.keyCredentials
            $updatedKeyCredentials = @()

            # Format existing certificates
            if ($existingKeyCredentials) {
                foreach ($existingKey in $existingKeyCredentials) {
                    $formattedExistingKey = @{
                        customKeyIdentifier = $existingKey.CustomKeyIdentifier
                        displayName = $existingKey.DisplayName
                        endDateTime = $existingKey.EndDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                        keyId = $existingKey.KeyId
                        startDateTime = $existingKey.StartDateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                        type = $existingKey.Type
                        usage = $existingKey.Usage
                    }
                    $updatedKeyCredentials += $formattedExistingKey
                }
            }

            # Add the new certificate to the collection
            $updatedKeyCredentials += $newKeyCredential

            # Update the application with the new certificate collection
            $payload = @{
                keyCredentials = $updatedKeyCredentials
            }

            Invoke-GraphDirectly -Commandlet Update-MgApplication -Body $payload -M365Environment $M365Environment -id $app.Id

            # Create result object with certificate information
            $certInfo = [PSCustomObject]@{
                Thumbprint = $cert.Thumbprint
                DisplayName = "CN=$CertName"
                AppID = $app.AppId
                AppRegistrationName = $app.DisplayName
                ExpiresOn = $cert.NotAfter
                StartDate = $cert.NotBefore
                Organization = $app.publisherDomain
            }

            Write-Output "Successfully added new certificate '$CertName' to application"
            return $certInfo
        } else {
            Write-Warning "Application ID: $AppID not found"
            return $null
        }
    } catch {
        Write-Warning "Failed to add new certificate: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function New-ScubaGearServicePrincipal, Get-ScubaGearAppPermission, Get-ScubaGearAppCert, Remove-ScubaGearAppCert, New-ScubaGearAppCert, Set-ScubaGearAppPermission