package defender
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.ReportDetailsBoolean
import data.defender.utils.SensitiveAccounts
import data.defender.utils.SensitiveAccountsConfig
import data.defender.utils.SensitiveAccountsSetting
import data.defender.utils.ImpersonationProtection
import data.defender.utils.ImpersonationProtectionConfig

# Example usage and output:
# GenerateArrayString([1,2], "numbers found:") ->
# 2 numbers found: 1, 2
GenerateArrayString(Array, CustomString) := Output if {
    Length := format_int(count(Array), 10)
    ArrayString := concat(", ", Array)
    Output := trim(concat(" ", [Length, concat(" ", [CustomString, ArrayString])]), " ")
}

CustomizeError(true, _) := ReportDetailsBoolean(true) if {}

CustomizeError(false, CustomString) := CustomString if {}

# If a defender license is present, don't apply the warning
# and leave the message unchanged
ApplyLicenseWarning(Status) := ReportDetailsBoolean(Status) if {
    input.defender_license == true
}

# If a defender license is not present, assume failure and
# replace the message with the warning
ApplyLicenseWarning(_) := concat("", [ReportDetailsBoolean(false), LicenseWarning]) if {
    input.defender_license == false
    LicenseWarning := " **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# MS.DEFENDER.1.1v1
#--

ReportDetails1_1(true, true) := ReportDetailsBoolean(true) if {}

ReportDetails1_1(false, true) := "Standard preset policy is disabled" if {}

ReportDetails1_1(true, false) := "Strict preset policy is disabled" if {}

ReportDetails1_1(false, false) := "Standard and Strict preset policies are both disabled" if {}

GetEnabledPolicies(Policies, Identity) := count([Policy |
    some Policy in Policies
    Policy.Identity == Identity
    Policy.State == "Enabled"
]) > 0

# For this one you need to check both:
# - Get-EOPProtectionPolicyRule
# - Get-ATPProtectionPolicyRule
#
# This is because there isn't an easy way to check if the toggle is on
# the main "Preset security policies" page is or set not. It is
# entirely possible for the standard/strict policies to be enabled
# but for one of the above commands to not reflect it.
#
# For example, if we enable the standard policy but only add users to
# Exchange online protection, Get-EOPProtectionPolicyRule will report
# the standard policy as enabled, but the standard policy won't even
# be included in the output of Get-ATPProtectionPolicyRule, and vice
# versa.
#
# TLDR: If at least one of the commandlets reports the policy as
# enabled, then the policy is enabled; if the policy is missing in
# the output of one, you need to check the other before you can
# conclude that it is disabled.
tests contains {
    "PolicyId": "MS.DEFENDER.1.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-EOPProtectionPolicyRule", "Get-ATPProtectionPolicyRule"],
    "ActualValue": {"StandardPresetState": IsStandardEnabled, "StrictPresetState": IsStrictEnabled},
    "ReportDetails": ReportDetails1_1(IsStandardEnabled, IsStrictEnabled),
    "RequirementMet": Status
} if {
    EOPPolicies := input.protection_policy_rules
    IsStandardEOPEnabled := GetEnabledPolicies(EOPPolicies, "Standard Preset Security Policy")
    IsStrictEOPEnabled := GetEnabledPolicies(EOPPolicies, "Strict Preset Security Policy")

    ATPPolicies := input.atp_policy_rules
    IsStandardATPEnabled := GetEnabledPolicies(ATPPolicies, "Standard Preset Security Policy")
    IsStrictATPEnabled := GetEnabledPolicies(ATPPolicies, "Strict Preset Security Policy")

    StandardConditions := [IsStandardEOPEnabled, IsStandardATPEnabled]
    IsStandardEnabled := count([Condition | some Condition in StandardConditions; Condition == true]) > 0

    StrictConditions := [IsStrictEOPEnabled, IsStrictATPEnabled]
    IsStrictEnabled := count([Condition | some Condition in StrictConditions; Condition == true]) > 0

    Conditions := [IsStandardEnabled, IsStrictEnabled]
    Status := count([Condition | some Condition in Conditions; Condition == false]) == 0
}

#--

#
# MS.DEFENDER.1.2v1
#--

# TODO check exclusions
AllRecipient(Policies, Identity) := count([Policy |
    some Policy in Policies
    Policy.Identity == Identity
    Policy.SentTo == null
    Policy.SentToMemberOf == null
    Policy.RecipientDomainIs == null
]) > 0

# If "Apply protection to" is set to "All recipients":
# - The policy will be included in the list output by
#   Get-EOPProtectionPolicyRule"
# - SentTo, SentToMemberOf, and RecipientDomainIs will all be
#   null.
#
# If "Apply protection to" is set to "None," the policy will be
# missing entirely.
#
# If "Apply protection to" is set to "Specific recipients," at
# least one of SentTo, SentToMemberOf, or RecipientDomainIs will
# not be null.
#
# In short, we need to assert that at least one of the preset
# policies is included in the output and has those three fields
# set to null.
tests contains {
    "PolicyId": "MS.DEFENDER.1.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-EOPProtectionPolicyRule"],
    "ActualValue": {"StandardSetToAll": IsStandardAll, "StrictSetToAll": IsStrictAll},
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Policies := input.protection_policy_rules
    IsStandardAll := AllRecipient(Policies, "Standard Preset Security Policy")
    IsStrictAll := AllRecipient(Policies, "Strict Preset Security Policy")
    Conditions := [IsStandardAll, IsStrictAll]
    Status := count([Condition | some Condition in Conditions; Condition == true]) > 0
}

#--

#
# MS.DEFENDER.1.3v1
#--

# TODO check exclusions

tests contains {
    "PolicyId": "MS.DEFENDER.1.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ATPProtectionPolicyRule"],
    "ActualValue": {"StandardSetToAll": IsStandardAll, "StrictSetToAll": IsStrictAll},
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    # See MS.DEFENDER.1.2v1, the same logic applies, just with a
    # different commandlet.

    Policies := input.atp_policy_rules
    IsStandardAll := AllRecipient(Policies, "Standard Preset Security Policy")
    IsStrictAll := AllRecipient(Policies, "Strict Preset Security Policy")
    Conditions := [IsStandardAll, IsStrictAll]
    Status := count([Condition | some Condition in Conditions; Condition == true]) > 0
}

#--

#
# MS.DEFENDER.1.4v1
#--

ProtectionPolicyForSensitiveIDs contains Policies if {
    Policies := input.protection_policy_rules
    AccountsSetting := SensitiveAccountsSetting(Policies)
    AccountsConfig := SensitiveAccountsConfig("MS.DEFENDER.1.4v1")

    SensitiveAccounts(AccountsSetting, AccountsConfig) == true
}

tests contains {
    "PolicyId": "MS.DEFENDER.1.4v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-EOPProtectionPolicyRule"],
    "ActualValue": {"EOPProtectionPolicies": Status},
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Status := count(ProtectionPolicyForSensitiveIDs) == 1
}

#--

#
# MS.DEFENDER.1.5v1
#--

ATPPolicyForSensitiveIDs contains Policies if {
    Policies := input.atp_policy_rules
    AccountsSetting := SensitiveAccountsSetting(Policies)
    AccountsConfig := SensitiveAccountsConfig("MS.DEFENDER.1.5v1")

    SensitiveAccounts(AccountsSetting, AccountsConfig) == true
}

tests contains {
    "PolicyId": "MS.DEFENDER.1.5v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ATPProtectionPolicyRule"],
    "ActualValue": {"ATPProtectionPolicies": Status},
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    Status := count(ATPPolicyForSensitiveIDs) == 1
}

#--

#
# MS.DEFENDER.2.1v1
#--

ImpersonationProtectionErrorMsg(false, true, AccountType) := Description if {
    String := concat(" ", ["Not all", AccountType])
    Description := concat(" ", [String, "are included for targeted protection in Strict policy."])
}

ImpersonationProtectionErrorMsg(true, false, AccountType) := Description if {
    String := concat(" ", ["Not all", AccountType])
    Description := concat(" ", [String, "are included for targeted protection in Standard policy."])
}

ImpersonationProtectionErrorMsg(false, false, AccountType) := Description if {
    String := concat(" ", ["Not all", AccountType])
    Description := concat(" ", [String, "are included for targeted protection in Strict or Standard policy."])
}

ImpersonationProtectionErrorMsg(true, true, "agency domains") := "No agency domains defined for impersonation protection assessment. See configuration file documentation for details on how to define."

ImpersonationProtectionErrorMsg(true, true, AccountType) := "" if {
    AccountType != "agency domains"
}

tests contains {
    "PolicyId": "MS.DEFENDER.2.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-AntiPhishPolicy"],
    "ActualValue": [StrictIP.Policy, StandardIP.Policy],
    "ReportDetails": CustomizeError(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    Policies := input.anti_phish_policies
    FilterKey := "EnableTargetedUserProtection"
    AccountKey := "TargetedUsersToProtect"
    ActionKey := "TargetedUserProtectionAction"
    ProtectedConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.1v1", "SensitiveUsers")
    StrictIP := ImpersonationProtection(Policies, "Strict Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    StandardIP := ImpersonationProtection(Policies, "Standard Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictIP.Result, StandardIP.Result, "sensitive users")
    Conditions := [
        StrictIP.Result == true,
        StandardIP.Result == true
    ]
    Status := count([x | some x in Conditions; x == false]) == 0
}

#--

#
# MS.DEFENDER.2.2v1
#--

# Assert that at least one of the enabled policies includes
# protection for the org's own domains
tests contains {
    "PolicyId": "MS.DEFENDER.2.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-AntiPhishPolicy"],
    "ActualValue": [StrictIP.Policy, StandardIP.Policy],
    "ReportDetails": CustomizeError(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    Policies := input.anti_phish_policies
    FilterKey := "EnableTargetedDomainsProtection"
    AccountKey := "TargetedDomainsToProtect"
    ActionKey := "TargetedDomainProtectionAction"
    ProtectedConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.2v1", "AgencyDomains")
    StrictIP := ImpersonationProtection(Policies, "Strict Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    StandardIP := ImpersonationProtection(Policies, "Standard Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictIP.Result, StandardIP.Result, "agency domains")
    Conditions := [
        StrictIP.Result == true,
        StandardIP.Result == true,
        count(ProtectedConfig) > 0
    ]
    Status := count([x | some x in Conditions; x == false]) == 0
}

#--

#
# MS.DEFENDER.2.3v1
#--
tests contains {
    "PolicyId": "MS.DEFENDER.2.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-AntiPhishPolicy"],
    "ActualValue": [StrictIP.Policy, StandardIP.Policy],
    "ReportDetails": CustomizeError(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    Policies := input.anti_phish_policies
    FilterKey := "EnableTargetedDomainsProtection"
    AccountKey := "TargetedDomainsToProtect"
    ActionKey := "TargetedDomainProtectionAction"
    ProtectedConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.3v1", "PartnerDomains")
    StrictIP := ImpersonationProtection(Policies, "Strict Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    StandardIP := ImpersonationProtection(Policies, "Standard Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictIP.Result, StandardIP.Result, "partner domains")
    Conditions := [
        StrictIP.Result == true,
        StandardIP.Result == true
    ]
    Status := count([x | some x in Conditions; x == false]) == 0
}

#--

#
# MS.DEFENDER.3.1v1
#--

# Find the set of policies that have EnableATPForSPOTeamsODB set to true
ATPPolicies contains {
    "Identity": Policy.Identity,
    "EnableATPForSPOTeamsODB": Policy.EnableATPForSPOTeamsODB
} if {
    some Policy in input.atp_policy_for_o365
    Policy.EnableATPForSPOTeamsODB == true
}

tests contains {
    "PolicyId": "MS.DEFENDER.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-AtpPolicyForO365"],
    "ActualValue": Policies,
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    Policies := ATPPolicies
    Status := count(Policies) > 0
}

#--

#
# MS.DEFENDER.4.1v1
#--
SensitiveContent := [
    "U.S. Social Security Number (SSN)",
    "U.S. Individual Taxpayer Identification Number (ITIN)",
    "Credit Card Number"
]

# Return set of content info types in basic rules
InfoTypeMatches(Rule) := ContentTypes if {
    Rule.IsAdvancedRule == false
    ContentTypes := {Content.name | some Content in Rule.ContentContainsSensitiveInformation}
}

# Return set of content info types in advanced rules
InfoTypeMatches(Rule) := ContentTypes if {
    Rule.IsAdvancedRule == true
    RuleText := replace(replace(Rule.AdvancedRule, "rn", ""), "'", "\"")

    # Split string to keep line length intact
    TypesRegex := concat("", [
        `(U.S. Social Security Number \(SSN\))|`,
        `(U.S. Individual Taxpayer Identification `,
        `Number \(ITIN\))|`,
        `(Credit Card Number)`
    ])
    ContentTypes := {Name | some Name in regex.find_n(TypesRegex, RuleText, -1)}
}

# Determine the set of rules that pertain to SSNs, ITINs, or credit card numbers.
# Used in multiple bullet points below
SensitiveRules contains {
    "Name": Rules.Name,
    "ParentPolicyName": Rules.ParentPolicyName,
    "BlockAccess": Rules.BlockAccess,
    "BlockAccessScope": Rules.BlockAccessScope,
    "NotifyUser": Rules.NotifyUser,
    "NotifyUserType": Rules.NotifyUserType,
    "ContentNames": ContentNames
} if {
    some Rules in input.dlp_compliance_rules
    Rules.Disabled == false
    ContentNames := InfoTypeMatches(Rules)
    count(ContentNames) > 0

    some Policy in input.dlp_compliance_policies
    Rules.ParentPolicyName == Policy.Name
    Policy.Enabled == true
    Policy.Mode == "Enable"
}

PoliciesWithFullProtection := [X | some X in SensitiveRules; count({X | some X in SensitiveContent} - X.ContentNames) == 0]

Rules := {
    "SSN": [Rule.Name | some Rule in SensitiveRules; SensitiveContent[0] in Rule.ContentNames],
    "ITIN": [Rule.Name | some Rule in SensitiveRules; SensitiveContent[1] in Rule.ContentNames],
    "Credit_Card": [Rule.Name | some Rule in SensitiveRules; SensitiveContent[2] in Rule.ContentNames]
}

error_rules contains SensitiveContent[0] if count(Rules.SSN) == 0

error_rules contains SensitiveContent[1] if count(Rules.ITIN) == 0

error_rules contains SensitiveContent[2] if count(Rules.Credit_Card) == 0

tests contains {
    "PolicyId": "MS.DEFENDER.4.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-DlpComplianceRule"],
    "ActualValue": Rules,
    "ReportDetails": CustomizeError(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    error_rule := "No matching rules found for:"
    ErrorMessage := concat(" ", [error_rule, concat(", ", error_rules)])

    Status := count(error_rules) == 0
}

#
# MS.DEFENDER.4.2v1
#--
# Step 2: determine the set of sensitive policies that apply to EXO, Teams, etc.
ProductEnableSensitiveProtection(Name, Location) := {
    "Name": Policy.Name,
    "Locations": Policy[Location],
    "Workload": Policy.Workload
} if {
    some Policy in input.dlp_compliance_policies
    some PolicyWithProtection in PoliciesWithFullProtection
    Policy.Name in PolicyWithProtection
    "All" in Policy[Location]
    contains(Policy.Workload, Name)
} else := set()

Policies := {
    "Exchange": ProductEnableSensitiveProtection("Exchange", "ExchangeLocation"),
    "SharePoint": ProductEnableSensitiveProtection("SharePoint", "SharePointLocation"),
    "OneDrive": ProductEnableSensitiveProtection("OneDriveForBusiness", "OneDriveLocation"),
    "Teams": ProductEnableSensitiveProtection("Teams", "TeamsLocation"),
    "Devices": ProductEnableSensitiveProtection("EndpointDevices", "EndpointDlpLocation"),
}

error_policies contains "Exchange" if count(Policies.Exchange) == 0

error_policies contains "SharePoint" if count(Policies.SharePoint) == 0

error_policies contains "OneDrive" if count(Policies.OneDrive) == 0

error_policies contains "Teams" if count(Policies.Teams) == 0

error_policies contains "Devices" if count(Policies.Devices) == 0

DefenderErrorMessage4_2 := ErrorMessage if {
    count(PoliciesWithFullProtection) > 0
    error_policy := "No enabled policy found that applies to:"
    ErrorMessage := concat(" ", [error_policy, concat(", ", error_policies)])
}

DefenderErrorMessage4_2 := ErrorMessage if {
    count(PoliciesWithFullProtection) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

tests contains {
    "PolicyId": "MS.DEFENDER.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DLPCompliancePolicy"],
    "ActualValue": Policies,
    "ReportDetails": CustomizeError(Status, DefenderErrorMessage4_2),
    "RequirementMet": Status
} if {
    Conditions := [
        count(error_policies) == 0,
        count(PoliciesWithFullProtection) > 0,
    ]
    Status := count([Condition | some Condition in Conditions; Condition == true]) == 2
}

#
# MS.DEFENDER.4.3v1
#--
# Step 3: Ensure that the action for the rules is set to block
SensitiveRulesNotBlocking contains Rule.Name if {
    some Rule in PoliciesWithFullProtection
    Rule.BlockAccess == false
    Rule.ParentPolicyName in Rule
}

SensitiveRulesNotBlocking contains Rule.Name if {
    some Rule in PoliciesWithFullProtection
    Rule.BlockAccess == true
    Rule.ParentPolicyName in Rule
    Rule.BlockAccessScope != "All"
}

DefenderErrorMessage4_3(Rules) := GenerateArrayString(Rules, ErrorMessage) if {
    count(PoliciesWithFullProtection) > 0
    ErrorMessage := "rule(s) found that do(es) not block access or associated policy not set to enforce block action:"
}

DefenderErrorMessage4_3(_) := ErrorMessage if {
    count(PoliciesWithFullProtection) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

tests contains {
    "PolicyId": "MS.DEFENDER.4.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpComplianceRule"],
    "ActualValue": Rules,
    "ReportDetails": CustomizeError(Status, DefenderErrorMessage4_3(Rules)),
    "RequirementMet": Status
} if {
    Rules := SensitiveRulesNotBlocking
    Conditions := [
        count(Rules) == 0,
        count(PoliciesWithFullProtection) > 0,
    ]
    Status := count([Condition | some Condition in Conditions; Condition == true]) == 2
}

#--

#
# MS.DEFENDER.4.4v1
#--
# Step 4: ensure that some user is notified in the event of a DLP violation
SensitiveRulesNotNotifying contains Rule.Name if {
    some Rule in PoliciesWithFullProtection
    count(SensitiveRules) > 0
    Rule.ParentPolicyName in Rule
    count(Rule.NotifyUser) == 0
}

DefenderErrorMessage4_4(Rules) := GenerateArrayString(Rules, ErrorMessage) if {
    count(PoliciesWithFullProtection) > 0
    ErrorMessage := "rule(s) found that do(es) not notify at least one user:"
}

DefenderErrorMessage4_4(_) := ErrorMessage if {
    count(PoliciesWithFullProtection) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

tests contains {
    "PolicyId": "MS.DEFENDER.4.4v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpComplianceRule"],
    "ActualValue": Rules,
    "ReportDetails": CustomizeError(Status, DefenderErrorMessage4_4(Rules)),
    "RequirementMet": Status
} if {
    Rules := SensitiveRulesNotNotifying
    Conditions := [
        count(Rules) == 0,
        count(PoliciesWithFullProtection) > 0,
    ]
    Status := count([Condition | some Condition in Conditions; Condition == true]) == 2
}

#--

#
# MS.DEFENDER.4.5v1
#--
# At this time we are unable to test for X because of Y
tests contains {
    "PolicyId": "MS.DEFENDER.4.5v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.DEFENDER.4.5v1"),
    "RequirementMet": false
}

#--

#
# MS.DEFENDER.4.6v1
#--
# At this time we are unable to test for X because of Y
tests contains {
    "PolicyId": "MS.DEFENDER.4.6v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.DEFENDER.4.6v1"),
    "RequirementMet": false
}

#--

#
# MS.DEFENDER.5.1v1
#--
# At a minimum, the alerts required by the EXO baseline SHALL be enabled.
RequiredAlerts := {
    "Suspicious email sending patterns detected",
    "Suspicious Email Forwarding Activity",
    "Messages have been delayed",
    "Tenant restricted from sending unprovisioned email",
    "User restricted from sending email",
    "A potentially malicious URL click was detected",
    "Suspicious connector activity"
}

EnabledAlerts contains Alert.Name if {
    some Alert in input.protection_alerts
    Alert.Disabled == false
}

tests contains {
    "PolicyId": "MS.DEFENDER.5.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ProtectionAlert"],
    "ActualValue": MissingAlerts,
    "ReportDetails": CustomizeError(Status, GenerateArrayString(MissingAlerts, ErrorMessage)),
    "RequirementMet": Status
} if {
    MissingAlerts := RequiredAlerts - EnabledAlerts
    ErrorMessage := "disabled required alert(s) found:"
    Status := count(MissingAlerts) == 0
}

#--

#
# MS.DEFENDER.5.2v1
#--
# SIEM incorporation cannot be checked programmatically
tests contains {
    "PolicyId": "MS.DEFENDER.5.2v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.DEFENDER.5.2v1"),
    "RequirementMet": false
}

#--

#
# MS.DEFENDER.6.1v1
#--

CorrectLogConfigs contains {
    "Identity": AuditLog.Identity,
    "UnifiedAuditLogIngestionEnabled": AuditLog.UnifiedAuditLogIngestionEnabled,
} if {
    some AuditLog in input.admin_audit_log_config
    AuditLog.UnifiedAuditLogIngestionEnabled == true
}

tests contains {
    "PolicyId": "MS.DEFENDER.6.1v1",
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
# MS.DEFENDER.6.2v1
#--
# Turns out audit logging is non-trivial to implement and test for.
# Would require looping through all users. See discussion in GitHub
# issue #200.
tests contains {
    "PolicyId": "MS.DEFENDER.6.2v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.DEFENDER.6.2v1"),
    "RequirementMet": false
}

#--

#
# MS.DEFENDER.6.3v1
#--
# Dictated by OMB M-21-31: 12 months in hot storage and 18 months in cold
# It is not required to maintain these logs in the M365 cloud environment;
# doing so would require an additional add-on SKU.
# This requirement can be met by offloading the logs out of the cloud environment.
tests contains {
    "PolicyId": "MS.DEFENDER.6.3v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.DEFENDER.6.3v1"),
    "RequirementMet": false
}

#--
