function Export-OneDriveProvider {
    <#
    .Description
    Gets the OneDrive settings that are relevant
    to the SCuBA OneDrive baselines using the SharePoint PowerShell Module
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $PnPFlag
    )
    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    $Tracker = Get-CommandTracker

    $SPOTenantInfo = ConvertTo-Json @()
    $TenantSyncInfo = ConvertTo-Json @()
    $UsedPnP = ConvertTo-Json $false
    if ($PnPFlag) {
        $SPOTenantInfo = ConvertTo-Json @($Tracker.TryCommand("Get-PnPTenant"))
        $TenantSyncInfo = ConvertTo-Json @($Tracker.TryCommand("Get-PnPTenantSyncClientRestriction"))
        $Tracker.AddSuccessfulCommand("Get-SPOTenant")
        $Tracker.AddSuccessfulCommand("Get-SPOTenantSyncClientRestriction")
        $UsedPnP = ConvertTo-Json $true
    }
    else {
        $SPOTenantInfo = ConvertTo-Json @($Tracker.TryCommand("Get-SPOTenant"))
        $TenantSyncInfo = ConvertTo-Json @($Tracker.TryCommand("Get-SPOTenantSyncClientRestriction"))
        $Tracker.AddSuccessfulCommand("Get-PnPTenant")
        $Tracker.AddSuccessfulCommand("Get-PnPTenantSyncClientRestriction")
    }

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "SPO_tenant_info": $SPOTenantInfo,
    "Tenant_sync_info": $TenantSyncInfo,
    "OneDrive_PnP_Flag": $UsedPnp,
    "OneDrive_successful_commands": $SuccessfulCommands,
    "OneDrive_unsuccessful_commands": $UnSuccessfulCommands,
"@

    # We need to remove the backslash characters from the json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
    $json
}
