function Export-DefenderProvider {
    <#
    .Description
    Gets the Microsoft 365 Defender settings that are relevant
    to the SCuBA Microsoft 365 Defender baselines using direct EXO Admin API calls.
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AccessToken,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ApiEndpoint
    )

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "EXORestHelper.psm1")
    $Tracker = Get-CommandTracker

    function Invoke-DefenderTrackedCommand {
        param(
            [Parameter(Mandatory = $true)]
            [string]$CmdletName,
            [Parameter(Mandatory = $false)]
            [bool]$SuppressWarning = $false
        )

        try {
            $Result = Invoke-EXORestMethod -CmdletName $CmdletName -ApiEndpoint $ApiEndpoint -AccessToken $AccessToken
            $Tracker.AddSuccessfulCommand($CmdletName)
            return @($Result)
        }
        catch {
            if (-not $SuppressWarning) {
                Write-Warning "Error running ${CmdletName}: $($_.Exception.Message)`n$($_.ScriptStackTrace)"
            }
            $Tracker.AddUnSuccessfulCommand($CmdletName)
            return @()
        }
    }

    $AdminAuditLogConfig = ConvertTo-Json @(Invoke-DefenderTrackedCommand -CmdletName "Get-AdminAuditLogConfig")
    $ProtectionPolicyRule = ConvertTo-Json @(Invoke-DefenderTrackedCommand -CmdletName "Get-EOPProtectionPolicyRule")
    $AntiPhishPolicy = ConvertTo-Json @(Invoke-DefenderTrackedCommand -CmdletName "Get-AntiPhishPolicy")
    $ConnectionFilter = ConvertTo-Json @(Invoke-DefenderTrackedCommand -CmdletName "Get-HostedConnectionFilterPolicy")

    $ATPPolicyResult = @(Invoke-DefenderTrackedCommand -CmdletName "Get-AtpPolicyForO365" -SuppressWarning $true)
    $ATPProtectionPolicyRuleResult = @(Invoke-DefenderTrackedCommand -CmdletName "Get-ATPProtectionPolicyRule" -SuppressWarning $true)

    if (($Tracker.GetUnSuccessfulCommands() -contains "Get-AtpPolicyForO365") -or ($Tracker.GetUnSuccessfulCommands() -contains "Get-ATPProtectionPolicyRule")) {
        $ATPPolicyResult = @()
        $ATPProtectionPolicyRuleResult = @()
        $DefenderLicense = ConvertTo-Json $false

        # Keep compatibility with prior report behavior for missing defender license.
        $Tracker.AddSuccessfulCommand("Get-AtpPolicyForO365")
        $Tracker.AddSuccessfulCommand("Get-ATPProtectionPolicyRule")
    }
    else {
        $DefenderLicense = ConvertTo-Json $true
    }

    $ATPPolicy = ConvertTo-Json @($ATPPolicyResult)
    $ATPProtectionPolicyRule = ConvertTo-Json @($ATPProtectionPolicyRuleResult)

    $DLPCompliancePolicyResult = @(Invoke-DefenderTrackedCommand -CmdletName "Get-DlpCompliancePolicy" -SuppressWarning $true)
    $DLPComplianceRulesResult = @(Invoke-DefenderTrackedCommand -CmdletName "Get-DlpComplianceRule" -SuppressWarning $true)
    $ProtectionAlertResult = @(Invoke-DefenderTrackedCommand -CmdletName "Get-ProtectionAlert" -SuppressWarning $true)

    if (($Tracker.GetUnSuccessfulCommands() -contains "Get-DlpCompliancePolicy") -or ($Tracker.GetUnSuccessfulCommands() -contains "Get-DlpComplianceRule") -or ($Tracker.GetUnSuccessfulCommands() -contains "Get-ProtectionAlert")) {
        $DLPCompliancePolicyResult = @()
        $DLPComplianceRulesResult = @()
        $ProtectionAlertResult = @()
        $DLPLicense = ConvertTo-Json $false

        # Keep compatibility with prior report behavior for missing DLP license.
        $Tracker.AddSuccessfulCommand("Get-DlpCompliancePolicy")
        $Tracker.AddSuccessfulCommand("Get-DlpComplianceRule")
        $Tracker.AddSuccessfulCommand("Get-ProtectionAlert")
    }
    else {
        $DLPLicense = ConvertTo-Json $true
    }

    foreach($Rule in $DLPComplianceRulesResult) {
        if ($Rule.Count -gt 0) {
            $Rule.ContentContainsSensitiveInformation = @($Rule.ContentContainsSensitiveInformation)
        }
    }

    $DLPCompliancePolicy = ConvertTo-Json @($DLPCompliancePolicyResult)
    $DLPComplianceRules = ConvertTo-Json -Depth 3 $DLPComplianceRulesResult
    $ProtectionAlert = ConvertTo-Json @($ProtectionAlertResult)

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    $json = @"
    "protection_policy_rules": $ProtectionPolicyRule,
    "atp_policy_rules": $ATPProtectionPolicyRule,
    "dlp_compliance_policies": $DLPCompliancePolicy,
    "dlp_compliance_rules": $DLPComplianceRules,
    "anti_phish_policies": $AntiPhishPolicy,
    "protection_alerts": $ProtectionAlert,
    "admin_audit_log_config": $AdminAuditLogConfig,
    "atp_policy_for_o365": $ATPPolicy,
    "conn_filter": $ConnectionFilter,
    "defender_license": $DefenderLicense,
    "defender_dlp_license": $DLPLicense,
    "defender_successful_commands": $SuccessfulCommands,
    "defender_unsuccessful_commands": $UnSuccessfulCommands,
"@

    $json
}
