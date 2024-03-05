package defender
import rego.v1
import data.utils.report.NotCheckedDetails
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsString
import data.utils.report.ReportDetailsArray
import data.utils.key.PASS
import data.utils.key.FilterArray
import data.utils.defender.SensitiveAccounts
import data.utils.defender.SensitiveAccountsConfig
import data.utils.defender.SensitiveAccountsSetting
import data.utils.defender.ImpersonationProtection
import data.utils.defender.ImpersonationProtectionConfig
import data.utils.defender.ApplyLicenseWarning


#################
# MS.DEFENDER.1 #
#################

#
# MS.DEFENDER.1.1v1
#--

# Return string based on boolean result of Standard & Strict conditions
ReportDetails1_1(true, true) := PASS

ReportDetails1_1(false, true) := "Standard preset policy is disabled"

ReportDetails1_1(true, false) := "Strict preset policy is disabled"

ReportDetails1_1(false, false) := "Standard and Strict preset policies are both disabled"

# Parse through all items in Policies, if item identity is the one
# we want & state is enabled, save item. Return number of items saved.
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
    "ActualValue": {"StandardPresetState": Conditions[0], "StrictPresetState": Conditions[1]},
    "ReportDetails": ReportDetails1_1(Conditions[0], Conditions[1]),
    "RequirementMet": Status
} if {
    EOPPolicies := input.protection_policy_rules
    ATPPolicies := input.atp_policy_rules

    StandardConditions := [
        GetEnabledPolicies(EOPPolicies, "Standard Preset Security Policy"),
        GetEnabledPolicies(ATPPolicies, "Standard Preset Security Policy")
    ]

    StrictConditions := [
        GetEnabledPolicies(EOPPolicies, "Strict Preset Security Policy"),
        GetEnabledPolicies(ATPPolicies, "Strict Preset Security Policy")
    ]

    Conditions := [
        count(FilterArray(StandardConditions, true)) > 0,
        count(FilterArray(StrictConditions, true)) > 0
    ]

    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.DEFENDER.1.2v1
#--

# TODO check exclusions
# Parse through all items in Policies, if item identity is the one
# we want & Users (SentTo) + Groups (SentToMemberOf) + Domains (RecipientDomainIs) are null,
# save item. Return number of items saved.
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
    "ActualValue": {"StandardSetToAll": Conditions[0], "StrictSetToAll": Conditions[1]},
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Policies := input.protection_policy_rules
    Conditions := [
        AllRecipient(Policies, "Standard Preset Security Policy"),
        AllRecipient(Policies, "Strict Preset Security Policy")
    ]
    Status := count(FilterArray(Conditions, true)) > 0
}
#--

#
# MS.DEFENDER.1.3v1
#--

# TODO check exclusions
# See MS.DEFENDER.1.2v1, the same logic applies, just with a
# different commandlet.
tests contains {
    "PolicyId": "MS.DEFENDER.1.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ATPProtectionPolicyRule"],
    "ActualValue": {"StandardSetToAll": Conditions[0], "StrictSetToAll": Conditions[1]},
    "ReportDetails": ApplyLicenseWarning(Status),
    "RequirementMet": Status
} if {
    Policies := input.atp_policy_rules
    Conditions := [
        AllRecipient(Policies, "Standard Preset Security Policy"),
        AllRecipient(Policies, "Strict Preset Security Policy")
    ]
    Status := count(FilterArray(Conditions, true)) > 0
}
#--

#
# MS.DEFENDER.1.4v1
#--

# Calls function in util file to find policies that protect
# sensitive accounts.
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

# Calls function in util file to find policies that protect
# sensitive accounts.
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


#################
# MS.DEFENDER.2 #
#################

#
# MS.DEFENDER.2.1v1
#--

# General report details function for impersonation protection
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

ImpersonationProtectionErrorMsg(true, true, "agency domains") := concat(" ", [
    "No agency domains defined for impersonation protection assessment.",
    "See configuration file documentation for details on how to define."
])

ImpersonationProtectionErrorMsg(true, true, AccountType) := "" if {
    AccountType != "agency domains"
}

# Calls function in util file to check if impersonation
# protection is active for strict & standard policies.
tests contains {
    "PolicyId": "MS.DEFENDER.2.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-AntiPhishPolicy"],
    "ActualValue": [StrictIP.Policy, StandardIP.Policy],
    "ReportDetails": ReportDetailsString(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    Policies := input.anti_phish_policies
    FilterKey := "EnableTargetedUserProtection"
    AccountKey := "TargetedUsersToProtect"
    ActionKey := "TargetedUserProtectionAction"
    ProtectedConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.1v1", "SensitiveUsers")
    StrictIP := ImpersonationProtection(
        Policies, "Strict Preset Security Policy",
        ProtectedConfig, FilterKey, AccountKey, ActionKey
    )
    StandardIP := ImpersonationProtection(
        Policies, "Standard Preset Security Policy",
        ProtectedConfig, FilterKey, AccountKey, ActionKey
    )
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictIP.Result, StandardIP.Result, "sensitive users")
    Status := count(FilterArray([StrictIP.Result == true, StandardIP.Result == true], false)) == 0
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
    "ReportDetails": ReportDetailsString(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    Policies := input.anti_phish_policies
    FilterKey := "EnableTargetedDomainsProtection"
    AccountKey := "TargetedDomainsToProtect"
    ActionKey := "TargetedDomainProtectionAction"
    ProtectedConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.2v1", "AgencyDomains")
    StrictIP := ImpersonationProtection(
        Policies, "Strict Preset Security Policy",
        ProtectedConfig, FilterKey, AccountKey, ActionKey
    )
    StandardIP := ImpersonationProtection(
        Policies, "Standard Preset Security Policy",
        ProtectedConfig, FilterKey, AccountKey, ActionKey
    )
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictIP.Result, StandardIP.Result, "agency domains")
    Conditions := [
        StrictIP.Result == true,
        StandardIP.Result == true,
        count(ProtectedConfig) > 0
    ]
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.DEFENDER.2.3v1
#--

# Calls function in util file to check if impersonation
# protection is active for strict & standard policies.
tests contains {
    "PolicyId": "MS.DEFENDER.2.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-AntiPhishPolicy"],
    "ActualValue": [StrictIP.Policy, StandardIP.Policy],
    "ReportDetails": ReportDetailsString(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    Policies := input.anti_phish_policies
    FilterKey := "EnableTargetedDomainsProtection"
    AccountKey := "TargetedDomainsToProtect"
    ActionKey := "TargetedDomainProtectionAction"
    ProtectedConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.3v1", "PartnerDomains")
    StrictIP := ImpersonationProtection(
        Policies, "Strict Preset Security Policy",
        ProtectedConfig, FilterKey, AccountKey, ActionKey
    )
    StandardIP := ImpersonationProtection(
        Policies, "Standard Preset Security Policy",
        ProtectedConfig, FilterKey, AccountKey, ActionKey
    )
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictIP.Result, StandardIP.Result, "partner domains")
    Status := count(FilterArray([StrictIP.Result == true, StandardIP.Result == true], false)) == 0
}
#--


#################
# MS.DEFENDER.3 #
#################

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

# Pass if at least one policy exists
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


#################
# MS.DEFENDER.4 #
#################

#
# MS.DEFENDER.4.1v1
#--
SensitiveContent := [
    "U.S. Social Security Number (SSN)",
    "U.S. Individual Taxpayer Identification Number (ITIN)",
    "Credit Card Number"
]

# Return set of content info types in basic rules
# Advanced rule must be set to false
# Parse through array & save the name (e.x. "Credit Card Number")
# Return all saved names in basic rules
InfoTypeMatches(Rule) := ContentTypes if {
    Rule.IsAdvancedRule == false
    ContentTypes := {Content.name | some Content in Rule.ContentContainsSensitiveInformation}
}

# Return set of content info types in advanced rules
# Advanced rule must be set to true
# Use replace function to remove "rn" & replace ' with "
# Use concat to make the regex expression as a raw string
# Search Advanced rule that has had chars replaced in for
# sensitive content & save the names that are found
# Return all saved names
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
# If policy is not disabled, grab the content names (e.x. "Credit Card Number")
# Find the parent policy & if parent policy is enabled, save.
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

# For each item in SensitiveRules, check if all contents in
# SensitiveContent is protected. For example, a rule may have
# 3 contents it is protecting but missing the protection for
# credit cards so it would fail & not be saved in PoliciesWithFullProtection.
# Each policy that protects SSN, ITIN, & credit cards is saved in
# PoliciesWithFullProtection.
PoliciesWithFullProtection := [
    SensitiveRule | some SensitiveRule in SensitiveRules;
    count({Item | some Item in SensitiveContent} - SensitiveRule.ContentNames) == 0
]

# Save the rules that protect an individual content type (for actual value)
Rules := {
    "SSN": [Rule.Name | some Rule in SensitiveRules; SensitiveContent[0] in Rule.ContentNames],
    "ITIN": [Rule.Name | some Rule in SensitiveRules; SensitiveContent[1] in Rule.ContentNames],
    "Credit_Card": [Rule.Name | some Rule in SensitiveRules; SensitiveContent[2] in Rule.ContentNames]
}

# Build the error message if a particular content is not protected by
# any policies.
error_rules contains SensitiveContent[0] if count(Rules.SSN) == 0

error_rules contains SensitiveContent[1] if count(Rules.ITIN) == 0

error_rules contains SensitiveContent[2] if count(Rules.Credit_Card) == 0

# If error_rules contains any value, then some sensitive content
# is not protected by any policy & check should fail.
tests contains {
    "PolicyId": "MS.DEFENDER.4.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-DlpComplianceRule"],
    "ActualValue": Rules,
    "ReportDetails": ReportDetailsString(Status, ErrorMessage),
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
# Check if policy protects all sensitive content (SSN, ITIN, Credit Card).
# If policy also indicates all for the M365 Product & is in the workload, return
# policy info, else an empty set.
ProductEnableSensitiveProtection(Name, Location) := {
    {
        "Name": Policy.Name,
        "Locations": Policy[Location],
        "Workload": Policy.Workload
    } | some Policy in input.dlp_compliance_policies;
    some PolicyWithProtection in PoliciesWithFullProtection;
    Policy.Name in PolicyWithProtection;
    "All" in Policy[Location];
    contains(Policy.Workload, Name)
}

Policies := {
    "Exchange": ProductEnableSensitiveProtection("Exchange", "ExchangeLocation"),
    "SharePoint": ProductEnableSensitiveProtection("SharePoint", "SharePointLocation"),
    "OneDrive": ProductEnableSensitiveProtection("OneDriveForBusiness", "OneDriveLocation"),
    "Teams": ProductEnableSensitiveProtection("Teams", "TeamsLocation"),
    "Devices": ProductEnableSensitiveProtection("EndpointDevices", "EndpointDlpLocation"),
}

# Build the error message if all sensitive content is not protected by
# any policies for the M365 product.
error_policies contains "Exchange" if count(Policies.Exchange) == 0

error_policies contains "SharePoint" if count(Policies.SharePoint) == 0

error_policies contains "OneDrive" if count(Policies.OneDrive) == 0

error_policies contains "Teams" if count(Policies.Teams) == 0

error_policies contains "Devices" if count(Policies.Devices) == 0

# Create the Report details message for policy
DefenderErrorMessage4_2 := ErrorMessage if {
    count(PoliciesWithFullProtection) > 0
    error_policy := "No enabled policy found that applies to:"
    ErrorMessage := concat(" ", [error_policy, concat(", ", error_policies)])
}

DefenderErrorMessage4_2 := ErrorMessage if {
    count(PoliciesWithFullProtection) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

# If error_policies contains any value, then some M365 product does not
# have a policy protectig all sensitive content & check should fail.
# Check should also fail if there are no policies that protect all sensitive
# content.
tests contains {
    "PolicyId": "MS.DEFENDER.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DLPCompliancePolicy"],
    "ActualValue": Policies,
    "ReportDetails": ReportDetailsString(Status, DefenderErrorMessage4_2),
    "RequirementMet": Status
} if {
    Conditions := [
        count(error_policies) == 0,
        count(PoliciesWithFullProtection) > 0,
    ]
    Status := count(FilterArray(Conditions, true)) == 2
}

#
# MS.DEFENDER.4.3v1
#--

# Step 3: Ensure that the action for the rules is set to block
# Save the rule name if BlockAccess is false OR BlockAccess
# is true & scope is not set to "ALL".
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

# Create the Report details message for policy
DefenderErrorMessage4_3(Rules) := ReportDetailsArray(false, Rules, ErrorMessage) if {
    count(PoliciesWithFullProtection) > 0
    ErrorMessage := "rule(s) found that do(es) not block access or associated policy not set to enforce block action:"
}

DefenderErrorMessage4_3(_) := ErrorMessage if {
    count(PoliciesWithFullProtection) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

# if there is any policy that protects all sensitive content &
# does not block access, the check should fail. The check should
# also fail if there are no policies that protect all sensitive content.
tests contains {
    "PolicyId": "MS.DEFENDER.4.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpComplianceRule"],
    "ActualValue": Rules,
    "ReportDetails": ReportDetailsString(Status, DefenderErrorMessage4_3(Rules)),
    "RequirementMet": Status
} if {
    Rules := SensitiveRulesNotBlocking
    Conditions := [
        count(Rules) == 0,
        count(PoliciesWithFullProtection) > 0,
    ]
    Status := count(FilterArray(Conditions, true)) == 2
}
#--

#
# MS.DEFENDER.4.4v1
#--

# Step 4: ensure that some user is notified in the event of a DLP violation
# Save policies that protect all sensitive content & do not have a user
# to notify,
SensitiveRulesNotNotifying contains Rule.Name if {
    some Rule in PoliciesWithFullProtection
    count(SensitiveRules) > 0
    Rule.ParentPolicyName in Rule
    count(Rule.NotifyUser) == 0
}

# Create the Report details message for policy
DefenderErrorMessage4_4(Rules) := ReportDetailsArray(false, Rules, ErrorMessage) if {
    count(PoliciesWithFullProtection) > 0
    ErrorMessage := "rule(s) found that do(es) not notify at least one user:"
}

DefenderErrorMessage4_4(_) := ErrorMessage if {
    count(PoliciesWithFullProtection) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

# if there is any policy that protects all sensitive content &
# does not have a user to notify, the check should fail. The check should
# also fail if there are no policies that protect all sensitive content.
tests contains {
    "PolicyId": "MS.DEFENDER.4.4v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpComplianceRule"],
    "ActualValue": Rules,
    "ReportDetails": ReportDetailsString(Status, DefenderErrorMessage4_4(Rules)),
    "RequirementMet": Status
} if {
    Rules := SensitiveRulesNotNotifying
    Conditions := [
        count(Rules) == 0,
        count(PoliciesWithFullProtection) > 0,
    ]
    Status := count(FilterArray(Conditions, true)) == 2
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


#################
# MS.DEFENDER.5 #
#################

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

# Save the names of all alerts that are enabled
EnabledAlerts contains Alert.Name if {
    some Alert in input.protection_alerts
    Alert.Disabled == false
}

# If any of the required alerts are not enabled, the check should fail
tests contains {
    "PolicyId": "MS.DEFENDER.5.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ProtectionAlert"],
    "ActualValue": MissingAlerts,
    "ReportDetails": ReportDetailsString(Status, ReportDetailsArray(false, MissingAlerts, ErrorMessage)),
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


#################
# MS.DEFENDER.6 #
#################

#
# MS.DEFENDER.6.1v1
#--

# Save the identity of audit logs that have logging enabled
CorrectLogConfigs contains {
    "Identity": AuditLog.Identity,
    "UnifiedAuditLogIngestionEnabled": AuditLog.UnifiedAuditLogIngestionEnabled,
} if {
    some AuditLog in input.admin_audit_log_config
    AuditLog.UnifiedAuditLogIngestionEnabled == true
}

# The test should pass if at least one log exists
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