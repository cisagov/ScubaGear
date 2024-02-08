function global:Get-ScubaDefault {
    <#
    .SYNOPSIS
    A function to provide Scuba specific default values
    .PARAMETER Name
    The name of the default value (i.e. DefaultOPAPath)
    .NOTES
    This default values are loaded before the module is loaded.  It is read only
    and cannot be changed in a given PowerShell session.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )

    # Add vlaues to the hash to make available as defaults
    if (-not $ScubaDefaults) {
        Set-Variable -Name 'ScubaDefaults' -Option Constant -Scope Global -Force -Value @{
            DefaultOPAPath = (Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools")
        }
    }
    $ScubaDefaults[$Name]
}