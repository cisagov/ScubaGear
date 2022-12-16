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
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [string]
        $M365Environment
    )
    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "SPOSiteHelper.psm1")
    $Tracker = Get-CommandTracker

    #Get InitialDomainPrefix
    $InitialDomain = ($Tracker.TryCommand("Get-MgOrganization")).VerifiedDomains | Where-Object {$_.isInitial}
    $InitialDomainPrefix = $InitialDomain.Name.split(".")[0]

    #Get SPOSiteIdentity
    $SPOSiteIdentity = Get-SPOSiteHelper -M365Environment $M365Environment -InitialDomainPrefix $InitialDomainPrefix

    $SPOTenantInfo = ConvertTo-Json @($Tracker.TryCommand("Get-SPOTenant"))
    $ExpectedResults = ConvertTo-Json @($Tracker.TryCommand("Get-SPOSite", @{"Identity"="$($SPOSiteIdentity)"}))
    $TenantSyncInfo = ConvertTo-Json @($Tracker.TryCommand("Get-SPOTenantSyncClientRestriction"))

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "SPO_tenant_info": $SPOTenantInfo,
    "Expected_results": $ExpectedResults,
    "Tenant_sync_info": $TenantSyncInfo,
    "OneDrive_successful_commands": $SuccessfulCommands,
    "OneDrive_unsuccessful_commands": $UnSuccessfulCommands,
"@

    # We need to remove the backslash characters from the json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
    $json
}
