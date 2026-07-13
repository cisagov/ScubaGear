package securitysuite
import rego.v1
import data.utils.report.NotCheckedDetails
import data.utils.report.ArraySizeStr
import data.utils.report.Description
import data.utils.report.ReportDetailsString
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsBooleanWarning
import data.utils.securitysuite.ImpersonationProtectionReportDetails
import data.utils.securitysuite.ImpersonationProtectionRequirementMet
import data.utils.securitysuite.ListConfigValues
import data.utils.securitysuite.OrganizationDomainProtectionCompliant
import data.utils.securitysuite.PartnerDomainConfig
import data.utils.securitysuite.PartnerDomainImpersonationCompliant
import data.utils.securitysuite.UserImpersonationCompliant
import data.utils.securitysuite.UserWarningsCompliant
import data.utils.securitysuite.PresetRecipientsCovered
import data.utils.securitysuite.RuleFieldEmpty
import data.utils.securitysuite.PresetPolicyCoversAllRecipients
import data.utils.securitysuite.CustomRuleCoversAllRecipients
import data.utils.securitysuite.HighestPriorityActiveAntiMalwarePolicyName
import data.utils.securitysuite.HighestPriorityActiveSafeAttachmentPolicyName
import data.utils.securitysuite.UserFriendlyPolicyName
import data.utils.securitysuite.ApplyLicenseWarning
import data.utils.securitysuite.ApplyLicenseWarningStringCustom
import data.utils.report.ReportDetailsArray
import data.utils.key.Count


######################
# MS.SECURITYSUITE.1 #
######################

#
# MS.SECURITYSUITE.1.1v1
#--

# Legend that explains each of the JSON nodes for the anti-malware policies 1.1 and 1.2
# anti_malware_rules = Contains only the custom policies. State = "Enabled"/"Disabled", Identity = Name of the policy
# anti_malware_policies = Contains all the policies (custom, standard preset, strict preset, default)
#

PolicyCompliantForBlockClickToRun(Policy) := true if {
    Policy.EnableFileFilter == true
    RequiredTypes := {"exe", "cmd", "vbe"}
    MissingTypes := RequiredTypes - {Type | some Type in Policy.FileTypes}
    count(MissingTypes) == 0
} else := false

PolicyBlockClickToRunNoncomplianceReasons contains "The common attachments filter is disabled." if {
    some Policy in input.anti_malware_policies
    Policy.Identity == HighestPriorityActiveAntiMalwarePolicyName
    Policy.EnableFileFilter != true
}

PolicyBlockClickToRunNoncomplianceReasons contains Reason if {
    RequiredTypes := {"exe", "cmd", "vbe"}
    some Policy in input.anti_malware_policies
    Policy.Identity == HighestPriorityActiveAntiMalwarePolicyName
    MissingTypes := RequiredTypes - {Type | some Type in Policy.FileTypes}
    count(MissingTypes) > 0
    Reason := concat("", [
        "The common attachments filter does not include ",
        concat(", ", MissingTypes),
        "."
    ])
}

AntiMalwarePolicyMessage := ". The highest priority anti-malware policy that applies to all users is: "

SecuritySuite_1_1_Details(Status) := 
    concat("", [
        ReportDetailsBoolean(Status),
        AntiMalwarePolicyMessage,
        UserFriendlyPolicyName(HighestPriorityActiveAntiMalwarePolicyName), ". ",
        concat(" ", PolicyBlockClickToRunNoncomplianceReasons)
    ])

tests contains {
    "PolicyId": "MS.SECURITYSUITE.1.1v1",
    "Criticality": "Shall",
    "Commandlet": [
        "Get-MalwareFilterPolicy",
        "Get-MalwareFilterRule",
        "Get-EOPProtectionPolicyRule",
        "Get-AcceptedDomain"
    ],
    "ActualValue": [{
        "Policy Name": HighestPriorityActiveAntiMalwarePolicyName,
        "EnableFileFilter": Policy.EnableFileFilter,
        "FileTypes": Policy.FileTypes
    }],
    "ReportDetails": SecuritySuite_1_1_Details(Status),
    "RequirementMet": Status
}
if {
    some Policy in input.anti_malware_policies
    Policy.Identity == HighestPriorityActiveAntiMalwarePolicyName
    Status := PolicyCompliantForBlockClickToRun(Policy)
}
#--

#
# MS.SECURITYSUITE.1.2v1
#--

PolicyZAPNoncomplianceReasons contains "Zero-hour auto purge is disabled." if {
    some Policy in input.anti_malware_policies
    Policy.Identity == HighestPriorityActiveAntiMalwarePolicyName
    Policy.ZapEnabled != true
}

SecuritySuite_1_2_Details(Status) := 
    concat("", [
        ReportDetailsBoolean(Status),
        ". The highest priority anti-malware policy that applies to all users is: ",
        UserFriendlyPolicyName(HighestPriorityActiveAntiMalwarePolicyName), ". ",
        concat(" ", PolicyZAPNoncomplianceReasons)
    ])

tests contains {
    "PolicyId": "MS.SECURITYSUITE.1.2v1",
    "Criticality": "Shall",
    "Commandlet": [
        "Get-MalwareFilterPolicy",
        "Get-MalwareFilterRule",
        "Get-EOPProtectionPolicyRule",
        "Get-AcceptedDomain"
    ],
    "ActualValue": [{
        "Policy Name": HighestPriorityActiveAntiMalwarePolicyName,
        "EnableFileFilter": Policy.ZapEnabled
    }],
    "ReportDetails": SecuritySuite_1_2_Details(Status),
    "RequirementMet": Status
}
if {
    some Policy in input.anti_malware_policies
    Policy.Identity == HighestPriorityActiveAntiMalwarePolicyName
    Status := Policy.ZapEnabled == true
}
#--

#
# MS.SECURITYSUITE.1.3v1
#--

SecurySuite_1_3_Result := {
    "Status": false,
    "Description": concat("", [
        ReportDetailsBoolean(false),
        ". No safe attachments policy applies to all users, including built-in protection."
    ])
} if {
    HighestPriorityActiveSafeAttachmentPolicyName == null
} else := {
    "Status": true,
    "Description": concat("", [
        ReportDetailsBoolean(true),
        ". The highest priority safe attachments policy that applies to all users is: ",
        UserFriendlyPolicyName(HighestPriorityActiveSafeAttachmentPolicyName), "."
    ])
} if {
    some Policy in input.safe_attachment_policies
    Policy.Identity == HighestPriorityActiveSafeAttachmentPolicyName
    Policy.Action in {"Block", "DynamicDelivery"}
} else := {
    "Status": false,
    "Description": concat("", [
        ReportDetailsBoolean(false),
        ". The highest priority safe attachments policy that applies to all users is: ",
        UserFriendlyPolicyName(HighestPriorityActiveSafeAttachmentPolicyName),
        ". Safe Attachments unknown malware Malware response is set to ",
        Policy.Action,
        "."
    ])
} if {
    some Policy in input.safe_attachment_policies
    Policy.Identity == HighestPriorityActiveSafeAttachmentPolicyName
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.1.3v1",
    "Criticality": "Shall",
    "Commandlet": [
        "Get-SafeAttachmentPolicy",
        "Get-SafeAttachmentRule",
        "Get-ATPProtectionPolicyRule",
        "Get-ATPBuiltInProtectionRule",
        "Get-AcceptedDomain"
    ],
    "ActualValue": [{
        "Policy Name": HighestPriorityActiveSafeAttachmentPolicyName
    }],
    "ReportDetails": ApplyLicenseWarningStringCustom(Status, Description),
    "RequirementMet": Status
}
if {
    Status := SecurySuite_1_3_Result.Status
    Description := SecurySuite_1_3_Result.Description
}
#--

#
# MS.SECURITYSUITE.1.4v1
#--
# Find the set of policies that have EnableATPForSPOTeamsODB set to true
ATPPolicies contains {
    "Identity": Policy.Identity,
    "EnableATPForSPOTeamsODB": Policy.EnableATPForSPOTeamsODB
} if {
    some Policy in input.atp_policy_for_o365
    Policy.EnableATPForSPOTeamsODB == true
}

# Pass if at least one policy exists
tests contains {
    "PolicyId": "MS.SECURITYSUITE.1.4v1",
    "Criticality": "Should",
    "Commandlet": ["Get-AtpPolicyForO365"],
    "ActualValue": ATPPolicies,
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
}
if {
    Status := count(ATPPolicies) > 0
}
#--


######################
# MS.SECURITYSUITE.2 #
######################

#
# MS.SECURITYSUITE.2.1v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.2.1v1",
    "Criticality": "Should",
    "Commandlet": [
        "Get-AntiPhishPolicy",
        "Get-AntiPhishRule",
        "Get-EOPProtectionPolicyRule",
        "Get-AcceptedDomain"
    ],
    "ActualValue": {"SensitiveUsers": SensitiveUsers},
    "ReportDetails": ImpersonationProtectionReportDetails(false, ErrorMessage),
    "RequirementMet": ImpersonationProtectionRequirementMet(false)
} if {
    SensitiveUsers := ListConfigValues("MS.SECURITYSUITE.2.1v1", "SensitiveUsers")
    count(SensitiveUsers) == 0
    ErrorMessage := "No users defined as sensitive users in the ScubaGear config file."
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.2.1v1",
    "Criticality": "Should",
    "Commandlet": [
        "Get-AntiPhishPolicy",
        "Get-AntiPhishRule",
        "Get-EOPProtectionPolicyRule",
        "Get-AcceptedDomain"
    ],
    "ActualValue": Evaluation,
    "ReportDetails": ImpersonationProtectionReportDetails(Status, ErrorMessage),
    "RequirementMet": ImpersonationProtectionRequirementMet(Status)
} if {
    SensitiveUsers := ListConfigValues("MS.SECURITYSUITE.2.1v1", "SensitiveUsers")
    count(SensitiveUsers) > 0
    Evaluation := UserImpersonationCompliant(SensitiveUsers)
    Status := Evaluation.Compliant
    ErrorMessage := Evaluation.Message
}
#--

#
# MS.SECURITYSUITE.2.2v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.2.2v1",
    "Criticality": "Should",
    "Commandlet": [
        "Get-AntiPhishPolicy",
        "Get-AntiPhishRule",
        "Get-EOPProtectionPolicyRule",
        "Get-AcceptedDomain"
    ],
    "ActualValue": OrganizationDomainProtectionCompliant,
    "ReportDetails": ImpersonationProtectionReportDetails(Status, ErrorMessage),
    "RequirementMet": ImpersonationProtectionRequirementMet(Status)
} if {
    Status := OrganizationDomainProtectionCompliant.Compliant
    ErrorMessage := OrganizationDomainProtectionCompliant.Message
}
#--

#
# MS.SECURITYSUITE.2.3v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.2.3v1",
    "Criticality": "Should",
    "Commandlet": [
        "Get-AntiPhishPolicy",
        "Get-AntiPhishRule",
        "Get-EOPProtectionPolicyRule",
        "Get-AcceptedDomain"
    ],
    "ActualValue": {"PartnerDomains": PartnerDomains},
    "ReportDetails": ImpersonationProtectionReportDetails(false, ErrorMessage),
    "RequirementMet": ImpersonationProtectionRequirementMet(false)
} if {
    PartnerDomains := PartnerDomainConfig("MS.SECURITYSUITE.2.3v1")
    count(PartnerDomains) == 0
    ErrorMessage := "No partner domains defined in the ScubaGear config file."
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.2.3v1",
    "Criticality": "Should",
    "Commandlet": [
        "Get-AntiPhishPolicy",
        "Get-AntiPhishRule",
        "Get-EOPProtectionPolicyRule",
        "Get-AcceptedDomain"
    ],
    "ActualValue": Evaluation,
    "ReportDetails": ImpersonationProtectionReportDetails(Status, ErrorMessage),
    "RequirementMet": ImpersonationProtectionRequirementMet(Status)
} if {
    PartnerDomains := PartnerDomainConfig("MS.SECURITYSUITE.2.3v1")
    count(PartnerDomains) > 0
    Evaluation := PartnerDomainImpersonationCompliant(PartnerDomains)
    Status := Evaluation.Compliant
    ErrorMessage := Evaluation.Message
}
#--

#
# MS.SECURITYSUITE.2.4v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.2.4v1",
    "Criticality": "Should",
    "Commandlet": [
        "Get-AntiPhishPolicy",
        "Get-AntiPhishRule",
        "Get-EOPProtectionPolicyRule",
        "Get-AcceptedDomain"
    ],
    "ActualValue": UserWarningsCompliant,
    "ReportDetails": ImpersonationProtectionReportDetails(Status, ErrorMessage),
    "RequirementMet": ImpersonationProtectionRequirementMet(Status)
} if {
    Status := UserWarningsCompliant.Compliant
    ErrorMessage := UserWarningsCompliant.Message
}
#--

######################
# MS.SECURITYSUITE.3 #
######################

#
# MS.SECURITYSUITE.3.1v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.1v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.3.1v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.3.2v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.2v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.3.2v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.3.3v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.3v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.3.3v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.3.4v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.4v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.3.4v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.3.5v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.5v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.3.5v1"),
    "RequirementMet": false
}
#--


######################
# MS.SECURITYSUITE.4 #
######################

#
# MS.SECURITYSUITE.4.1v1
#--
BaseRequiredAlerts := {
    "Suspicious email sending patterns detected",
    "Suspicious connector activity",
    "Suspicious Email Forwarding Activity",
    "Messages have been delayed",
    "Tenant restricted from sending unprovisioned email",
    "Tenant restricted from sending email",
}
AdditionalRequiredAlerts contains "A potentially malicious URL click was detected" if {
    some alert in input.protection_alerts
    alert.Name == "A potentially malicious URL click was detected"
}
RequiredAlerts := BaseRequiredAlerts | AdditionalRequiredAlerts
EnabledAlerts contains alert.Name if {
    some alert in input.protection_alerts
    alert.Name in RequiredAlerts
    alert.Disabled == false
}
# if there are any missing required alerts, the test fails
tests contains {
    "PolicyId": "MS.SECURITYSUITE.4.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ProtectionAlert"],
    "ActualValue": MissingAlerts,
    "ReportDetails": ReportDetailsString(Status,
        ReportDetailsArray(false, MissingAlerts, ErrorMessage)),
    "RequirementMet": Status
} if {
    MissingAlerts := RequiredAlerts - EnabledAlerts
    ErrorMessage := "disabled required alert(s) found:"
    Status := count(MissingAlerts) == 0
}
#--

#
# MS.SECURITYSUITE.4.2v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.4.2v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.4.2v1"),
    "RequirementMet": false
}
#--


######################
# MS.SECURITYSUITE.5 #
######################

#
# MS.SECURITYSUITE.5.1v1
#--
# Save the identity of audit logs that have logging enabled
CorrectLogConfigs contains {
    "Identity": AuditLog.Identity,
    "UnifiedAuditLogIngestionEnabled": AuditLog.UnifiedAuditLogIngestionEnabled
} if {
    some AuditLog in input.admin_audit_log_config
    AuditLog.UnifiedAuditLogIngestionEnabled == true
}

# The test should pass if at least one log exists
tests contains {
    "PolicyId": "MS.SECURITYSUITE.5.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-AdminAuditLogConfig"],
    "ActualValue": CorrectLogConfigs,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Status := count(CorrectLogConfigs) >= 1
}
#--

#
# MS.SECURITYSUITE.5.2v1
#--
# Retention durations that satisfy the 12 month minimum retention requirement.
# Get-UnifiedAuditLogRetentionPolicy reports duration as one of: SevenDays,
# OneMonth, ThreeMonths, SixMonths, NineMonths, TwelveMonths, ThreeYears,
# FiveYears, SevenYears, TenYears. Anything 12 months or longer is compliant.
CompliantRetentionDurations := {"TwelveMonths", "ThreeYears", "FiveYears", "SevenYears", "TenYears"}

# Note appended to the report details to clarify the license dependency of
# audit log retention in M365.
RetentionLicenseNote := concat(" ", [
    "Note that the data retention policy only applies to users with an Office 365 E5",
    "or Microsoft 365 E5 license or a Microsoft Purview Suite",
    "(formerly known as Microsoft 365 E5 Compliance) or E5 eDiscovery and Audit add-on license."
])

# Service plans that grant the advanced (premium) audit capability required to
# retain audit logs beyond 180 days on a per-user basis. M365_ADVANCED_AUDITING
# is included with Office 365/Microsoft 365 E5, the Microsoft Purview Suite (E5
# Compliance), and the E5 eDiscovery and Audit add-on, but not with E3/G3.
AdvancedAuditingLicenses contains ServicePlan.ServicePlanId if {
    some ServicePlan in input.service_plans
    ServicePlan.ServicePlanName == "M365_ADVANCED_AUDITING"
}

# Save audit log retention policies that retain logs for at least 12 months
# and are not disabled.
CompliantRetentionPolicies contains {
    "Name": Policy.Name,
    "RetentionDuration": Policy.RetentionDuration
} if {
    some Policy in input.unified_audit_log_retention_policies
    Policy.RetentionDuration in CompliantRetentionDurations
    not Policy.Enabled == false
}

# The requirement is met only when the tenant has the per-user license needed to
# retain logs beyond 180 days AND at least one retention policy keeps logs for 12
# months or longer. Tenants at the E3/G3 license level fail regardless of any
# configured retention policy because the retention capability is not licensed.
# Get-MgBetaSubscribedSku is intentionally omitted from the Commandlet list: when
# the license data is unavailable the policy must report non-compliant rather
# than a "command did not execute" dependency error.
default AuditRetentionRequirementMet := false
AuditRetentionRequirementMet if {
    count(AdvancedAuditingLicenses) > 0
    count(CompliantRetentionPolicies) >= 1
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.5.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-UnifiedAuditLogRetentionPolicy"],
    "ActualValue": CompliantRetentionPolicies,
    "ReportDetails": ReportDetailsBooleanWarning(AuditRetentionRequirementMet, RetentionLicenseNote),
    "RequirementMet": AuditRetentionRequirementMet
}
#--


######################
# MS.SECURITYSUITE.6 #
######################

#
# MS.SECURITYSUITE.6.1v1
#--

ActivePresetContentFilterPolicies contains Rule.HostedContentFilterPolicy if {
    some Rule in input.protection_policy_rules
    Rule.State == "Enabled"
    PresetPolicyCoversAllRecipients(Rule.Identity)
}

ActiveCustomContentFilterPolicies contains Rule.HostedContentFilterPolicy if {
    some Rule in input.hosted_content_filter_rules
    Rule.State == "Enabled"
    CustomRuleCoversAllRecipients(Rule)
}

ActiveContentFilterPolicy(Policy) if { Policy.IsDefault == true }

ActiveContentFilterPolicy(Policy) if {
    Policy.RecommendedPolicyType in { "Standard", "Strict" }
    Policy.Identity in ActivePresetContentFilterPolicies
}

ActiveContentFilterPolicy(Policy) if {
    Policy.RecommendedPolicyType == "Custom"
    Policy.IsDefault == false
    Policy.Identity in ActiveCustomContentFilterPolicies
}

AllowedSpamActions := { "MoveToJmf", "Quarantine", "Redirect", "Delete" }

# Per Microsoft's order of precedence for anti-spam policies:
# 1. Strict preset
# 2. Standard preset
# 3. Custom policies
# 4. Default policy
#
# A lower-priority policy's non-compliance is only counted when no
# higher-priority active compliant policy shields it for shared recipients.

# Strict preset is active and has compliant spam action settings
StrictPresetIsCompliantForSpam if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Strict"
    Policy.Identity in ActivePresetContentFilterPolicies
    Actions := {
        Policy.SpamAction,
        Policy.HighConfidenceSpamAction,
        Policy.PhishSpamAction,
        Policy.HighConfidencePhishAction
    }
    Count(Actions - AllowedSpamActions) == 0
}

# Standard preset is active and has compliant spam action settings
StandardPresetIsCompliantForSpam if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Standard"
    Policy.Identity in ActivePresetContentFilterPolicies
    Actions := {
        Policy.SpamAction,
        Policy.HighConfidenceSpamAction,
        Policy.PhishSpamAction,
        Policy.HighConfidencePhishAction
    }
    Count(Actions - AllowedSpamActions) == 0
}

AnyPresetIsCompliantForSpam if { StrictPresetIsCompliantForSpam }
AnyPresetIsCompliantForSpam if { StandardPresetIsCompliantForSpam }

# At least one active custom policy has compliant spam action settings
AnyCustomIsCompliantForSpam if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Custom"
    Policy.IsDefault == false
    Policy.Identity in ActiveCustomContentFilterPolicies
    Actions := {
        Policy.SpamAction,
        Policy.HighConfidenceSpamAction,
        Policy.PhishSpamAction,
        Policy.HighConfidencePhishAction
    }
    Count(Actions - AllowedSpamActions) == 0
}

# Strict preset: always check if active (highest priority, nothing overrides it)
PoliciesWithInboxDelivery contains Policy.Identity if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Strict"
    Policy.Identity in ActivePresetContentFilterPolicies
    Actions := {
        Policy.SpamAction,
        Policy.HighConfidenceSpamAction,
        Policy.PhishSpamAction,
        Policy.HighConfidencePhishAction
    }
    Count(Actions - AllowedSpamActions) > 0
}

# Standard preset: check only when strict preset policy is not active and compliant
PoliciesWithInboxDelivery contains Policy.Identity if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Standard"
    Policy.Identity in ActivePresetContentFilterPolicies
    not StrictPresetIsCompliantForSpam
    Actions := {
        Policy.SpamAction,
        Policy.HighConfidenceSpamAction,
        Policy.PhishSpamAction,
        Policy.HighConfidencePhishAction
    }
    Count(Actions - AllowedSpamActions) > 0
}

# Custom policies: check only when no active compliant preset exists
PoliciesWithInboxDelivery contains Policy.Identity if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Custom"
    Policy.IsDefault == false
    Policy.Identity in ActiveCustomContentFilterPolicies
    not AnyPresetIsCompliantForSpam
    Actions := {
        Policy.SpamAction,
        Policy.HighConfidenceSpamAction,
        Policy.PhishSpamAction,
        Policy.HighConfidencePhishAction
    }
    Count(Actions - AllowedSpamActions) > 0
}

# Default policy: check only when no higher-priority active compliant policy exists
PoliciesWithInboxDelivery contains Policy.Identity if {
    some Policy in input.hosted_content_filter_policies
    Policy.IsDefault == true
    not AnyPresetIsCompliantForSpam
    not AnyCustomIsCompliantForSpam
    Actions := {
        Policy.SpamAction,
        Policy.HighConfidenceSpamAction,
        Policy.PhishSpamAction,
        Policy.HighConfidencePhishAction
    }
    Count(Actions - AllowedSpamActions) > 0
}

ActiveContentFilterPoliciesChecked contains Policy.Identity if {
    some Policy in input.hosted_content_filter_policies
    ActiveContentFilterPolicy(Policy)
}

# Describes the active precedence tier and what was not evaluated
default SpamCascadeStatus := "No active compliant preset or Custom policy. All active policies evaluated"

SpamCascadeStatus := "Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated" if {
    StrictPresetIsCompliantForSpam
}

SpamCascadeStatus := "Standard preset is active and compliant (Strict not active or non-compliant). Custom and Default policies not evaluated" if {
    not StrictPresetIsCompliantForSpam
    StandardPresetIsCompliantForSpam
}

SpamCascadeStatus := "No active compliant preset. Custom policy evaluation applied; Default policy not evaluated" if {
    not StrictPresetIsCompliantForSpam
    not StandardPresetIsCompliantForSpam
    AnyCustomIsCompliantForSpam
}

# On pass, describe which tier is applied and what was not evaluated
ReportDetailsSpamPolicy(true, _, CascadeStatus, _) := concat(" ", [
    "Requirement met.",
    CascadeStatus
])

# On fail, lead with the cascade context, then list which policies failed.
ReportDetailsSpamPolicy(false, FailingPolicies, CascadeStatus, ErrString) := Description([
    concat("", [CascadeStatus, "."]),
    ArraySizeStr(FailingPolicies),
    ErrString,
    concat(", ", FailingPolicies)
])

tests contains {
    "PolicyId": "MS.SECURITYSUITE.6.1v1",
    "Criticality": "Shall",
    "Commandlet": [
        "Get-HostedContentFilterPolicy",
        "Get-HostedContentFilterRule",
        "Get-EOPProtectionPolicyRule"
    ],
    "ActualValue": PoliciesWithInboxDelivery,
    "ReportDetails": ReportDetailsSpamPolicy(
        Status,
        PoliciesWithInboxDelivery,
        SpamCascadeStatus,
        "anti-spam polic(ies) that may deliver spam/phishing to inbox:"
    ),
    "RequirementMet": Status
} if {
    Status := Count(PoliciesWithInboxDelivery) == 0
}
#--

#
# MS.SECURITYSUITE.6.2v1
#--

# Strict preset is active and has no allowed sender domains
StrictPresetIsCompliantForDomains if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Strict"
    Policy.Identity in ActivePresetContentFilterPolicies
    Count(Policy.AllowedSenderDomains) == 0
}

# Standard preset is active and has no allowed sender domains
StandardPresetIsCompliantForDomains if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Standard"
    Policy.Identity in ActivePresetContentFilterPolicies
    Count(Policy.AllowedSenderDomains) == 0
}

AnyPresetIsCompliantForDomains if { StrictPresetIsCompliantForDomains }
AnyPresetIsCompliantForDomains if { StandardPresetIsCompliantForDomains }

# At least one active Custom policy has no allowed sender domains
AnyCustomIsCompliantForDomains if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Custom"
    Policy.IsDefault == false
    Policy.Identity in ActiveCustomContentFilterPolicies
    Count(Policy.AllowedSenderDomains) == 0
}

# Strict preset: always check if active
PoliciesWithAllowedDomains contains Policy.Identity if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Strict"
    Policy.Identity in ActivePresetContentFilterPolicies
    Count(Policy.AllowedSenderDomains) > 0
}

# Standard preset: check only when Strict is not active and compliant
PoliciesWithAllowedDomains contains Policy.Identity if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Standard"
    Policy.Identity in ActivePresetContentFilterPolicies
    not StrictPresetIsCompliantForDomains
    Count(Policy.AllowedSenderDomains) > 0
}

# Custom policies: check only when no active compliant preset exists
PoliciesWithAllowedDomains contains Policy.Identity if {
    some Policy in input.hosted_content_filter_policies
    Policy.RecommendedPolicyType == "Custom"
    Policy.IsDefault == false
    Policy.Identity in ActiveCustomContentFilterPolicies
    not AnyPresetIsCompliantForDomains
    Count(Policy.AllowedSenderDomains) > 0
}

# Default policy: check only when no higher-priority active compliant policy exists
PoliciesWithAllowedDomains contains Policy.Identity if {
    some Policy in input.hosted_content_filter_policies
    Policy.IsDefault == true
    not AnyPresetIsCompliantForDomains
    not AnyCustomIsCompliantForDomains
    Count(Policy.AllowedSenderDomains) > 0
}

default DomainsCascadeStatus := "No active compliant preset or Custom policy. All active policies evaluated"

DomainsCascadeStatus := "Strict preset is active and compliant. Standard preset, Custom, and Default policies not evaluated" if {
    StrictPresetIsCompliantForDomains
}

DomainsCascadeStatus := "Standard preset is active and compliant (Strict not active or non-compliant). Custom and Default policies not evaluated" if {
    not StrictPresetIsCompliantForDomains
    StandardPresetIsCompliantForDomains
}

DomainsCascadeStatus := "No active compliant preset. Custom policy evaluation applied; Default policy not evaluated" if {
    not StrictPresetIsCompliantForDomains
    not StandardPresetIsCompliantForDomains
    AnyCustomIsCompliantForDomains
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.6.2v1",
    "Criticality": "Shall",
    "Commandlet": [
        "Get-HostedContentFilterPolicy",
        "Get-HostedContentFilterRule",
        "Get-EOPProtectionPolicyRule"
    ],
    "ActualValue": PoliciesWithAllowedDomains,
    "ReportDetails": ReportDetailsSpamPolicy(
        Status,
        PoliciesWithAllowedDomains,
        DomainsCascadeStatus,
        "anti-spam polic(ies) with allowed domains:"
    ),
    "RequirementMet": Status
} if {
    Status := Count(PoliciesWithAllowedDomains) == 0
}
#--


######################
# MS.SECURITYSUITE.7 #
######################

#
# MS.SECURITYSUITE.7.1v1
#--

# Highest priority corresponds to the lowest priority number
HighestPriorityEnabledRuleCoversAllRecipients := Rule if {
    some Rule in input.safe_links_rules
    Rule.State == "Enabled"
    RuleFieldEmpty(Rule.SentTo)
    RuleFieldEmpty(Rule.SentToMemberOf)
    RuleFieldEmpty(Rule.RecipientDomainIs)
    not LowerPriorityEnabledRuleExists(Rule)
}

LowerPriorityEnabledRuleExists(Rule) if {
    some OtherRule in input.safe_links_rules
    OtherRule.State == "Enabled"
    RuleFieldEmpty(OtherRule.SentTo)
    RuleFieldEmpty(OtherRule.SentToMemberOf)
    RuleFieldEmpty(OtherRule.RecipientDomainIs)
    OtherRule.Priority < Rule.Priority
}

default AppliedPolicy := "Built-In Protection Policy"
AppliedPolicy := HighestPriorityEnabledRuleCoversAllRecipients.SafeLinksPolicy

default CustomPolicySafeLinksEnabled := false
CustomPolicySafeLinksEnabled if {
    some Policy in input.safe_links_policies
    Policy.Identity == AppliedPolicy
    Policy.EnableSafeLinksForEmail == true
    Policy.EnableSafeLinksForTeams == true
    Policy.EnableSafeLinksForOffice == true
    Policy.EnableForInternalSenders == true
}

default ReportDetails7_1 := "URL comparison with a block-list is NOT enabled for URLs in emails, Teams messages, and Office documents."
ReportDetails7_1 := "URL comparison with a block-list is enabled via the standard or strict preset security policies." if {
    PresetRecipientsCovered
}

ReportDetails7_1 := concat("", ["URL comparison with a block-list is enabled via policy ", AppliedPolicy, "."]) if {
    not PresetRecipientsCovered
    CustomPolicySafeLinksEnabled
}

default SafeLinksCompliant := false
SafeLinksCompliant if {
    ReportDetails7_1 != "URL comparison with a block-list is NOT enabled for URLs in emails, Teams messages, and Office documents."
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.7.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-SafeLinksPolicy", "Get-SafeLinksRule", "Get-EOPProtectionPolicyRule"],
    "ActualValue": {"SafeLinks_Rules": input.safe_links_rules, "SafeLinks_Policies": input.safe_links_policies},
    "ReportDetails": ReportDetails7_1,
    "RequirementMet": SafeLinksCompliant
}
#-- 

#
# MS.SECURITYSUITE.7.2v1
#--

default CustomPolicyScanURLsEnabled := false
CustomPolicyScanURLsEnabled := true if {
    some Policy in input.safe_links_policies
    Policy.Identity == AppliedPolicy
    Policy.ScanUrls == true
    Policy.DeliverMessageAfterScan == true
}

default ReportDetails7_2 := "Direct download links are NOT scanned for malware."
ReportDetails7_2 := "Direct download links are scanned for malware via the standard or strict preset security policies." if {
    PresetRecipientsCovered
}

ReportDetails7_2 := concat("", ["Direct download links are scanned for malware via policy ", AppliedPolicy, "."]) if {
    not PresetRecipientsCovered
    CustomPolicyScanURLsEnabled
}

default ScanURLsCompliant := false
ScanURLsCompliant if {
    ReportDetails7_2 != "Direct download links are NOT scanned for malware."
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.7.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-SafeLinksPolicy", "Get-SafeLinksRule", "Get-EOPProtectionPolicyRule"],
    "ActualValue": {"SafeLinks_Rules": input.safe_links_rules, "SafeLinks_Policies": input.safe_links_policies},
    "ReportDetails": ReportDetails7_2,
    "RequirementMet": ScanURLsCompliant 
}
#--

#
# MS.SECURITYSUITE.7.3v1
#--

default CustomPolicyTrackClicksEnabled := false
CustomPolicyTrackClicksEnabled := true if {
    some Policy in input.safe_links_policies
    Policy.Identity == AppliedPolicy
    Policy.TrackClicks == true
}

default ReportDetails7_3 := "User click tracking is NOT enabled."
ReportDetails7_3 := "User click tracking is enabled via the standard or strict preset security policies." if {
    PresetRecipientsCovered
}

ReportDetails7_3 := concat("", ["User click tracking is enabled via policy ", AppliedPolicy, "."]) if {
    not PresetRecipientsCovered
    CustomPolicyTrackClicksEnabled
}

default TrackClicksCompliant := false
TrackClicksCompliant if {
    ReportDetails7_3 != "User click tracking is NOT enabled."
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.7.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-SafeLinksPolicy", "Get-SafeLinksRule", "Get-EOPProtectionPolicyRule"],
    "ActualValue": {"SafeLinks_Rules": input.safe_links_rules, "SafeLinks_Policies": input.safe_links_policies},
    "ReportDetails": ReportDetails7_3,
    "RequirementMet": TrackClicksCompliant
}

#--


######################
# MS.SECURITYSUITE.8 #
######################

#
# MS.SECURITYSUITE.8.1v1
#--

# Loop thorugh connection filter. If filter has an IP allow
# list, save the filter name to ConnFiltersWithIPAllowList array.
ConnFiltersWithIPAllowList contains ConnFilter.Name if {
    some ConnFilter in input.conn_filter
    count(ConnFilter.IPAllowList) > 0
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.8.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-HostedConnectionFilterPolicy"],
    "ActualValue": input.conn_filter,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    ErrString := "connection filter polic(ies) with an IP allowlist:"
    ErrMessage := Description([ArraySizeStr(ConnFiltersWithIPAllowList), ErrString , concat(", ", ConnFiltersWithIPAllowList)])
    Status := count(ConnFiltersWithIPAllowList) == 0
}
#--

#
# MS.SECURITYSUITE.8.2v1
#--

# Loop thorugh connection filter. If filter has safe
# list enabled, save filter name to ConnFiltersWithSafeList
# array.
ConnFiltersWithSafeList contains ConnFilter.Name if {
    some ConnFilter in input.conn_filter
    ConnFilter.EnableSafeList == true
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.8.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-HostedConnectionFilterPolicy"],
    "ActualValue": input.conn_filter,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    ErrString := "connection filter polic(ies) with a safe list:"
    ErrMessage := Description([ArraySizeStr(ConnFiltersWithSafeList), ErrString , concat(", ", ConnFiltersWithSafeList)])
    Status := count(ConnFiltersWithSafeList) == 0
}
#--
