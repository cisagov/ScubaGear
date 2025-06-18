
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
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $commandlet,

        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [System.Collections.Hashtable]
        $queryParams,

        [string]$ID
    )

    Write-Debug "Using Graph REST API instead of cmdlet: $commandlet"

    # Use Get-ScubaGearPermissions to convert cmdlets to API calls
    if($ID){
        $endpoint = Get-ScubaGearPermissions -CmdletName $commandlet -OutAs api -Environment $M365Environment -id $ID
    } else {
        $endpoint = Get-ScubaGearPermissions -CmdletName $commandlet -OutAs api -Environment $M365Environment
    }

    If($null -eq $endpoint){
        Write-Error "The commandlet $commandlet can't be used with the Invoke-GraphDirectly function yet."
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

    $apiHeader = Get-ScubaGearPermissions -CmdletName $commandlet -OutAs apiheader -Environment $M365Environment
    if($Null -ne $apiHeader.PSObject.Properties.Name) {
        # If the API header is passed in, we add it to the request.
        $headers = @{}

        foreach ($property in $apiHeader.PSObject.Properties) {
            $headers[$property.Name] = $property.Value
        }
        $resp = Invoke-MgGraphRequest -ErrorAction Stop -Uri $endpoint -Headers $headers
    } else {
        $resp = Invoke-MgGraphRequest -ErrorAction Stop -Uri $endpoint
    }

    return $resp | ConvertFrom-GraphHashtable

}

Function ConvertFrom-GraphHashtable {
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
            # Check if the item is a hashtable, if so convert it to a PSObject.
            # This function reduces code changes to the AADConditionalAccessHelper module and REGO.
            if ($Item -is [hashtable]) {
                # Create a new object
                $Object = New-Object -TypeName PSObject

                # Process each property in the hashtable
                foreach ($property in $Item.GetEnumerator()) {
                    # Capitalize the first letter of the property key
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
                # Handle normal objects, no conversion needed just return the results
                [void]$GraphObject.Add($Item)
            }
        }
    }

    End {
        return $GraphObject
    }
}

Export-ModuleMember -Function @(
    'Get-Utf8NoBom',
    'Set-Utf8NoBom',
    'Invoke-GraphDirectly',
    'ConvertFrom-GraphHashtable'
)