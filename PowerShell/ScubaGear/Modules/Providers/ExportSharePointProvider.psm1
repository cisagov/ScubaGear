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
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $true)]
        [string]
        $AccessToken,

        [Parameter(Mandatory = $true)]
        [string]
        $AdminUrl
    )
    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "SPOSiteHelper.psm1")
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "SPORestHelper.psm1")
    Import-Module -Name $PSScriptRoot/../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable
    Add-Type -AssemblyName System.Web
    $Tracker = Get-CommandTracker

    # Get InitialDomainPrefix
    $InitialDomain = $Tracker.TryCommand("Get-MgBetaOrganization", @{"M365Environment"=$M365Environment; "GraphDirect"=$true}).VerifiedDomains | Where-Object {$_.isInitial}
    $InitialDomainPrefix = $InitialDomain.Name.split(".")[0]

    # Get SPOSiteIdentity
    $SPOSiteIdentity = Get-SPOSiteHelper -M365Environment $M365Environment -InitialDomainPrefix $InitialDomainPrefix

    $SPOTenant = ConvertTo-Json @()
    $SPOSite = ConvertTo-Json @()
    $UsedPnP = ConvertTo-Json $false

    # Use access token acquired by Connection.psm1
    try {
        # Get tenant settings via REST
        $TenantData = Get-SPOTenantRest -AdminUrl $AdminUrl -AccessToken $AccessToken

        $SPOTenant = ConvertTo-Json @($TenantData) -Depth 10
        $Tracker.AddSuccessfulCommand("SharePoint REST API")

        # Get site properties via REST (not currently used by policies but collected for completeness)
        $SiteData = Get-SPOSiteRest -AdminUrl $AdminUrl -AccessToken $AccessToken -Identity $SPOSiteIdentity
        $SPOSite = ConvertTo-Json @($SiteData | Select-Object -Property *) -Depth 10

        # Set to false so Rego policy actually evaluates OneDrive settings (REST API can retrieve them)
        $UsedPnP = ConvertTo-Json $false
    }
    catch {
        Write-Warning "SharePoint REST API call failed: $($_.Exception.Message)"
        $Tracker.AddUnSuccessfulCommand("SharePoint REST API")
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

    $json
}
