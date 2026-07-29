Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Utility/Utility.psm1") -Function Invoke-ScubaRestMethod
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../../Permissions/PermissionsHelper.psm1") -Function Get-ScubaGearPermissions

function Get-TeamsScope {
    <#
    .SYNOPSIS
        Returns the OAuth2 scope for Teams API access.
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
        default { return Get-ScubaGearPermissions -Product teams -OutAs oauthScope -Environment $M365Environment }
    }
}

function Get-TeamsBaseUrl {
    <#
    .SYNOPSIS
        Returns the Teams API endpoint URL for the given M365 environment.
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
        default { return Get-ScubaGearPermissions -Product teams -OutAs endpoint -Environment $M365Environment }
    }
}

function Get-TeamsMeetingPolicyRest {
    <#
    .SYNOPSIS
        Gets Meeting policy settings via REST API.
    .DESCRIPTION
        Replaces Get-CsTeamsMeetingPolicy cmdlet.
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

    $Endpoint = "/Skype.Policy/configurations/TeamsMeetingPolicy"

    $Response = Invoke-ScubaRestMethod -BaseUrl $BaseUrl -AccessToken $AccessToken -Endpoint $Endpoint -Method "GET"
    return $Response
}

# function Invoke-DefenderRestMethod {
#     <#
#     .SYNOPSIS
#         Invokes a Microsoft Defender for Office 365 cmdlet via the Graph API.
#     .DESCRIPTION
#         Calls the Microsoft Graph API with the specified method and endpoint.
#         The function handles authentication headers and response parsing.
#     .PARAMETER Method
#         The HTTP method (e.g., "Get", "Post").
#     .PARAMETER Endpoint
#         The API endpoint path (e.g., "/security/securityScores").
#     .PARAMETER ApiEndpoint
#         The fully-qualified API base URI.
#     .PARAMETER AccessToken
#         The OAuth2 access token for Defender.
#     .PARAMETER Body
#         Optional request body for POST/PATCH operations.
#     .PARAMETER QueryParameters
#         Optional hashtable of query parameters.
#     .FUNCTIONALITY
#         Internal
#     #>
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [ValidateSet("Get", "Post", "Patch", "Put", "Delete")]
#         [string]$Method,

#         [Parameter(Mandatory = $true)]
#         [string]$Endpoint,

#         [Parameter(Mandatory = $true)]
#         [string]$ApiEndpoint,

#         [Parameter(Mandatory = $true)]
#         [string]$AccessToken,

#         [Parameter(Mandatory = $false)]
#         [hashtable]$Body,

#         [Parameter(Mandatory = $false)]
#         [hashtable]$QueryParameters = @{}
#     )

#     $Headers = @{
#         "Authorization" = "Bearer $AccessToken"
#         "ContentType"   = "application/json"
#         "User-Agent"    = "ScubaGear"
#     }

#     $Uri = "$ApiEndpoint$Endpoint"

#     # Build query string if parameters provided
#     if ($QueryParameters.Count -gt 0) {
#         $QueryString = ($QueryParameters.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
#         $Uri = "$Uri`?$QueryString"
#     }

#     try {
#         $InvokeParams = @{
#             Method      = $Method
#             Uri         = $Uri
#             Headers     = $Headers
#             ContentType = "application/json"
#         }

#         if ($Body) {
#             $InvokeParams["Body"] = $Body | ConvertTo-Json -Depth 5
#         }

#         $Response = Invoke-RestMethod @InvokeParams
#         return $Response
#     }
#     catch {
#         throw "Microsoft Defender API call failed: $($_.Exception.Message)"
#     }
# }

Export-ModuleMember -Function @(
    'Get-TeamsScope',
    'Get-TeamsBaseUrl',
    'Get-TeamsMeetingPolicyRest'
)
