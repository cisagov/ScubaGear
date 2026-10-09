function Get-AADLicenseState {
    <#
    .SYNOPSIS
    Returns a simple, robust view of the tenant's license state for Entra ID scenarios.

    .DESCRIPTION
    Derives license state from subscribed SKUs/service plans. This avoids relying on
    commerce/billing APIs that are not consistently available via Graph. The goal is to
    give the provider a safe, non-crashing signal for gating optional calls and for
    reporting.

    .PARAMETER SubscribedSku
    Array/object returned from Get-MgBetaSubscribedSku (or equivalent Tracker call).

    .PARAMETER LicenseWarningDays
    Threshold in days for marking licenses as expiring soon. Currently unused because
    expiration data is not available from the provided inputs. Kept for future extension.

    .OUTPUTS
    Hashtable with keys: state, has_any_sku, has_active_plans, is_expired, days_until_expiration,
    is_expiring_soon, state_reason
    #>
    param (
        [Parameter(Mandatory=$false)]
        $SubscribedSku,

        [Parameter(Mandatory=$false)]
        [int]
        $LicenseWarningDays = 30
    )

    $hasAnySku = $false
    $hasActivePlans = $false

    try {
        $hasAnySku = @($SubscribedSku).Count -gt 0
    } catch {
        $hasAnySku = $false
    }

    if ($hasAnySku) {
        try {
            $servicePlans = $SubscribedSku.ServicePlans
            if ($servicePlans) {
                $hasActivePlans = ($servicePlans | Where-Object -Property ProvisioningStatus -eq -Value "Success") | ForEach-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
                $hasActivePlans = [bool]($hasActivePlans -gt 0)
            } else {
                $hasActivePlans = $false
            }
        } catch {
            $hasActivePlans = $false
        }
    }

    # Derive state
    $state = "Unknown"
    $reason = "State could not be determined from subscribed SKUs."

    if (-not $hasAnySku) {
        $state = "NoLicense"
        $reason = "No subscribed SKUs were found for the tenant."
    }
    elseif ($hasActivePlans) {
        $state = "Active"
        $reason = "At least one service plan is provisioned successfully."
    }
    else {
        $state = "Inactive"
        $reason = "Subscribed SKUs exist but no service plans are provisioned successfully."
    }

    # Expiration signals are not available from SubscribedSku; keep null/false for now
    $result = @{
        state = $state
        has_any_sku = $hasAnySku
        has_active_plans = $hasActivePlans
        is_expired = ($state -eq "Inactive") # best-effort; may represent disabled/expired/suspended
        days_until_expiration = $null
        is_expiring_soon = $false
        state_reason = $reason
        warning_days_threshold = $LicenseWarningDays
    }

    return $result
}


function Get-CachedSubscribedSku {
    <#
    .SYNOPSIS
        Returns subscribed SKUs, cached per M365Environment for the current run.
    .DESCRIPTION
        Memoizes GET /subscribedSkus so Connect-Tenant and Export-AADProvider
        share one Graph call instead of hitting the API twice per run (#2338).
        The caller injects -Fetcher; this module never calls Graph itself.
        Empty/null results are NOT cached: TryCommand returns @() on failure
        and caching that would poison later calls with fail-open data.
        Call Clear-SkuCache at run start (Connect-Tenant) for long sessions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$M365Environment = "commercial",
        [Parameter(Mandatory = $false)]
        [switch]$Reset,
        [Parameter(Mandatory = $false)]
        [scriptblock]$Fetcher = $null
    )
    if (-not (Test-Path variable:script:__SkuCache)) {
        $script:__SkuCache = @{}
    }
    if ($Reset) {
        $script:__SkuCache.Remove($M365Environment)
        return $null
    }
    if ($script:__SkuCache.ContainsKey($M365Environment)) {
        return $script:__SkuCache[$M365Environment]
    }
    if ($null -eq $Fetcher) {
        throw "Get-CachedSubscribedSku: cache miss and no -Fetcher provided."
    }
    $result = & $Fetcher $M365Environment
    if ($null -ne $result -and @($result).Count -gt 0) {
        $script:__SkuCache[$M365Environment] = $result
    }
    return $result
}

function Clear-SkuCache {
    <#
    .SYNOPSIS
        Empties the SubscribedSku cache for all environments.
    #>
    [CmdletBinding()]
    param()
    $script:__SkuCache = @{}
}
