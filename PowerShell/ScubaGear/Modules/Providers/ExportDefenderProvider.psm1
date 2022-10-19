function Export-DefenderProvider {
    <#
    .Description
    Gets the Microsoft 365 Defender settings that are relevant
    to the SCuBA Microsft 365 Defender baselines using the EXO PowerShell Module
    .Functionality
    Internal
    #>

    # Sign in for the Defender Provider if not connected
    $ExchangeConnected = Get-OrganizationConfig -ErrorAction SilentlyContinue
    if(-not $ExchangeConnected) {
        Connect-ExchangeOnline -ShowBanner:$false | Out-Null
    }
    Import-Module ExchangeOnlineManagement

    # Regular Exchange i.e non IPPSSession cmdlets
    $AdminAuditLogConfig = Get-AdminAuditLogConfig | ConvertTo-Json
    $ProtectionPolicyRule = ConvertTo-Json @(Get-EOPProtectionPolicyRule)
    $MalwareFilterPolicy = ConvertTo-Json @(Get-MalwareFilterPolicy)
    $AntiPhishPolicy = ConvertTo-Json @(Get-AntiPhishPolicy)
    $HostedContentFilterPolicy = ConvertTo-Json @(Get-HostedContentFilterPolicy)
    $AllDomains = Get-AcceptedDomain | ConvertTo-Json

    # Test if Defender specific commands are available. If the tenant does
    # not have a defender license (plan 1 or plan 2), the following
    # commandlets will fail with "The term [Cmdlet name] is not recognized
    # as the name of a cmdlet, function, script file, or operable program,"
    # so we can test for this using Get-Command.
    if (Get-Command Get-SafeAttachmentPolicy -errorAction SilentlyContinue) {
        $SafeAttachmentPolicy = ConvertTo-Json @(Get-SafeAttachmentPolicy)
        $SafeAttachmentRule = ConvertTo-Json @(Get-SafeAttachmentRule)
        $SafeLinksPolicy = ConvertTo-Json @(Get-SafeLinksPolicy)
        $SafeLinksRule = ConvertTo-Json @(Get-SafeLinksRule)
        $ATPPolicy = ConvertTo-Json @(Get-AtpPolicyForO365)
        $DefenderLicense = ConvertTo-Json $true
    }
    else {
        # The tenant can't make use of the defender commands
        $SafeAttachmentPolicy = ConvertTo-Json @()
        $SafeAttachmentRule = ConvertTo-Json @()
        $SafeLinksPolicy = ConvertTo-Json @()
        $SafeLinksRule = ConvertTo-Json @()
        $ATPPolicy = ConvertTo-Json @()
        $DefenderLicense = ConvertTo-Json $false
    }

    $AllDomains = ConvertTo-Json @(Get-AcceptedDomain)

    # Connect to Security & Compliance
    Connect-IPPSSession | Out-Null

    $DLPCompliancePolicy = ConvertTo-Json @(Get-DlpCompliancePolicy)
    $DLPComplianceRules =  @(Get-DlpComplianceRule)
    $ProtectionAlert = Get-ProtectionAlert | ConvertTo-Json

    # Powershell is inconsistent with how they save lists to json.
    # This loop ensures that the format of ContentContainsSensitiveInformation
    # will *always* be a list.
    foreach($Rule in $DLPComplianceRules) {
        $Rule.ContentContainsSensitiveInformation = @($Rule.ContentContainsSensitiveInformation)
    }

    # We need to specify the depth because the data contains some
    # nested tables.
    $DLPComplianceRules = ConvertTo-Json -Depth 3 $DLPComplianceRules

    # Note the spacing and the last comma in the json is important
    $json = @"
    "protection_policy_rules": $ProtectionPolicyRule,
    "dlp_compliance_policies": $DLPCompliancePolicy,
    "dlp_compliance_rules": $DLPComplianceRules,
    "malware_filter_policies": $MalwareFilterPolicy,
    "anti_phish_policies": $AntiPhishPolicy,
    "hosted_content_filter_policies": $HostedContentFilterPolicy,
    "safe_attachment_policies": $SafeAttachmentPolicy,
    "safe_attachment_rules": $SafeAttachmentRule,
    "all_domains": $AllDomains,
    "protection_alerts": $ProtectionAlert,
    "admin_audit_log_config": $AdminAuditLogConfig,
    "safe_links_policies": $SafeLinksPolicy,
    "safe_links_rules": $SafeLinksRule,
    "atp_policy_for_o365": $ATPPolicy,
    "defender_license": $DefenderLicense,
"@

    # We need to remove the backslash characters from the
    # json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
    $json
}

function Get-DefenderTenantDetail {
    <#
    .Description
    Gets the tenant details using the AAD PowerShell Module
    .Functionality
    Internal
    #>
    Import-Module ExchangeOnlineManagement
    $Config = Get-OrganizationConfig
    $TenantInfo = @{"DisplayName"=$Config.Name;}
    $TenantInfo = $TenantInfo | ConvertTo-Json -Depth 4
    $TenantInfo
}
