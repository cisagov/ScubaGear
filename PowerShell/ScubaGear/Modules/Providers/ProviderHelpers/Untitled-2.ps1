function Invoke-GraphDirectlyMainBranch {
    <#
    .SYNOPSIS
    Invoke Microsoft Graph API requests directly, replacing specific cmdlets.

    .Description
    This function is used to invoke Microsoft Graph API requests directly, replacing the need for specific cmdlets.

    .Parameter commandlet
    The name of the commandlet to replace, e.g., "Get-MgBetaServicePrincipal".

    .Parameter M365Environment
    The Microsoft 365 environment to target, e.g., "Commercial", "Government", etc.

    .Parameter queryParams
    A hashtable of query parameters to append to the request URI.

    .Parameter apiHeader
    A switch to indicate whether to include API headers in the request.

    .Parameter ID
    The ID of the resource to target, if applicable.

    .Parameter Body
    The body of the request, typically used for POST or PATCH requests.

    .Example
    Invoke-GraphDirectly -commandlet "Get-MgBetaServicePrincipal" -M365Environment "Commercial" -queryParams @{ filter = "displayName eq 'Test'" } -apiHeader -ID "12345"

    This example invokes the Microsoft Graph API to get a service principal with the specified filter, using the commercial environment and including API headers.

    .Example
    Invoke-GraphDirectly -commandlet "New-MgBetaServicePrincipal" -M365Environment "Commercial" -Body @{ displayName = "New SP"; appId = "12345678-1234-1234-1234-123456789012" } -Method "POST"

    This example invokes the Microsoft Graph API to create a new service principal with the specified body, using the commercial environment.

    #>
    [cmdletbinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $commandlet,

        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [System.Collections.Hashtable]
        $queryParams,

        [string]$ID,

        [object]$Body
    )

    Write-Debug "Using Graph REST API instead of cmdlet: $commandlet"

    # Determine HTTP method based on commandlet name
    if ($commandlet) {
    $verb = $commandlet.Split('-')[0]
    $Method = switch ($verb) {
        "Get"    { "GET" }
        "New"    { "POST" }
        "Update" { "PATCH" }
        "Remove" { "DELETE" }
        default  { "GET" }
        }
    }

    # Determine endpoint
    if ($ID) {
        $endpoint = Get-ScubaGearPermissions -CmdletName $commandlet -OutAs api -Environment $M365Environment -id $ID
    } else {
        $endpoint = Get-ScubaGearPermissions -CmdletName $commandlet -OutAs api -Environment $M365Environment
    }

    if ($queryParams) {
        # If query params are passed in, we augment the endpoint URI to include the params.
        $q = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)
        foreach ($item in $queryParams.GetEnumerator()) {
            $q.Add($item.Key, $item.Value)
        }
        $uri = [System.UriBuilder]::new("", "", 443, $endpoint)
        $uri.Query = $q.ToString()
        $APIFilter = $uri.Query
        $endpoint = $endpoint + $APIFilter
    }
    Write-Debug "Graph Api direct: $endpoint"

    If($null -eq $endpoint){
        Write-Error "The commandlet $commandlet can't be used with the Invoke-GraphDirectly function yet."
    }

    $apiHeader = Get-ScubaGearPermissions -CmdletName $commandlet -OutAs apiheader -Environment $M365Environment

    if($Null -ne $apiHeader.PSObject.Properties.Name) {
        # If the API header is passed in, we add it to the request.
        $headers = @{}
        foreach ($property in $apiHeader.PSObject.Properties) {
            $headers[$property.Name] = $property.Value
        }

        if ($Body) {
            $resp = Invoke-MgGraphRequest -ErrorAction Stop -Uri $endpoint -Headers $headers -Method $Method -Body ($Body | ConvertTo-Json -Depth 10) -ContentType "application/json"
        } else {
            $resp = Invoke-MgGraphRequest -ErrorAction Stop -Uri $endpoint -Headers $headers -Method $Method
        }
    } else {
        if ($Body) {
            $resp = Invoke-MgGraphRequest -ErrorAction Stop -Uri $endpoint -Method $Method -Body ($Body | ConvertTo-Json -Depth 10) -ContentType "application/json"
        } else {
            $resp = Invoke-MgGraphRequest -ErrorAction Stop -Uri $endpoint -Method $Method
        }
    }

    if($Method -notmatch "DELETE|PATCH"){
        return $resp | ConvertFrom-GraphHashtable
    }

}