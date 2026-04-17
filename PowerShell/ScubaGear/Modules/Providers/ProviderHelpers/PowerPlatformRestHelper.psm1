Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Permissions/PermissionsHelper.psm1") -Function Get-ScubaGearPermissions

function Get-PowerPlatformBaseUrl {
    <#
    .SYNOPSIS
        Returns the BAP API base URL for the given M365 environment.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    switch ($M365Environment) {
        default { return Get-ScubaGearPermissions -Product powerplatform -OutAs endpoint -Environment $M365Environment }
    }
}

function Get-PowerPlatformScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Power Platform API access.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    switch ($M365Environment) {
        default { return Get-ScubaGearPermissions -Product powerplatform -OutAs oauthScope -Environment $M365Environment }
    }
}

function Get-PowerPlatformTenantSettingsRest {
    <#
    .SYNOPSIS
        Gets Power Platform tenant settings via REST API.
    .DESCRIPTION
        Replaces Get-TenantSettings cmdlet with direct BAP REST API call.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/providers/Microsoft.BusinessAppPlatform/listTenantSettings?api-version=2023-06-01"

    try {
        $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "POST"
        return $Response
    }
    catch {
        throw "Failed to get Power Platform Tenant Settings: $($_.Exception.Message)"
    }
}

function Get-PowerPlatformEnvironmentsRest {
    <#
    .SYNOPSIS
        Gets Power Platform environments via REST API.
    .DESCRIPTION
        Replaces Get-AdminPowerAppEnvironment cmdlet with direct BAP REST API call.
        Transforms response into the format expected by Rego policies.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments?api-version=2023-06-01"

    try {
        $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"

        $Environments = @()
        if ($Response.value) {
            foreach ($Env in $Response.value) {
                $Environments += [PSCustomObject]@{
                    EnvironmentName = $Env.name
                    DisplayName     = $Env.properties.displayName
                    IsDefault       = $Env.properties.isDefault
                    Location        = $Env.location
                    EnvironmentType = $Env.properties.environmentSku
                    CreatedTime     = $Env.properties.createdTime
                }
            }
        }

        return $Environments
    }
    catch {
        throw "Failed to get Power Platform Environments: $($_.Exception.Message)"
    }
}

function Get-PowerPlatformDlpPoliciesRest {
    <#
    .SYNOPSIS
        Gets Power Platform DLP policies via REST API.
    .DESCRIPTION
        Replaces Get-DlpPolicy cmdlet with direct BAP REST API call.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $Endpoint = "/providers/Microsoft.BusinessAppPlatform/scopes/admin/apiPolicies?api-version=2016-11-01"

    try {
        $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"

        # The 2016-11-01 endpoint returns a nested schema (properties.definition) rather than
        # the flat schema (displayName, environmentType, environments at the top level) that
        # Rego expects. Normalize the response to match the flat schema.
        $NormalizedPolicies = foreach ($Policy in $Response.value) {
            $Def = $Policy.properties.definition
            $Ef = $Def.constraints.environmentFilter1

            if ($null -eq $Ef) {
                $EnvType = "AllEnvironments"
                $Environments = @()
            }
            elseif ($Ef.parameters.filterType -eq "include") {
                $EnvType = "OnlyEnvironments"
                $Environments = @($Ef.parameters.environments)
            }
            else {
                $EnvType = "ExceptEnvironments"
                $Environments = @($Ef.parameters.environments)
            }

            [PSCustomObject]@{
                name            = $Policy.name
                displayName     = $Policy.properties.displayName
                environmentType = $EnvType
                environments    = $Environments
                connectorGroups = @()
            }
        }

        return [PSCustomObject]@{ value = @($NormalizedPolicies) }
    }
    catch {
        throw "Failed to get Power Platform DLP Policies: $($_.Exception.Message)"
    }
}

function Get-PowerPlatformTenantIsolationRest {
    <#
    .SYNOPSIS
        Gets Power Platform tenant isolation policy via REST API.
    .DESCRIPTION
        Replaces Get-PowerAppTenantIsolationPolicy cmdlet with direct BAP REST API call.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        # TenantId is required - it is a path segment in the PowerPlatform.Governance endpoint.
        [Parameter(Mandatory = $true)]
        [string]$TenantId
    )

    # Correct endpoint sourced from Microsoft.PowerApps.Administration.PowerShell v2.0.216
    # provider: PowerPlatform.Governance/v1, not Microsoft.BusinessAppPlatform
    $Endpoint = "/providers/PowerPlatform.Governance/v1/tenants/$TenantId/tenantIsolationPolicy?api-version=2020-06-01"

    try {
        $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
        return $Response
    }
    catch {
        throw "Failed to get Power Platform Tenant Isolation Policy: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @(
    'Get-PowerPlatformBaseUrl',
    'Get-PowerPlatformScope',
    'Get-PowerPlatformTenantSettingsRest',
    'Get-PowerPlatformEnvironmentsRest',
    'Get-PowerPlatformDlpPoliciesRest',
    'Get-PowerPlatformTenantIsolationRest'
)
