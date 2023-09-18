function Export-SharePointProvider {
    <#
    .Description
    Gets the SharePoint/OneDrive settings that are relevant
    to the SCuBA SharePoint baselines using the SharePoint PowerShell Module
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        #[ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $false)]
        [switch]
        $PnPFlag
    )
    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "SPOSiteHelper.psm1")
    $Tracker = Get-CommandTracker

    #Get InitialDomainPrefix
    $InitialDomain = ($Tracker.TryCommand("Get-MgBetaOrganization")).VerifiedDomains | Where-Object {$_.isInitial}
    $InitialDomainPrefix = $InitialDomain.Name.split(".")[0]

    #Get SPOSiteIdentity
    $SPOSiteIdentity = Get-SPOSiteHelper -M365Environment $M365Environment -InitialDomainPrefix $InitialDomainPrefix


    $SPOTenant = ConvertTo-Json @()
    $SPOSite = ConvertTo-Json @()
    $UsedPnP = ConvertTo-Json $false
    if ($PnPFlag) {
        $SPOTenant = ConvertTo-Json @($Tracker.TryCommand("Get-PnPTenant"))
        $SPOSite = ConvertTo-Json @($Tracker.TryCommand("Get-PnPTenantSite",@{"Identity"="$($SPOSiteIdentity)"; "Detailed"=$true}) | Select-Object -Property *)
        $Tracker.AddSuccessfulCommand("Get-SPOTenant")
        $Tracker.AddSuccessfulCommand("Get-SPOSite")
        $UsedPnP = ConvertTo-Json $true
    }
    else {
        $SPOTenant = ConvertTo-Json @($Tracker.TryCommand("Get-SPOTenant"))
        $SPOSite = ConvertTo-Json @($Tracker.TryCommand("Get-SPOSite", @{"Identity"="$($SPOSiteIdentity)"; "Detailed"=$true}) | Select-Object -Property *)
        $Tracker.AddSuccessfulCommand("Get-PnPTenant")
        $Tracker.AddSuccessfulCommand("Get-PnPTenantSite")
    }


    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
    $json = @"
    "SPO_tenant": $SPOTenant,
    "SPO_site": $SPOSite,
    "OneDrive_PnP_Flag": $UsedPnp,
    "SharePoint_successful_commands": $SuccessfulCommands,
    "SharePoint_unsuccessful_commands": $UnSuccessfulCommands,
"@

    # We need to remove the backslash characters from the json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
    $json
}
