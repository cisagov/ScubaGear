Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../Utility/Utility.psm1') -Function Get-ScubaGearCatalog

Function Get-ScubaGearPermissions {
    <#
    .SYNOPSIS
        Retrieves the Graph/REST permission scopes required by ScubaGear.

    .DESCRIPTION
        Returns the leastPermissions (or higherPermissions) scopes for a product or a specific
        cmdlet. Base URLs, Graph request URIs, OAuth scopes, service principal roles and API
        headers are produced by the dedicated Get-ScubaGear* functions (Get-ScubaGearServiceEndpoint,
        Get-ScubaGearGraphEndpoint, Get-ScubaGearOAuthScope, Get-ScubaGearServicePrincipalRole,
        Get-ScubaGearApiHeader, Get-ScubaGearResourceAppId).

    .PARAMETER CmdletName
        The name of the cmdlet for which the permissions are to be retrieved.

    .PARAMETER PermissionLevel
        The level of permission to be retrieved. The possible values are 'least' and 'higher'. Default is 'least'.

    .PARAMETER ServicePrincipal
        The switch to indicate that the permissions are to be retrieved for a service principal.

    .PARAMETER Product
        The product for which the permissions are to be retrieved. Options are 'aad', 'exo', 'defender', 'securitysuite', 'teams', 'sharepoint', 'powerplatform'. Can be an array of products and used in pipeline. 'securitysuite' is an alias for 'defender' (the Security Suite).

    .PARAMETER Environment
        The Environment for which the permissions are to be retrieved. Options are 'commercial', 'gcc', 'gcchigh', 'dod'. Default is 'commercial'.

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaDirectorySetting

    .EXAMPLE
        Get-ScubaGearPermissions -CmdletName Get-MgBetaDirectorySetting -PermissionLevel higher

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad
        Get-ScubaGearPermissions -Product exo
        Get-ScubaGearPermissions -Product securitysuite

    .EXAMPLE
        Get-ScubaGearPermissions -Product aad -servicePrincipal

    .EXAMPLE
        'aad','scubatank' | Get-ScubaGearPermissions

    .NOTES
        NAME: Get-ScubaGearPermissions
        VERSION: 3.0

        USE TO FIND PERMS:
            (Find-MgGraphCommand -Command Get-MgBetaPolicyRoleManagementPolicyAssignment).Permissions | Select Name, IsLeastPrivilege
            Find-MgGraphPermission -All

        CHANGELOG:
        2024-10-03 - Initial version
        2024-12-20 - Added pipeline and multi-product support
        2026-06-19 - Added SecuritySuite and removed ScubaTank to product list
        2026-10-07 - Split -OutAs output modes into dedicated Get-ScubaGear* functions; catalog now keyed by functionName/entryType
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
        [ValidateSet('least', 'higher')]
        [Alias('PermissionType')]
        [string]$PermissionLevel = 'least',

        [Parameter(Mandatory = $false)]
        [ValidateSet('commercial', 'gcc', 'gcchigh', 'dod')]
        [string]$Environment = 'commercial'
    )
    Begin{
        $ErrorActionPreference = 'Stop'

        # If ProductName is * then set Product to all possible values
        if ($Product -contains '*') {
            $Product = @('aad', 'exo', 'securitysuite', 'teams', 'sharepoint', 'powerplatform')
        }

        # Permission records are every entry except the restHelper path-only records (those carry no grantable permission of their own).
        $permissionSet = Get-ScubaGearCatalog | Where-Object { $_.entryType -ne 'restHelper' }
        Write-Verbose "Command: `$permissionSet = Get-ScubaGearCatalog | Where-Object { `$_.entryType -ne 'restHelper' }"

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
                $conditions += {$_.functionName -eq $CmdletName}
                $conditionsmsg += '`$_.functionName -eq "' + $CmdletName + '"'
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

                If($true){
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

        # This function now returns only permission scopes. The former -OutAs modes (endpoint, api,
        # apiHeader, oauthScope, role, appId) each have a dedicated Get-ScubaGear* function.
        # The Graph connect record (graphConnect) carries only the auth-time User.Read scope, so it is excluded.
        If($PermissionLevel -eq 'least'){
            Write-Verbose -Message "Command: `$collection | Where-Object {`$_.entryType -ne 'graphConnect'} | Select-Object -ExpandProperty leastPermissions -Unique"
            $output += $collection | Where-Object {$_.entryType -ne 'graphConnect'} | Select-Object -ExpandProperty leastPermissions -Unique
        }
        else{
            Write-Verbose -Message "Command: `$collection | Where-Object {`$_.entryType -ne 'graphConnect'} | Select-Object -ExpandProperty higherPermissions -Unique"
            $output += $collection | Where-Object {$_.entryType -ne 'graphConnect'} | Select-Object -ExpandProperty higherPermissions -Unique
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
    $allPermissions = Get-ScubaGearProductRecord -Product aad -Environment $Environment

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
    $allPermissions = Get-ScubaGearProductRecord -Product $ProductNames -Environment $Environment

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

function Get-ScubaGearProductRecord {
    <#
    .SYNOPSIS
        Returns the full catalog records for the given product(s) and environment.
    .DESCRIPTION
        Replaces the former 'Get-ScubaGearPermissions -OutAs all' usage. restHelper path-only
        records are excluded automatically because they carry no supportedEnv.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Product,

        [Parameter(Mandatory = $false)]
        [ValidateSet('commercial', 'gcc', 'gcchigh', 'dod')]
        [string]$Environment = 'commercial'
    )
    Get-ScubaGearCatalog | Where-Object {
        $item = $_
        ($item.entryType -ne 'restHelper') -and
        ($Product | Where-Object { $item.scubaGearProduct -contains $_ }) -and
        ($item.supportedEnv -contains $Environment)
    }
}

function Get-ScubaGearServicePrincipalRole {
    <#
    .SYNOPSIS
        Returns the Entra directory role(s) a service principal needs for the given product(s).
    .DESCRIPTION
        Replaces the former 'Get-ScubaGearPermissions -OutAs role'.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Product,

        [Parameter(Mandatory = $false)]
        [ValidateSet('commercial', 'gcc', 'gcchigh', 'dod')]
        [string]$Environment = 'commercial'
    )
    process {
        Get-ScubaGearCatalog | Where-Object {
            $item = $_
            ($item.entryType -ne 'restHelper') -and
            ($Product | Where-Object { $item.scubaGearProduct -contains $_ }) -and
            ($item.supportedEnv -contains $Environment) -and
            (@($item.spRolePermissions).Count -gt 0)
        } | Select-Object -ExpandProperty spRolePermissions -Unique
    }
}

function Get-ScubaGearResourceAppId {
    <#
    .SYNOPSIS
        Returns the resource API application ID(s) for the given product(s)/environment.
    .DESCRIPTION
        Replaces the former 'Get-ScubaGearPermissions -OutAs appId'.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Product,

        [Parameter(Mandatory = $false)]
        [switch]$ServicePrincipal,

        [Parameter(Mandatory = $false)]
        [ValidateSet('commercial', 'gcc', 'gcchigh', 'dod')]
        [string]$Environment = 'commercial'
    )
    process {
        # -ServicePrincipal is accepted so callers can pass it, but the app IDs do not depend on the auth mode.
        $null = $ServicePrincipal
        Get-ScubaGearCatalog | Where-Object {
            $item = $_
            ($item.entryType -ne 'restHelper') -and
            ($Product | Where-Object { $item.scubaGearProduct -contains $_ }) -and
            ($item.supportedEnv -contains $Environment)
        } | Select-Object -ExpandProperty resourceAPIAppId -Unique | ForEach-Object { ($_ -split '#')[0] }
    }
}

function Get-ScubaGearEndpointRest {
    <#
    .SYNOPSIS
        Lists the REST API hosts that ScubaGear connects to, for building firewall or proxy allow lists.

    .DESCRIPTION
        Returns the service hosts ScubaGear calls to assess the selected products in the selected
        Microsoft 365 environment: Microsoft Graph plus each product's admin API. The list is read
        from ScubaGearApiCatalog.json, so it reflects the version of ScubaGear that is installed.

        Sign-in (Entra ID) hosts and hosts used only to install or update ScubaGear are not included.
        All connections use HTTPS on port 443.

        SharePoint admin hosts include the tenant name. Pass -Domain to get the real host name;
        otherwise the host is shown with a <tenant> placeholder.

    .PARAMETER ProductNames
        The products to include. Accepts the same values as Invoke-SCuBA. 'defender' is treated as
        'securitysuite', and '*' (the default) selects every product ScubaGear tests.

    .PARAMETER M365Environment
        The Microsoft 365 environment: 'commercial' (default), 'gcc', 'gcchigh' or 'dod'.

    .PARAMETER Domain
        The tenant name used in SharePoint admin host names, for example 'contoso' for contoso.onmicrosoft.com.

    .PARAMETER Format
        'Object' (default) returns one object per host and product. 'Hosts' returns the unique host names,
        one per line. 'Csv', 'Json' and 'Markdown' return text that can be pasted into a ticket or document.

    .PARAMETER OutFile
        Writes the output to this file as UTF-8 without a byte order mark. With -Format Object the file
        contains the 'Hosts' format.

    .PARAMETER Clipboard
        Copies the output to the clipboard. With -Format Object the clipboard receives the 'Hosts' format.

    .EXAMPLE
        Get-ScubaGearEndpointRest

        Lists the hosts for all products in a commercial tenant.

    .EXAMPLE
        Get-ScubaGearEndpointRest -ProductNames exo, teams -M365Environment gcchigh -Format Hosts

    .EXAMPLE
        Get-ScubaGearEndpointRest -M365Environment gcc -Domain contoso -Format Markdown -OutFile .\scubagear-hosts.md

    .FUNCTIONALITY
        Public
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject], [string])]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('teams', 'exo', 'defender', 'securitysuite', 'aad', 'powerplatform', 'sharepoint', 'powerbi', '*', IgnoreCase = $false)]
        [string[]]$ProductNames = '*',

        [Parameter(Mandatory = $false)]
        [ValidateSet('commercial', 'gcc', 'gcchigh', 'dod')]
        [string]$M365Environment = 'commercial',

        [Parameter(Mandatory = $false)]
        [ValidatePattern('^[A-Za-z0-9-]+$')]
        [string]$Domain,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Object', 'Hosts', 'Csv', 'Json', 'Markdown')]
        [string]$Format = 'Object',

        [Parameter(Mandatory = $false)]
        [string]$OutFile,

        [Parameter(Mandatory = $false)]
        [switch]$Clipboard
    )

    $AllProducts = 'aad', 'securitysuite', 'exo', 'powerplatform', 'sharepoint', 'teams', 'powerbi'
    $Products = if ($ProductNames -contains '*') { $AllProducts } else { $ProductNames -replace '^defender$', 'securitysuite' }
    $Products = @($Products | Sort-Object -Unique)

    # Teams also reads its tenant settings from the unified settings host, which the catalog lists as its own product.
    $CatalogProducts = @($Products | ForEach-Object { $_; if ($_ -eq 'teams') { 'teamsunified' } })

    $Catalog = @(Get-ScubaGearCatalog)

    # Every product's data comes from Microsoft Graph, so its host is needed whenever the catalog
    # has Graph resources for a selected product in this environment.
    $UsesGraph = [bool]($Catalog | Where-Object {
            $Item = $_
            $Item.entryType -eq 'graphResource' -and
            $Item.supportedEnv -contains $M365Environment -and
            ($Products | Where-Object { $Item.scubaGearProduct -contains $_ })
        })

    $Inventory = foreach ($Entry in $Catalog) {
        if ($Entry.entryType -notin 'graphConnect', 'restBase' -or $Entry.supportedEnv -notcontains $M365Environment) { continue }

        $EntryProducts = @($CatalogProducts | Where-Object { $Entry.scubaGearProduct -contains $_ })
        if ($Entry.entryType -eq 'graphConnect') {
            if (-not $UsesGraph) { continue }
            $Label = 'Microsoft Graph'
            $EntryProducts = $Products
        }
        elseif ($EntryProducts.Count -eq 0) { continue }
        else {
            # Purpose is the API named in the catalog note, e.g. "SharePoint Admin API".
            $Sentence = (([string]$Entry.notes) -split '(?<=\.)\s', 2)[0].Trim()
            $Label = if ($Sentence -match 'calls to the (.+?)\.?$') { $Matches[1] } else { $Sentence }
            # The unified settings host is listed under its own catalog product but belongs to Teams.
            $EntryProducts = @($EntryProducts -replace '^teamsunified$', 'teams')
        }

        $Placeholder = $Entry.endpointPath -match '\{domain\}'
        $BaseUrl = $Entry.endpointPath -replace '\{domain\}', $(if ($Domain) { $Domain } else { '<tenant>' })
        $HostName = ($BaseUrl -replace '^https?://', '') -replace '/.*$', ''

        [PSCustomObject]@{
            Host        = $HostName
            Port        = 443
            BaseUrl     = $BaseUrl
            Products    = ($EntryProducts | Sort-Object -Unique) -join ', '
            Environment = $M365Environment
            Purpose     = $Label
            Note        = $(if ($Placeholder -and -not $Domain) { 'Replace <tenant> with your tenant name, or pass -Domain.' } else { '' })
        }
    }
    $Inventory = @($Inventory | Sort-Object -Property Host, Products -Unique)

    $TextFormat = if ($Format -eq 'Object') { 'Hosts' } else { $Format }
    $Text = switch ($TextFormat) {
        'Hosts' { (@($Inventory.Host | Sort-Object -Unique)) -join [Environment]::NewLine }
        'Csv' { ($Inventory | ConvertTo-Csv -NoTypeInformation) -join [Environment]::NewLine }
        'Json' { ConvertTo-Json -InputObject @($Inventory) }
        'Markdown' {
            $Escape = { param($Value) ([string]$Value) -replace '\|', '\|' }
            $Lines = @('| Host | Port | Products | Purpose | Note |', '| --- | --- | --- | --- | --- |')
            $Lines += foreach ($Row in $Inventory) {
                "| $(& $Escape $Row.Host) | $($Row.Port) | $(& $Escape $Row.Products) | $(& $Escape $Row.Purpose) | $(& $Escape $Row.Note) |"
            }
            $Lines -join [Environment]::NewLine
        }
    }

    if ($OutFile) {
        $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)
        [System.IO.File]::WriteAllText($Path, $Text + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
    }
    if ($Clipboard) {
        if (Get-Command -Name Set-Clipboard -ErrorAction SilentlyContinue) { Set-Clipboard -Value $Text }
        else { Write-Warning 'Set-Clipboard is not available on this system; the clipboard was not changed.' }
    }

    if ($Format -eq 'Object') { return $Inventory }
    return $Text
}

Export-ModuleMember -Function Get-ScubaGearPermissions, Get-ScubaGearEntraMinimumPermissions, Get-ServicePrincipalPermissions, Get-ScubaGearServicePrincipalRole, Get-ScubaGearResourceAppId, Get-ScubaGearProductRecord, Get-ScubaGearEndpointRest