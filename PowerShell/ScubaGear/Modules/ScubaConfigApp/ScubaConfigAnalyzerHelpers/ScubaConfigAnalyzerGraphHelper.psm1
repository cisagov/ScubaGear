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

    Import-ScAApiCatalog -ApiCatalogPath $ApiCatalogPath
    if ($AnalyzerControlPath -and (Test-Path $AnalyzerControlPath)) {
        try { Import-ScAAnalyzerRules -AnalyzerSchema (Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json) } catch { Write-Verbose "Analyzer rules load failed (scopes): $($_.Exception.Message)" }
    }

    $prod = $Product.ToLower()
    $cmdlets = @()
    if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $prod) {
        foreach ($c in $BaselineSchema.baselineValidations.$prod) { if ($c.apiPermissionRef) { $cmdlets += $c.apiPermissionRef } }
    }
    # The named operations (CA read, organization, user/group/SP lookups) need scopes too.
    foreach ($op in $syncHash.ScAApiOperations.Values) { if ($op.cmdlet) { $cmdlets += [string]$op.cmdlet } }
    $cmdlets = @($cmdlets | Select-Object -Unique)

    $scopes = New-Object System.Collections.Generic.HashSet[string]
    foreach ($cmd in $cmdlets) {
        $entry = if ($syncHash.ScAApiCatalog.ContainsKey($cmd)) { $syncHash.ScAApiCatalog[$cmd] } else { $null }
        if ($entry -and $entry.leastPermissions) {
            foreach ($p in @($entry.leastPermissions)) { if ($p) { [void]$scopes.Add([string]$p) } }
        }
    }
    if ($scopes.Count -eq 0) { [void]$scopes.Add('Directory.Read.All') }   # safety net when the catalog is unavailable
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

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    $graphEnv = switch ($M365Environment) {
        'gcchigh' { 'USGov' }
        'dod'     { 'USGovDoD' }
        default   { 'Global' }
    }
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
    Connect-MgGraph @connectParams | Out-Null
    return (Get-MgContext)
}

function Invoke-ScubaGraphGet {
    <#
    .SYNOPSIS
    GETs a Graph resource with Invoke-MgGraphRequest (raw REST, only needs
    Microsoft.Graph.Authentication) and follows @odata.nextLink paging. Returns the
    collected .value items (or the single object for non-collection resources).
    #>
    param([Parameter(Mandatory)][string]$Uri)

    $items = @()
    $next = $Uri
    while ($next) {
        $resp = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType PSObject -ErrorAction Stop
        if ($null -eq $resp) { break }
        if ($resp.PSObject.Properties.Name -contains 'value') {
            $items += @($resp.value)
            $next = if ($resp.PSObject.Properties.Name -contains '@odata.nextLink') { $resp.'@odata.nextLink' } else { $null }
        }
        else {
            $items += $resp
            $next = $null
        }
    }
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
    if (-not $rules -or -not $rules.displayNameLookup -or -not $rules.displayNameLookup.rules) { return $lookup }
    $guidRe = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

    foreach ($rule in @($rules.displayNameLookup.rules)) {
        $ids = @()
        foreach ($p in @($Policies)) { $ids += @(Get-ScAValueAtPath -Object $p -Path $rule.policyPath) }
        $ids = @($ids | Where-Object { $_ -match $guidRe } | Select-Object -Unique)
        if (@($ids).Count -eq 0) { continue }

        $op = if ($syncHash.ScAApiOperations.ContainsKey([string]$rule.operation)) { $syncHash.ScAApiOperations[[string]$rule.operation] } else { $null }
        $nameProps = if ($op -and $op.nameProperties) { @($op.nameProperties) } else { @('displayName') }

        foreach ($id in $ids) {
            $uri = Resolve-ScAApiResource -Operation ([string]$rule.operation) -Id $id
            if (-not $uri) { continue }
            try {
                $o = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject -ErrorAction Stop
                if ($o) {
                    foreach ($np in $nameProps) {
                        $val = ($o.PSObject.Properties | Where-Object { $_.Name -ieq [string]$np } | Select-Object -First 1).Value
                        if ($val) { $lookup[$id] = $val; break }
                    }
                }
            } catch { Write-Verbose "Display-name lookup failed for '$id': $($_.Exception.Message)" }
        }
    }
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

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

    # Load the analyzer rules (named operations) + API catalog so every URL below is
    # resolved from ScubaGearApiCatalog.json rather than hardcoded here.
    if ($AnalyzerControlPath -and (Test-Path $AnalyzerControlPath)) {
        try { Import-ScAAnalyzerRules -AnalyzerSchema (Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json) } catch { Write-Verbose "Analyzer rules load failed (tenant data): $($_.Exception.Message)" }
    }
    Import-ScAApiCatalog -ApiCatalogPath $ApiCatalogPath

    $data = @{ conditional_access_policies = @(); OrgDisplayName = $null; Organization = $null; TenantId = $null; DisplayNameLookup = @{} }

    $prod = $Product.ToLower()
    $controls = @()
    if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $prod) {
        $controls = @($BaselineSchema.baselineValidations.$prod)
    }

    # Tenant identity + organization (resource resolved from the catalog).
    try { $ctx = Get-MgContext; if ($ctx) { $data.TenantId = $ctx.TenantId } } catch { Write-Verbose "Get-MgContext unavailable: $($_.Exception.Message)" }
    try {
        $orgUri = Resolve-ScAApiResource -Operation 'organization'
        if ($orgUri) {
            $org = @(Invoke-ScubaGraphGet -Uri $orgUri)
            if (@($org).Count -gt 0) {
                $data.OrgDisplayName = $org[0].displayName
                # Organization = the tenant's PRIMARY (default) verified domain, so a custom
                # domain set as primary is used. Fall back to the initial onmicrosoft.com
                # domain, then to the first verified domain.
                $domains = @($org[0].verifiedDomains)
                $primary = @($domains | Where-Object { $_.isDefault -eq $true })
                if (@($primary).Count -eq 0) { $primary = @($domains | Where-Object { $_.isInitial -eq $true }) }
                if (@($primary).Count -eq 0) { $primary = $domains }
                if (@($primary).Count -gt 0) { $data.Organization = $primary[0].name }
            }
        }
    } catch { Write-Verbose "Organization lookup failed: $($_.Exception.Message)" }

    # Conditional Access policies: read only when a control uses the CA operation's cmdlet.
    $caOp = if ($syncHash.ScAApiOperations.ContainsKey('conditionalAccessPolicies')) { $syncHash.ScAApiOperations['conditionalAccessPolicies'] } else { $null }
    $caCmdlet = if ($caOp) { [string]$caOp.cmdlet } else { $null }
    $usesCa = $caCmdlet -and (@($controls | Where-Object { $_.apiPermissionRef -eq $caCmdlet }).Count -gt 0)
    if ($usesCa) {
        $uri = Resolve-ScAApiResource -Operation 'conditionalAccessPolicies'
        if (-not $uri) {
            # Fall back to the baseline's own create-resource for the CA cmdlet if the catalog lacks it.
            $caControl = @($controls | Where-Object { $_.apiPermissionRef -eq $caCmdlet -and $_.buildInstructions.apiResourceCreate })[0]
            if ($caControl) { $uri = $caControl.buildInstructions.apiResourceCreate }
        }
        if ($uri) {
            $data.conditional_access_policies = @(Invoke-ScubaGraphGet -Uri $uri)
            # Resolve display names for excluded principals/apps so the generated YAML can be annotated.
            try { $data.DisplayNameLookup = Get-ScADisplayNameLookup -Policies $data.conditional_access_policies } catch { Write-Verbose "Display-name resolution skipped: $($_.Exception.Message)" }
        }
    }

    # Non-CA provider data (e.g. EXO remote domains, anti-phish policies). Each exclusion
    # type may declare its own analysis+fetch (exclusionDefinitions.<field>.analysis); when a
    # baseline control for this product uses that cmdlet, best-effort fetch it and store under
    # rawKey so Get-ScAProviderAnalysis reads it exactly like the offline ScubaResults Raw.<key>.
    $fetched = @{}
    foreach ($field in @($syncHash.ScAExclusionDefinitions.Keys)) {
        $an = $syncHash.ScAExclusionDefinitions[$field].analysis
        if (-not $an -or -not $an.fetch -or -not $an.rawKey) { continue }
        $cmdName = [string]$an.fetch.cmdlet
        $rawKey  = [string]$an.rawKey
        if (-not $cmdName -or $fetched.ContainsKey($rawKey)) { continue }
        # Only fetch when a baseline control for this product depends on this cmdlet.
        if (@($controls | Where-Object { $_.apiPermissionRef -eq $cmdName }).Count -eq 0) { continue }

        try {
            $items = Get-ScAExchangeData -Fetch $an.fetch -Organization $data.Organization
            if ($null -ne $items) { $data[$rawKey] = @($items); $fetched[$rawKey] = $true }
        } catch {
            Write-Warning "Provider fetch '$cmdName' failed: $($_.Exception.Message)"
        }
    }

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

    if ($AnalyzerControlPath -and (Test-Path $AnalyzerControlPath)) {
        try { Import-ScAAnalyzerRules -AnalyzerSchema (Get-Content $AnalyzerControlPath -Raw | ConvertFrom-Json) } catch { Write-Verbose "Analyzer rules load failed (fetch connections): $($_.Exception.Message)" }
    }

    $cmdlets = New-Object System.Collections.Generic.HashSet[string]
    foreach ($p in $Products) {
        $pl = $p.ToLower()
        if ($BaselineSchema.baselineValidations.PSObject.Properties.Name -contains $pl) {
            foreach ($c in $BaselineSchema.baselineValidations.$pl) { if ($c.apiPermissionRef) { [void]$cmdlets.Add([string]$c.apiPermissionRef) } }
        }
    }

    $conns = [ordered]@{}
    foreach ($field in @($syncHash.ScAExclusionDefinitions.Keys)) {
        $an = $syncHash.ScAExclusionDefinitions[$field].analysis
        if (-not $an -or -not $an.fetch) { continue }
        $cmd = [string]$an.fetch.cmdlet
        if (-not $cmdlets.Contains($cmd)) { continue }
        $key = [string]$an.fetch.connectCmdlet
        if ($key -and -not $conns.Contains($key)) {
            $conns[$key] = @{ module = [string]$an.fetch.module; connectCmdlet = $key; cmdlet = $cmd }
        }
    }
    return @($conns.Values)
}

