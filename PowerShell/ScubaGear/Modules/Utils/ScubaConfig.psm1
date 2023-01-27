function Get-ScubaConfig {
    <#
    .Description
    This function is used to read in a SCuBA configuration file and set the
    "ScubaConfig" read only variable in local scope. The file must
    be in JSON format and adhere to the SCUBA configuration schema.
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

    Set-Variable -Name "ScubaConfig" -Value $Config -Option ReadOnly -Scope Global -Description "SCuBA Configuration parameters"
}

function Remove-ScubaConfig {
    <#
    .Description
    This function is used to remove the SCuBA configuration variable, "ScubaConfig".
    .Functionality
    Internal
    #>

    try {
        if (Get-Variable -Name "ScubaConfig" -Scope Global){
            Remove-Variable -Name "ScubaConfig" -Scope Global -Force
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
