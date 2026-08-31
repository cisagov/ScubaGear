Function Get-ScubaGearPermissions {
    <#
    .SYNOPSIS
        This Function is used to retrieve the permissions of the SCuBAGear module

    .DESCRIPTION
        This Function is used to retrieve the permissions of the SCuBAGear module

    .PARAMETER Domain
        The domain to be used in the apiResource

    .PARAMETER CmdletName
        The name of the cmdlet for which the permissions are to be retrieved

    .PARAMETER PermissionLevel
        The level of permission to be retrieved. The possible values are 'least' and 'higher'. Default is 'least'

    .PARAMETER ServicePrincipal
        The switch to indicate that the permissions are to be retrieved for a service principal

    .PARAMETER Product
        The product for which the permissions are to be retrieved. Options are 'aad', 'exo', 'defender', 'securitysuite', 'teams', 'sharepoint', 'powerplatform'. Can be an array of products and used in pipeline. 'securitysuite' is an alias for 'defender' (the Security Suite).

    .PARAMETER Environment
        The Environment for which the permissions are to be retrieved. Options are 'commercial', 'gcc', 'gcchigh', 'dod'. Default is 'commercial'

    .PARAMETER OutAs
        The output format. The possible values are 'perms', 'endpoint', 'modules', 'api', 'support'. Default is 'perms'

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaDirectorySettings

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaDirectorySettings -PermissionLevel higher

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad -OutAs all

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaPrivilegedAccessResource -OutAs support

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaGroupMember -OutAs api -id '559aabe6-7ef4-4fb6-b271-fa3d19e76017'

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad
        Get-ScubaGearPermissions -Product exo
        Get-ScubaGearPermissions -Product securitysuite

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaUser -OutAs modules

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad -OutAs modules

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad -servicePrincipal

    .EXAMPLE
        Get-ScubaGearPermissions -Product exo -servicePrincipal

    .EXAMPLE
        Get-ScubaGearPermissions -Product exo -OutAs appId

    .EXAMPLE
        Get-ScubaGearPermissions -Product exo -OutAs endpoint

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad -OutAs api -id '559aabe6-7ef4-4fb6-b271-fa3d19e76017'

    .EXAMPLE
        Get-ScubaGearPermissions -Product sharepoint -OutAs endpoint -Environment gcchigh -Domain contoso

    .EXAMPLE
        Get-ScubaGearPermissions -OutAs endpoint -Domain contoso

    .EXAMPLE
        'teams' | Get-ScubaGearPermissions -OutAs role

    .EXAMPLE
        'aad','scubatank' | Get-ScubaGearPermissions

    .NOTES
        NAME: Get-ScubaGearPermissions
        VERSION: 2.0

        USE TO FIND PERMS:
            (Find-MgGraphCommand -Command Get-MgBetaPolicyRoleManagementPolicyAssignment).Permissions | Select Name, IsLeastPrivilege
            Find-MgGraphPermission -All

        CHANGELOG:
        2024-10-03 - Initial version
        2024-11-05 - Added support for ServicePrincipal with id's and typos
        2024-11-07 - Added support for Domain, and beta api.
        2024-11-15 - Removed redundantpermissions and added verbose messages
        2024-12-20 - Added version and changelog. Added support for pipeline and for multiple products. Fixed issue with role output for null values
        2024-12-23 - Adjusted endpoint output based on structure changes in the permissions file
        2026-06-19 - Added SecuritySuite and removed ScubaTank to product list

        DEVELOPER EXPLANATION OF the possible OutAs parameter values since they is hard to discern from the code alone:
        perms       - Returns the value in the leastPermissions field
        api         - Returns a conglomerate set of values from  the apiResource field
                        Pass the -id field with this and it will place the value into the URI "/v1.0/roleManagement/directory/roleDefinitions/{id}"
        role        - Returns the values in the spRolePermissions field (these are the roles that the service principal needs to be assigned) (details in /docs/prerequisites/noninteractive.md).
        oauthScope  - Returns the values in the oauthScope field (used to mint tokens by MSAL for the various products)
        endpoint    - Returns the value in the apiResource field where $_.moduleCmdlet -like 'Connect-*' -or $_.moduleCmdlet -like '*REST API' (this is the base URI used by the Export Providers to call REST APIs)
        apiHeader   - Returns the apiHeader value based on the CmdletName (currently only /beta/users/ has a value). Used for the HTTP header in REST API calls.
        all         - Returns all the fields from every record in the JSON that matches the product name
        The following OutAs parameter values are currently not used anywhere in ScubaGear:
        modules     - Returns the values in the poshModule field 
        appId       - Returns the resourceAPIAppId
    #>

    [CmdletBinding(DefaultParameterSetName = 'CmdletName')]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = 'CmdletName')]
        [Alias('Command')]
        [string]$CmdletName,

        [Parameter(Mandatory = $false, ParameterSetName = 'ServicePrincipal')]
        [switch]$ServicePrincipal,

        [Parameter(Mandatory = $true, ParameterSetName = 'ServicePrincipal',ValueFromPipeline=$true)]
        [ValidateSet('aad', 'exo', 'defender', 'securitysuite', 'teams', 'sharepoint', 'scubatank', 'powerplatform', 'teamsunified', '*')]
        [string[]]$Product,

        [Parameter(Mandatory = $false)]
        [string]$Domain,

        [Parameter(Mandatory = $false)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [ValidateSet('least', 'higher')]
        [Alias('PermissionType')]
        [string]$PermissionLevel = 'least',

        [Parameter(Mandatory = $false)]
        [ValidateSet('commercial', 'gcc', 'gcchigh', 'dod')]
        [string]$Environment = 'commercial',

        [Parameter(Mandatory = $false)]
        [ValidateSet('perms','modules', 'api', 'endpoint', 'support', 'role' , 'appId', 'all', 'apiHeader', 'oauthScope')]
        [string]$OutAs ='perms'
    )
    Begin{
        $ErrorActionPreference = 'Stop'

        # If ProductName is * then set Product to all possible values
        if ($Product -contains '*') {
            $Product = @('aad', 'exo', 'securitysuite', 'teams', 'sharepoint', 'powerplatform')
        }

        if($OutAs -eq "endpoint" -and $Product -eq 'sharepoint' -and !$Domain){
            Write-Error -Message "Parameter [-Domain] is required when OutAs is endpoint"
        }

        if($OutAs -eq 'api' -and $Product -match 'aad' -and !$Id){
            Write-Error -Message "Parameter [-id] is required when OutAs is api or endpoint and Product is aad"
        }

        [string]$ResourceRoot = ($PWD.ProviderPath, $PSScriptRoot)[[bool]$PSScriptRoot]

        $permissionSet = Get-Content -Path "$ResourceRoot\..\..\schemas\ScubaGearApiCatalog.json" | ConvertFrom-Json
        Write-Verbose "Command: `$permissionSet = Get-Content -Path '$ResourceRoot\..\..\schemas\ScubaGearApiCatalog.json' | ConvertFrom-Json"

        # This hashtable contains the Entra AppId values for MS Graph (aad), Office 365 Exchange Online and SharePoint.
        # The New-ScubaGearServicePrincipal cmdlet references these AppIds and their respective permissions from ScubaGearApiCatalog.json to
        #   create the service principal permissions in the tenant.
        $ResourceAPIHash = @{
            'aad'        = '00000003-0000-0000-c000-000000000000'
            'exo'        = @(
                '00000002-0000-0ff1-ce00-000000000000',
                '00000007-0000-0ff1-ce00-000000000000'
            )
            'securitysuite' = @(
                '00000002-0000-0ff1-ce00-000000000000',
                '00000007-0000-0ff1-ce00-000000000000'
            )
            'sharepoint' = '00000003-0000-0ff1-ce00-000000000000'
            'teams' = '48ac35b8-9aa8-4d74-927d-1f4a14a0b239'
        }

        # Start with an empty array to build the filter
        $conditions = @()
        $conditionsmsg = @()
        $output = @()
    }
    Process{

        switch($PSBoundParameters.Keys){
            'CmdletName' {
                $conditions += {$_.moduleCmdlet -eq $CmdletName}
                $conditionsmsg += '`$_.moduleCmdlet -eq "' + $CmdletName + '"'
            }

            'Product' {
                # Build OR condition for products - item should match ANY of the specified products
                $productCondition = {
                    $item = $_
                    $matchFound = $false
                    foreach($prod in $Product) {
                        if ($item.scubaGearProduct -contains $prod) {
                            $matchFound = $true
                            break
                        }
                    }
                    return $matchFound
                }
                $conditions += $productCondition
                $conditionsmsg += '`$_.scubaGearProduct -contains any of "' + ($Product -join '", "') + '"'

                # # Don't add resourceAPIAppId filters when querying for roles or endpoints
                # # If($OutAs -ne 'role' -and $OutAs -ne 'endpoint'){
                If($OutAs -eq 'perms'){
                    Foreach($ProductItem in $Product){
                        If($ServicePrincipal -or $ProductItem -eq 'aad'){
                            # When running non-interactive, fetch the permissions associated with with the product's REST API record in the JSON (e.g. "Teams admin REST API").
                            # These are the permissions that a service principal needs and are listed in /docs/prerequisites/noninteractive.md for the specific product.
                            # aad is the only exception. For aad for both interactive and non-interactive we need to fetch the Graph permissions.
                            $conditions += {$_.resourceAPIAppId -match ($ResourceAPIHash[$ProductItem] -join '|')}
                            $conditionsmsg += '`$_.resourceAPIAppId -match "' + ($ResourceAPIHash[$ProductItem] -Join '|') + '"'
                        }
                        else{
                            # When running interactive, the permissions returned are only the minimum necessary to run
                            #   the MS Graph API /organization to get information about the tenant which is called by all of the products.
                            # This logic fetches the permissions from the /beta/organization record in the JSON.
                            $conditions += {$_.resourceAPIAppId -notmatch ($ResourceAPIHash[$ProductItem] -join '|')}
                            $conditionsmsg += '`$_.resourceAPIAppId -notmatch "' + ($ResourceAPIHash[$ProductItem] -join '|') + '"'
                        }
                    }
                }
            }
        }

        foreach ($EnvironmentItem in $Environment) {
            $conditions += {$_.supportedEnv -contains $EnvironmentItem }
            $conditionsmsg += '`$_.supportedEnv -contains "' + $EnvironmentItem + '"'
        }

        #write a verbose statement where the values are expanded in the $conditions
        # the $_ causes the join to fail, so we need to replace it with another character
        $filterCondition = $conditionsmsg -join '' -replace '`', ' -and ' -replace '^\s+(-and)\s+', ''

        # Correct verbose message with escaped braces
        Write-Verbose -Message ("Command: `$collection = `$permissionSet | Where-Object {{ {0} }}" -f $filterCondition)

        # Combine the conditions into a single script block
        $filterScript = {
            $result = $true
            foreach ($condition in $conditions) {
                $result = $result -and (&$condition)
            }
            return $result
        }

        $collection = $permissionSet | Where-Object $filterScript

        # Apply the dynamically built filter in Where-Object
        switch ($OutAs) {
            'perms' {
                If($PermissionLevel -eq 'least'){
                    Write-Verbose -Message "Command: `$collection | Where-Object {`$_.moduleCmdlet -notlike 'Connect-Mg*'} | Select-Object -ExpandProperty leastPermissions -Unique"
                    $output += $collection | Where-Object {$_.moduleCmdlet -notlike 'Connect-Mg*'} | Select-Object -ExpandProperty leastPermissions -Unique
                }
                else{
                    Write-Verbose -Message "Command: `$collection  | Where-Object {`$_.moduleCmdlet -notlike 'Connect-Mg*'}| Select-Object -ExpandProperty higherPermissions -Unique"
                    $output += $collection | Where-Object {$_.moduleCmdlet -notlike 'Connect-Mg*'} | Select-Object -ExpandProperty higherPermissions -Unique
                }
            }
            'modules' {
                Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty poshModule -Unique"
                $output += $collection | Where-Object $filterScript | Select-Object -ExpandProperty poshModule -Unique
            }
            'endpoint' {

                #only get the api
                Write-Verbose -Message "Command: `$collection | Where-Object {`$_.moduleCmdlet -like 'Connect-*'} | foreach-object {`$_.apiResource -replace '{id}',$Id -replace '{domain}',$Domain} | Select-Object -Unique"
                #combine the apiResource and api filter if exists
                $output += $collection | Where-Object $filterScript | Where-Object {$_.moduleCmdlet -like 'Connect-*' -or $_.moduleCmdlet -like '*REST API'} | foreach-object {
                    #$apiResource = $_.'apiResource'

                    If($_.apifilter){
                        ($_.apiResource -replace "{id}",$Id -replace '{domain}',$Domain) + '?$filter=' + $_.apifilter
                    }else{
                        $_.apiResource -replace '{id}',$Id -replace '{domain}',$Domain
                    }
                } | Select-Object -Unique

            }
            'api'{

                If($PSBoundParameters.ContainsKey('CmdletName') -and $CmdletName -match '-Mg'){
                    #if cmdlete is a graph cmdlet, then get the connect-* cmdlet
                    Write-Verbose -Message "Command: `$connecturi = `$permissionSet | Where-Object {`$_.moduleCmdlet -eq 'Connect-MgGraph' -and `$_.supportedEnv -eq '$Environment'} | foreach-object {`$_.apiResource} | Select-Object -Unique"
                    $connecturi = $permissionSet | Where-Object {$_.moduleCmdlet -eq 'Connect-MgGraph' -and $_.supportedEnv -eq $Environment} | foreach-object {$_.apiResource} | Select-Object -Unique
                }Else{
                    #get the connect-* cmdlet:
                    Write-Verbose -Message "Command: `$connecturi = `$collection | Where-Object {`$_.moduleCmdlet -like 'Connect-*'} | foreach-object {`$_.apiResource} | Select-Object -Unique"
                    $connecturi = $collection | Where-Object $filterScript | Where-Object {$_.moduleCmdlet -like 'Connect-*'} | foreach-object {$_.apiResource} | Select-Object -Unique
                }

                #only get the api
                Write-Verbose -Message "Command: `$collection | Where-Object {`$_.moduleCmdlet -notlike 'Connect-*'} | foreach-object {'$connecturi + ($_.apiResource -replace '{id}',$Id -replace '{domain}',$Domain)'} | Select-Object -Unique"
                #combine the apiResource and api filter if exists
                $output += $collection | Where-Object $filterScript | Where-Object {$_.moduleCmdlet -notlike 'Connect-*'} | foreach-object {
                    #$apiResource = $_.'apiResource'

                    If($_.apifilter){
                        if($_.apifilter -match '{id}'){
                            #if the apifilter contains {id}, then replace it with the id
                            $connecturi + ($_.apiResource -replace "{id}",$Id -replace '{domain}',$Domain) + $_.apifilter -replace '{id}',$Id
                        }else{
                            $connecturi + ($_.apiResource -replace "{id}",$Id -replace '{domain}',$Domain) + $_.apifilter
                        }
                    }else{
                        $connecturi + $_.apiResource -replace '{id}',$Id -replace '{domain}',$Domain
                    }
                } | Select-Object -Unique

            }
            'apiHeader'{
                If ($PSBoundParameters.ContainsKey('CmdletName') -and $CmdletName -match '-Mg') {
                    # if cmdlet is a graph cmdlet, then get the connect-* cmdlet
                    Write-Verbose -Message "Command: `$connecturi = `$permissionSet | Where-Object {`$_.moduleCmdlet -eq 'Connect-MgGraph' -and `$_.supportedEnv -eq '$Environment'} | foreach-object {`$_.apiResource} | Select-Object -Unique"
                    $apiHeader = $permissionSet | Where-Object { $_.moduleCmdlet -eq 'Connect-MgGraph' -and $_.supportedEnv -eq $Environment } | foreach-object { $_.apiResource } | Select-Object -Unique
                    $output += $apiHeader
                }
                $output += $collection | Where-Object $filterScript | Select-Object -ExpandProperty apiHeader -Unique
                # Filter out any unwanted values
                $output = $output | Where-Object { $_ -isnot [string] -or $_ -notlike 'https://*graph.microsoft.*' }
            }
            'support' {
                Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty supportLinks -Unique"
                $output += $collection | Where-Object $filterScript | Select-Object -ExpandProperty supportLinks -Unique
            }
            'appId'{
                Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty resourceAPIAppId -Unique"
                $output += $collection | Where-Object $filterScript | Select-Object -ExpandProperty resourceAPIAppId -Unique | ForEach-Object { $_.Split('#')[0] }
            }
            'role' {
                Try{
                    Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty sprolePermissions -Unique"
                    $output += $collection | Where-Object $filterScript | Where-Object { $null -ne $_.sprolePermissions } | Select-Object -ExpandProperty sprolePermissions -Unique
                }Catch{
                    $output += $null
                }
            }
            'oauthScope' {
                Write-Verbose -Message "Command: `$collection | Select-Object -ExpandProperty oauthScope -Unique"
                $output += $collection | Where-Object $filterScript | ForEach-Object {
                    $_.oauthScope -replace '{domain}',$Domain
                } | Where-Object { $_ -ne '' } | Select-Object -Unique
            }
            'all' {
                Write-Verbose -Message "Command: `$collection | Sort-Object"
                $objects += $collection | Where-Object $filterScript

                #replace domain and id if found in objects
                foreach ($object in $objects) {
                    $properties = $object.PSObject.Properties
                    foreach ($property in $properties) {
                        if ($property.Value -is [string]) {
                            # Replace in string values
                            $property.Value = ($property.Value -replace '{id}',$Id -replace '{domain}',$Domain -split '#')[0]
                        } elseif ($property.Value -is [array]) {
                            # Replace in array values while keeping it as an array
                            $property.Value = @($property.Value | ForEach-Object {
                                if ($_ -is [string]) {
                                    $_ -replace '{id}',$Id -replace '{domain}',$Domain
                                } else {
                                    $_
                                }
                            })
                        }
                    }
                }

                $output = $objects
            }
        }
    }
    End{
        return $output | Sort-Object
    }
}

Function Get-ScubaGearEntraMinimumPermissions{
    <#
    .SYNOPSIS
        This Function is used to retrieve the redundant permissions of the SCuBAGear module

    .DESCRIPTION
        This Function is used to retrieve the redundant permissions of the SCuBAGear module for aad only

    .PARAMETER Environment
        The Environment for which the permissions are to be retrieved. Options are 'commercial', 'gcc', 'gcchigh', 'dod'. Default is 'commercial'

    .EXAMPLE
        Get-ScubaGearEntraMinimumPermissions
    #>

    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('commercial', 'gcc', 'gcchigh', 'dod')]
        [string]$Environment = 'commercial'
    )

    # Create a list to hold the filtered permissions
    $filteredPermissions = @()

    # get all modules with least and higher permissions
    $allPermissions = Get-ScubaGearPermissions -Product aad -OutAs all -Environment $Environment

    # Compare the permissions to find the redundant ones
    $comparedPermissions = Compare-Object $allPermissions.leastPermissions $allPermissions.higherPermissions -IncludeEqual

    # filter to get the higher overwriting permissions
    $OverwriteHigherPermissions = $comparedPermissions | Where-Object {$_.SideIndicator -eq "=="} | Select-Object -ExpandProperty InputObject -Unique

    # loop thru each module and grab the least permissions unless the higher permissions is one from the $overriteHigherPermissions
    # Don't include the least permissions that are overwriten by the higher permissions
    foreach($permission in $allPermissions){
        if( (Compare-Object $permission.higherPermissions -DifferenceObject $OverwriteHigherPermissions -IncludeEqual).SideIndicator -notcontains "=="){
            $filteredPermissions += $permission
        }
    }

    $NewPermissions = @()
    # Build a new list of permissions that includes the least permissions and the higher permissions that overwrite them

    $NewPermissions += $filteredPermissions | Select-Object -ExpandProperty leastPermissions -Unique

    # include overwrite higher permissions
    $NewPermissions += $OverwriteHigherPermissions
    $NewPermissions = $NewPermissions | Sort-Object -Unique

    # Display the filtered permissions
    return $NewPermissions
}

Function Get-ServicePrincipalPermissions {
    <#
    .SYNOPSIS
        This Function is used to retrieve the permissions that are needed for running ScubaGear with a service principal

    .DESCRIPTION
        This Function is used to retrieve the permissions of the SCuBAGear module for service principals. It also accounts for the minimum permissions required for Entra roles which may overwrite least permissions.

    .PARAMETER Environment

        The Environment for which the permissions are to be retrieved. Options are 'commercial', 'gcc', 'gcchigh', 'dod'. Default is 'commercial'
        Different environments may have different minimum permissions, I.E. GCCHigh

    .EXAMPLE
        Get-ServicePrincipalPermissions
    #>

    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('commercial', 'gcc', 'gcchigh', 'dod')]
        [string]$Environment = 'commercial'
    )

    $ProductNames = "aad", "exo", "sharepoint", "securitysuite"

    # Create a list to hold the filtered permissions
    $filteredPermissions = @()

    # get all modules with least and higher permissions
    $allPermissions = $ProductNames | Get-ScubaGearPermissions -OutAs all -Environment $Environment -servicePrincipal

    # Only get overwrite higher permissions if AAD is in the product list
    if ($ProductNames -contains 'aad') {
        $OverwriteHigherPermissions = Get-ScubaGearEntraMinimumPermissions -Environment $Environment
    } else {
        $OverwriteHigherPermissions = @()
    }

    # if the ServicePrincipal switch is used, then add the appropriate resourceAPIAppId to $OverwriteHigherPermissions from line 356 by looking at the $allPermissions
    $newOverwriteHigherPermissions = @()
    if ($OverwriteHigherPermissions.Count -gt 0) {
        ForEach($permission in $OverwriteHigherPermissions) {
            $resourceAPIAppId = ($allPermissions | Where-Object { $_.leastPermissions -contains $permission } | Select-Object -ExpandProperty resourceAPIAppId -Unique)

            # Get the scubaGearProduct for this permission - combine all products that use this permission
            $products = ($allPermissions | Where-Object { $_.leastPermissions -contains $permission } | Select-Object -ExpandProperty scubaGearProduct) | Sort-Object -Unique

            $newObject = [PSCustomObject]@{
                resourceAPIAppId   = $resourceAPIAppId
                leastPermissions   = $permission
                scubaGearProduct   = $products  # This will be an array of all products
            }
            $newOverwriteHigherPermissions += $newObject
        }
    }

    # loop thru each module and grab the least permissions unless the higher permissions is one from the $overriteHigherPermissions
    # Don't include the least permissions that are overwriten by the higher permissions
    foreach($permission in $allPermissions){
        if ($OverwriteHigherPermissions.Count -eq 0 -or
            (Compare-Object $permission.higherPermissions -DifferenceObject $OverwriteHigherPermissions -IncludeEqual).SideIndicator -notcontains "=="){
            $filteredPermissions += $permission
        }
    }

    $NewPermissions = @()
    # Build a new list of permissions that includes the least permissions and the higher permissions that overwrite them

    $NewPermissions += $filteredPermissions

    # include overwrite higher permissions only if they exist
    if ($newOverwriteHigherPermissions.Count -gt 0) {
        $NewPermissions += $newOverwriteHigherPermissions
    }

    # Group by permission name and resourceAPIAppId to combine duplicate entries with different products
    $groupedPermissions = $NewPermissions | Group-Object -Property @{Expression={$_.leastPermissions}}, @{Expression={$_.resourceAPIAppId}}

    $deduplicatedPermissions = @()
    foreach ($group in $groupedPermissions) {
        # Combine all products from duplicate entries
        $allProducts = @()
        foreach ($item in $group.Group) {
            if ($item.scubaGearProduct) {
                # Handle both arrays and single values
                if ($item.scubaGearProduct -is [array]) {
                    $allProducts += $item.scubaGearProduct
                } else {
                    $allProducts += $item.scubaGearProduct
                }
            }
        }

        # Get unique products
        $uniqueProducts = $allProducts | Sort-Object -Unique

        # Take the first item and update its scubaGearProduct with all unique products
        $consolidatedItem = $group.Group[0].PSObject.Copy()
        $consolidatedItem.scubaGearProduct = $uniqueProducts

        $deduplicatedPermissions += $consolidatedItem
    }

    # Display the filtered permissions - return deduplicated results
    return $deduplicatedPermissions | Select-Object -Property LeastPermissions, ResourceAPIAppID, scubaGearProduct -Unique
}

Export-ModuleMember -Function Get-ScubaGearPermissions, Get-ScubaGearEntraMinimumPermissions, Get-ServicePrincipalPermissions