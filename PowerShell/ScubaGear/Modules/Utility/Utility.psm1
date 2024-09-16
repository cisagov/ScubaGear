
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

Export-ModuleMember -Function @(
    'Get-Utf8NoBom',
    'Set-Utf8NoBom'
)
