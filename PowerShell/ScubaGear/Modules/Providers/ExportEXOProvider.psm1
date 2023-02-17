function Export-EXOProvider {
    <#
    .Description
    Gets the Exchange Online (EXO) settings that are relevant
    to the SCuBA EXO baselines using the EXO PowerShell Module
    .Functionality
    Internal
    #>

    # Manually importing the module name here to bypass cmdlet name conflicts
    # There are conflicting PowerShell Cmdlet names in EXO and Power Platform
    Import-Module ExchangeOnlineManagement

    Import-Module $PSScriptRoot/ProviderHelpers/CommandTracker.psm1
    $Tracker = Get-CommandTracker
    <#
    2.1
    #>
    $RemoteDomains = ConvertTo-Json @($Tracker.TryCommand("Get-RemoteDomain"))

    <#
    2.2 SPF
    #>
    $domains = $Tracker.TryCommand("Get-AcceptedDomain")
    $SPFRecords = ConvertTo-Json @($Tracker.TryCommand("Get-ScubaSpfRecords", @{"Domains"=$domains}))

    <#
    2.3 DKIM
    #>
    $DKIMConfig = ConvertTo-Json @($Tracker.TryCommand("Get-DkimSigningConfig"))
    $DKIMRecords = ConvertTo-Json @($Tracker.TryCommand("Get-ScubaDkimRecords", @{"Domains"=$domains}))

    <#
    2.4 DMARC
    #>
    $DMARCRecords = ConvertTo-Json @($Tracker.TryCommand("Get-ScubaDmarcRecords", @{"Domains"=$domains}))

    <#
    2.5
    #>

    $TransportConfig = ConvertTo-Json @($Tracker.TryCommand("Get-TransportConfig"))

    <#
    2.6
    #>
    $SharingPolicy = ConvertTo-Json @($Tracker.TryCommand("Get-SharingPolicy"))

    <#
    2.7
    #>

    $TransportRules = ConvertTo-Json @($Tracker.TryCommand("Get-TransportRule"))

    <#
    2.12
    #>

    $ConnectionFilter = ConvertTo-Json @($Tracker.TryCommand("Get-HostedConnectionFilterPolicy"))

    <#
    2.13
    #>
    $Config = $Tracker.TryCommand("Get-OrganizationConfig") | Select-Object Name, DisplayName, AuditDisabled
    $Config = ConvertTo-Json @($Config)


    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

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
    "conn_filter": $ConnectionFilter,
    "org_config": $Config,
    "exo_successful_commands": $SuccessfulCommands,
    "exo_unsuccessful_commands": $UnSuccessfulCommands,
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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [string]
        $M365Environment
    )
    try {
        Import-Module ExchangeOnlineManagement
        $OrgConfig = Get-OrganizationConfig -ErrorAction "Stop"
        $DomainName = $OrgConfig.Name
        $TenantId = "Error retrieving Tenant ID"
        $Uri = "https://login.microsoftonline.com/$($DomainName)/.well-known/openid-configuration"

        if (($M365Environment -eq "gcchigh") -or ($M365Environment -eq "dod")) {
            $TLD = ".us"
            $Uri = "https://login.microsoftonline$($TLD)/$($DomainName)/.well-known/openid-configuration"
        }
        try {
            $Content = (Invoke-WebRequest -Uri $Uri  -ErrorAction "Stop").Content
            $TenantId = (ConvertFrom-Json $Content).token_endpoint.Split("/")[3]
        }
        catch {
            Write-Warning "Unable to retrieve EXO Tenant ID with URI. This may be caused by proxy error see 'Running the Script Behind Some Proxies' in the README for a solution. $($_)"
        }

        $EXOTenantInfo = @{
            "DisplayName"= $OrgConfig.DisplayName;
            "DomainName" = $DomainName;
            "TenantId" = $TenantId;
            "EXOAdditionalData" = "Unable to safely retrieve due to EXO API changes";
        }
        $EXOTenantInfo = ConvertTo-Json @($EXOTenantInfo) -Depth 4
        $EXOTenantInfo
    }
    catch {
        Write-Warning "Error retrieving Tenant details using Get-EXOTenantDetail $($_)"
        $EXOTenantInfo = @{
            "DisplayName" = "Error retrieving Display name";
            "DomainName" = "Error retrieving Domain name";
            "TenantId" = "Error retrieving Tenant ID";
            "EXOAdditionalData" = "Error retrieving additional data";
        }
        $EXOTenantInfo = ConvertTo-Json @($EXOTenantInfo) -Depth 4
        $EXOTenantInfo
    }
}
function Get-ScubaSpfRecords {
    <#
    .Description
    Gets the SPF records for each domain in $Domains
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]
        $Domains
    )

    $SPFRecords = @()

    foreach ($d in $Domains) {
        try {
            $response = Resolve-DnsName $d.DomainName txt -ErrorAction Stop
            $rdata = @($response.Strings)
        }
        catch {
            if ($_.FullyQualifiedErrorId -eq "DNS_ERROR_RCODE_NAME_ERROR,Microsoft.DnsClient.Commands.ResolveDnsName") {
                # Error is expected, just means the SPF record does not exist, does not mean the command failed
                $rdata = ""
            }
            else {
                # Error is not expected, let the exception propagate
                throw $_
            }
        }

        $DomainName = $d.DomainName
        $SPFRecords += [PSCustomObject]@{
            "domain" = $DomainName;
            "rdata" = $rdata
        }
    }

    $SPFRecords
}

function Get-ScubaDkimRecords {
    <#
    .Description
    Gets the DKIM records for each domain in $Domains
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]
        $Domains
    )

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
                if ($_.FullyQualifiedErrorId -eq "DNS_ERROR_RCODE_NAME_ERROR,Microsoft.DnsClient.Commands.ResolveDnsName") {
                    # Error is expected, just means the DKIM record does not exist with this selector,
                    # we need to try again with a different one
                    continue
                }
                else {
                    # Error is not expected, let the exception propagate
                    throw $_
                }
            }
        }

        $DKIMRecords += [PSCustomObject]@{
            "domain" = $DomainName;
            "rdata" = "$rdata"
        }
    }

    $DKIMRecords
}

function Get-ScubaDmarcRecords {
    <#
    .Description
    Gets the DMARC records for each domain in $Domains
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]
        $Domains
    )

    $DMARCRecords = @()

    foreach ($d in $domains) {
        try {
            # First check to see if the record is available at the full domain level
            $DomainName = $d.DomainName
            $response = Resolve-DnsName "_dmarc.$DomainName" txt -ErrorAction Stop
            $rdata = $response.Strings
        }
        catch {
            if ($_.FullyQualifiedErrorId -eq "DNS_ERROR_RCODE_NAME_ERROR,Microsoft.DnsClient.Commands.ResolveDnsName") {
                # Error is expected, just means the domain does not exist, does not mean the command failed
                # If the record is not available at the full domain level, we need to check at the
                # organizational domain level
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
                    if ($_.FullyQualifiedErrorId -eq "DNS_ERROR_RCODE_NAME_ERROR,Microsoft.DnsClient.Commands.ResolveDnsName") {
                        # Error is expected, just means the dmarc record does not exist, does not mean
                        # the command failed
                        $rdata = ""
                    }
                    else {
                        # Error is not expected, let the exception propagate
                        throw $_
                    }
                }
            }
            else {
                # Error is not expected, let the exception propagate
                throw $_
            }
        }

        $DomainName = $d.DomainName
        $DMARCRecords += [PSCustomObject]@{
            "domain" = $DomainName;
            "rdata" = "$rdata"
        }
    }

    $DMARCRecords
}
