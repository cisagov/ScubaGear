package securitysuite
import rego.v1
import data.utils.report.NotCheckedDetails
import data.utils.report.ArraySizeStr
import data.utils.report.Description
import data.utils.report.ReportDetailsString
import data.utils.report.ReportDetailsBoolean
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
import data.utils.report.ReportDetailsArray


######################
# MS.SECURITYSUITE.1 #
######################

#
# MS.SECURITYSUITE.1.1v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.1.1v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.1.1v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.1.2v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.1.2v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.1.2v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.1.3v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.1.3v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.1.3v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.1.4v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.1.4v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.1.4v1"),
    "RequirementMet": false
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
tests contains {
    "PolicyId": "MS.SECURITYSUITE.5.2v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.5.2v1"),
    "RequirementMet": false
}
#--


######################
# MS.SECURITYSUITE.6 #
######################

#
# MS.SECURITYSUITE.6.1v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.6.1v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.6.1v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.6.2v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.6.2v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.6.2v1"),
    "RequirementMet": false
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
