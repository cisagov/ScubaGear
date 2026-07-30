Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod

function Get-DefenderScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Microsoft Defender based on M365 environment.
    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    $Scope = switch ($M365Environment.ToLower()) {
        "commercial" { "https://manage.office.com/.default" }
        "gcc"        { "https://manage.office.com/.default" }
        "gcchigh"    { "https://manage.office365.us/.default" }
        "dod"        { "https://manage.office365.us/.default" }
    }

    return $Scope
}

function Get-DefenderApiEndpoint {
    <#
    .SYNOPSIS
        Dynamically resolves the Microsoft Defender for Office 365 API endpoint URI.
    .DESCRIPTION
        Determines the appropriate API endpoint for the Organization Reporting endpoint.
        Returns a URI in the format:
        https://api.security.microsoft.com/api/GetOrganizationReportData
    .PARAMETER M365Environment
        The M365 environment (commercial, gcc, gcchigh, dod).
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment
    )

    $ApiEndpoint = switch ($M365Environment.ToLower()) {
        { $_ -in @("commercial", "gcc") } { "https://graph.microsoft.com/beta" }
        { $_ -in @("gcchigh", "dod") } { "https://graph.microsoft.us/beta" }
    }

    return $ApiEndpoint
}

Export-ModuleMember -Function @(
    'Get-DefenderScope',
    'Get-DefenderApiEndpoint'
)
