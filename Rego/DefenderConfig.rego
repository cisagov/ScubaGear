package defender
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.ReportDetailsBoolean
import data.defender.utils.SensitiveAccounts
import data.defender.utils.SensitiveAccountsConfig
import data.defender.utils.SensitiveAccountsSetting
import data.defender.utils.ImpersonationProtection
import data.defender.utils.ImpersonationProtectionConfig

## Report details menu
#
# NOTE: Use report.utils package for common report formatting functions.
#
# If you simply want a boolean "Requirement met" / "Requirement not met"
# just call ReportDetailsBoolean(Status) and leave it at that.
#
# If you want to customize the error message, wrap the ReportDetails call
# inside CustomizeError, like so:
# CustomizeError(ReportDetailsBoolean(Status), "Custom error message")
#
# If you want to customize the error message with details about an array,
# generate the custom error message using GenerateArrayString, for example:
# CustomizeError(ReportDetailsBoolean(Status), GenerateArrayString(BadPolicies, "bad policies found:"))
#
# If the setting in question requires a defender license,
# wrap the details string inside ApplyLicenseWarning, like so:
# ApplyLicenseWarning(ReportDetailsBoolean(Status))
#
# These functions can be nested. For example:
# ApplyLicenseWarning(CustomizeError(ReportDetailsBoolean(Status), "Custom error message"))
#
##

GenerateArrayString(Array, CustomString) := Output if {
    # Example usage and output:
    # GenerateArrayString([1,2], "numbers found:") ->
    # 2 numbers found: 1, 2
    Length := format_int(count(Array), 10)
    ArrayString := concat(", ", Array)
    Output := trim(concat(" ", [Length, concat(" ", [CustomString, ArrayString])]), " ")
}

CustomizeError(Message, CustomString) := Message if {
    # If the message reports success, don't apply the custom
    # error message
    Message == ReportDetailsBoolean(true)
}

CustomizeError(Message, CustomString) := CustomString if {
    # If the message does not report success, apply the custom
    # error message
    Message != ReportDetailsBoolean(true)
}

ApplyLicenseWarning(Message) := Message if {
    # If a defender license is present, don't apply the warning
    # and leave the message unchanged
    input.defender_license == true
}

ApplyLicenseWarning(Message) := concat("", [ReportDetailsBoolean(false), LicenseWarning]) if {
    # If a defender license is not present, assume failure and
    # replace the message with the warning
    input.defender_license == false
    LicenseWarning := " **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}


#
# MS.DEFENDER.1.1v1
#--

ReportDetails1_1(Standard, Strict) := "Requirement met" if {
    Standard == true
    Strict == true
}
ReportDetails1_1(Standard, Strict) := "Standard preset policy is disabled" if {
    Standard == false
    Strict == true
}
ReportDetails1_1(Standard, Strict) := "Strict preset policy is disabled" if {
    Standard == true
    Strict == false
}
ReportDetails1_1(Standard, Strict) := "Standard and Strict preset policies are both disabled" if {
    Standard == false
    Strict == false
}

tests[{
    "PolicyId" : "MS.DEFENDER.1.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-EOPProtectionPolicyRule", "Get-ATPProtectionPolicyRule"],
	"ActualValue" : {"StandardPresetState": IsStandardEnabled, "StrictPresetState": IsStrictEnabled},
    "ReportDetails" : ReportDetails1_1(IsStandardEnabled, IsStrictEnabled),
    "RequirementMet" : Status
}] {
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

    EOPPolicies := input.protection_policy_rules
    IsStandardEOPEnabled := count([Policy | Policy = EOPPolicies[_];
        Policy.Identity == "Standard Preset Security Policy";
        Policy.State == "Enabled"]) > 0
    IsStrictEOPEnabled := count([Policy | Policy = EOPPolicies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.State == "Enabled"]) > 0

    ATPPolicies := input.atp_policy_rules
    IsStandardATPEnabled := count([Policy | Policy = ATPPolicies[_];
        Policy.Identity == "Standard Preset Security Policy";
        Policy.State == "Enabled"]) > 0
    IsStrictATPEnabled := count([Policy | Policy = ATPPolicies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.State == "Enabled"]) > 0

    StandardConditions := [IsStandardEOPEnabled, IsStandardATPEnabled]
    IsStandardEnabled := count([Condition | Condition = StandardConditions[_]; Condition == true]) > 0

    StrictConditions := [IsStrictEOPEnabled, IsStrictATPEnabled]
    IsStrictEnabled := count([Condition | Condition = StrictConditions[_]; Condition == true]) > 0

    Conditions := [IsStandardEnabled, IsStrictEnabled]
    Status := count([Condition | Condition = Conditions[_]; Condition == false]) == 0
}
#--

#
# MS.DEFENDER.1.2v1
#--

# TODO check exclusions

tests[{
    "PolicyId" : "MS.DEFENDER.1.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-EOPProtectionPolicyRule"],
	"ActualValue" : {"StandardSetToAll": IsStandardAll, "StrictSetToAll": IsStrictAll},
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
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

    Policies := input.protection_policy_rules
    IsStandardAll := count([Policy | Policy = Policies[_];
        Policy.Identity == "Standard Preset Security Policy";
        Policy.SentTo == null;
        Policy.SentToMemberOf == null;
        Policy.RecipientDomainIs == null]) > 0
    IsStrictAll := count([Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo == null;
        Policy.SentToMemberOf == null;
        Policy.RecipientDomainIs == null]) > 0
    Conditions := [IsStandardAll, IsStrictAll]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}
#--

#
# MS.DEFENDER.1.3v1
#--

# TODO check exclusions

tests[{
    "PolicyId" : "MS.DEFENDER.1.3v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-ATPProtectionPolicyRule"],
	"ActualValue" : {"StandardSetToAll": IsStandardAll, "StrictSetToAll": IsStrictAll},
    "ReportDetails" : ApplyLicenseWarning(ReportDetailsBoolean(Status)),
    "RequirementMet" : Status
}] {
    # See MS.DEFENDER.1.2v1, the same logic applies, just with a
    # different commandlet.

    Policies := input.atp_policy_rules
    IsStandardAll := count([Policy | Policy = Policies[_];
        Policy.Identity == "Standard Preset Security Policy";
        Policy.SentTo == null;
        Policy.SentToMemberOf == null;
        Policy.RecipientDomainIs == null]) > 0
    IsStrictAll := count([Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy";
        Policy.SentTo == null;
        Policy.SentToMemberOf == null;
        Policy.RecipientDomainIs == null]) > 0
    Conditions := [IsStandardAll, IsStrictAll]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}
#--

#
# MS.DEFENDER.1.4v1
#--

ProtectionPolicyForSensitiveIDs[Policies] {
    Policies := input.protection_policy_rules
    AccountsSetting := SensitiveAccountsSetting(Policies)
    AccountsConfig := SensitiveAccountsConfig("MS.DEFENDER.1.4v1")

    SensitiveAccounts(AccountsSetting, AccountsConfig) == true
}

tests[{
    "PolicyId" : "MS.DEFENDER.1.4v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-EOPProtectionPolicyRule"],
	"ActualValue" : {"EOPProtectionPolicies": Status},
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Status := count(ProtectionPolicyForSensitiveIDs) == 1
}
#--

#
# MS.DEFENDER.1.5v1
#--

# TODO: look at config file to get list of sensitive users. Current
# implementation just asserts that the strict policy applies to at
# least one person.

tests[{
    "PolicyId" : "MS.DEFENDER.1.5v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-ATPProtectionPolicyRule"],
	"ActualValue" : {"ATPProtectionPolicies": Policies},
    "ReportDetails" : ApplyLicenseWarning(ReportDetailsBoolean(Status)),
    "RequirementMet" : Status
}] {
    Policies := input.atp_policy_rules
    # If no one has been assigned to the strict policy, it won't even
    # be included in the output of Get-ATPProtectionPolicyRule
    Status := count([Policy | Policy = Policies[_];
        Policy.Identity == "Strict Preset Security Policy"]) > 0
}
#--

#
# MS.DEFENDER.2.1v1
#--

ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection) := Description if {
    Description := "No users are included for targeted user protection in Strict policy."
    StrictImpersonationProtection.Result == false
    StandardImpersonationProtection.Result == true
}

ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection) := Description if {
    Description := "No users are included for targeted user protection in Standard policy."
    StrictImpersonationProtection.Result == true
    StandardImpersonationProtection.Result == false
}

ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection) := Description if {
    Description := "No users are included for targeted user protection in Strict or Standard policy."
    StrictImpersonationProtection.Result == false
    StandardImpersonationProtection.Result == false
}

ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection) := Description if {
    Description := ""
    StrictImpersonationProtection.Result == true
    StandardImpersonationProtection.Result == true
}

tests[{
    "PolicyId" : "MS.DEFENDER.2.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : [StrictImpersonationProtection.Policy, StandardImpersonationProtection.Policy],
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet" : Status
}] {
    Policies := input.anti_phish_policies
    ProtectedUsersConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.1v1")
    StrictImpersonationProtection := ImpersonationProtection(Policies, "Strict Preset Security Policy", ProtectedUsersConfig)
    StandardImpersonationProtection := ImpersonationProtection(Policies, "Standard Preset Security Policy", ProtectedUsersConfig)
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection)
    Conditions := [
        StrictImpersonationProtection.Result == true,
        StandardImpersonationProtection.Result == true
    ]
    Status := count([x | x := Conditions[_]; x == false]) == 0
}
#--

#
# MS.DEFENDER.2.2v1
#--

# TODO: update this policy to match emerald baseline
# The following check is from pre-emerald 2.5 second bullet,
# which is similar but needs some adjustments.

ProtectedOrgDomainsPolicies[{
    "Name" : Policy.Name,
	"OrgDomains" : Policy.EnableOrganizationDomainsProtection,
    "Action" : Policy.TargetedDomainProtectionAction
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Enabled # filter out the disabled policies
    Policy.EnableTargetedDomainsProtection # filter out the policies that don't have domain impersonation protection enabled
    Policy.EnableOrganizationDomainsProtection # filter out the policies that don't protect org domains
}

# assert that at least one of the enabled policies includes
# protection for the org's own domains
tests[{
    "PolicyId" : "MS.DEFENDER.2.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Policies := ProtectedOrgDomainsPolicies
    Status := count(Policies) > 0
}
#--

#
# MS.DEFENDER.2.3v1
#--

# TODO: update this policy to match emerald baseline
# The following check is from pre-emerald 2.5 third bullet,
# which is similar but needs some adjustments.

ProtectedCustomDomainsPolicies[{
    "Name" : Policy.Name,
	"CustomDomains" : Policy.TargetedDomainsToProtect,
    "Action" : Policy.TargetedDomainProtectionAction
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Enabled # filter out the disabled policies
    Policy.EnableTargetedDomainsProtection # filter out the policies that don't have domain impersonation protection enabled
    count(Policy.TargetedDomainsToProtect) > 0 # filter out the policies that don't list any custom domains
}

# assert that at least one of the enabled policies includes
# protection for custom domains
tests[{
    "PolicyId" : "MS.DEFENDER.2.3v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet" : Status
}] {
    Policies := ProtectedCustomDomainsPolicies
    ErrorMessage := "The Custom Domains protection policies: Enabled, EnableTargetedDomainsProtection, and TargetedDomainsToProtect are not set correctly"
    Status := count(Policies) > 0
}
#--

#
# MS.DEFENDER.3.1v1
#--

# Find the set of policies that have EnableATPForSPOTeamsODB set to true
ATPPolicies[{
    "Identity" : Policy.Identity,
    "EnableATPForSPOTeamsODB" : Policy.EnableATPForSPOTeamsODB}] {
    Policy := input.atp_policy_for_o365[_]
    Policy.EnableATPForSPOTeamsODB == true
}

tests[{
    "PolicyId" : "MS.DEFENDER.3.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AtpPolicyForO365"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetailsBoolean(Status)),
    "RequirementMet" : Status
}] {
    Policies := ATPPolicies
    Status := count(Policies) > 0
}
#--

#
# MS.DEFENDER.4.1v1
#--

# Determine the set of rules that pertain to SSNs, ITINs, or credit card numbers.
# Used in multiple bullet points below
SensitiveRules[{
    "Name" : Rules.Name,
	"ParentPolicyName" : Rules.ParentPolicyName,
	"BlockAccess" : Rules.BlockAccess,
	"BlockAccessScope" : Rules.BlockAccessScope,
	"NotifyUser" : Rules.NotifyUser,
	"NotifyUserType" : Rules.NotifyUserType,
    "ContentNames" : ContentNames
}] {
	Rules := input.dlp_compliance_rules[_]
	Rules.Disabled == false
    ContentNames := [Content.name | Content = Rules.ContentContainsSensitiveInformation[_]]
	Conditions := [ "U.S. Social Security Number (SSN)" in ContentNames,
                    "U.S. Individual Taxpayer Identification Number (ITIN)" in ContentNames,
                    "Credit Card Number" in ContentNames]
    count([Condition | Condition = Conditions[_]; Condition == true]) > 0

    Policy := input.dlp_compliance_policies[_]
    Rules.ParentPolicyName == Policy.Name
    Policy.Enabled == true
}

# Step 1: Ensure that there is coverage for SSNs, ITINs, and credit cards
SSNRules[Rule.Name] {
    Rule := SensitiveRules[_]
    "U.S. Social Security Number (SSN)" in Rule.ContentNames
}

ITINRules[Rule.Name] {
    Rule := SensitiveRules[_]
    "U.S. Individual Taxpayer Identification Number (ITIN)" in Rule.ContentNames
}

CardRules[Rule.Name] {
    Rule := SensitiveRules[_]
    "Credit Card Number" in Rule.ContentNames
}

tests[{
    #TODO: Appears this policy is broken into 3 parts in code and only 1 in baseline
    # Combine this and the following two that are commented out into a single test
    #"Requirement" : "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: U.S. Social Security Number (SSN)",
    "PolicyId" : "MS.DEFENDER.4.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-DlpComplianceRule"],
	"ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet" : Status
}] {
    Rules := SSNRules
    ErrorMessage := "No matching rule found for U.S. Social Security Number (SSN)"
    Status := count(Rules) > 0
}

# tests[{
#     "Requirement" : "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: U.S. Individual Taxpayer Identification Number (ITIN)",
#     "Control" : "Defender 2.2",
#     "Criticality" : "Shall",
#     "Commandlet" : ["Get-DlpComplianceRule"],
# 	"ActualValue" : Rules,
#     "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
#     "RequirementMet" : Status
# }] {
#     Rules := ITINRules
#     ErrorMessage := "No matching rule found for U.S. Individual Taxpayer Identification Number (ITIN)"
#     Status := count(Rules) > 0
# }

# tests[{
#     "Requirement" : "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: Credit Card Number",
#     "Control" : "Defender 2.2",
#     "Criticality" : "Shall",
#     "Commandlet" : ["Get-DlpComplianceRule"],
# 	"ActualValue" : Rules,
#     "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
#     "RequirementMet" : Status
# }] {
#     Rules := CardRules
#     ErrorMessage := "No matching rule found for Credit Card Number"
#     Status := count(Rules) > 0
# }
#--

#
# MS.DEFENDER.4.2v1
#--

# Step 2: determine the set of sensitive policies that apply to EXO, Teams, etc.
ExchangePolicies[{
    "Name" : Policy.Name,
    "Locations" : Policy.ExchangeLocation,
    "Workload" : Policy.Workload
}] {
    SensitivePolicies := {Rule.ParentPolicyName | Rule = SensitiveRules[_]}
    Policy := input.dlp_compliance_policies[_]
    Policy.Name in SensitivePolicies
    "All" in Policy.ExchangeLocation
    contains(Policy.Workload, "Exchange")
}

SharePointPolicies[{
    "Name" : Policy.Name,
    "Locations" : Policy.SharePointLocation,
    "Workload" : Policy.Workload
}] {
    SensitivePolicies := {Rule.ParentPolicyName | Rule = SensitiveRules[_]}
    Policy := input.dlp_compliance_policies[_]
    Policy.Name in SensitivePolicies
    "All" in Policy.SharePointLocation
    contains(Policy.Workload, "SharePoint")
}

OneDrivePolicies[{
    "Name" : Policy.Name,
    "Locations" : Policy.OneDriveLocation,
    "Workload" : Policy.Workload
}] {
    SensitivePolicies := {Rule.ParentPolicyName | Rule = SensitiveRules[_]}
    Policy := input.dlp_compliance_policies[_]
    Policy.Name in SensitivePolicies
    "All" in Policy.OneDriveLocation
    contains(Policy.Workload, "OneDrivePoint") # Is this supposed to be OneDrivePoint or OneDrive?
}

TeamsPolicies[{
    "Name" : Policy.Name,
    "Locations" : Policy.TeamsLocation,
    "Workload" : Policy.Workload
    }] {
    SensitivePolicies := {Rule.ParentPolicyName | Rule = SensitiveRules[_]}
    Policy := input.dlp_compliance_policies[_]
    Policy.Name in SensitivePolicies
    "All" in Policy.TeamsLocation
    contains(Policy.Workload, "Teams")
}

tests[{
    # TODO: Appears this policy is broken into 4 parts in code and only 1 in baseline
    # Combine this test and the following 3 commented out tests into a single test
    #"Requirement" : "The custom policy SHOULD be applied in Exchange",
    "PolicyId" : "MS.DEFENDER.4.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DLPCompliancePolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet" : Status
}] {
    Policies := ExchangePolicies
    ErrorMessage := "No policy found that applies to Exchange."
    Status := count(Policies) > 0
}

# tests[{
#     "Requirement" : "The custom policy SHOULD be applied in SharePoint",
#     "Control" : "Defender 2.2",
#     "Criticality" : "Should",
#     "Commandlet" : ["Get-DLPCompliancePolicy"],
# 	"ActualValue" : Policies,
#     "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
#     "RequirementMet" : Status
# }] {
#     Policies := SharePointPolicies
#     ErrorMessage := "No policy found that applies to SharePoint."
#     Status := count(Policies) > 0
# }

# tests[{
#     "Requirement" : "The custom policy SHOULD be applied in OneDrive",
#     "Control" : "Defender 2.2",
#     "Criticality" : "Should",
#     "Commandlet" : ["Get-DLPCompliancePolicy"],
# 	"ActualValue" : Policies,
#     "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
#     "RequirementMet" : Status
# }] {
#     Policies := OneDrivePolicies
#     ErrorMessage := "No policy found that applies to OneDrive."
#     Status := count(Policies) > 0
# }

# tests[{
#     "Requirement" : "The custom policy SHOULD be applied in Teams",
#     "Control" : "Defender 2.2",
#     "Criticality" : "Should",
#     "Commandlet" : ["Get-DLPCompliancePolicy"],
# 	"ActualValue" : Policies,
#     "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
#     "RequirementMet" : Status
# }] {
#     Policies := TeamsPolicies
#     ErrorMessage := "No policy found that applies to Teams."
#     Status := count(Policies) > 0
# }
#--

#
# MS.DEFENDER.4.3v1
#--
# Step 3: Ensure that the action for the rules is set to block
SensitiveRulesNotBlocking[Rule.Name] {
    Rule := SensitiveRules[_]
    not Rule.BlockAccess
    Policy := input.dlp_compliance_policies[_]
    Rule.ParentPolicyName == Policy.Name
    Policy.Mode == "Enable"
}

# Covers rules set to block, but inside policies set to
# "TestWithNotifications" or "TestWithoutNotifications" that won't enforce the block
SensitiveRulesNotBlocking[Rule.Name] {
    Rule := SensitiveRules[_]
    Policy := input.dlp_compliance_policies[_]
    Rule.ParentPolicyName == Policy.Name
    Rule.BlockAccess
    startswith(Policy.Mode, "TestWith") == true
}

tests[{
    "PolicyId" : "MS.DEFENDER.4.3v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpComplianceRule"],
	"ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), GenerateArrayString(Rules, ErrorMessage)),
    "RequirementMet" : Status
}] {
    Rules := SensitiveRulesNotBlocking
    ErrorMessage := "rule(s) found that do(es) not block access or associated policy not set to enforce block action:"
	Status := count(Rules) == 0
}
#--

#
# MS.DEFENDER.4.4v1
#--
# Step 4: ensure that some user is notified in the event of a DLP violation
SensitiveRulesNotNotifying[Rule.Name] {
    Rule := SensitiveRules[_]
    count(Rule.NotifyUser) == 0
}

tests[{
    "PolicyId" : "MS.DEFENDER.4.4v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpComplianceRule"],
	"ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), GenerateArrayString(Rules, ErrorMessage)),
    "RequirementMet" : Status
}] {
    Rules := SensitiveRulesNotNotifying
    ErrorMessage := "rule(s) found that do(es) not notify at least one user:"
	Status := count(Rules) == 0
}
#--

#
# MS.DEFENDER.4.5v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.DEFENDER.4.5v1"
    true
}
#--

#
# MS.DEFENDER.4.6v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.DEFENDER.4.6v1"
    true
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

EnabledAlerts[Alert.Name] {
    Alert := input.protection_alerts[_]
    Alert.Disabled == false
}

tests[{
    "PolicyId" : "MS.DEFENDER.5.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-ProtectionAlert"],
	"ActualValue" : MissingAlerts,
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), GenerateArrayString(MissingAlerts, ErrorMessage)),
    "RequirementMet" : Status
}] {
    MissingAlerts := RequiredAlerts - EnabledAlerts
    ErrorMessage := "disabled required alert(s) found:"
    Status := count(MissingAlerts) == 0
}
#--

#
# MS.DEFENDER.5.2v1
#--
# SIEM incorporation cannot be checked programmatically
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.DEFENDER.5.2v1"
    true
}
#--


#
# MS.DEFENDER.6.1v1
#--

CorrectLogConfigs[{
    "Identity": AuditLog.Identity,
    "UnifiedAuditLogIngestionEnabled": AuditLog.UnifiedAuditLogIngestionEnabled
}] {
    AuditLog := input.admin_audit_log_config[_]
    AuditLog.UnifiedAuditLogIngestionEnabled == true
}

tests[{
    "PolicyId" : "MS.DEFENDER.6.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AdminAuditLogConfig"],
	"ActualValue" : CorrectLogConfigs,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Status := count(CorrectLogConfigs) >= 1
}
#--

#
# MS.DEFENDER.6.2v1
#--
# Turns out audit logging is non-trivial to implement and test for.
# Would require looping through all users. See discussion in GitHub
# issue #200.
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.DEFENDER.6.2v1"
    true
}
#--

#
# MS.DEFENDER.6.3v1
#--
# Dictated by OMB M-21-31: 12 months in hot storage and 18 months in cold
# It is not required to maintain these logs in the M365 cloud environment; doing so would require an additional add-on SKU.
# This requirement can be met by offloading the logs out of the cloud environment.
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.DEFENDER.6.3v1"
    true
}
#--
