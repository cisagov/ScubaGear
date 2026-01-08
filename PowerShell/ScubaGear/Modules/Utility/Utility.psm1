
function Set-Utf8NoBom {
    <#
    .Description
    Using the .NET framework, save the provided input as a UTF-8 file without the byte-order marking (BOM).
    .Functionality
    Internal
    .Parameter Content
    The content to save to the file.
    .Parameter Location
    The location to save the file to. Note that it MUST already exist and that the name of the file you want to save
    should not be included in this string.
    .Parameter FileName
    The name of the file you want to save. Note this should not include the full path, i.e., use "Example.json" instead
    of "./examplefolder/Example.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Content,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Location,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FileName
    )
    process {
        # Need to insure the location is an absolute path, otherwise you can get some inconsistent behavior.
        $ResolvedPath = $(Resolve-Path $Location).ProviderPath
        $FinalPath = Join-Path -Path $ResolvedPath -ChildPath $FileName -ErrorAction 'Stop'
        # The $false in the next line indicates that the BOM should not be used.
        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
        Invoke-WriteAllText -Content $Content -Path $FinalPath -Encoding $Utf8NoBomEncoding
        $FinalPath  # Used to test path construction more easily
    }
}

function Get-Utf8NoBom {
    <#
    .Description
    Using the .NET framework, read the provided path as a UTF-8 file without the byte-order marking (BOM).
    .Functionality
    Internal
    .Parameter FilePath
    The full path of the file you want to read.  The file must exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FilePath
    )
    process {
        # The $false in the next line indicates that the BOM should not be used.
        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False

        $ResolvedPath = $(Resolve-Path $FilePath).ProviderPath
        $Content = Invoke-ReadAllText -Path $ResolvedPath -Encoding $Utf8NoBomEncoding
        $Content
    }
}

function Invoke-WriteAllText {
    <#
    .Description
    Using the .NET framework, save the provided content to the file
    path provided using the given encoding.
    .Functionality
    Internal
    .Parameter Content
    The content to save to the file.
    .Parameter Path
    The full file path to the file being written.
    .Parameter Encoding
    An object of type System.Text.Encoding that determines how the
    content is encoded for output to file.
    Default: UTF-8 without BOM encoding used
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Content,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Text.Encoding]
        $Encoding = (New-Object System.Text.UTF8Encoding $False)
    )
    process {
        [System.IO.File]::WriteAllText($Path, $Content, $Encoding)
    }
}

function Invoke-ReadAllText {
    <#
    .Description
    Using the .NET framework, read content from the file
    path provided using the given encoding.
    .Functionality
    Internal
    .Parameter Path
    The full file path to the file being read.
    .Parameter Encoding
    An object of type System.Text.Encoding that determines how the
    content is encoded for output to file.
    Default: UTF-8 without BOM encoding used
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Text.Encoding]
        $Encoding = (New-Object System.Text.UTF8Encoding $False)
    )
    process {
        $Content = [System.IO.File]::ReadAllText($Path, $Encoding)
        $Content
    }
}

function Invoke-GraphDirectly {
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

Function ConvertFrom-GraphHashtable {
    <#
    .SYNOPSIS
    Converts a collection of hashtables from Microsoft Graph API responses into PowerShell objects.

    .DESCRIPTION
    This function processes a collection of hashtables, typically returned from Microsoft Graph API responses,
    and converts them into PowerShell objects. It handles nested hashtables and arrays, converting them into
    appropriate PowerShell object properties. The function is designed to work with the output of the
    Invoke-GraphDirectly function, allowing for easy manipulation and access to the data.

    .PARAMETER GraphData
    The input data, which is expected to be a collection of hashtables or objects returned from Microsoft Graph API requests.

    .EXAMPLE
    $graphData = @(
        @{ id = "1"; displayName = "Example 1"; properties = @{ nestedProp = "value1" } },
        @{ id = "2"; displayName = "Example 2"; properties = @{ nestedProp = "value2" } }
    )
    $convertedData = ConvertFrom-GraphHashtable -GraphData $graphData

    This example takes a collection of hashtables representing Microsoft Graph API data and converts them into PowerShell objects,
    allowing for easier access to properties and nested data.

    .NOTES
    This function is part of the ScubaGear PowerShell module and is intended for internal use to facilitate
    the conversion of Microsoft Graph API responses into a more manageable format in order to limit REGO changes.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $GraphData
    )

    Begin {
        $GraphObject = [System.Collections.ArrayList]::new()
    }

    Process {
        foreach ($Item in $GraphData) {
            if ($Item -is [hashtable]) {
                # Create a new object
                $Object = New-Object -TypeName PSObject

                # Process each property in the hashtable
                foreach ($property in $Item.GetEnumerator()) {
                    $UpperCamelCase = ($property.key).Substring(0,1).ToUpper() + ($property.key).Substring(1)
                    if ($property.Value -is [hashtable]) {
                        # Recursive call to process nested hashtables
                        $NestedObject = ConvertFrom-GraphHashtable -GraphData @($property.Value)

                        $Object | Add-Member -MemberType NoteProperty -Name $UpperCamelCase -Value $NestedObject
                    }
                    elseif ($property.Value -is [array]) {
                        # Handle arrays (check if elements are hashtables)
                        $ProcessedArray = @()
                        foreach ($element in $property.Value) {
                            if ($element -is [hashtable]) {
                                $ProcessedArray += ConvertFrom-GraphHashtable -GraphData @($element)
                            } else {
                                $ProcessedArray += $element
                            }
                        }
                        $Object | Add-Member -MemberType NoteProperty -Name $UpperCamelCase -Value $ProcessedArray
                    }
                    else {
                        $Value = $property.Value
                        $Object | Add-Member -MemberType NoteProperty -Name $UpperCamelCase -Value $Value
                    }
                }

                [void]$GraphObject.Add($Object)
            }
            else {
                # Handle normal objects
                [void]$GraphObject.Add($Item)
            }
        }
    }

    End {
        return $GraphObject
    }
}

function Invoke-GraphBatchRequest {
    <#
    .SYNOPSIS
        Executes multiple Graph API requests in a single batch call.

    .DESCRIPTION
        Uses Microsoft Graph $batch endpoint to execute up to 20 requests in a single HTTP call.
        Automatically handles batching if more than 20 requests are provided.

    .PARAMETER Requests
        Array of request objects. Each object should have: id, method, url

    .PARAMETER M365Environment
        The M365 environment to use for the batch request.

    .PARAMETER ApiVersion
        The Microsoft Graph API version to use (default: v1.0).
        Valid values are "v1.0" and "beta".

    .EXAMPLE
        $requests = @(
            @{ id = "1"; method = "GET"; url = "/servicePrincipals/12345" }
            @{ id = "2"; method = "GET"; url = "/servicePrincipals/67890" }
        )
        $results = Invoke-GraphBatchRequest -Requests $requests -M365Environment "commercial"

        This example executes two GET requests in a single batch call to retrieve service principals.

    .EXAMPLE
        $requests = @(
            @{ id = "1"; method = "GET"; url = "/users" }
            @{ id = "2"; method = "GET"; url = "/groups" }
        )
        $results = Invoke-GraphBatchRequest -Requests $requests -M365Environment "commercial" -ApiVersion "beta"

        This example executes two GET requests in a single batch call to retrieve users and groups using the beta API version.

    .NOTES
        This function is part of the ScubaGear PowerShell module and is intended for internal use to facilitate
        efficient Graph API interactions by minimizing the number of HTTP requests.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Requests,

        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $True)]
        [string]$M365Environment,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "beta", IgnoreCase = $True)]
        [string]$ApiVersion = "v1.0"
    )

    $allResults = @{}
    $batchSize = 20  # Microsoft Graph batch limit

    # Split requests into batches of 20
    for ($i = 0; $i -lt $Requests.Count; $i += $batchSize) {
        $batchRequests = $Requests[$i..[Math]::Min($i + $batchSize - 1, $Requests.Count - 1)]

        # Build batch request body
        $batchBody = @{
            requests = @($batchRequests)
        }

        try {
            # Execute batch request using Invoke-MgGraphRequest
            Write-Verbose "Executing batch request with $($batchRequests.Count) requests"
            $endpoint = Get-ScubaGearPermissions -CmdletName Connect-MgGraph -Environment $M365Environment -OutAs endpoint
            $batchResponse = Invoke-MgGraphRequest -Method POST -Uri "$endpoint/$ApiVersion/`$batch" -Body ($batchBody | ConvertTo-Json -Depth 10)

            # Parse responses
            foreach ($response in $batchResponse.responses) {
                $allResults[$response.id] = $response
            }
        }
        catch {
            Write-Warning "Batch request failed: $($_.Exception.Message)"
            throw
        }
    }

    return $allResults
}

Export-ModuleMember -Function @(
    'Get-Utf8NoBom',
    'Set-Utf8NoBom',
    'Invoke-GraphDirectly',
    'ConvertFrom-GraphHashtable',
    'Invoke-GraphBatchRequest'
)