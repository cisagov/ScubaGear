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
    .PARAMETER AccessToken
        The OAuth2 access token for Defender.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]$M365Environment,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $ApiEndpoint = switch ($M365Environment.ToLower()) {
        { $_ -in @("commercial", "gcc") } { "https://graph.microsoft.com/beta" }
        { $_ -in @("gcchigh", "dod") } { "https://graph.microsoft.us/beta" }
    }

    return $ApiEndpoint
}

function Invoke-DefenderRestMethod {
    <#
    .SYNOPSIS
        Invokes a Microsoft Defender for Office 365 cmdlet via the Graph API.
    .DESCRIPTION
        Calls the Microsoft Graph API with the specified method and endpoint.
        The function handles authentication headers and response parsing.
    .PARAMETER Method
        The HTTP method (e.g., "Get", "Post").
    .PARAMETER Endpoint
        The API endpoint path (e.g., "/security/securityScores").
    .PARAMETER ApiEndpoint
        The fully-qualified API base URI.
    .PARAMETER AccessToken
        The OAuth2 access token for Defender.
    .PARAMETER Body
        Optional request body for POST/PATCH operations.
    .PARAMETER QueryParameters
        Optional hashtable of query parameters.
    .FUNCTIONALITY
        Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Get", "Post", "Patch", "Put", "Delete")]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Mandatory = $true)]
        [string]$ApiEndpoint,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken,

        [Parameter(Mandatory = $false)]
        [hashtable]$Body,

        [Parameter(Mandatory = $false)]
        [hashtable]$QueryParameters = @{}
    )

    $Headers = @{
        "Authorization" = "Bearer $AccessToken"
        "ContentType"   = "application/json"
        "User-Agent"    = "ScubaGear"
    }

    $Uri = "$ApiEndpoint$Endpoint"

    # Build query string if parameters provided
    if ($QueryParameters.Count -gt 0) {
        $QueryString = ($QueryParameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
        $Uri = "$Uri`?$QueryString"
    }

    try {
        $InvokeParams = @{
            Method      = $Method
            Uri         = $Uri
            Headers     = $Headers
            ContentType = "application/json"
        }

        if ($Body) {
            $InvokeParams["Body"] = $Body | ConvertTo-Json -Depth 5
        }

        $Response = Invoke-RestMethod @InvokeParams
        return $Response
    }
    catch {
        throw "Microsoft Defender API call failed: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @(
    'Get-DefenderScope',
    'Get-DefenderApiEndpoint',
    'Invoke-DefenderRestMethod'
)
