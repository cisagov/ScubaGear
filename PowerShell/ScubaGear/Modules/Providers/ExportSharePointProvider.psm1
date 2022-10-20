function Export-SharePointProvider {
    <#
    .Description
    Gets the SharePoint settings that are relevant
    to the SCuBA SharePoint baselines using the SharePoint PowerShell Module
    .Functionality
    Internal
    #>

    $InitialDomain = (Get-MgOrganization).VerifiedDomains | Where-Object {$_.isInitial}
    $InitialDomainPrefix = $InitialDomain.Name.split(".")[0]
    $SPOTenant = Get-SPOTenant | ConvertTo-Json
    $SPOSite = Get-SPOSite -Identity "https://$($InitialDomainPrefix).sharepoint.com/" -detailed | Select-Object -Property * | ConvertTo-Json

    # Note the spacing and the last comma in the json is important
    $json = @"
    "SPO_tenant": $SPOTenant,
    "SPO_site": $SPOSite,
"@
    # We need to remove the backslash characters from the json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
    $json
}
