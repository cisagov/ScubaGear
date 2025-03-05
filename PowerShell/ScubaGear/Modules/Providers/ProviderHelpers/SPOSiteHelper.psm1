function Get-SPOSiteHelper {
    <#
    .Description
    This function is used for assisting in connecting to different M365 Environments for EXO.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Report')]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod")]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $true, ParameterSetName = 'Report')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TenantName
    )
    $SPOSiteIdentity = ""
    switch ($M365Environment) {
        {"commercial" -or "gcc"} {
            $SPOSiteIdentity = "https://$($TenantName).sharepoint.com/"
        }
        "gcchigh" {
            $SPOSiteIdentity = "https://$($TenantName).sharepoint.us/"
        }
        "dod" {
            $SPOSiteIdentity = "https://$($TenantName).sharepoint-mil.us/"
        }
        default {
            Write-Error -Message "Unsupported or invalid M365Environment argument"
        }
    }
    $SPOSiteIdentity
}

Export-ModuleMember -Function @(
    'Get-SPOSiteHelper'
)