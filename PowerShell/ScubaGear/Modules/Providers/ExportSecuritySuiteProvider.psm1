function Export-SecuritySuiteProvider {
    <#
    .Description
    Gets the Microsoft 365 Security Suite settings that are relevant
    to the SCuBA Security Suite baselines using direct EXO Admin API calls.
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
        $ApiEndpoint,

        [Parameter(Mandatory = $false)]
        [string]
        $ComplianceAccessToken,

        [Parameter(Mandatory = $false)]
        [string]
        $ComplianceApiEndpoint
    )

        Write-Verbose "Running SecuritySuite provider export for environment '$M365Environment'."

        if ([string]::IsNullOrWhiteSpace($AccessToken)) {
            throw "AccessToken is required for SecuritySuite provider export."
        }

        if ([string]::IsNullOrWhiteSpace($ApiEndpoint)) {
            throw "ApiEndpoint is required for SecuritySuite provider export."
        }

    $HelperFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "ProviderHelpers"
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "CommandTracker.psm1")
    Import-Module (Join-Path -Path $HelperFolderPath -ChildPath "EXORestHelper.psm1")
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "../Utility/ScubaLogging.psm1") -Function Trace-ScubaFunction
    $Tracker = Get-CommandTracker

    function Format-SecuritySuitePolicyTable {
        <#
        .SYNOPSIS
        Orders policy and policy-rule tables for consistent SecuritySuite output.

        .DESCRIPTION
        Preset policies do not follow the usual custom-policy priority convention.
        Keep Strict and Standard at the top of every relevant table, then order
        remaining entries by their numeric Priority (where supplied by EXO).
        #>
        param(
            [Parameter()]
            [AllowEmptyCollection()]
            [object[]]$InputObject
        )

        $SortProperties = @(
            @{ Expression = {
                    $Name = [string]$_.Name
                    if ([string]::IsNullOrWhiteSpace($Name)) {
                        $Name = [string]$_.Identity
                    }

                    if ($Name -like 'Strict Preset Security Policy*') { return 0 }
                    if ($Name -like 'Standard Preset Security Policy*') { return 1 }
                    return 2
                }
            }
            @{ Expression = {
                    $Priority = 0
                    if ([int]::TryParse([string]$_.Priority, [ref]$Priority)) {
                        return $Priority
                    }
                    return [int]::MaxValue
                }
            }
            @{ Expression = {
                    if ($null -ne $_.Name) { return [string]$_.Name }
                    return [string]$_.Identity
                }
            }
        )
        $InputObject | Sort-Object -Property $SortProperties
    }

    function Invoke-SecuritySuiteTrackedCommand {
        param(
            [Parameter(Mandatory = $true)]
            [string]$CmdletName,
            [Parameter(Mandatory = $false)]
            [bool]$SuppressWarning = $false
        )

        try {
            $Result = Trace-ScubaFunction -FunctionName $CmdletName -LogErrors $false -ScriptBlock {
                Invoke-EXORestMethod -CmdletName $CmdletName -ApiEndpoint $ApiEndpoint -AccessToken $AccessToken
            }
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

    # IPPS/Compliance cmdlets require the Security & Compliance endpoint.
    # These include DLP, ProtectionAlert, and audit log retention policies.
    $HasComplianceEndpoint = (-not [string]::IsNullOrWhiteSpace($ComplianceAccessToken)) -and (-not [string]::IsNullOrWhiteSpace($ComplianceApiEndpoint))

    function Invoke-ComplianceTrackedCommand {
        param(
            [Parameter(Mandatory = $true)]
            [string]$CmdletName,
            [Parameter(Mandatory = $false)]
            [bool]$SuppressWarning = $false
        )

        # Try compliance endpoint first, then fall back to EXO endpoint.
        # GCCHigh: compliance endpoint works (EXO returns 403 for IPPS cmdlets)
        # Commercial/GCC: EXO endpoint works (compliance rejects EXO-scoped tokens)
        $Endpoints = @()
        if ($HasComplianceEndpoint) {
            $Endpoints += @{ Token = $ComplianceAccessToken; Endpoint = $ComplianceApiEndpoint }
        }
        $Endpoints += @{ Token = $AccessToken; Endpoint = $ApiEndpoint }

        foreach ($ep in $Endpoints) {
            try {
                $Result = Trace-ScubaFunction -FunctionName $CmdletName -LogErrors $false -ScriptBlock {
                    Invoke-EXORestMethod -CmdletName $CmdletName -ApiEndpoint $ep.Endpoint -AccessToken $ep.Token
                }
                $Tracker.AddSuccessfulCommand($CmdletName)
                return @($Result)
            }
            catch {
                # Try next endpoint
                continue
            }
        }

        # All endpoints failed
        if (-not $SuppressWarning) {
            Write-Warning "Error running ${CmdletName}: all endpoints failed."
        }
        $Tracker.AddUnSuccessfulCommand($CmdletName)
        return @()
    }


    # Get the tenant's provisioned service plans via Graph. These are used to
    # determine whether the tenant has the per-user license (E5 / E5 Compliance /
    # E5 eDiscovery and Audit add-on) required to retain audit logs beyond 180
    # days for MS.SECURITYSUITE.5.2v1. The Rego looks at the service_plans list.
    $SubscribedSku = $Tracker.TryCommand("Get-MgBetaSubscribedSku", @{"M365Environment"=$M365Environment; "GraphDirect"=$true})
    $ServicePlans = $SubscribedSku.ServicePlans | Where-Object -Property ProvisioningStatus -eq -Value "Success"
    $ServicePlans = ConvertTo-Json -Depth 3 @($ServicePlans)

    $AdminAuditLogConfig = ConvertTo-Json @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-AdminAuditLogConfig")
    $ProtectionPolicyRule = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-EOPProtectionPolicyRule"))
    $AntiPhishPolicy = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-AntiPhishPolicy"))
    $AntiPhishRule = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-AntiPhishRule"))
    $AcceptedDomains = ConvertTo-Json @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-AcceptedDomain")
    $ConnectionFilter = ConvertTo-Json @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-HostedConnectionFilterPolicy")
    $SafeLinksPolicy = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-SafeLinksPolicy"))
    $SafeLinksRule = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-SafeLinksRule"))
    $HostedContentFilterPolicies = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-HostedContentFilterPolicy"))
    $HostedContentFilterRules = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-HostedContentFilterRule"))
    $AntiMalwarePolicy = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-MalwareFilterPolicy"))
    $AntiMalwareRule = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-MalwareFilterRule"))
    $SafeAttachmentPolicy = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-SafeAttachmentPolicy"))
    $SafeAttachmentRule = ConvertTo-Json @(Format-SecuritySuitePolicyTable @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-SafeAttachmentRule"))
    $BuiltInProtectionRule = ConvertTo-Json @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-ATPBuiltInProtectionRule")

    $ATPPolicyResult = @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-AtpPolicyForO365" -SuppressWarning $true)
    $ATPProtectionPolicyRuleResult = @(Invoke-SecuritySuiteTrackedCommand -CmdletName "Get-ATPProtectionPolicyRule" -SuppressWarning $true)

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

    $ATPPolicy = ConvertTo-Json @(Format-SecuritySuitePolicyTable $ATPPolicyResult)
    $ATPProtectionPolicyRule = ConvertTo-Json @(Format-SecuritySuitePolicyTable $ATPProtectionPolicyRuleResult)

    $DLPCompliancePolicyResult = @(Invoke-ComplianceTrackedCommand -CmdletName "Get-DlpCompliancePolicy" -SuppressWarning $true)
    $DLPComplianceRulesResult = @(Invoke-ComplianceTrackedCommand -CmdletName "Get-DlpComplianceRule" -SuppressWarning $true)
    $ProtectionAlertResult = @(Invoke-ComplianceTrackedCommand -CmdletName "Get-ProtectionAlert" -SuppressWarning $true)

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

    $DLPCompliancePolicy = ConvertTo-Json @(Format-SecuritySuitePolicyTable $DLPCompliancePolicyResult)
    $DLPComplianceRules = ConvertTo-Json -Depth 3 @(Format-SecuritySuitePolicyTable $DLPComplianceRulesResult)
    $ProtectionAlert = ConvertTo-Json @($ProtectionAlertResult)


    # Audit log retention policies are needed to evaluate MS.SECURITYSUITE.5.2v1.
    $UnifiedAuditLogRetentionPolicy = ConvertTo-Json @(Invoke-ComplianceTrackedCommand -CmdletName "Get-UnifiedAuditLogRetentionPolicy" -SuppressWarning $true)

    $SuccessfulCommands = ConvertTo-Json @($Tracker.GetSuccessfulCommands())
    $UnSuccessfulCommands = ConvertTo-Json @($Tracker.GetUnSuccessfulCommands())

    $json = @"
    "protection_policy_rules": $ProtectionPolicyRule,
    "atp_policy_rules": $ATPProtectionPolicyRule,
    "dlp_compliance_policies": $DLPCompliancePolicy,
    "dlp_compliance_rules": $DLPComplianceRules,
    "anti_phish_policies": $AntiPhishPolicy,
    "anti_phish_rules": $AntiPhishRule,
    "safe_attachment_policies": $SafeAttachmentPolicy,
    "safe_attachment_rules": $SafeAttachmentRule,
    "built_in_protection_rules": $BuiltInProtectionRule,
    "accepted_domains": $AcceptedDomains,
    "protection_alerts": $ProtectionAlert,
    "admin_audit_log_config": $AdminAuditLogConfig,
    "atp_policy_for_o365": $ATPPolicy,
    "service_plans": $ServicePlans,
    "unified_audit_log_retention_policies": $UnifiedAuditLogRetentionPolicy,
    "conn_filter": $ConnectionFilter,
    "safe_links_policies": $SafeLinksPolicy,
    "safe_links_rules": $SafeLinksRule,
    "defender_license": $DefenderLicense,
    "defender_dlp_license": $DLPLicense,
    "hosted_content_filter_policies": $HostedContentFilterPolicies,
    "hosted_content_filter_rules": $HostedContentFilterRules,
    "anti_malware_policies": $AntiMalwarePolicy,
    "anti_malware_rules": $AntiMalwareRule,
    "securitysuite_successful_commands": $SuccessfulCommands,
    "securitysuite_unsuccessful_commands": $UnSuccessfulCommands,
"@

    $json
}
