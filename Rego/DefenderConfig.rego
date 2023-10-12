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

ATPPolicyForSensitiveIDs[Policies] {
    Policies := input.atp_policy_rules
    AccountsSetting := SensitiveAccountsSetting(Policies)
    AccountsConfig := SensitiveAccountsConfig("MS.DEFENDER.1.5v1")

    SensitiveAccounts(AccountsSetting, AccountsConfig) == true
}

tests[{
    "PolicyId" : "MS.DEFENDER.1.5v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-ATPProtectionPolicyRule"],
    "ActualValue" : {"ATPProtectionPolicies": Status},
    "ReportDetails" : ApplyLicenseWarning(ReportDetailsBoolean(Status)),
    "RequirementMet" : Status
}] {
    Status := count(ATPPolicyForSensitiveIDs) == 1
}
#--

#
# MS.DEFENDER.2.1v1
#--

ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection, AccountType) := Description if {
    String := concat(" ", ["Not all", AccountType])
    Description := concat(" ", [String, "are included for targeted protection in Strict policy."])
    StrictImpersonationProtection.Result == false
    StandardImpersonationProtection.Result == true
}

ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection, AccountType) := Description if {
    String := concat(" ", ["Not all", AccountType])
    Description := concat(" ", [String, "are included for targeted protection in Standard policy."])
    StrictImpersonationProtection.Result == true
    StandardImpersonationProtection.Result == false
}

ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection, AccountType) := Description if {
    String := concat(" ", ["Not all", AccountType])
    Description := concat(" ", [String, "are included for targeted protection in Strict or Standard policy."])
    StrictImpersonationProtection.Result == false
    StandardImpersonationProtection.Result == false
}

ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection, AccountType) := Description if {
    Description := "No agency domains defined for impersonation protection assessment. See configuration file documentation for details on how to define."
    StrictImpersonationProtection.Result == true
    StandardImpersonationProtection.Result == true
    AccountType == "agency domains"
}

ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection, AccountType) := Description if {
    Description := ""
    StrictImpersonationProtection.Result == true
    StandardImpersonationProtection.Result == true
    AccountType != "agency domains"
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
    FilterKey := "EnableTargetedUserProtection"
    AccountKey := "TargetedUsersToProtect"
    ActionKey := "TargetedUserProtectionAction"
    ProtectedConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.1v1", "SensitiveUsers")
    StrictImpersonationProtection := ImpersonationProtection(Policies, "Strict Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    StandardImpersonationProtection := ImpersonationProtection(Policies, "Standard Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection, "sensitive users")
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

# Assert that at least one of the enabled policies includes
# protection for the org's own domains
tests[{
    "PolicyId" : "MS.DEFENDER.2.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
    "ActualValue" : [StrictImpersonationProtection.Policy, StandardImpersonationProtection.Policy],
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet" : Status
}] {
    Policies := input.anti_phish_policies
    FilterKey := "EnableTargetedDomainsProtection"
    AccountKey := "TargetedDomainsToProtect"
    ActionKey := "TargetedDomainProtectionAction"
    ProtectedConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.2v1", "AgencyDomains")
    StrictImpersonationProtection := ImpersonationProtection(Policies, "Strict Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    StandardImpersonationProtection := ImpersonationProtection(Policies, "Standard Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection, "agency domains")
    Conditions := [
        StrictImpersonationProtection.Result == true,
        StandardImpersonationProtection.Result == true,
        count(ProtectedConfig) > 0
    ]
    Status := count([x | x := Conditions[_]; x == false]) == 0
}
#--

#
# MS.DEFENDER.2.3v1
#--
tests[{
    "PolicyId" : "MS.DEFENDER.2.3v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
    "ActualValue" : [StrictImpersonationProtection.Policy, StandardImpersonationProtection.Policy],
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet" : Status
}] {
    Policies := input.anti_phish_policies
    FilterKey := "EnableTargetedDomainsProtection"
    AccountKey := "TargetedDomainsToProtect"
    ActionKey := "TargetedDomainProtectionAction"
    ProtectedConfig := ImpersonationProtectionConfig("MS.DEFENDER.2.3v1", "PartnerDomains")
    StrictImpersonationProtection := ImpersonationProtection(Policies, "Strict Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    StandardImpersonationProtection := ImpersonationProtection(Policies, "Standard Preset Security Policy", ProtectedConfig, FilterKey, AccountKey, ActionKey)
    ErrorMessage := ImpersonationProtectionErrorMsg(StrictImpersonationProtection, StandardImpersonationProtection, "partner domains")
    Conditions := [
        StrictImpersonationProtection.Result == true,
        StandardImpersonationProtection.Result == true
    ]
    Status := count([x | x := Conditions[_]; x == false]) == 0
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

# Return set of content info types in basic rules
InfoTypeMatches(Rule) := ContentTypes if {
    Rule.IsAdvancedRule == false
    ContentTypes := {Content.name | Content := Rule.ContentContainsSensitiveInformation[_]}
}

# Return set of content info types in advanced rules
InfoTypeMatches(Rule) := ContentTypes if {
    Rule.IsAdvancedRule == true
    RuleText := replace(replace(Rule.AdvancedRule, "rn", ""), "'", "\"")

    # Split string to keep line length intact
    TypesRegex := concat("",[
                                `(U.S. Social Security Number \(SSN\))|`,
                                `(U.S. Individual Taxpayer Identification `,
                                `Number \(ITIN\))|`,
                                `(Credit Card Number)`
                            ]
                        )
    ContentTypes := { name | some name in regex.find_n(TypesRegex, RuleText, -1) }
}

SensitiveInfoTypes(PolicyName) := MatchingInfoTypes if {
    InfoTypes := {
                    "U.S. Social Security Number (SSN)",
                    "U.S. Individual Taxpayer Identification Number (ITIN)",
                    "Credit Card Number"
                 }

    ContentTypeSets := { Types |
        some Rule in input.dlp_compliance_rules
        Rule.Disabled == false
        Rule.ParentPolicyName == PolicyName
        Types := InfoTypeMatches(Rule)
    }

    # Flatten set of sets of content types
    MatchingInfoTypes := InfoTypes & union(ContentTypeSets)
}

# Return set of policy names that contain all sensitive info types in rules
SensitiveInfoPolicies[Policy.Name] {
    Policy := input.dlp_compliance_policies[_]

    # Inspect rules for sensitive info types
    InfoTypes := SensitiveInfoTypes(Policy.Name)

    Conditions := [ "U.S. Social Security Number (SSN)" in InfoTypes,
                    "U.S. Individual Taxpayer Identification Number (ITIN)" in InfoTypes,
                    "Credit Card Number" in InfoTypes ]

    count([Condition | Condition := Conditions[_]; Condition == true]) == 3
    Policy.Enabled == true
    Policy.Mode == "Enable"
}

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
    Rules.IsAdvancedRule == false
    ContentNames := [Content.name | Content := Rules.ContentContainsSensitiveInformation[_]]
    Conditions := [ "U.S. Social Security Number (SSN)" in ContentNames,
                    "U.S. Individual Taxpayer Identification Number (ITIN)" in ContentNames,
                    "Credit Card Number" in ContentNames]
    count([Condition | Condition = Conditions[_]; Condition == true]) > 0

    Policy := input.dlp_compliance_policies[_]
    Rules.ParentPolicyName == Policy.Name
    Policy.Enabled == true
    Policy.Mode == "Enable"
}

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
    Rules.IsAdvancedRule == true

    Policy := input.dlp_compliance_policies[_]
    Rules.ParentPolicyName == Policy.Name
    Policy.Enabled == true
    Policy.Mode == "Enable"

    # Trim converted end-of-line "rn" delimters and convert single quotes to
    # double for unmarshalling
    RuleText := replace(replace(Rules.AdvancedRule, "rn", ""), "'", "\"")

    ContentNames := InfoTypeMatches(Rules)

    Conditions := [ contains(RuleText, "U.S. Social Security Number (SSN)"),
                    contains(RuleText, "U.S. Individual Taxpayer Identification Number (ITIN)"),
                    contains(RuleText, "Credit Card Number")]

    count([Condition | Condition := Conditions[_]; Condition == true]) > 0
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

Rules := {
    "SSN" : SSNRules,
    "ITIN" : ITINRules,
    "Credit_Card" : CardRules
}

error_rules contains "U.S. Social Security Number (SSN)" if count(Rules.SSN) == 0
error_rules contains "U.S. Individual Taxpayer Identification Number (ITIN)" if count(Rules.ITIN) == 0
error_rules contains "Credit Card Number" if count(Rules.Credit_Card) == 0

tests[{
    "PolicyId" : "MS.DEFENDER.4.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-DlpComplianceRule"],
    "ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet" : Status
}] {
    error_rule := "No matching rules found for:"
    ErrorMessage := concat(" ",  [error_rule, concat(", ", error_rules)])

    Status := count(SensitiveInfoPolicies) > 0
}

#
# MS.DEFENDER.4.2v1
#--

# Step 2: determine the set of sensitive policies that apply to EXO, Teams, etc.
ExchangePolicies[{
    "Name" : Policy.Name,
    "Locations" : Policy.ExchangeLocation,
    "Workload" : Policy.Workload
}] {
    Policy := input.dlp_compliance_policies[_]
    Policy.Name in SensitiveInfoPolicies
    "All" in Policy.ExchangeLocation
    contains(Policy.Workload, "Exchange")
}

SharePointPolicies[{
    "Name" : Policy.Name,
    "Locations" : Policy.SharePointLocation,
    "Workload" : Policy.Workload
}] {
    Policy := input.dlp_compliance_policies[_]
    Policy.Name in SensitiveInfoPolicies
    "All" in Policy.SharePointLocation
    contains(Policy.Workload, "SharePoint")
}

OneDrivePolicies[{
    "Name" : Policy.Name,
    "Locations" : Policy.OneDriveLocation,
    "Workload" : Policy.Workload
}] {
    Policy := input.dlp_compliance_policies[_]
    Policy.Name in SensitiveInfoPolicies
    "All" in Policy.OneDriveLocation
    contains(Policy.Workload, "OneDriveForBusiness")
}

TeamsPolicies[{
    "Name" : Policy.Name,
    "Locations" : Policy.TeamsLocation,
    "Workload" : Policy.Workload
    }] {
    Policy := input.dlp_compliance_policies[_]
    Policy.Name in SensitiveInfoPolicies
    "All" in Policy.TeamsLocation
    contains(Policy.Workload, "Teams")
}

DevicesPolicies[{
    "Name" : Policy.Name,
    "Locations" : Policy.EndpointDlpLocation,
    "Workload" : Policy.Workload
    }] {
    Policy := input.dlp_compliance_policies[_]
    Policy.Name in SensitiveInfoPolicies
    "All" in Policy.EndpointDlpLocation
    contains(Policy.Workload, "EndpointDevices")
}

Policies := {
    "Exchange": ExchangePolicies,
    "SharePoint": SharePointPolicies,
    "OneDrive": OneDrivePolicies,
    "Teams": TeamsPolicies,
    "Devices": DevicesPolicies
}

error_policies contains "Exchange" if count(Policies.Exchange) == 0
error_policies contains "SharePoint" if count(Policies.SharePoint) == 0
error_policies contains "OneDrive" if count(Policies.OneDrive) == 0
error_policies contains "Teams" if count(Policies.Teams) == 0
error_policies contains "Devices" if count(Policies.Devices) == 0

DefenderErrorMessage4_2 := ErrorMessage if {
    count(SensitiveInfoPolicies) > 0
    error_policy := "No enabled policy found that applies to:"
    ErrorMessage := concat(" ", [error_policy, concat(", ", error_policies)])
}

DefenderErrorMessage4_2 := ErrorMessage if {
    count(SensitiveInfoPolicies) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

tests[{
    "PolicyId": "MS.DEFENDER.4.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DLPCompliancePolicy"],
    "ActualValue": Policies,
    "ReportDetails": CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet": Status
}] {
    ErrorMessage := DefenderErrorMessage4_2
    Conditions := [ count(error_policies) == 0,
                    count(SensitiveInfoPolicies) > 0 ]
    Status := count([Condition | Condition := Conditions[_]; Condition == true ]) == 2
}

#
# MS.DEFENDER.4.3v1
#--
# Step 3: Ensure that the action for the rules is set to block
SensitiveRulesNotBlocking[Rule.Name] {
    Rule := SensitiveRules[_]
    not Rule.BlockAccess
    Rule.ParentPolicyName in SensitiveInfoPolicies
}

SensitiveRulesNotBlocking[Rule.Name] {
    Rule := SensitiveRules[_]
    Rule.BlockAccess
    Rule.ParentPolicyName in SensitiveInfoPolicies
    Rule.BlockAccessScope != "All"
}

DefenderErrorMessage4_3(Rules) := GenerateArrayString(Rules, ErrorMessage) if {
    count(SensitiveInfoPolicies) > 0
    ErrorMessage := "rule(s) found that do(es) not block access or associated policy not set to enforce block action:"
}

DefenderErrorMessage4_3(Rules) := ErrorMessage if {
    count(SensitiveInfoPolicies) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

tests[{
    "PolicyId" : "MS.DEFENDER.4.3v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpComplianceRule"],
    "ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet" : Status
}] {
    Rules := SensitiveRulesNotBlocking
    ErrorMessage := DefenderErrorMessage4_3(Rules)
    Conditions := [ count(Rules) == 0,
                    count(SensitiveInfoPolicies) > 0 ]
    Status := count([Condition | Condition := Conditions[_]; Condition == true ]) == 2
}
#--

#
# MS.DEFENDER.4.4v1
#--
# Step 4: ensure that some user is notified in the event of a DLP violation
SensitiveRulesNotNotifying[Rule.Name] {
    Rule := SensitiveRules[_]
    count(SensitiveInfoPolicies) > 0
    Rule.ParentPolicyName in SensitiveInfoPolicies
    count(Rule.NotifyUser) == 0
}

DefenderErrorMessage4_4(Rules) := GenerateArrayString(Rules, ErrorMessage) if {
    count(SensitiveInfoPolicies) > 0
    ErrorMessage := "rule(s) found that do(es) not notify at least one user:"
}

DefenderErrorMessage4_4(Rules) := ErrorMessage if {
    count(SensitiveInfoPolicies) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

tests[{
    "PolicyId" : "MS.DEFENDER.4.4v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpComplianceRule"],
    "ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetailsBoolean(Status), ErrorMessage),
    "RequirementMet" : Status
}] {
    Rules := SensitiveRulesNotNotifying
    ErrorMessage := DefenderErrorMessage4_4(Rules)
    Conditions := [ count(Rules) == 0,
                    count(SensitiveInfoPolicies) > 0 ]
    Status := count([Condition | Condition := Conditions[_]; Condition == true ]) == 2
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
