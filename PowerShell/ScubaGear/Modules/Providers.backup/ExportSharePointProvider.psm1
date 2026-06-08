function Export-SharePointProvider {
    <#
    .Description
    Gets the SharePoint/OneDrive settings that are relevant
    to the SCuBA SharePoint baselines using direct REST API calls.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $AccessToken,

        [Parameter(Mandatory = $true)]
        [string]
        $AdminUrl
    )
    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "SPORestHelper.psm1")
    $Tracker = Get-CommandTracker

    $UsedPnP = ConvertTo-Json $false

    # Use access token acquired by Connection.psm1
    $TenantData = $Tracker.TryCommand("Get-SPOTenantRest", @{AdminUrl = $AdminUrl; AccessToken = $AccessToken})
    $SPOTenant = ConvertTo-Json @($TenantData) -Depth 10

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "SPO_tenant": $SPOTenant,
    "OneDrive_PnP_Flag": $UsedPnp,
    "SharePoint_successful_commands": $SuccessfulCommands,
    "SharePoint_unsuccessful_commands": $UnSuccessfulCommands,
"@

    $json
}
