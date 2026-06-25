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
# Retention durations that satisfy the 12 month minimum retention requirement.
CompliantRetentionDurations := {"TwelveMonths", "TenYears"}

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
default AuditRetentionRequirementMet := false
AuditRetentionRequirementMet if {
    count(AdvancedAuditingLicenses) > 0
    count(CompliantRetentionPolicies) >= 1
}

tests contains {
    "PolicyId": "MS.SECURITYSUITE.5.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-UnifiedAuditLogRetentionPolicy", "Get-MgBetaSubscribedSku"],
    "ActualValue": CompliantRetentionPolicies,
    "ReportDetails": ReportDetailsBooleanWarning(Status, RetentionLicenseNote),
    "RequirementMet": Status
} if {
    Status := AuditRetentionRequirementMet
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
