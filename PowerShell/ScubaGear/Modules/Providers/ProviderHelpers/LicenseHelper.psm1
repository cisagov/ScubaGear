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

function Get-CopilotLicense {
    <#
    .SYNOPSIS
    Returns whether the tenant has a Microsoft 365 Copilot license entitlement.

    .DESCRIPTION
    Checks the service plan IDs within subscribed SKUs instead of SKU names, so
    standalone licenses and bundles such as Microsoft 365 E7 are handled alike.
    A matching SKU must have enabled or warning (grace period) prepaid seats and
    must not be suspended, deleted, or locked out. Unassigned seats count.

    This checks license ownership, not user assignment or feature provisioning.
    A Copilot plan still identifies the entitlement when its ProvisioningStatus
    is Disabled or pending. Free Copilot Chat, standalone Copilot Studio, and
    Security Copilot alone do not establish a Microsoft 365 Copilot entitlement.
    Trial entitlements with enabled seats count; subscribedSkus does not identify
    whether a license was purchased or obtained through a trial.

    This function makes no network calls. Callers must retrieve subscribed SKUs
    and handle retrieval failures before using the result to gate provider calls.

    .PARAMETER SubscribedSku
    Raw subscribed SKU objects returned by Get-MgBetaSubscribedSku or the
    equivalent CommandTracker GraphDirect call. Pass the objects before projecting
    license_information or flattening service_plans; both lose required details.
    Null or an empty collection returns false.

    .EXAMPLE
    Import-Module "$PSScriptRoot/ProviderHelpers/LicenseHelper.psm1" -Function Get-CopilotLicense
    $SubscribedSku = $Tracker.TryCommand('Get-MgBetaSubscribedSku', @{
        M365Environment = $M365Environment
        GraphDirect = $true
    })
    $HasCopilot = Get-CopilotLicense -SubscribedSku $SubscribedSku

    .OUTPUTS
    System.Boolean

    .LINK
    https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference

    .LINK
    https://learn.microsoft.com/en-us/copilot/plan/copilot-license-options

    .FUNCTIONALITY
    Internal
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]]
        $SubscribedSku
    )

    # Core Microsoft 365 Copilot entitlements from Microsoft's service plan reference.
    # Avoid wildcard name matching: related products and shared supporting plans
    # (for example, connectors) do not establish this entitlement by themselves.
    $CopilotServicePlanIds = @(
        'a62f8878-de10-42f3-b68f-6149a25ceb97' # M365_COPILOT_APPS
        '3f30311c-6b1e-48a4-ab79-725b469da960' # M365_COPILOT_BUSINESS_CHAT
        'b95945de-b3bd-46db-8437-f2beb6ea2347' # M365_COPILOT_TEAMS
        '0aedf20c-091d-420b-aadf-30c042609612' # M365_COPILOT_SHAREPOINT
    )

    foreach ($Sku in $SubscribedSku) {
        if ($null -eq $Sku) {
            continue
        }

        if ($Sku.CapabilityStatus -and $Sku.CapabilityStatus -notin @('Enabled', 'Warning')) {
            continue
        }

        if (($Sku.PrepaidUnits.Enabled -le 0) -and ($Sku.PrepaidUnits.Warning -le 0)) {
            continue
        }

        foreach ($Plan in $Sku.ServicePlans) {
            if ($CopilotServicePlanIds -contains [string]$Plan.ServicePlanId) {
                return $true
            }
        }
    }

    return $false
}

Export-ModuleMember -Function Get-AADLicenseState, Get-CopilotLicense
