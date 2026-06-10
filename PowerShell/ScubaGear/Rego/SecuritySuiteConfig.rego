# NOTE: This file (package securitysuite) is NOT evaluated at runtime.
# The Orchestrator maps the 'securitysuite' product to BaselineName "Defender",
# which resolves to DefenderConfig.rego (package defender) for both OPA evaluation
# and report generation. This file is retained as a scaffold for future use if
# the securitysuite product is ever decoupled from the defender baseline.
# See Orchestrator.psm1: ArgToProd mapping (securitysuite = "Defender") and
# RegoPackageName override ($Product -eq "securitysuite" => "defender").
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
import data.utils.securitysuite.PresetPolicyCoversAllRecipients
import data.utils.securitysuite.CustomRuleCoversAllRecipients
import data.utils.report.ReportDetailsArray
import data.utils.key.Count


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
tests contains {
    "PolicyId": "MS.SECURITYSUITE.7.1v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.7.1v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.7.2v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.7.2v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.7.2v1"),
    "RequirementMet": false
}
#--

#
# MS.SECURITYSUITE.7.3v1
#--
tests contains {
    "PolicyId": "MS.SECURITYSUITE.7.3v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.SECURITYSUITE.7.3v1"),
    "RequirementMet": false
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
