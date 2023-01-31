function Get-ScubaConfig {
    <#
    .Description
    This function is used to read in a SCuBA configuration file and set the
    "ScubaConfig" read only variable in local scope. The file must
    be in JSON or YAML format and adhere to the SCUBA configuration schema.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-Not ($_ | Test-Path)){
                throw "SCuBA configuration file or folder does not exist."
            }
            if (-Not ($_ | Test-Path -PathType Leaf)){
                throw "SCuBA configuration Path argument must be a file."
            }
            return $true
        })]
        [System.IO.FileInfo]
        $Path
    )

    $Content = Get-Content -Raw -Path $Path
    $Config = $Content | ConvertFrom-Yaml

    Set-Variable -Name "ScubaConfig" -Value $Config -Option AllScope -Scope Script -Description "SCuBA Configuration parameters"
}

function Remove-ScubaConfig {
    <#
    .Description
    This function is used to remove the SCuBA configuration variable, "ScubaConfig".
    .Functionality
    Internal
    #>

    try {
        $Result = Get-Variable -Name "ScubaConfig" -Scope Script -ErrorAction 'silentlycontinue'
        if ($Result){
            Remove-Variable -Name "ScubaConfig" -Scope Script -Force
        }

    }
    catch{
        Write-Debug "Variable, ScubaConfig, was not found"
    }
}

Export-ModuleMember -Function @(
    'Get-ScubaConfig',
    'Remove-ScubaConfig'
)
