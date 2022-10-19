function Export-OneDriveProvider {
    <#
    .Description
    Gets the OneDrive settings that are relevant
    to the SCuBA OneDrive baselines using the SharePoint PowerShell Module
    .Functionality
    Internal
    #>

    $InitialDomain = (Get-MgOrganization).VerifiedDomains | Where-Object {$_.isInitial}
    $InitialDomainPrefix = $InitialDomain.Name.split(".")[0]
    $SPOTenantInfo = Get-SPOTenant | ConvertTo-Json
    $ExpectedResults = Get-SPOSite -Identity "https://$($InitialDomainPrefix).sharepoint.com/"  | ConvertTo-Json
    $TenantSyncInfo = Get-SPOTenantSyncClientRestriction | ConvertTo-Json

    # Note the spacing and the last comma in the json is important
    $json = @"
    "SPO_tenant_info": $SPOTenantInfo,
    "Expected_results": $ExpectedResults,
    "Tenant_sync_info": $TenantSyncInfo,
"@

    # We need to remove the backslash characters from the json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
    $json
}
