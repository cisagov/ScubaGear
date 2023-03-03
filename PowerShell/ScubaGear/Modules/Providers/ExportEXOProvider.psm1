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

function Invoke-RobustDnsTxt {
    <#
    .Description
    Requests the TXT record for the given qname. First tries to make the query over traditional DNS
    but retries over DoH in the event of failure.
    .Parameter Qname
    The fully-qualified domain name to request.
    .Parameter MaxTries
    The number of times to retry each kind of query. If all queries are unsuccessful, the traditional
    queries and the DoH queries will each be made $MaxTries times. Default is 2.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Qname,

        [Parameter(Mandatory=$false)]
        [string]
        $MaxTries = 2
    )
    $Answers = @()
    $ErrorMessages = @()
    $TryNumber = 0
    $Success = $false
    $TradEmptyOrNx = $false
    while ($TryNumber -lt $MaxTries) {
        try {
            $TryNumber += 1
            $Response = Resolve-DnsName $Qname txt -ErrorAction Stop | Where-Object {$_.Section -eq "Answer"}
            if ($Response.Strings.Length -gt 0) {
                $Answers += $Response.Strings
                # We got our answer, so break out of the retry loop and set $Success to $true, no
                # need to retry the traditional query or retry with DoH.
                $Success = $true
                break
            }
            else {
                # The answer section was empty. This usually means that while the domain exists, but
                # there are no records of the requested type. No need to retry the traditional query,
                # this was not a transient failure. Don't set $Success to $true though, as we want to
                # retry this query from a public resolver, in case the internal DNS server returns a
                # different answer than what is served to the public (i.e., split horizon DNS).
                $TradEmptyOrNx = $true
                break
            }
        }
        catch {
            if ($_.FullyQualifiedErrorId -eq "DNS_ERROR_RCODE_NAME_ERROR,Microsoft.DnsClient.Commands.ResolveDnsName") {
                # The server returned NXDomain, no need to retry the traditional query, this was not
                # a transient failure. Don't set $Success to $true though, as we want to retry this
                # query from a public resolver, in case the internal DNS server returns a different
                # answer than what is served to the public (i.e., split horizon DNS).
                $TradEmptyOrNx = $true
                break
            }
            else {
                # The query failed, possibly a transient failure. Retry if we haven't reached $MaxsTries.
                $ErrorMessages += "Traditional DNS query resulted in $($_.FullyQualifiedErrorId)."
            }
        }
    }

    if (-not $Success) {
        # The traditional DNS query(ies) failed. Retry with DoH
        $TryNumber = 0
        while ($TryNumber -lt $MaxTries) {
            try {
                $TryNumber += 1
                $Uri = "https://1.1.1.1/dns-query?name=$($Qname)&type=txt"
                $RawResponse = $(Invoke-WebRequest -H @{"accept"="application/dns-json"} -Uri $Uri).RawContent
                $ResponseLines = $RawResponse -Split "`n"
                $LastLine = $ResponseLines[$ResponseLines.Length - 1]
                $ResponseBody = ConvertFrom-Json $LastLine
                if ($ResponseBody.Status -eq 0) {
                    # 0 indicates there was no error
                    $Answers += ($ResponseBody.Answer.data | ForEach-Object {$_.Replace('"', '')})
                    $Success = $true
                    break
                }
                elseif ($ResponseBody.Status -eq 3) {
                    # 3 indicates NXDomain. The DNS query succeeded, but the domain did not exist.
                    # Set $Success to $true, because event though the domain does not exist, the
                    # query succeeded, and this came from an external resolver so split horizon is
                    # not an issue here.
                    $Success = $true
                    break
                }
                else {
                    # The remainder of the response codes indicate that the query did not succeed.
                    # Retry if we haven't reached $MaxTries.
                    $ErrorMessages += "DoH query returned response code $($ResponseBody.Status)."
                }
            }
            catch {
                # The DoH query failed, likely due to a network issue. Retry if we haven't reached
                # $MaxTries.
                $ErrorMessages = "DoH query returned response code $($_.FullyQualifiedErrorId)."
            }
        }
    }

    # There are three possible outcomes of this function:
    # - Full confidence: we know conclusively that the domain exists or not, either via an answer
    # from traditional DNS, an answer from DoH, or NXDomain from DoH.
    # - Medium confidence: domain likely doesn't exist, but there is some doubt (NXDomain from
    # traditonal DNS and DoH failed).
    # No confidence: all queries failed. Throw an exception in this case.
    if ($Success) {
        @{"Answers" = $Answers; "HighConfidence" = $true}
    }
    elseif ($TradEmptyOrNx) {
        @{"Answers" = $Answers; "HighConfidence" = $false}
    }
    else {
        throw "Failed to resolve $($Qname). $($ErrorMessages)"
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
    $NLowConf = 0

    foreach ($d in $Domains) {
        $Response = Invoke-RobustDnsTxt $d.DomainName
        if (-not $Response.HighConfidence) {
            $NLowConf += 1
        }
        $DomainName = $d.DomainName
        $SPFRecords += [PSCustomObject]@{
            "domain" = $DomainName;
            "rdata" = $Response.Answers
        }
    }

    if ($NLowConf -gt 0) {
        Write-Warning "Get-ScubaSpfRecords: for $($NLowConf) domain(s), the tradtional DNS queries returned either NXDomain or an empty answer section and the DoH queries failed. Will assume SPF not configured, but can't guarantee that failure isn't due to something like split horizon DNS."
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
    $NLowConf = 0

    foreach ($d in $domains) {
        $DomainName = $d.DomainName
        $selectors = "selector1", "selector2"
        $selectors += "selector1.$DomainName" -replace "\.", "-"
        $selectors += "selector2.$DomainName" -replace "\.", "-"

        foreach ($s in $selectors) {
            $Response = Invoke-RobustDnsTxt "$s._domainkey.$DomainName"
            if ($Response.Answers.Length -eq 0) {
                # The DKIM record does not exist with this selector, we need to try again with
                # a different one
                continue
            }
            else {
                # The DKIM record exists with this selector, no need to try the rest
                break
            }
        }

        if (-not $Response.HighConfidence) {
            $NLowConf += 1
        }

        $DKIMRecords += [PSCustomObject]@{
            "domain" = $DomainName;
            "rdata" = $Response.Answers
        }
    }

    if ($NLowConf -gt 0) {
        Write-Warning "Get-ScubaDkimRecords: for $($NLowConf) domain(s), the tradtional DNS queries returned either NXDomain or an empty answer section and the DoH queries failed. Will assume DKIM not configured, but can't guarantee that failure isn't due to something like split horizon DNS."
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
    $NLowConf = 0

    foreach ($d in $Domains) {
            # First check to see if the record is available at the full domain level
            $DomainName = $d.DomainName
            $Response = Invoke-RobustDnsTxt "_dmarc.$DomainName"
            if ($Response.Answers.Length -eq 0) {
                # The domain does not exist. If the record is not available at the full domain
                # level, we need to check at the organizational domain level.
                $Labels = $d.DomainName.Split(".")
                $Labels = $d.DomainName.Split(".")
                $OrgDomain = $Labels[-2] + "." + $Labels[-1]
                $Response = Invoke-RobustDnsTxt "_dmarc.$OrgDomain"
            }

            $DomainName = $d.DomainName
            if (-not $Response.HighConfidence) {
                $NLowConf += 1
            }
            $DMARCRecords += [PSCustomObject]@{
                "domain" = $DomainName;
                "rdata" = $Response.Answers
            }
        }

    if ($NLowConf -gt 0) {
        Write-Warning "Get-ScubaDmarcRecords: for $($NLowConf) domain(s), the tradtional DNS queries returned either NXDomain or an empty answer section and the DoH queries failed. Will assume DMARC not configured, but can't guarantee that failure isn't due to something like split horizon DNS."
    }
    $DMARCRecords
}