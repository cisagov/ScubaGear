<#
.SYNOPSIS
    Analyzer helper: Microsoft Graph connect, scopes, raw Graph reads, and tenant-data collection.
.NOTES
    Imported (Import-Module) by Start-SCuBAConfigAnalyzer alongside the other analyzer
    helpers. Shared analyzer state lives on the synchronized $syncHash ($syncHash.ScA*), so
    every helper module reads/writes the same caches (mirrors how ScubaConfigApp shares
    state). Populated at scan time by Import-ScA*.
    Part of the ScubaGear project - https://github.com/cisagov/ScubaGear
#>

function Write-ScAEngineActivity {
    <#
    .SYNOPSIS
    Reports a data-collection step to the analyzer Activity Log from engine (non-UI) code.
    .DESCRIPTION
    Engine helpers never touch WPF. Instead they append to the shared activity sink
    ($syncHash.ScAActivitySink) that the "Connect & Scan" worker points at $connectSync.Log;
    the UI's DispatcherTimer drains it onto the Activity Log tab. When no sink is present
    (headless unit tests, or the load-file path) it degrades to Write-Verbose only, so the
    engine stays UI-free and testable.
    #>
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info','Warning','Error')][string]$Level = 'Info'
    )
    Write-Verbose $Message
    # Attempt to write the activity to the shared sink, if available.
    try {
        if ($syncHash -and $null -ne $syncHash.ScAActivitySink) { [void]$syncHash.ScAActivitySink.Add(@{ Message = $Message; Level = $Level }) }
    } catch { Write-Verbose "Write-ScAEngineActivity sink failed: $($_.Exception.Message)" }
}

function Get-ScubaAnalyzerScopes {
    <#
    .SYNOPSIS
    Aggregates the Microsoft Graph delegated scopes a product needs, resolved from the API
    catalog: least permissions for every cmdlet named in the baseline schema (apiPermissionRef)
    plus every cmdlet behind a named analyzer apiOperation (CA read, organization, name
    lookups). Fully JSON-driven - the only hardcoded scope is a Directory.Read.All safety net
    used when the catalog cannot be read at all.
    #>
    param(
        [Parameter(Mandatory)][string]$Product,
        [Parameter(Mandatory)]$BaselineSchema,
        [string]$ApiCatalogPath,
        [string]$AnalyzerControlPath
    )

    # Import the API catalog and analyzer rules to resolve the required scopes.
    Import-ScAApiCatalog -ApiCatalogPath $ApiCatalogPath
    if ($AnalyzerControlPath -and (Test-Path $AnalyzerControlPath)) {
        try { Import-ScAAnalyzerRules -AnalyzerSchema (Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json) } catch { Write-Verbose "Analyzer rules load failed (scopes): $($_.Exception.Message)" }
    }

    # Normalize the product name to lowercase for consistent key lookups.
    $prod = $Product.ToLower()
    $cmdlets = @()

    # Initialize the list of cmdlets to aggregate scopes for.
    if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $prod) {
        foreach ($c in $BaselineSchema.baselineValidations.$prod) { if ($c.apiPermissionRef) { $cmdlets += $c.apiPermissionRef } }
    }

    # The named operations (CA read, organization, user/group/SP lookups) need scopes too.
    foreach ($op in $syncHash.ScAApiOperations.Values) { if ($op.cmdlet) { $cmdlets += [string]$op.cmdlet } }
    $cmdlets = @($cmdlets | Select-Object -Unique)

    # Aggregate the least permissions for each cmdlet to determine the required scopes.
    $scopes = New-Object System.Collections.Generic.HashSet[string]
    # Iterate over each cmdlet to collect its least permissions from the API catalog.
    foreach ($cmd in $cmdlets) {
        # Look up the API catalog entry for the current cmdlet.
        $entry = if ($syncHash.ScAApiCatalog.ContainsKey($cmd)) { $syncHash.ScAApiCatalog[$cmd] } else { $null }
        if ($entry -and $entry.leastPermissions) {
            foreach ($p in @($entry.leastPermissions)) { if ($p) { [void]$scopes.Add([string]$p) } }
        }
    }
    # Return the aggregated set of required scopes.
    if ($scopes.Count -eq 0) { [void]$scopes.Add('Directory.Read.All') }   # safety net when the catalog is unavailable

    # Ensure that there is at least one scope in the set, adding a default if necessary.
    return @($scopes)
}

function Connect-ScubaAnalyzerGraph {
    <#
    .SYNOPSIS
    Connects to Microsoft Graph for the given environment. Interactive (delegated scopes)
    by default; if -AppId + -CertificateThumbprint are supplied it uses non-interactive
    app-only certificate auth (application permissions, so -Scopes is ignored). Should be
    called on the UI thread for the interactive path. Returns Get-MgContext.
    #>
    param(
        [string[]]$Scopes = @(),
        [string]$M365Environment = 'commercial',
        [string]$AppId,
        [string]$CertificateThumbprint,
        [string]$Organization
    )

    # Import the Microsoft Graph Authentication module to enable connecting to Graph.
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    # Determine the appropriate Graph environment based on the specified M365 environment.
    $graphEnv = switch ($M365Environment) {
        'gcchigh' { 'USGov' }
        'dod'     { 'USGovDoD' }
        default   { 'Global' }
    }

    # Prepare the connection parameters for Connect-MgGraph.
    $connectParams = @{ Environment = $graphEnv; NoWelcome = $true; ErrorAction = 'Stop' }
    if ($AppId -and $CertificateThumbprint) {
        # App-only (non-interactive) certificate auth uses application permissions, not
        # delegated scopes, so -Scopes is intentionally not passed.
        $connectParams.ClientId = $AppId
        $connectParams.CertificateThumbprint = $CertificateThumbprint
        if ($Organization) { $connectParams.TenantId = $Organization }
    } else {
        $connectParams.Scopes = $Scopes
    }

    # Connect to Microsoft Graph using the prepared parameters.
    Connect-MgGraph @connectParams | Out-Null
    return (Get-MgContext)
}

function Invoke-ScubaGraphGet {
    <#
    .DESCRIPTION
    This function handles GET requests to Microsoft Graph, automatically following pagination links and aggregating results.
    .SYNOPSIS
    GETs a Graph resource with Invoke-MgGraphRequest (raw REST, only needs
    Microsoft.Graph.Authentication) and follows @odata.nextLink paging. Returns the
    collected .value items (or the single object for non-collection resources).
    #>
    param([Parameter(Mandatory)][string]$Uri)

    $items = @()
    $next = $Uri
    # Loop through the paginated results until there are no more pages.
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType PSObject -ErrorAction Stop
        if ($null -eq $resp) { break }
        # Break the loop if the response is null, indicating no more data.
        if ($resp.PSObject.Properties.Name -contains 'value') {
            $items += @($resp.value)
            $next = if ($resp.PSObject.Properties.Name -contains '@odata.nextLink') { $resp.'@odata.nextLink' } else { $null }
        }
        else {
            $items += $resp
            $next = $null
        }
    }

    # Return the aggregated collection of items from all pages.
    return $items
}

function Get-ScADisplayNameLookup {
    <#
    .SYNOPSIS
    Best-effort resolve of display names for excluded principals/apps across the given
    Conditional Access policies. Which policy paths to read and which Graph operation resolves
    each are declared in the analyzer schema's displayNameLookup rules (the actual URLs come
    from the API catalog). Returns id -> name to annotate the generated YAML. Requires an
    active Graph connection; per-id failures are ignored.
    #>
    param([array]$Policies = @())

    $lookup = @{}
    $rules = $syncHash.ScACaRules
    # Return early if there are no displayNameLookup rules defined.
    if (-not $rules -or -not $rules.displayNameLookup -or -not $rules.displayNameLookup.rules) { return $lookup }
    $guidRe = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

    # Regular expression to match GUIDs.
    foreach ($rule in @($rules.displayNameLookup.rules)) {
        $ids = @()
        # Collect all IDs from the current policy according to the rule's policy path.
        foreach ($p in @($Policies)) { $ids += @(Get-ScAValueAtPath -Object $p -Path $rule.policyPath) }
        $ids = @($ids | Where-Object { $_ -match $guidRe } | Select-Object -Unique)
        if (@($ids).Count -eq 0) { continue }

        # Skip this rule if there are no valid IDs to look up.
        $op = if ($syncHash.ScAApiOperations.ContainsKey([string]$rule.operation)) { $syncHash.ScAApiOperations[[string]$rule.operation] } else { $null }
        $nameProps = if ($op -and $op.nameProperties) { @($op.nameProperties) } else { @('displayName') }

        # Resolve each ID to its display name using the specified API operation and name properties.
        foreach ($id in $ids) {
            $uri = Resolve-ScAApiResource -Operation ([string]$rule.operation) -Id $id
            if (-not $uri) { continue }
            # Skip this ID if the URI could not be resolved.
            try {
                $o = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject -ErrorAction Stop
                if ($o) {
                    foreach ($np in $nameProps) {
                        $val = ($o.PSObject.Properties | Where-Object { $_.Name -ieq [string]$np } | Select-Object -First 1).Value
                        if ($val) { $lookup[$id] = $val; break }
                    }
                }
            } catch { 
                # Handle any errors that occur during the display name lookup.
                Write-Verbose "Display-name lookup failed for '$id': $($_.Exception.Message)" 
            }
        }
    }

    # Return the lookup table containing the resolved display names.
    return $lookup
}

function Get-ScAUserPrincipalNameLookup {
    <#
    .SYNOPSIS
    Resolves the user object ids referenced by the CA policies (the displayNameLookup rules
    whose operation is 'userLookup' - i.e. include/exclude users) to their userPrincipalName.
    The tenant governance JSON emits users by UPN (the monitor compares users by UPN), while
    the generated YAML keeps display names - so this is a separate, user-only map.
    #>
    param([array]$Policies = @())

    $lookup = @{}
    # Extract the relevant displayNameLookup rules from the schema.
    $rules = $syncHash.ScACaRules
    # If there are no displayNameLookup rules, skip the user UPN resolution.
    if (-not $rules -or -not $rules.displayNameLookup -or -not $rules.displayNameLookup.rules) {
        Write-ScAEngineActivity "User UPN resolution: no displayNameLookup rules loaded - skipped." -Level Warning
        return $lookup
    }
    # Extract the policy paths for the 'userLookup' operation from the displayNameLookup rules.
    $userPaths = @($rules.displayNameLookup.rules | Where-Object { [string]$_.operation -eq 'userLookup' } | ForEach-Object { [string]$_.policyPath })
    if (@($userPaths).Count -eq 0) {
        Write-ScAEngineActivity "User UPN resolution: no 'userLookup' paths declared in the schema - skipped." -Level Warning
        return $lookup
    }
    # Prepare a regular expression to validate GUIDs for user IDs.
    $guidRe = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

    $ids = @()
    # Initialize an array to store the user IDs extracted from the policies.
    # Extract the user IDs from each policy at the specified paths.
    foreach ($p in @($Policies)) { foreach ($path in $userPaths) { $ids += @(Get-ScAValueAtPath -Object $p -Path $path) } }
    # Filter the extracted IDs to include only valid GUIDs and remove duplicates.
    $ids = @($ids | Where-Object { $_ -match $guidRe } | Select-Object -Unique)
    Write-ScAEngineActivity "User UPN resolution: $(@($ids).Count) distinct user id(s) found via $(@($userPaths).Count) path(s) ($($userPaths -join ', ')) across $(@($Policies).Count) policy/policies."
    
    # If no valid user IDs were found, skip the user UPN resolution.
    if (@($ids).Count -eq 0) { return $lookup }

    # Iterate over each valid user ID to resolve its corresponding user principal name (UPN) via the Microsoft Graph API.
    foreach ($id in $ids) {
        $uri = Resolve-ScAApiResource -Operation 'userLookup' -Id $id
        # If the URI could not be resolved, log a warning and continue to the next user ID.
        if (-not $uri) { Write-ScAEngineActivity "User UPN resolution: could not resolve a Graph URI for user '$id'." -Level Warning; continue }
        # Attempt to resolve the user principal name (UPN) for the current user ID.
        try {
            $o = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject -ErrorAction Stop
            $upn = if ($o) { ($o.PSObject.Properties | Where-Object { $_.Name -ieq 'userPrincipalName' } | Select-Object -First 1).Value } else { $null }
            if ($upn) { $lookup[$id] = $upn }
            else { Write-ScAEngineActivity "User UPN resolution: user '$id' returned no userPrincipalName." -Level Warning }
        } catch { Write-ScAEngineActivity "User UPN lookup failed for '$id': $($_.Exception.Message)" -Level Warning }
    }

    Write-ScAEngineActivity "User UPN resolution: resolved $(@($lookup.Keys).Count) of $(@($ids).Count) user principal name(s)."
    
    # Return the lookup table containing resolved user principal names (UPNs) keyed by user ID.
    return $lookup
}

function Get-ScubaTenantGraphData {
    <#
    .SYNOPSIS
    Reads the live tenant configuration a product's controls need using ONLY Microsoft
    Graph authentication + raw Graph API calls (Invoke-MgGraphRequest). The resource
    path is resolved from the JSON (API catalog 'apiResource' for the cmdlet named in
    the baseline schema's apiPermissionRef, falling back to buildInstructions
    .apiResourceCreate) so the schema stays the single source of truth and can change
    without code edits. Requires an existing Graph connection (Connect-ScubaAnalyzerGraph).

    The REST response is camelCase; the validation engine navigates policy properties
    case-insensitively, so no reshaping is needed.
    #>
    param(
        [Parameter(Mandatory)][string]$Product,
        [Parameter(Mandatory)]$BaselineSchema,
        [string]$ApiCatalogPath,
        [string]$AnalyzerControlPath
    )

    # Ensure the Microsoft Graph Authentication module is imported for subsequent Graph API calls.
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    # Load the analyzer rules (named operations) + API catalog so every URL below is
    # resolved from ScubaGearApiCatalog.json rather than hardcoded here.
    if ($AnalyzerControlPath -and (Test-Path $AnalyzerControlPath)) {
        try { Import-ScAAnalyzerRules -AnalyzerSchema (Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json) } catch { Write-Verbose "Analyzer rules load failed (tenant data): $($_.Exception.Message)" }
    }
    # Ensure the API catalog is loaded for resolving resource URIs.
    Import-ScAApiCatalog -ApiCatalogPath $ApiCatalogPath
    # Initialize the data structure to hold tenant and organization information.
    $data = @{ 
        conditional_access_policies = @(); 
        OrgDisplayName = $null; 
        Organization = $null; 
        TenantId = $null; 
        DisplayNameLookup = @{}; 
        UserUpnLookup = @{} }

    # Determine the product-specific controls from the baseline schema.
    $prod = $Product.ToLower()
    $controls = @()

    # Check if the baseline schema contains validations for the specified product.
    if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $prod) {
        $controls = @($BaselineSchema.baselineValidations.$prod)
    }

    # Tenant identity + organization (resource resolved from the catalog).
    try { $ctx = Get-MgContext; if ($ctx) { $data.TenantId = $ctx.TenantId } } catch { Write-Verbose "Get-MgContext unavailable: $($_.Exception.Message)" }
    # Retrieve the current Microsoft Graph context to obtain the tenant ID.
    try {
        $orgUri = Resolve-ScAApiResource -Operation 'organization'
        # Resolve the organization resource URI from the API catalog.
        if ($orgUri) {
            Write-ScAEngineActivity "[$prod] Reading organization details ($orgUri)."
            $org = @(Invoke-ScubaGraphGet -Uri $orgUri)
            # Check if the organization details were successfully retrieved.
            if (@($org).Count -gt 0) {
                $data.OrgDisplayName = $org[0].displayName
                # Organization = the tenant's PRIMARY (default) verified domain, so a custom
                # domain set as primary is used. Fall back to the initial onmicrosoft.com
                # domain, then to the first verified domain.
                $domains = @($org[0].verifiedDomains)
                $primary = @($domains | Where-Object { $_.isDefault -eq $true })
                # If no primary domain is found, fall back to the initial domain.
                if (@($primary).Count -eq 0) { $primary = @($domains | Where-Object { $_.isInitial -eq $true }) }
                # If still no primary domain is found, use the first verified domain.
                if (@($primary).Count -eq 0) { $primary = $domains }
                # Set the organization's primary domain.
                if (@($primary).Count -gt 0) { $data.Organization = $primary[0].name }
                Write-ScAEngineActivity "[$prod] Organization '$($data.OrgDisplayName)' (primary domain: $($data.Organization); $(@($domains).Count) verified domain(s); tenant $($data.TenantId))."
            }
        }
    } catch { Write-ScAEngineActivity "Organization lookup failed: $($_.Exception.Message)" -Level Warning }

    # Conditional Access policies: read only when a control uses the CA operation's cmdlet.
    $caOp = if ($syncHash.ScAApiOperations.ContainsKey('conditionalAccessPolicies')) { $syncHash.ScAApiOperations['conditionalAccessPolicies'] } else { $null }
    $caCmdlet = if ($caOp) { [string]$caOp.cmdlet } else { $null }
    # Determine if any controls use the Conditional Access cmdlet.
    $usesCa = $caCmdlet -and (@($controls | Where-Object { $_.apiPermissionRef -eq $caCmdlet }).Count -gt 0)
    if ($usesCa) {
        # Resolve the API resource URI for Conditional Access policies.
        $uri = Resolve-ScAApiResource -Operation 'conditionalAccessPolicies'
        if (-not $uri) {
            # Fall back to the baseline's own create-resource for the CA cmdlet if the catalog lacks it.
            $caControl = @($controls | Where-Object { $_.apiPermissionRef -eq $caCmdlet -and $_.buildInstructions.apiResourceCreate })[0]
            if ($caControl) { $uri = $caControl.buildInstructions.apiResourceCreate }
        }
        # If no URI could be resolved, skip reading Conditional Access policies.
        if ($uri) {
            Write-ScAEngineActivity "[$prod] Reading Conditional Access policies ($uri)."
            $data.conditional_access_policies = @(Invoke-ScubaGraphGet -Uri $uri)
            $caCount = @($data.conditional_access_policies).Count
            Write-ScAEngineActivity "[$prod] Retrieved $caCount Conditional Access policy/policies."
            # Log each retrieved Conditional Access policy.
            foreach ($pol in @($data.conditional_access_policies)) {
                $pName  = if ($pol.displayName) { [string]$pol.displayName } else { [string]$pol.id }
                $pState = if ($pol.state) { [string]$pol.state } else { 'unknown' }
                Write-ScAEngineActivity "[$prod]   - CA policy '$pName' (state: $pState)."
            }
            # Resolve display names for excluded principals/apps so the generated YAML can be annotated.
            try {
                $data.DisplayNameLookup = Get-ScADisplayNameLookup -Policies $data.conditional_access_policies
                # Log the number of resolved display names for excluded principals/apps.
                if (@($data.DisplayNameLookup.Keys).Count -gt 0) {
                    Write-ScAEngineActivity "[$prod] Resolved $(@($data.DisplayNameLookup.Keys).Count) excluded principal/app display name(s)."
                }
            } catch { Write-ScAEngineActivity "Display-name resolution skipped: $($_.Exception.Message)" -Level Warning }
            # Users are emitted by UPN in the tenant governance JSON (the monitor compares users by UPN).
            try {
                $data.UserUpnLookup = Get-ScAUserPrincipalNameLookup -Policies $data.conditional_access_policies
            } catch { Write-ScAEngineActivity "User UPN resolution skipped: $($_.Exception.Message)" -Level Warning }
        }
    }

    # Non-CA provider data (e.g. EXO remote domains, anti-phish policies). Each exclusion
    # type may declare its own analysis+fetch (exclusionDefinitions.<field>.analysis); when a
    # baseline control for this product uses that cmdlet, best-effort fetch it and store under
    # rawKey so Get-ScAProviderAnalysis reads it exactly like the offline ScubaResults Raw.<key>.
    $fetched = @{}
    # Iterate over each exclusion type defined in the schema to fetch non-CA provider data.
    foreach ($field in @($syncHash.ScAExclusionDefinitions.Keys)) {
        $an = $syncHash.ScAExclusionDefinitions[$field].analysis
        if (-not $an -or -not $an.fetch -or -not $an.rawKey) { continue }

        # Extract the cmdlet name and raw key for this exclusion type.
        $cmdName = [string]$an.fetch.cmdlet
        $rawKey  = [string]$an.rawKey

        # Skip if no cmdlet is specified or if this raw key has already been fetched.
        if (-not $cmdName -or $fetched.ContainsKey($rawKey)) { continue }
        # Only fetch when a baseline control for this product depends on this cmdlet.
        if (@($controls | Where-Object { $_.apiPermissionRef -eq $cmdName }).Count -eq 0) { continue }

        # Log the attempt to fetch provider data for this exclusion type.
        try {
            Write-ScAEngineActivity "[$prod] Reading provider data via $cmdName (-> $rawKey)."
            $items = Get-ScAExchangeData -Fetch $an.fetch -Organization $data.Organization
            # Store the fetched items under the raw key if any were retrieved.
            if ($null -ne $items) {
                $data[$rawKey] = @($items); $fetched[$rawKey] = $true
                Write-ScAEngineActivity "[$prod] Retrieved $(@($items).Count) record(s) from $cmdName."
            }
        } catch {
            Write-ScAEngineActivity "Provider fetch '$cmdName' failed: $($_.Exception.Message)" -Level Warning
        }
    }

    # Return the updated data object containing all fetched provider data.
    return $data
}

function Get-ScubaAnalyzerFetchConnections {
    <#
    .SYNOPSIS
    Returns the distinct provider connections (module/connectCmdlet) the selected products
    need, driven entirely by the schema: an exclusion type's analysis.fetch is required when
    a baseline control for a selected product uses that fetch cmdlet. The UI uses this to
    connect (e.g. Exchange Online) up front on the sign-in thread when EXO/SecuritySuite is
    checked, so the live reads succeed.
    .OUTPUTS
    @( @{ module; connectCmdlet; cmdlet }, ... )  (empty when only Graph is needed)
    #>
    param(
        [Parameter(Mandatory)][string[]]$Products,
        [Parameter(Mandatory)]$BaselineSchema,
        [string]$AnalyzerControlPath
    )

    # Import analyzer rules from the specified control path if it exists.
    if ($AnalyzerControlPath -and (Test-Path $AnalyzerControlPath)) {
        try { Import-ScAAnalyzerRules -AnalyzerSchema (Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json) } catch { Write-Verbose "Analyzer rules load failed (fetch connections): $($_.Exception.Message)" }
    }

    # Initialize a hash set to keep track of all unique cmdlets referenced by the selected products.
    $cmdlets = New-Object System.Collections.Generic.HashSet[string]
    # Iterate over each selected product and collect all cmdlets referenced in its baseline validations.
    foreach ($p in $Products) {
        $pl = $p.ToLower()
        
        # Check if the baseline schema contains validations for the current product.
        if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $pl) {
            foreach ($c in $BaselineSchema.baselineValidations.$pl) { if ($c.apiPermissionRef) { [void]$cmdlets.Add([string]$c.apiPermissionRef) } }
        }
    }

    $conns = [ordered]@{}
    # Iterate over each exclusion definition in the analyzer rules and collect the necessary connection information for the cmdlets used.
    foreach ($field in @($syncHash.ScAExclusionDefinitions.Keys)) {
        $an = $syncHash.ScAExclusionDefinitions[$field].analysis
        # Skip this exclusion definition if it doesn't have a fetch analysis.
        if (-not $an -or -not $an.fetch) { continue }
        $cmd = [string]$an.fetch.cmdlet
        # Skip this exclusion definition if the cmdlet is not used by any of the selected products.
        if (-not $cmdlets.Contains($cmd)) { continue }
        # Get the connection key for the fetch cmdlet.
        $key = [string]$an.fetch.connectCmdlet
        if ($key -and -not $conns.Contains($key)) {
            $conns[$key] = @{ module = [string]$an.fetch.module; connectCmdlet = $key; cmdlet = $cmd }
        }
    }

    # Return the collected connection information as an array of hashtables.
    return @($conns.Values)
}