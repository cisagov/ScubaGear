function Export-DefenderProvider {
    <#
    .Description
    Gets the Microsoft 365 Defender settings that are relevant
    to the SCuBA Microsft 365 Defender baselines using the EXO PowerShell Module
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
    $ParentPath = Split-Path $PSScriptRoot -Parent
    $ConnectionFolderPath = Join-Path -Path $ParentPath -ChildPath "Connection"
    Import-Module (Join-Path -Path $ConnectionFolderPath -ChildPath "ConnectHelpers.psm1")

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    $Tracker = Get-CommandTracker

    # Manually importing the module name here to bypass cmdlet name conflicts
    # There are conflicting PowerShell Cmdlet names in EXO and Power Platform
    Import-Module ExchangeOnlineManagement

    # Sign in for the Defender Provider if not connected
    $ExchangeConnected = Get-Command Get-OrganizationConfig -ErrorAction SilentlyContinue
    if(-not $ExchangeConnected) {
        try {
            Connect-EXOHelper -M365Environment $M365Environment
        }
        catch {
            Write-Error "Error connecting to ExchangeOnline. $($_)"
        }
    }

    # Regular Exchange i.e non IPPSSession cmdlets
    $AdminAuditLogConfig = ConvertTo-Json @($Tracker.TryCommand("Get-AdminAuditLogConfig"))
    $ProtectionPolicyRule = ConvertTo-Json @($Tracker.TryCommand("Get-EOPProtectionPolicyRule"))
    $MalwareFilterPolicy = ConvertTo-Json @($Tracker.TryCommand("Get-MalwareFilterPolicy"))
    $AntiPhishPolicy = ConvertTo-Json @($Tracker.TryCommand("Get-AntiPhishPolicy"))
    $HostedContentFilterPolicy = ConvertTo-Json @($Tracker.TryCommand("Get-HostedContentFilterPolicy"))
    $AllDomains = ConvertTo-Json @($Tracker.TryCommand("Get-AcceptedDomain"))

    # Test if Defender specific commands are available. If the tenant does
    # not have a defender license (plan 1 or plan 2), the following
    # commandlets will fail with "The term [Cmdlet name] is not recognized
    # as the name of a cmdlet, function, script file, or operable program,"
    # so we can test for this using Get-Command.
    if (Get-Command Get-SafeAttachmentPolicy -ErrorAction SilentlyContinue) {
        $SafeAttachmentPolicy = ConvertTo-Json @($Tracker.TryCommand("Get-SafeAttachmentPolicy"))
        $SafeAttachmentRule = ConvertTo-Json @($Tracker.TryCommand("Get-SafeAttachmentRule"))
        $SafeLinksPolicy = ConvertTo-Json @($Tracker.TryCommand("Get-SafeLinksPolicy"))
        $SafeLinksRule = ConvertTo-Json @($Tracker.TryCommand("Get-SafeLinksRule"))
        $ATPPolicy = ConvertTo-Json @($Tracker.TryCommand("Get-AtpPolicyForO365"))
        $DefenderLicense = ConvertTo-Json $true
    }
    else {
        # The tenant can't make use of the defender commands
        Write-Warning "Defender license not available in tenant. Omitting the following commands: Get-SafeAttachmentPolicy, Get-SafeAttachmentRule, Get-SafeLinksPolicy, Get-SafeLinksRule, and Get-AtpPolicyForO365."
        $SafeAttachmentPolicy = ConvertTo-Json @()
        $SafeAttachmentRule = ConvertTo-Json @()
        $SafeLinksPolicy = ConvertTo-Json @()
        $SafeLinksRule = ConvertTo-Json @()
        $ATPPolicy = ConvertTo-Json @()
        $DefenderLicense = ConvertTo-Json $false

        # While it is counter-intuitive to add these to SuccessfulCommands
        # and UnSuccessfulCommands, this is a unique error case that is
        # handled within the Rego.
        $Tracker.AddSuccessfulCommand("Get-SafeAttachmentPolicy")
        $Tracker.AddSuccessfulCommand("Get-SafeAttachmentRule")
        $Tracker.AddSuccessfulCommand("Get-SafeLinksPolicy")
        $Tracker.AddSuccessfulCommand("Get-SafeLinksRule")
        $Tracker.AddSuccessfulCommand("Get-AtpPolicyForO365")

        $Tracker.AddUnSuccessfulCommand("Get-SafeAttachmentPolicy")
        $Tracker.AddUnSuccessfulCommand("Get-SafeAttachmentRule")
        $Tracker.AddUnSuccessfulCommand("Get-SafeLinksPolicy")
        $Tracker.AddUnSuccessfulCommand("Get-SafeLinksRule")
        $Tracker.AddUnSuccessfulCommand("Get-AtpPolicyForO365")
    }

    # Connect to Security & Compliance
    $IPPSConnected = $false
    try {
        Connect-DefenderHelper -M365Environment $M365Environment 
        $IPPSConnected = $true
    }
    catch {
        Write-Error "Error running Connect-IPPSSession. $($_)"
        Write-Warning "Omitting the following commands: Get-DlpCompliancePolicy, Get-DlpComplianceRule, and Get-ProtectionAlert."
        $Tracker.AddUnSuccessfulCommand("Get-DlpCompliancePolicy")
        $Tracker.AddUnSuccessfulCommand("Get-DlpComplianceRule")
        $Tracker.AddUnSuccessfulCommand("Get-ProtectionAlert")
    }
    if ($IPPSConnected) {
        $DLPCompliancePolicy = ConvertTo-Json @($Tracker.TryCommand("Get-DlpCompliancePolicy"))
        $ProtectionAlert = ConvertTo-Json @($Tracker.TryCommand("Get-ProtectionAlert"))
        $DLPComplianceRules = @($Tracker.TryCommand("Get-DlpComplianceRule"))

        # Powershell is inconsistent with how it saves lists to json.
        # This loop ensures that the format of ContentContainsSensitiveInformation
        # will *always* be a list.

        foreach($Rule in $DLPComplianceRules) {
            if ($Rule.Count -gt 0) {
                $Rule.ContentContainsSensitiveInformation = @($Rule.ContentContainsSensitiveInformation)
            }
        }

        # We need to specify the depth because the data contains some
        # nested tables.
        $DLPComplianceRules = ConvertTo-Json -Depth 3 $DLPComplianceRules
    }
    else {
        $DLPCompliancePolicy = ConvertTo-Json @()
        $DLPComplianceRules = ConvertTo-Json @()
        $ProtectionAlert = ConvertTo-Json @()
        $DLPComplianceRules = ConvertTo-Json @()
    }

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

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
    "defender_successful_commands": $SuccessfulCommands,
    "defender_unsuccessful_commands": $UnSuccessfulCommands,
"@

    # We need to remove the backslash characters from the
    # json, otherwise rego gets mad.
    $json = $json.replace("\`"", "'")
    $json = $json.replace("\", "")
    $json
}
