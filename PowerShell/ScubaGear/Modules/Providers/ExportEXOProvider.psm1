function Export-EXOProvider {
    <#
    .Description
    Gets the Exchange Online (EXO) settings that are relevant
    to the SCuBA EXO baselines using the EXO PowerShell Module
    .Functionality
    Internal
    #>

    [CmdletBinding()]
    [OutputType([String])]
    param()

    # Manually importing the module name here to bypass cmdlet name conflicts
    # There are conflicting PowerShell Cmdlet names in EXO and Power Platform
    Import-Module ExchangeOnlineManagement

    Import-Module $PSScriptRoot/ProviderHelpers/CommandTracker.psm1
    $Tracker = Get-CommandTracker

    <#
    MS.EXO.1.1v1
    #>
    $RemoteDomains = ConvertTo-Json @($Tracker.TryCommand("Get-RemoteDomain"))

    <#
    MS.EXO.2.1v1 SPF
    #>
    $domains = $Tracker.TryCommand("Get-AcceptedDomain")
    $SPFRecords = ConvertTo-Json @($Tracker.TryCommand("Get-ScubaSpfRecord", @{"Domains"=$domains})) -Depth 3

    <#
    MS.EXO.3.1v1 DKIM
    #>
    $DKIMConfig = ConvertTo-Json @($Tracker.TryCommand("Get-DkimSigningConfig"))
    $DKIMRecords = ConvertTo-Json @($Tracker.TryCommand("Get-ScubaDkimRecord", @{"Domains"=$domains})) -Depth 3

    <#
    MS.EXO.4.1v1 DMARC
    #>
    $DMARCRecords = ConvertTo-Json @($Tracker.TryCommand("Get-ScubaDmarcRecord", @{"Domains"=$domains})) -Depth 3

    <#
    MS.EXO.5.1v1
    #>
    $TransportConfig = ConvertTo-Json @($Tracker.TryCommand("Get-TransportConfig"))

    <#
    MS.EXO.6.1v1
    #>
    $SharingPolicy = ConvertTo-Json @($Tracker.TryCommand("Get-SharingPolicy"))

    <#
    MS.EXO.7.1v1
    #>
    $TransportRules = ConvertTo-Json @($Tracker.TryCommand("Get-TransportRule"))

    <#
    MS.EXO.12.1v1
    #>
    $ConnectionFilter = ConvertTo-Json @($Tracker.TryCommand("Get-HostedConnectionFilterPolicy"))

    <#
    MS.EXO.13.1v1
    #>
    $Config = $Tracker.TryCommand("Get-OrganizationConfig") | Select-Object Name, DisplayName, AuditDisabled
    $Config = ConvertTo-Json @($Config)

    # Used in the reporter to check successful cmdlet invocation
    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    # Note the spacing and the last comma in the json is important
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
        [ValidateNotNullOrEmpty()]
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
            $Content = (Invoke-WebRequest -Uri $Uri -UseBasicParsing -ErrorAction "Stop").Content
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

# A $script:scoped variable used to indicate the preferred DoH server.
# Initialize to empty string to indicate that we don't yet know the
# preferred server. Will be set when the Select-DohServer function is
# called.
$DohServer = ""

function Select-DohServer {
    <#
    .Description
    Iterates through several DoH servers. Returns the first successful server. If none are successful, returns $null.
    .Functionality
    Internal
    #>
    $DoHServers = @("cloudflare-dns.com", "[2606:4700:4700::1111]", "1.1.1.1")
    $PreferredServer = $null
    foreach ($Server in $DoHServers) {
        try {
            # Attempt to resolve a.root-servers.net over DoH. The domain chosen is somewhat
            # arbitrary, as we don't care what the answer is, only if the query succeeds/fails.
            # a.root-servers.net, the address of one of the DNS root servers, was chosen as a
            # benign, highly-available domain.
            $Uri = "https://$($Server)/dns-query?name=a.root-servers.net"
            Invoke-WebRequest -Headers @{"accept"="application/dns-json"} -Uri $Uri `
                -TimeoutSec 2 -UseBasicParsing -ErrorAction "Stop" | Out-Null
            # No error was thrown, return this server
            $PreferredServer = $Server
            break
        }
        catch {
            # This server didn't work, try the next one
            continue
        }
    }
    $PreferredServer
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
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Qname,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]
        $MaxTries = 2
    )
    $Answers = @()
    $LogEntries = @()

    $TryNumber = 0
    $Success = $false
    $TradEmpty = $false
    while ($TryNumber -lt $MaxTries) {
        $TryNumber += 1
        try {
            $Response = Resolve-DnsName $Qname txt -ErrorAction Stop | Where-Object {$_.Section -eq "Answer"}
            if ($Response.Strings.Length -gt 0) {
                # We got our answer, so break out of the retry loop and set $Success to $true, no
                # need to retry the traditional query or retry with DoH.
                $LogEntries += @{
                    "query_name"=$Qname;
                    "query_method"="traditional";
                    "query_result"="Query returned $($Response.Strings.Length) txt records"
                }
                $Answers += $Response.Strings
                $Success = $true
                break
            }
            else {
                # The answer section was empty. This usually means that while the domain exists, but
                # there are no records of the requested type. No need to retry the traditional query,
                # this was not a transient failure. Don't set $Success to $true though, as we want to
                # retry this query from a public resolver, in case the internal DNS server returns a
                # different answer than what is served to the public (i.e., split horizon DNS).
                $LogEntries += @{
                    "query_name"=$Qname;
                    "query_method"="traditional";
                    "query_result"="Query returned 0 txt records"
                }
                $TradEmpty = $true
                break
            }
        }
        catch {
            if ($_.FullyQualifiedErrorId -eq "DNS_ERROR_RCODE_NAME_ERROR,Microsoft.DnsClient.Commands.ResolveDnsName") {
                # The server returned NXDomain, no need to retry the traditional query or retry with
                # DoH, this was not a transient failure. Break out of loop and set $Success to $true
                $LogEntries += @{
                    "query_name"=$Qname;
                    "query_method"="traditional";
                    "query_result"="Query returned NXDomain"
                }
                $Success = $True
                break
            }
            else {
                # The query failed, possibly a transient failure. Retry if we haven't reached $MaxsTries.
                $LogEntries += @{
                    "query_name"=$Qname;
                    "query_method"="traditional";
                    "query_result"="Query resulted in exception, $($_.FullyQualifiedErrorId)"
                }
            }
        }
    }

    if (-not $Success) {
        # The traditional DNS query(ies) failed. Retry with DoH
        if ($script:DohServer -eq "") {
            # We haven't determined if DoH is available yet, select the first server that works
            $script:DohServer = Select-DohServer
        }
        if ($null -eq $script:DohServer) {
            # None of the DoH servers are accessible
            $LogEntries += @{"query_name"=$Qname; "query_method"="DoH"; "query_result"="NA, DoH servers unreachable"}
        }
        else {
            # DoH is available, query for the domain
            $TryNumber = 0
            while ($TryNumber -lt $MaxTries) {
                $TryNumber += 1
                try {
                    $Uri = "https://$($script:DohServer)/dns-query?name=$($Qname)&type=txt"
                    $Headers = @{"accept"="application/dns-json"}
                    $RawResponse = $(Invoke-WebRequest -Headers $Headers -Uri $Uri -UseBasicParsing -ErrorAction "Stop").RawContent
                    $ResponseLines = $RawResponse -Split "`n"
                    $LastLine = $ResponseLines[$ResponseLines.Length - 1]
                    $ResponseBody = ConvertFrom-Json $LastLine
                    if ($ResponseBody.Status -eq 0) {
                        # 0 indicates there was no error
                        $LogEntries += @{
                            "query_name"=$Qname;
                            "query_method"="DoH";
                            "query_result"="Query returned $($ResponseBody.Answer.data.Length) txt records"
                        }
                        $Answers += ($ResponseBody.Answer.data | ForEach-Object {$_.Replace('"', '')})
                        $Success = $true
                        break
                    }
                    elseif ($ResponseBody.Status -eq 3) {
                        # 3 indicates NXDomain. The DNS query succeeded, but the domain did not exist.
                        # Set $Success to $true, because event though the domain does not exist, the
                        # query succeeded, and this came from an external resolver so split horizon is
                        # not an issue here.
                        $LogEntries += @{
                            "query_name"=$Qname;
                            "query_method"="DoH";
                            "query_result"="Query returned NXDomain"
                        }
                        $Success = $true
                        break
                    }
                    else {
                        # The remainder of the response codes indicate that the query did not succeed.
                        # Retry if we haven't reached $MaxTries.
                        $LogEntries += @{
                            "query_name"=$Qname;
                            "query_method"="DoH";
                            "query_result"="Query returned response code $($ResponseBody.Status)"
                        }
                    }
                }
                catch {
                    # The DoH query failed, likely due to a network issue. Retry if we haven't reached
                    # $MaxTries.
                    $LogEntries += @{
                        "query_name"=$Qname;
                        "query_method"="DoH";
                        "query_result"="Query resulted in exception, $($_.FullyQualifiedErrorId)"
                    }
                }
            }
        }
    }

    # There are three possible outcomes of this function:
    # - Full confidence: we know conclusively that the domain exists or not, either via a non-empty
    # answer from traditional DNS or an answer from DoH.
    # - Medium confidence: domain likely doesn't exist, but there is some doubt (empty answer from
    # traditonal DNS and DoH failed).
    # No confidence: all queries failed. Throw an exception in this case.
    if ($Success) {
        @{"Answers" = $Answers; "HighConfidence" = $true; "LogEntries" = $LogEntries}
    }
    elseif ($TradEmpty) {
        @{"Answers" = $Answers; "HighConfidence" = $false; "LogEntries" = $LogEntries}
    }
    else {
        $Log = ($LogEntries | ForEach-Object {ConvertTo-Json $_ -Compress}) -Join "`n"
        throw "Failed to resolve $($Qname). `n$($Log)"
    }
}

function Get-ScubaSpfRecord {
    <#
    .Description
    Gets the SPF records for each domain in $Domains
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
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
            "rdata" = $Response.Answers;
            "log" = $Response.LogEntries;
        }
    }

    if ($NLowConf -gt 0) {
        Write-Warning "Get-ScubaSpfRecord: for $($NLowConf) domain(s), the tradtional DNS queries returned an empty answer section and the DoH queries failed. Will assume SPF not configured, but can't guarantee that failure isn't due to something like split horizon DNS. See ProviderSettingsExport.json under 'spf_records' for more details."
    }
    $SPFRecords
}

function Get-ScubaDkimRecord {
    <#
    .Description
    Gets the DKIM records for each domain in $Domains
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
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

        $LogEntries = @()
        foreach ($s in $selectors) {
            $Response = Invoke-RobustDnsTxt "$s._domainkey.$DomainName"
            $LogEntries += $Response.LogEntries
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
            "rdata" = $Response.Answers;
            "log" = $LogEntries;
        }
    }

    if ($NLowConf -gt 0) {
        Write-Warning "Get-ScubaDkimRecord: for $($NLowConf) domain(s), the tradtional DNS queries returned an empty answer section and the DoH queries failed. Will assume DKIM not configured, but can't guarantee that failure isn't due to something like split horizon DNS. See ProviderSettingsExport.json under 'dkim_records' for more details."
    }
    $DKIMRecords
}

function Get-ScubaDmarcRecord {
    <#
    .Description
    Gets the DMARC records for each domain in $Domains
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $Domains
    )

    $DMARCRecords = @()
    $NLowConf = 0

    foreach ($d in $Domains) {
    $LogEntries = @()
        # First check to see if the record is available at the full domain level
        $DomainName = $d.DomainName
        $Response = Invoke-RobustDnsTxt "_dmarc.$DomainName"
        $LogEntries += $Response.LogEntries
        if ($Response.Answers.Length -eq 0) {
            # The domain does not exist. If the record is not available at the full domain
            # level, we need to check at the organizational domain level.
            $Labels = $d.DomainName.Split(".")
            $Labels = $d.DomainName.Split(".")
            $OrgDomain = $Labels[-2] + "." + $Labels[-1]
            $Response = Invoke-RobustDnsTxt "_dmarc.$OrgDomain"
            $LogEntries += $Response.LogEntries
        }

        $DomainName = $d.DomainName
        if (-not $Response.HighConfidence) {
            $NLowConf += 1
        }
        $DMARCRecords += [PSCustomObject]@{
            "domain" = $DomainName;
            "rdata" = @($Response.Answers);
            "log" = $LogEntries;
        }
    }

    if ($NLowConf -gt 0) {
        Write-Warning "Get-ScubaDmarcRecord: for $($NLowConf) domain(s), the tradtional DNS queries returned an empty answer section and the DoH queries failed. Will assume DMARC not configured, but can't guarantee that failure isn't due to something like split horizon DNS. See ProviderSettingsExport.json under 'dmarc_records' for more details."
    }
    $DMARCRecords
}