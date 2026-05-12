Import-Module -Name $PSScriptRoot/../../Utility/Utility.psm1 -Function Invoke-GraphDirectly

function Get-AppManagementPolicies {
    <#
    .Description
    Retrieves all custom app management policies and enriches each one with the
    list of applications and service principals it applies to (Id, AppId, DisplayName).
    Used to support MS.AAD.5.5v1, MS.AAD.5.6v1, and MS.AAD.5.7v1 checks.
    .Parameter AppPolicies
    The raw policy objects returned from Get-MgBetaPolicyAppManagementPolicy.
    .Parameter M365Environment
    The M365 environment string (commercial, gcc, gcchigh, dod).
    .Functionality
    Internal
    #>
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]
        $AppPolicies,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )

    $RestrictedApps = [System.Collections.Generic.List[object]]::new()

    foreach ($Policy in $AppPolicies) {
        $AppliesTo = @()
        try {
            $AppliesToResponse = (Invoke-GraphDirectly `
                -Commandlet "Get-MgBetaPolicyAppManagementPolicyApplyTo" `
                -M365Environment $M365Environment `
                -Id $Policy.Id).Value

            if ($AppliesToResponse) {
                $AppliesTo = @($AppliesToResponse | ForEach-Object {
                    [ordered]@{
                        "Id"          = $_.Id
                        "AppId"       = $_.AppId
                        "DisplayName" = $_.DisplayName
                    }
                })
            }
        }
        catch {
            Write-Warning "Failed to retrieve appliesTo for app management policy '$($Policy.DisplayName)' ($($Policy.Id)): $($_.Exception.Message)"
        }

        # Embed the AppliesTo list into each restriction entry so Rego can correlate
        # excluded apps by restrictionType (e.g. passwordLifetime, passwordAddition,
        # asymmetricKeyLifetime) without needing to join at the policy level.
        $PasswordCredentials = @($Policy.Restrictions.PasswordCredentials | Where-Object { $null -ne $_ } | ForEach-Object {
            $entry = [ordered]@{}
            $_.PSObject.Properties | Where-Object { $null -ne $_.Name } | ForEach-Object { $entry[$_.Name] = $_.Value }
            $entry["AppliesTo"] = $AppliesTo
            $entry
        })
        $KeyCredentials = @($Policy.Restrictions.KeyCredentials | Where-Object { $null -ne $_ } | ForEach-Object {
            $entry = [ordered]@{}
            $_.PSObject.Properties | Where-Object { $null -ne $_.Name } | ForEach-Object { $entry[$_.Name] = $_.Value }
            $entry["AppliesTo"] = $AppliesTo
            $entry
        })

        $RestrictedApps.Add([ordered]@{
            "Id"          = $Policy.Id
            "DisplayName" = $Policy.DisplayName
            "IsEnabled"   = $Policy.IsEnabled
            "Restrictions" = [ordered]@{
                "PasswordCredentials" = $PasswordCredentials
                "KeyCredentials"      = $KeyCredentials
            }
        })
    }

    $RestrictedApps
}

Export-ModuleMember -Function @(
    "Get-AppManagementPolicies"
)
