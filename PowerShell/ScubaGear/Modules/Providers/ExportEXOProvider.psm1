function Export-EXOProvider {
    <#
    .Description
    Gets the Exchange Online (EXO) settings that are relevant
    to the SCuBA EXO baselines using the EXO PowerShell Module
    .Functionality
    Internal
    #>

    Import-Module ExchangeOnlineManagement
    <#
    2.1
    #>
    $RemoteDomains = @(Get-RemoteDomain)
    foreach ($d in $RemoteDomains) {
        # Need to explicitly convert these values to strings, otherwise
        # these fields contain values Rego can't parse.
        $d.WhenChanged = $d.WhenChanged.ToString()
        $d.WhenCreated = $d.WhenCreated.ToString()
        $d.WhenChangedUTC = $d.WhenChangedUTC.ToString()
        $d.WhenCreatedUTC = $d.WhenCreatedUTC.ToString()
    }

    $RemoteDomains = ConvertTo-Json $RemoteDomains
    <#
    2.2 SPF
    #>

    $SPFRecords = @()

    $domains = Get-AcceptedDomain

    foreach ($d in $domains) {
        try {
            $response = Resolve-DnsName $d.DomainName txt -ErrorAction Stop
            $rdata = @($response.Strings)
        }
        catch {
            $rdata = ""
        }

        $DomainName = $d.DomainName
        $SPFRecords += [PSCustomObject]@{
            "domain" = $DomainName;
            "rdata" = $rdata
        }
    }

    $SPFRecords = ConvertTo-Json $SPFRecords

    <#
    2.3 DKIM
    #>
    $DKIMConfig = @(Get-DkimSigningConfig)
    $DKIMRecords = @()
    foreach ($d in $domains) {
        $DomainName = $d.DomainName
        $selectors = "selector1", "selector2"
        $selectors += "selector1.$DomainName" -replace "\.", "-"
        $selectors += "selector2.$DomainName" -replace "\.", "-"

        $rdata = ""
        foreach ($s in $selectors) {
            try {
                $response = Resolve-DnsName  "$s._domainkey.$DomainName" txt -ErrorAction Stop
                $rdata = $response.Strings
                break
            }
            catch {
                continue
            }
        }
        $DKIMRecords += [PSCustomObject]@{
            "domain" = $DomainName;
            "rdata" = "$rdata"
        }
    }

    $DKIMRecords = ConvertTo-Json $DKIMRecords
    $DKIMConfig = ConvertTo-Json $DKIMConfig
    <#
    2.4 DMARC
    #>
    $DMARCRecords = @()

    foreach ($d in $domains) {
        try {
            $DomainName = $d.DomainName
            $response = Resolve-DnsName "_dmarc.$DomainName" txt -ErrorAction Stop
            $rdata = $response.Strings
        }
        catch {
            $Labels = $d.DomainName.Split(".")
            try {
                 $Labels = $d.DomainName.Split(".")
                 $OrgDomain = $Labels[-2] + "." + $Labels[-1]
                 # Technically the logic above is incomplete. This will work when the tld is single
                 # label (e.g., com, org, gov). However, when the tld is two-labels (e.g., gov.uk),
                 # this will cause an error. Leaving cases like that as out-of-scope for now.
                 $response = Resolve-DnsName "_dmarc.$OrgDomain" txt -ErrorAction Stop
                 $rdata = $response.Strings
                }
                catch {
                    $rdata = ""
                }
            }

            $DomainName = $d.DomainName
            $DMARCRecords += [PSCustomObject]@{
                "domain" = $DomainName;
                "rdata" = "$rdata"
            }
        }
        $DMARCRecords = ConvertTo-Json $DMARCRecords
        <#
        2.5
        #>

        $TransportConfig = Get-TransportConfig
        $TransportConfig.WhenChanged = $TransportConfig.WhenChanged.ToString()
        $TransportConfig.WhenCreated = $TransportConfig.WhenCreated.ToString()
        $TransportConfig.WhenChangedUTC = $TransportConfig.WhenChangedUTC.ToString()
        $TransportConfig.WhenCreatedUTC = $TransportConfig.WhenCreatedUTC.ToString()
        $TransportConfig = ConvertTo-Json $TransportConfig

        <#
        2.6
        #>
        $SharingPolicy = Get-SharingPolicy
        $SharingPolicy.WhenChanged = $SharingPolicy.WhenChanged.ToString()
        $SharingPolicy.WhenCreated = $SharingPolicy.WhenCreated.ToString()
        $SharingPolicy.WhenChangedUTC = $SharingPolicy.WhenChangedUTC.ToString()
        $SharingPolicy.WhenCreatedUTC = $SharingPolicy.WhenCreatedUTC.ToString()
        $SharingPolicy = ConvertTo-Json $SharingPolicy

        <#
        2.7
        #>

        $TransportRules = @(Get-TransportRule)
        foreach ($Rule in $TransportRules) {
            $Rule.WhenChanged = $Rule.WhenChanged.ToString()
        }
        $TransportRules = ConvertTo-Json $TransportRules

        <#
        2.12
        #>

        $ConnectionFilter = Get-HostedConnectionFilterPolicy | ConvertTo-Json

        <#
        2.13
        #>
        $Config = Get-OrganizationConfig
        $Config = $Config | ConvertTo-Json


        <#
        Save output
        #>
        $json = @"
        "remote_domains": $RemoteDomains,
        "spf_records": $SPFRecords,
        "dkim_config": $DKIMConfig,
        "dkim_records": $DKIMRecords,
        "dmarc_records": $DMARCRecords,
        "transport_config": $TransportConfig,
        "sharing_policy": $SharingPolicy,
        "transport_rule": $TransportRules,
        "org_config": $Config,
        "conn_filter": $ConnectionFilter,
"@


        # We need to remove the backslash characters from the
        # json, otherwise rego gets mad.
        $json = $json.replace("\`"", "'")
        $json = $json.replace("\", "")
        $json
}

function Get-EXOTenantDetail {
    <#
    .Description
    Gets the tenant details using the EXO PowerShell Module
    .Functionality
    Internal
    #>
    Import-Module ExchangeOnlineManagement
    $Config = Get-OrganizationConfig
    $TenantInfo = @{"DisplayName"=$Config.Name;}
    $TenantInfo = $TenantInfo | ConvertTo-Json -Depth 4
    $TenantInfo
}
