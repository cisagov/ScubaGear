function Get-PowerBIBaseUrl {
    <#
    .SYNOPSIS
        Returns the Power BI Admin API base URL for the given M365 environment.
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
        "commercial" { return "https://api.powerbi.com" }
        "gcc"        { return "https://api.powerbigov.us" }
        "gcchigh"    { return "https://api.high.powerbigov.us" }
        "dod"        { return "https://app.mil.powerbigov.us" }
    }
}

Export-ModuleMember -Function @(
    'Get-PowerBIBaseUrl'
)