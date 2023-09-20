package defender
import future.keywords

## Report details menu
#
# If you simply want a boolean "Requirement met" / "Requirement not met"
# just call ReportDetails(Status) and leave it at that.
#
# If you want to customize the error message, wrap the ReportDetails call
# inside CustomizeError, like so:
# CustomizeError(ReportDetails(Status), "Custom error message")
#
# If you want to customize the error message with details about an array,
# generate the custom error message using GenerateArrayString, for example:
# CustomizeError(ReportDetails(Status), GenerateArrayString(BadPolicies, "bad policies found:"))
#
# If the setting in question requires a defender license,
# wrap the details string inside ApplyLicenseWarning, like so:
# ApplyLicenseWarning(ReportDetails(Status))
#
# These functions can be nested. For example:
# ApplyLicenseWarning(CustomizeError(ReportDetails(Status), "Custom error message"))
#
##
ReportDetails(Status) := "Requirement met" if {
    Status == true
}

ReportDetails(Status) := "Requirement not met" if {
    Status == false
}

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
    Message == ReportDetails(true)
}

CustomizeError(Message, CustomString) := CustomString if {
    # If the message does not report success, apply the custom
    # error message
    Message != ReportDetails(true)
}

ApplyLicenseWarning(Message) := Message if {
    # If a defender license is present, don't apply the warning
    # and leave the message unchanged
    input.defender_license == true
}

ApplyLicenseWarning(Message) := concat("", [ReportDetails(false), LicenseWarning]) if {
    # If a defender license is not present, assume failure and
    # replace the message with the warning
    input.defender_license == false
    LicenseWarning := " **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

################
# Baseline 2.1 #
################

#
# Baseline 2.1: Policy 1
#--
StandardPresetSecurityPolicy[Rules.State] {
    Rules := input.protection_policy_rules[_]
    Rules.Identity == "Standard Preset Security Policy"
}

tests[{
    "Requirement" : "Standard Preset security profiles SHOULD NOT be used",
    "Control" : "Defender 2.1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-EOPProtectionPolicyRule"],
	"ActualValue" : Policy,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.1.1",
    "TestId": "defender-2.1.1-t1"
}] {
    Policy := StandardPresetSecurityPolicy
    ErrorMessage := "The Standard Preset Security Policy is present and not disabled"
    Conditions := [count(Policy) == 0, "Disabled" in Policy]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}
#--

#
# Baseline 2.1: Policy 2
#--
StrictPresetSecurityPolicy[Rules.State] {
    Rules := input.protection_policy_rules[_]
    Rules.Identity == "Strict Preset Security Policy"
}

tests[{
    "Requirement" : "Strict Preset security profiles SHOULD NOT be used",
    "Control" : "Defender 2.1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-EOPProtectionPolicyRule"],
	"ActualValue" : Policy,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.1.2",
    "TestId": "defender-2.1.2-t1"
}] {
    Policy := StrictPresetSecurityPolicy
    ErrorMessage := "The Strict Preset Security Policy is present and not disabled"
    Conditions := [count(Policy) == 0, "Disabled" in Policy]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}
#--


################
# Baseline 2.2 #
################

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

#
# Baseline 2.2: Policy 1
#--
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
    "Requirement" : "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: U.S. Social Security Number (SSN)",
    "Control" : "Defender 2.2",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-DlpComplianceRule"],
	"ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.2.1",
    "TestId": "defender-2.2.1-t1"
}] {
    Rules := SSNRules
    ErrorMessage := "No matching rule found for U.S. Social Security Number (SSN)"
    Status := count(Rules) > 0
}

tests[{
    "Requirement" : "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: U.S. Individual Taxpayer Identification Number (ITIN)",
    "Control" : "Defender 2.2",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-DlpComplianceRule"],
	"ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.2.1",
    "TestId": "defender-2.2.1-t2"
}] {
    Rules := ITINRules
    ErrorMessage := "No matching rule found for U.S. Individual Taxpayer Identification Number (ITIN)"
    Status := count(Rules) > 0
}

tests[{
    "Requirement" : "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: Credit Card Number",
    "Control" : "Defender 2.2",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-DlpComplianceRule"],
	"ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.2.1",
    "TestId": "defender-2.2.1-t3"
}] {
    Rules := CardRules
    ErrorMessage := "No matching rule found for Credit Card Number"
    Status := count(Rules) > 0
}
#--

#
# Baseline 2.2: Policy 2
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
    "Requirement" : "The custom policy SHOULD be applied in Exchange",
    "Control" : "Defender 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DLPCompliancePolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.2.2",
    "TestId": "defender-2.2.2-t1"
}] {
    Policies := ExchangePolicies
    ErrorMessage := "No policy found that applies to Exchange."
    Status := count(Policies) > 0
}

tests[{
    "Requirement" : "The custom policy SHOULD be applied in SharePoint",
    "Control" : "Defender 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DLPCompliancePolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.2.2",
    "TestId": "defender-2.2.2-t2"
}] {
    Policies := SharePointPolicies
    ErrorMessage := "No policy found that applies to SharePoint."
    Status := count(Policies) > 0
}

tests[{
    "Requirement" : "The custom policy SHOULD be applied in OneDrive",
    "Control" : "Defender 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DLPCompliancePolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.2.2",
    "TestId": "defender-2.2.2-t3"
}] {
    Policies := OneDrivePolicies
    ErrorMessage := "No policy found that applies to OneDrive."
    Status := count(Policies) > 0
}

tests[{
    "Requirement" : "The custom policy SHOULD be applied in Teams",
    "Control" : "Defender 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DLPCompliancePolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.2.2",
    "TestId": "defender-2.2.2-t4"
}] {
    Policies := TeamsPolicies
    ErrorMessage := "No policy found that applies to Teams."
    Status := count(Policies) > 0
}
#--

#
# Baseline 2.2: Policy 3
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
    "Requirement" : "The action for the DLP policy SHOULD be set to block sharing sensitive information with everyone when DLP conditions are met",
    "Control" : "Defender 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpComplianceRule"],
	"ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Rules, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.2.3",
    "TestId": "defender-2.2.3-t1"
}] {
    Rules := SensitiveRulesNotBlocking
    ErrorMessage := "rule(s) found that do(es) not block access or associated policy not set to enforce block action:"
	Status := count(Rules) == 0
}
#--

#
# Baseline 2.2: Policy 4
#--
# Step 4: ensure that some user is notified in the event of a DLP violation
SensitiveRulesNotNotifying[Rule.Name] {
    Rule := SensitiveRules[_]
    count(Rule.NotifyUser) == 0
}

tests[{
    "Requirement" : "Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled",
    "Control" : "Defender 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpComplianceRule"],
	"ActualValue" : Rules,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Rules, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.2.4",
    "TestId": "defender-2.2.4-t1"
}] {
    Rules := SensitiveRulesNotNotifying
    ErrorMessage := "rule(s) found that do(es) not notify at least one user:"
	Status := count(Rules) == 0
}
#--

#
# Baseline 2.2: Policy 5
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "A list of apps that are not allowed to access files protected by DLP policy SHOULD be defined",
    "Control" : "Defender 2.2",
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.2 for instructions on manual check",
    "RequirementMet" : false,
    "PolicyId" : "defender-2.2.5",
    "TestId": "defender-2.2.5-t1"
}] {
    true
}
#--

#
# Baseline 2.2: Policy 6
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "A list of browsers that are not allowed to access files protected by DLP policy SHOULD be defined",
    "Control" : "Defender 2.2",
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.2 for instructions on manual check",
    "RequirementMet" : false,
    "PolicyId" : "defender-2.2.6",
    "TestId": "defender-2.2.6-t1"
}] {
    true
}
#--


################
# Baseline 2.3 #
################

#
# Baseline 2.3: Policy 1
#--
MalwarePoliciesWithoutFileFilter[Policy.Name] {
    Policy := input.malware_filter_policies[_]
    not Policy.EnableFileFilter
}

tests[{
    "Requirement" : "The common attachments filter SHALL be enabled in the default anti-malware policy and in all existing policies",
    "Control" : "Defender 2.3",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-MalwareFilterPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.3.1",
    "TestId": "defender-2.3.1-t1"
}] {
    Policies := MalwarePoliciesWithoutFileFilter
    ErrorMessage := "malware policy(ies) found that do(es) not have the common attachments filter enabled:"
    Status := count(Policies) == 0
}
#--

#
# Baseline 2.3: Policy 2
#--
# exe
MalwarePoliciesBlockingEXE[Policy.Name] {
    Policy := input.malware_filter_policies[_]
    Policy.EnableFileFilter
    "exe" in Policy.FileTypes
}

tests[{
    "Requirement" : "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked: exe files",
    "Control" : "Defender 2.3",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MalwareFilterPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.3.2",
    "TestId": "defender-2.3.2-t1"
}] {
    Policies := MalwarePoliciesBlockingEXE
    Status := count(Policies) > 0
    ErrorMessage := "No malware policies found that block .exe files."
}

# cmd
MalwarePoliciesBlockingCMD[Policy.Name] {
    Policy := input.malware_filter_policies[_]
    Policy.EnableFileFilter
    "cmd" in Policy.FileTypes
}

tests[{
    "Requirement" : "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked: cmd files",
    "Control" : "Defender 2.3",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MalwareFilterPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.3.2",
    "TestId": "defender-2.3.2-t2"
}] {
    Policies := MalwarePoliciesBlockingCMD
    Status := count(Policies) > 0
    ErrorMessage := "No malware policies found that block .cmd files."
}

# vbe
MalwarePoliciesBlockingVBE[Policy.Name] {
    Policy := input.malware_filter_policies[_]
    Policy.EnableFileFilter
    "vbe" in Policy.FileTypes
}

tests[{
    "Requirement" : "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked: vbe files",
    "Control" : "Defender 2.3",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MalwareFilterPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.3.2",
    "TestId": "defender-2.3.2-t3"
}] {
    Policies := MalwarePoliciesBlockingVBE
    Status := count(Policies) > 0
    ErrorMessage := "No malware policies found that block .vbe files."
}
#--


################
# Baseline 2.4 #
################

#
# Baseline 2.4: Policy 1
#--
MalwarePoliciesWithoutZAP[Policy.Name] {
    Policy := input.malware_filter_policies[_]
    not Policy.ZapEnabled
}

tests[{
    "Requirement" : "Zero-hour Auto Purge (ZAP) for malware SHOULD be enabled in the default anti-malware policy and in all existing custom policies",
    "Control" : "Defender 2.4",
    "Criticality" : "Should",
    "Commandlet" : ["Get-MalwareFilterPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.4.1",
    "TestId": "defender-2.4.1-t1"
}] {
    Policies := MalwarePoliciesWithoutZAP
    Status := count(Policies) == 0
    ErrorMessage := "malware policy(ies) found without ZAP for malware enabled:"
}
#--


################
# Baseline 2.5 #
################

#
# Baseline 2.5: Policy 1
#--
ProtectedUsersPolicies[{
    "Name" : Policy.Name,
	"Users" : Policy.TargetedUsersToProtect,
    "Action" : Policy.TargetedUserProtectionAction
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Enabled # filter out the disabled policies
    Policy.EnableTargetedUserProtection # filter out the policies that have impersonation protections disabled
    count(Policy.TargetedUsersToProtect) > 0 # filter out the policies that don't list any protected users
}

# assert that at least one of the enabled policies includes protected users
tests[{
    "Requirement" : "User impersonation protection SHOULD be enabled for key agency leaders",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.1",
    "TestId": "defender-2.5.1-t1"
}] {
    Policies := ProtectedUsersPolicies
    ErrorMessage := "No users are included for targeted user protection."
    Status := count(Policies) > 0
}
#--

#
# Baseline 2.5: Policy 2
#--
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
    "Requirement" : "Domain impersonation protection SHOULD be enabled for domains owned by the agency",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.2",
    "TestId": "defender-2.5.2-t1"
}] {
    Policies := ProtectedOrgDomainsPolicies
    Status := count(Policies) > 0
}
#--

#
# Baseline 2.5: Policy 3
#--
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
    "Requirement" : "Domain impersonation protection SHOULD be added for frequent partners",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), ErrorMessage),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.3",
    "TestId": "defender-2.5.3-t1"
}] {
    Policies := ProtectedCustomDomainsPolicies
    ErrorMessage := "The Custom Domains protection policies: Enabled, EnableTargetedDomainsProtection, and TargetedDomainsToProtect are not set correctly"
    Status := count(Policies) > 0
}
#--

#
# Baseline 2.5: Policy 4
#--
IntelligenceProtectionPolicies[{
    "Name" : Policy.Name,
	"IntelligenceProtection" : Policy.EnableMailboxIntelligenceProtection,
    "Action" : Policy.MailboxIntelligenceProtectionAction
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Enabled # filter out the disabled policies
    Policy.EnableMailboxIntelligenceProtection # filter out the policies that don't have intelligence protection enabled
}

# assert that at least one of the enabled policies includes
# intelligence protection
tests[{
    "Requirement" : "Intelligence for impersonation protection SHALL be enabled",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.4",
    "TestId": "defender-2.5.4-t1"
}] {
    Policies := IntelligenceProtectionPolicies
    Status := count(Policies) > 0
}
#--

#
# Baseline 2.5: Policy 5
#--
# Step 1: Default (SHALL)
tests[{
    "Requirement" : "Message action SHALL be set to quarantine if the message is detected as impersonated: users default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.TargetedUserProtectionAction,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.5",
    "TestId": "defender-2.5.5-t1"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.TargetedUserProtectionAction == "Quarantine"
}

tests[{
    "Requirement" : "Message action SHALL be set to quarantine if the message is detected as impersonated: domains default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.TargetedDomainProtectionAction,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.5",
    "TestId": "defender-2.5.5-t2"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.TargetedDomainProtectionAction == "Quarantine"
}

tests[{
    "Requirement" : "Message action SHALL be set to quarantine if the message is detected as impersonated: mailbox default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.MailboxIntelligenceProtectionAction,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.5",
    "TestId": "defender-2.5.5-t3"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.MailboxIntelligenceProtectionAction == "Quarantine"
}


# Step 2: non-default (SHOULD)
AntiPhishTargetedUserNotQuarantine[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    not Policy.Identity == "Office365 AntiPhish Default"
    not Policy.TargetedUserProtectionAction == "Quarantine"
}

tests[ {
    "Requirement" : "Message action SHOULD be set to quarantine if the message is detected as impersonated: users non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.5",
    "TestId": "defender-2.5.5-t4"
}] {
    Policies := AntiPhishTargetedUserNotQuarantine
    ErrorMessage := "non-default anti phish policy(ies) found where the action for messages detected as user impersonation is not quarantine:"
    Status := count(Policies) == 0
}

AntiPhishTargetedDomainNotQuarantine[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    not Policy.Identity == "Office365 AntiPhish Default"
    not Policy.TargetedDomainProtectionAction == "Quarantine"
}

tests[ {
    "Requirement" : "Message action SHOULD be set to quarantine if the message is detected as impersonated: domains non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.5",
    "TestId": "defender-2.5.5-t5"
}] {
    Policies := AntiPhishTargetedDomainNotQuarantine
    ErrorMessage := "non-default anti phish policy(ies) found where the action for messages detected as domain impersonation is not quarantine:"
    Status := count(Policies) == 0
}

AntiPhishMailIntNotQuarantine[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    not Policy.Identity == "Office365 AntiPhish Default"
    not Policy.MailboxIntelligenceProtectionAction == "Quarantine"
}

tests[ {
    "Requirement" : "Message action SHOULD be set to quarantine if the message is detected as impersonated: mailbox non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.5",
    "TestId": "defender-2.5.5-t6"
}] {
    Policies := AntiPhishMailIntNotQuarantine
    ErrorMessage := "non-default anti phish policy(ies) found where the action for messages flagged by mailbox intelligence is not quarantine:"
    Status := count(Policies) == 0
}

#
# Baseline 2.5: Policy 6
#--
# Previous test divided into two rules. In the baseline we specify
# that default policies SHALL and custom policies SHOULD. To
# represent this, we have two tests checking the default and the
# nondefault.
tests[ {
    "Requirement" : "Mail classified as spoofed SHALL be quarantined: default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.AuthenticationFailAction,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.6",
    "TestId": "defender-2.5.6-t1"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.AuthenticationFailAction == "Quarantine"
}

# Helper rule to get set of custom anti phishing policies where the
# AuthenticationFailAction is not set to quarantine
CustomAntiPhishSpoofNotQuarantine[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    Policy.Identity != "Office365 AntiPhish Default"
    Policy.AuthenticationFailAction != "Quarantine"
}

tests[ {
    "Requirement" : "Mail classified as spoofed SHOULD be quarantined: non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.6",
    "TestId": "defender-2.5.6-t2"
}] {
    ErrorMessage := "custom anti phish policy(ies) found where the action for spoofed emails is not set to quarantine:"
    Policies := CustomAntiPhishSpoofNotQuarantine
    Status := count(Policies) == 0
}
#--

#
# Baseline 2.5: Policy 7
#--
# First contact default policy
tests[ {
    "Requirement" : "All safety tips SHALL be enabled: first contact default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.EnableFirstContactSafetyTips,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t1"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.EnableFirstContactSafetyTips == true
}

# First contact non-default policies
CustomAntiPhishNoSafetyTips[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    Policy.Identity != "Office365 AntiPhish Default"
    not Policy.EnableFirstContactSafetyTips
}

tests[{
    "Requirement" : "All safety tips SHOULD be enabled: first contact non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t2"
}] {
    ErrorMessage := "custom anti phish policy(ies) found where first contact safety tips are not enabled:"
    Policies := CustomAntiPhishNoSafetyTips
    Status := count(Policies) == 0
}

# Similar users default policy
tests[{
    "Requirement" : "All safety tips SHALL be enabled: user impersonation default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.EnableSimilarUsersSafetyTips,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t3"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.EnableSimilarUsersSafetyTips == true
}

# Similar users non-default policies
CustomAntiPhishNoSimilarUserTips[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    Policy.Identity != "Office365 AntiPhish Default"
    not Policy.EnableSimilarUsersSafetyTips
}

tests[{
    "Requirement" : "All safety tips SHOULD be enabled: user impersonation non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t4"
}] {
    ErrorMessage := "custom anti phish policy(ies) found where similar user safety tips are not enabled:"
    Policies := CustomAntiPhishNoSimilarUserTips
    Status := count(Policies) == 0
}

# Similar domains default policy
tests[{
    "Requirement" : "All safety tips SHALL be enabled: domain impersonation default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.EnableSimilarDomainsSafetyTips,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t5"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.EnableSimilarDomainsSafetyTips == true
}

# Similar domains non-default policies
CustomAntiPhishNoSimilarDomainTips[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    Policy.Identity != "Office365 AntiPhish Default"
    not Policy.EnableSimilarDomainsSafetyTips
}

tests[{
    "Requirement" : "All safety tips SHOULD be enabled: domain impersonation non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t6"
}] {
    ErrorMessage := "custom anti phish policy(ies) found where similar domains safety tips are not enabled:"
    Policies := CustomAntiPhishNoSimilarDomainTips
    Status := count(Policies) == 0
}

# Unusual characters default policy
tests[{
    "Requirement" : "All safety tips SHALL be enabled: user impersonation unusual characters default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.EnableUnusualCharactersSafetyTips,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t7"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.EnableUnusualCharactersSafetyTips == true
}

# Unusual characters non-default policies
CustomAntiPhishNoUnusualCharTips[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    Policy.Identity != "Office365 AntiPhish Default"
    not Policy.EnableUnusualCharactersSafetyTips
}

tests[{
    "Requirement" : "All safety tips SHOULD be enabled: user impersonation unusual characters non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t8"
}] {
    ErrorMessage := "custom anti phish policy(ies) found where unusual character safety tips are not enabled:"
    Policies := CustomAntiPhishNoUnusualCharTips
    Status := count(Policies) == 0
}

# Via tag default policy
tests[{
    "Requirement" : "All safety tips SHALL be enabled: \"via\" tag default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.EnableViaTag,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t9"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.EnableViaTag == true
}

# Via tag non-default policies
CustomAntiPhishNoViaTagTips[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    Policy.Identity != "Office365 AntiPhish Default"
    not Policy.EnableViaTag
}

tests[{
    "Requirement" : "All safety tips SHOULD be enabled: \"via\" tag non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t10"
}] {
    ErrorMessage := "custom anti phish policy(ies) found where via tag is not enabled:"
    Policies := CustomAntiPhishNoViaTagTips
    Status := count(Policies) == 0
}

# Unauthenticated sender default policy
tests[{
    "Requirement" : "All safety tips SHALL be enabled: \"?\" for unauthenticated senders for spoof default policy",
    "Control" : "Defender 2.5",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policy.EnableUnauthenticatedSender,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t11"
}] {
    Policy := input.anti_phish_policies[_]
    Policy.Identity == "Office365 AntiPhish Default"
    Status := Policy.EnableUnauthenticatedSender == true
}

# Unauthenticated sender non-default policies
CustomAntiPhishNoUnauthSenderTips[Policy.Identity] {
    Policy := input.anti_phish_policies[_]
    # Ignore the standard preset security policy because we can't  change it in the tenant but it's always there.
    not regex.match("Standard Preset Security Policy[0-9]+", Policy.Identity)
    Policy.Identity != "Office365 AntiPhish Default"
    not Policy.EnableUnauthenticatedSender
}

tests[{
    "Requirement" : "All safety tips SHOULD be enabled: \"?\" for unauthenticated senders for spoof non-default policies",
    "Control" : "Defender 2.5",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AntiPhishPolicy"],
	"ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.5.7",
    "TestId": "defender-2.5.7-t12"
}] {
    ErrorMessage := "custom anti phish policy(ies) found where '?' for unauthenticated sender is not enabled:"
    Policies := CustomAntiPhishNoUnauthSenderTips
    Status := count(Policies) == 0
}
#--



################
# Baseline 2.6 #
################

#
# Baseline 2.6: Policy 1
#--
tests[{
    "Requirement" : "The bulk complaint level (BCL) threshold SHOULD be set to six or lower: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
	"ActualValue" : Policy.BulkThreshold,
	"ReportDetails" : ReportDetails(Status),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.6.1",
    "TestId": "defender-2.6.1-t1"
}] {
	Policy := input.hosted_content_filter_policies[_] # Refactor
    Policy.Identity == "Default"
    Status := Policy.BulkThreshold <= 6
}

CustomBulkThresholdWrong [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    Policy.BulkThreshold > 6
}

tests[{
    "Requirement" : "The bulk complaint level (BCL) threshold SHOULD be set to six or lower: non-default policies",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.6.1",
    "TestId": "defender-2.6.1-t2"
}] {
	ErrorMessage := "custom anti-spam policy(ies) found where bulk complaint level threshold is set to 7 or more:"
	Policies = CustomBulkThresholdWrong
	Status := count(Policies) == 0
}
#--

#
# Baseline 2.6: Policy 2
#--
# Step 1: The default policy (SHALL)
tests[{
    "Requirement" : "Spam SHALL be moved to either the junk email folder or the quarantine folder: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.SpamAction,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.2",
    "TestId": "defender-2.6.2-t1"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.SpamAction in ["Quarantine", "MoveToJmf"]
}

tests[{
    "Requirement" : "High confidence spam SHALL be moved to either the junk email folder or the quarantine folder: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.HighConfidenceSpamAction,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.2",
    "TestId": "defender-2.6.2-t2"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.HighConfidenceSpamAction in ["Quarantine", "MoveToJmf"]
}

# Step 2: The non-default policies (SHOULD)
CustomSpamActionWrong [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    not Policy.SpamAction in ["Quarantine", "MoveToJmf"]
}

tests[{
    "Requirement" : "Spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.2",
    "TestId": "defender-2.6.2-t3"
}] {
	ErrorMessage := "custom anti-spam policy(ies) found where spam is not being sent to the Quarantine folder or the Junk Mail Folder:"
	Policies = CustomSpamActionWrong
	Status := count(Policies) == 0
}

CustomHighConfidenceSpamActionWrong [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    not Policy.HighConfidenceSpamAction in ["Quarantine", "MoveToJmf"]
}

tests[{
    "Requirement" : "High confidence spam SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.2",
    "TestId": "defender-2.6.2-t4"
}] {
	ErrorMessage := "custom anti-spam policy(ies) found where high confidence spam is not being sent to the Quarantine folder or the Junk Mail Folder:"
	Policies = CustomHighConfidenceSpamActionWrong
	Status := count(Policies) == 0
}
#--

#
# Baseline 2.6: Policy 3
#--
# Step 1: The default policy (SHALL)
tests[{
    "Requirement" : "Phishing SHALL be quarantined: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.PhishSpamAction,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.3",
    "TestId": "defender-2.6.3-t1"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.PhishSpamAction == "Quarantine"
}

tests[{
    "Requirement" : "High confidence phishing SHALL be quarantined: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.HighConfidencePhishAction,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.3",
    "TestId": "defender-2.6.3-t2"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.HighConfidencePhishAction == "Quarantine"
}

# Step 2: The non-default policies (SHOULD)

CustomPhishSpamActionWrong [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    Policy.PhishSpamAction != "Quarantine"
}

tests[{
    "Requirement" : "Phishing SHOULD be quarantined: non-default policies",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.3",
    "TestId": "defender-2.6.3-t3"
}] {
    ErrorMessage := "custom anti-spam policy(ies) found where phishing isn't moved to the quarantine folder:"
    Policies = CustomPhishSpamActionWrong
    Status := count(Policies) == 0
}

CustomHighConfidencePhishActionWrong [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    Policy.HighConfidencePhishAction != "Quarantine"
}

tests[{
    "Requirement" : "High confidence phishing SHOULD be quarantined: non-default policies",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.3",
    "TestId": "defender-2.6.3-t4"
}] {
    ErrorMessage := "custom anti-spam policy(ies) found where high-confidence phishing isn't moved to quarantine folder:"
    Policies = CustomHighConfidencePhishActionWrong
    Status := count(Policies) == 0
}

#
# Baseline 2.6: Policy 4
#--
tests[{
    "Requirement" : "Bulk email SHOULD be moved to either the junk email folder or the quarantine folder: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.BulkSpamAction,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.4",
    "TestId": "defender-2.6.4-t1"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.BulkSpamAction in ["Quarantine", "MoveToJmf"]
}

CustomBulkSpamActionWrong [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    not Policy.BulkSpamAction in ["Quarantine", "MoveToJmf"]
}

tests[{
    "Requirement" : "Bulk email SHOULD be moved to either the junk email folder or the quarantine folder: non-default policies",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.4",
    "TestId": "defender-2.4.4-t2"
}] {
    ErrorMessage := "custom anti-spam policy(ies) found where bulk spam action is not Quarantine or Move to Junk Email Folder"
    Policies = CustomBulkSpamActionWrong
    Status := count(Policies) == 0
}
#--

#
# Baseline 2.6: Policy 5
#--
tests[{
    "Requirement" : "Spam in quarantine SHOULD be retained for at least 30 days: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.QuarantineRetentionPeriod,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.5",
    "TestId": "defender-2.6.5-t1"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.QuarantineRetentionPeriod == 30
}

CustomQuarantineRetentionPeriodWrong [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    Policy.QuarantineRetentionPeriod != 30
}

tests[{
    "Requirement" : "Spam in quarantine SHOULD be retained for at least 30 days: non-default policies",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.5",
    "TestId": "defender-2.6.5-t2"
}] {
    ErrorMessage := "custom anti-spam policy(ies) found where spam in quarantine isn't retained for 30 days:"
    Policies = CustomQuarantineRetentionPeriodWrong
    Status := count(Policies) == 0
}
#--

#
# Baseline 2.6: Policy 6
#--
tests[{
    "Requirement" : "Spam safety tips SHOULD be turned on: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.InlineSafetyTipsEnabled,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.6",
    "TestId": "defender-2.6.6-t1"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.InlineSafetyTipsEnabled
}

CustomInlineSafetyTipsDisabled [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    not Policy.InlineSafetyTipsEnabled
}

tests[{
    "Requirement" : "Spam safety tips SHOULD be turned on: non-default policies",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.6",
    "TestId": "defender-2.6.6-t2"
}] {
    ErrorMessage := "custom anti-spam policy(ies) found where spam safety tips is disabled:"
    Policies = CustomInlineSafetyTipsDisabled
    Status := count(Policies) == 0
}
#--

#
# Baseline 2.6: Policy 7
#--
# Step 1: The default policy (SHALL)
tests[{
    "Requirement" : "Zero-hour auto purge (ZAP) SHALL be enabled: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.ZapEnabled,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.7",
    "TestId": "defender-2.6.7-t1"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.ZapEnabled
}

tests[{
    "Requirement" : "Zero-hour auto purge (ZAP) SHALL be enabled for spam messages: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.SpamZapEnabled,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.7",
    "TestId": "defender-2.6.7-t2"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.SpamZapEnabled
}

tests[{
    "Requirement" : "Zero-hour auto purge (ZAP) SHALL be enabled for phishing: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policy.PhishZapEnabled,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.7",
    "TestId": "defender-2.6.7-t3"
}] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    Status := Policy.PhishZapEnabled
}

# Step 2: The non-default policies (SHOULD)
CustomZapDisabled [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    not Policy.ZapEnabled
}

tests[{
    "Requirement" : "Zero-hour auto purge (ZAP) SHOULD be enabled: non-default",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.7",
    "TestId": "defender-2.6.7-t4"
}] {
    ErrorMessage := "custom anti-spam policies found where Zero-hour auto purge is disabled:"
    Policies = CustomZapDisabled
    Status := count(Policies) == 0
}

CustomSpamZapDisabled [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    not Policy.SpamZapEnabled
}

tests[{
    "Requirement" : "Zero-hour auto purge (ZAP) SHOULD be enabled for Spam: non-default",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.7",
    "TestId": "defender-2.6.7-t5"
}] {
    ErrorMessage := "custom anti-spam policies found where Zero-hour auto purge for spam is disabled:"
    Policies = CustomSpamZapDisabled
    Status := count(Policies) == 0
}

CustomPhishZapDisabled [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    not Policy.PhishZapEnabled
}

tests[{
    "Requirement" : "Zero-hour auto purge (ZAP) SHOULD be enabled for phishing: non-default",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.7",
    "TestId": "defender-2.6.7-t6"
}] {
    ErrorMessage := "custom anti-spam policy(ies) found where Zero-hour auto purge for phishing is disabled:"
    Policies = CustomPhishZapDisabled
    Status := count(Policies) == 0
}
#--

#
# Baseline 2.6: Policy 8
#--
AllowedSenderDomainsNotEmpty [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity == "Default"
    count(Policy.AllowedSenderDomains) > 0
}
tests[{
    "Requirement" : "Allowed senders MAY be added but allowed domains SHALL NOT be added: default policy",
    "Control" : "Defender 2.6",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.8",
    "TestId": "defender-2.6.8-t1"
}] {
    ErrorMessage := "custom anti-spam policy(ies) found where there is at least one allowed sender domain:"
    Policies = AllowedSenderDomainsNotEmpty
    Status := count(Policies) == 0
}

AllowedSenderDomainsNotEmptyCustom [Policy.Identity] {
    Policy := input.hosted_content_filter_policies[_]
    Policy.Identity != "Default"
    count(Policy.AllowedSenderDomains) > 0
}
tests[{
    "Requirement" : "Allowed senders MAY be added but allowed domains SHOULD NOT be added: non-default",
    "Control" : "Defender 2.6",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedContentFilterPolicy"],
    "ActualValue" : Policies,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(Policies, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.6.8",
    "TestId": "defender-2.6.8-t2"
}] {
    ErrorMessage := "custom policy(ies) found where there is at least one allowed sender domain:"
    Policies = AllowedSenderDomainsNotEmptyCustom
    Status := count(Policies) == 0
}
#--


################
# Baseline 2.7 #
################

#
# Baseline 2.7: Policy 1
#--
AllDomainsSafeLinksPolicies[{
    "Identity" : Rule.SafeLinksPolicy,
    "RecipientDomains" : RecipientDomains}] {
    Rule := input.safe_links_rules[_]
    Rule.State == "Enabled"
    DomainNames := {Name.DomainName | Name = input.all_domains[_]}
    RecipientDomains := {Name | Name = Rule.RecipientDomainIs[_]}
    Difference := DomainNames - RecipientDomains # set difference
    count(Difference) == 0
}

tests[{
    "Requirement" : "The Safe Links Policy SHALL include all agency domains-and by extension-all users",
    "Control" : "Defender 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeLinksRule", "Get-AcceptedDomain"],
	"ActualValue" : AllDomainsSafeLinksPolicies,
    "ReportDetails" : ApplyLicenseWarning(CustomizeError(ReportDetails(Status), ErrorMessage)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.7.1",
    "TestId": "defender-2.7.1-t1"
}] {
	DomainNames := {Name.DomainName | Name = input.all_domains[_]}
    ErrorMessage := concat("", ["No policy found that applies to all domains: ", concat(", ", DomainNames)])
    Status := count(AllDomainsSafeLinksPolicies) > 0
}
#--

#
# Baseline 2.7: Policy 2
#--
EnableSafeLinksForEmailCorrect[Policy.Identity] {
    Policy := input.safe_links_policies[_]
    Policy.Identity != "Built-In Protection Policy"
    Policy.EnableSafeLinksForEmail == true
    Rule := input.safe_links_rules[_]
    Rule.SafeLinksPolicy == Policy.Identity
    Rule.State == "Enabled"
}

tests[{
    "Requirement" : "URL rewriting and malicious link click checking SHALL be enabled",
    "Control" : "Defender 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeLinksPolicy", "Get-SafeLinksRule"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetails(Status)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.7.2",
    "TestId": "defender-2.7.2-t1"
}] {
	Policies := EnableSafeLinksForEmailCorrect
    Status := count(Policies) >= 1
}
#--

#
# Baseline 2.7: Policy 3
#--
EnableSafeLinksForTeamsCorrect[Policy.Identity] {
    Policy := input.safe_links_policies[_]
    Policy.Identity != "Built-In Protection Policy"
    Policy.EnableSafeLinksForTeams == true
    Rule := input.safe_links_rules[_]
    Rule.SafeLinksPolicy == Policy.Identity
    Rule.State == "Enabled"
}

tests[{
    "Requirement" : "Malicious link click checking SHALL be enabled with Microsoft Teams",
    "Control" : "Defender 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeLinksPolicy", "Get-SafeLinksRule"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetails(Status)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.7.3",
    "TestId": "defender-2.7.3-t1"
}] {
	Policies := EnableSafeLinksForTeamsCorrect
    Status := count(Policies) >= 1
}
#--

#
# Baseline 2.7: Policy 4
#--
ScanUrlsCorrect[Policy.Identity] {
    Policy := input.safe_links_policies[_]
    Policy.Identity != "Built-In Protection Policy"
    Policy.ScanUrls == true
    Rule := input.safe_links_rules[_]
    Rule.SafeLinksPolicy == Policy.Identity
    Rule.State == "Enabled"
}

tests[{
    "Requirement" : "Real-time suspicious URL and file-link scanning SHALL be enabled",
    "Control" : "Defender 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeLinksPolicy", "Get-SafeLinksRule"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetails(Status)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.7.4",
    "TestId": "defender-2.7.4-t1"
}] {
	Policies := ScanUrlsCorrect
    Status := count(Policies) >= 1
}
#--

#
# Baseline 2.7: Policy 5
#--
DeliverMessageAfterScanCorrect[Policy.Identity] {
    Policy := input.safe_links_policies[_]
    Policy.Identity != "Built-In Protection Policy"
    Policy.DeliverMessageAfterScan == true
    Rule := input.safe_links_rules[_]
    Rule.SafeLinksPolicy == Policy.Identity
    Rule.State == "Enabled"
}

tests[{
    "Requirement" : "URLs SHALL be scanned completely before message delivery",
    "Control" : "Defender 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeLinksPolicy", "Get-SafeLinksRule"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetails(Status)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.7.5",
    "TestId": "defender-2.7.5-t1"
}] {
	Policies := DeliverMessageAfterScanCorrect
    Status := count(Policies) >= 1
}
#--

#
# Baseline 2.7: Policy 6
#--
EnableForInternalSendersCorrect[Policy.Identity] {
    Policy := input.safe_links_policies[_]
    Policy.Identity != "Built-In Protection Policy"
    Policy.EnableForInternalSenders == true
    Rule := input.safe_links_rules[_]
    Rule.SafeLinksPolicy == Policy.Identity
    Rule.State == "Enabled"
}

tests[{
    "Requirement" : "Internal agency email messages SHALL have safe links enabled",
    "Control" : "Defender 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeLinksPolicy", "Get-SafeLinksRule"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetails(Status)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.7.6",
    "TestId": "defender-2.7.6-t1"
}] {
	Policies := EnableForInternalSendersCorrect
    Status := count(Policies) >= 1
}
#--

#
# Baseline 2.7: Policy 7
#--
TrackClicksCorrect[Policy.Identity] {
    Policy := input.safe_links_policies[_]
    Policy.Identity != "Built-In Protection Policy"
    Policy.TrackClicks == true
    Rule := input.safe_links_rules[_]
    Rule.SafeLinksPolicy == Policy.Identity
    Rule.State == "Enabled"
}

tests[{
    "Requirement" : "User click tracking SHALL be enabled",
    "Control" : "Defender 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeLinksPolicy", "Get-SafeLinksRule"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetails(Status)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.7.7",
    "TestId": "defender-2.7.7-t1"
}] {
	Policies := TrackClicksCorrect
    Status := count(Policies) >= 1
}
#--

#
# Baseline 2.7: Policy 8
#--
EnableSafeLinksForOfficeCorrect[Policy.Identity] {
    Policy := input.safe_links_policies[_]
    Policy.EnableSafeLinksForOffice == true
    Rule := input.safe_links_rules[_]
    Rule.SafeLinksPolicy == Policy.Identity
    Rule.State == "Enabled"
}

tests[{
    "Requirement" : "Safe Links in Office 365 apps SHALL be turned on",
    "Control" : "Defender 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeLinksPolicy", "Get-SafeLinksRule"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetails(Status)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.7.8",
    "TestId": "defender-2.7.8-t1"
}] {
	Policies := EnableSafeLinksForOfficeCorrect
    Status := count(Policies) >= 1
}
#--

#
# Baseline 2.7: Policy 9
#--
AllowClickThroughCorrect[Policy.Identity] {
    Policy := input.safe_links_policies[_]
    Policy.AllowClickThrough == false
    Rule := input.safe_links_rules[_]
    Rule.SafeLinksPolicy == Policy.Identity
    Rule.State == "Enabled"
}

tests[{
    "Requirement" : "Users SHALL NOT be enabled to click through to the original URL",
    "Control" : "Defender 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeLinksPolicy", "Get-SafeLinksRule"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetails(Status)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.7.9",
    "TestId": "defender-2.7.9-t1"
}] {
	Policies := AllowClickThroughCorrect
    Status := count(Policies) >= 1
}
#--


################
# Baseline 2.8 #
################

#
# Baseline 2.8: Policy 1
#--
# find the set of policies that are applied to all of the tenant's domains
AllDomainsSafeAttachmentRules[{
    "SafeAttachmentPolicy" : Rule.SafeAttachmentPolicy,
    "RecipientDomains" : RecipientDomains}] {
    Rule := input.safe_attachment_rules[_]
    DomainNames = {Name.DomainName | Name = input.all_domains[_]}
    RecipientDomains = {Name | Name = Rule.RecipientDomainIs[_]}
    Difference := DomainNames - RecipientDomains # set difference
    count(Difference) == 0
}

tests[{
    "Requirement" : "At least one Safe Attachments Policy SHALL include all agency domains-and by extension-all users",
    "Control" : "Defender 2.8",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeAttachmentRule", "Get-AcceptedDomain"],
	"ActualValue" : AllDomainsSafeAttachmentRules,
    "ReportDetails" : ApplyLicenseWarning(CustomizeError(ReportDetails(Status), ErrorMessage)),
	"RequirementMet" : Status,
    "PolicyId" : "defender-2.8.1",
    "TestId": "defender-2.8.1-t1"
}] {
	DomainNames := {Name.DomainName | Name = input.all_domains[_]}
    ErrorMessage := concat("", ["No policy found that applies to all domains: ", concat(", ", DomainNames)])
    Status := count(AllDomainsSafeAttachmentRules) > 0
}
#--

#
# Baseline 2.8: Policy 2
#--
# Find the set of policies that:
# - have the action set to block
# - are enabled
# - and are one of the policies that apply to all domains
BlockMalwarePolicies[{
    "Identity" : SafeAttachmentPolicies.Identity,
    "Action" : SafeAttachmentPolicies.Action,
    "Enable" : SafeAttachmentPolicies.Enable,
    "RedirectAddress" : SafeAttachmentPolicies.RedirectAddress}] {
        SafeAttachmentPolicies := input.safe_attachment_policies[_]
        SafeAttachmentPolicies.Action == "Block"
        SafeAttachmentPolicies.Enable
        AllDomainsPoliciesNames := {Rule.SafeAttachmentPolicy | Rule = AllDomainsSafeAttachmentRules[_]}
        SafeAttachmentPolicies.Identity in AllDomainsPoliciesNames
}

tests[{
    "Requirement" : "The action for malware in email attachments SHALL be set to block",
    "Control" : "Defender 2.8",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SafeAttachmentPolicy", "Get-SafeAttachmentRule", "Get-AcceptedDomain"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(CustomizeError(ReportDetails(Status), ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.8.2",
    "TestId": "defender-2.8.2-t1"
}] {
    Policies := BlockMalwarePolicies
    ErrorMessage := "No enabled policy found with action set to block that apply to all domains"
    Status := count(Policies) > 0
}
#--

#
# Baseline 2.8: Policy 3
#--
# Find the set of policies that are blocking malware and have a
# redirection address specified
RedirectionPolicies[{
    "Identity" : Policy.Identity,
    "RedirectAddress" : Policy.RedirectAddress}] {
    Policy := BlockMalwarePolicies[_]
    Policy.RedirectAddress != ""
}

tests[{
    "Requirement" : "Redirect emails with detected attachments to an agency-specified email SHOULD be enabled",
    "Control" : "Defender 2.8",
    "Criticality" : "Should",
    "Commandlet" : ["Get-SafeAttachmentPolicy", "Get-SafeAttachmentRule", "Get-AcceptedDomain"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(CustomizeError(ReportDetails(Status), ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.8.3",
    "TestId": "defender-2.8.3-t1"
}] {
    Policies := RedirectionPolicies
    ErrorMessage := "No enabled policy found with action set to block and at least one contact specified"
    Status := count(Policies) > 0
}
#--

#
# Baseline 2.8: Policy 4
#--
# Find the set of policies that have EnableATPForSPOTeamsODB set to true
ATPPolicies[{
    "Identity" : Policy.Identity,
    "EnableATPForSPOTeamsODB" : Policy.EnableATPForSPOTeamsODB}] {
    Policy := input.atp_policy_for_o365[_]
    Policy.EnableATPForSPOTeamsODB == true
}

tests[{
    "Requirement" : "Safe attachments SHOULD be enabled for SharePoint, OneDrive, and Microsoft Teams",
    "Control" : "Defender 2.8",
    "Criticality" : "Should",
    "Commandlet" : ["Get-AtpPolicyForO365"],
	"ActualValue" : Policies,
    "ReportDetails" : ApplyLicenseWarning(ReportDetails(Status)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.8.4",
    "TestId": "defender-2.8.4-t1"
}] {
    Policies := ATPPolicies
    Status := count(Policies) > 0
}
#--


#################
# Baseline 2.9 #
#################

#
# Baseline 2.9: Policy 1
#--
# At a minimum, the alerts required by the EXO baseline SHALL be enabled.
RequiredAlerts := {
    "Suspicious email sending patterns detected",
    "Unusual increase in email reported as phish",
    "Suspicious Email Forwarding Activity",
    "Messages have been delayed",
    "Tenant restricted from sending unprovisioned email",
    "User restricted from sending email",
    "Malware campaign detected after delivery",
    "A potentially malicious URL click was detected",
    "Suspicious connector activity"
}

EnabledAlerts[Alert.Name] {
    Alert := input.protection_alerts[_]
    Alert.Disabled == false
}

tests[{
    "Requirement" : "At a minimum, the alerts required by the Exchange Online Minimum Viable Secure Configuration Baseline SHALL be enabled",
    "Control" : "Defender 2.9",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-ProtectionAlert"],
	"ActualValue" : MissingAlerts,
    "ReportDetails" : CustomizeError(ReportDetails(Status), GenerateArrayString(MissingAlerts, ErrorMessage)),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.9.1",
    "TestId": "defender-2.9.1-t1"
}] {
    MissingAlerts := RequiredAlerts - EnabledAlerts
    ErrorMessage := "disabled required alert(s) found:"
    Status := count(MissingAlerts) == 0
}
#--

#
# Baseline 2.9: Policy 2
#--
# SIEM incorporation cannot be checked programmatically
tests[{
    "Requirement" : "The alerts SHOULD be sent to a monitored address or incorporated into a SIEM",
    "Control" : "Defender 2.9",
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.9 for instructions on manual check",
    "RequirementMet" : false,
    "PolicyId" : "defender-2.9.2",
    "TestId": "defender-2.9.2-t1"
}] {
    true
}
#--


#################
# Baseline 2.10 #
#################

CorrectLogConfigs[{
    "Identity": AuditLog.Identity,
    "UnifiedAuditLogIngestionEnabled": AuditLog.UnifiedAuditLogIngestionEnabled
}] {
    AuditLog := input.admin_audit_log_config[_]
    AuditLog.UnifiedAuditLogIngestionEnabled == true
}

#
# Baseline 2.10: Policy 1
#--
tests[{
    "Requirement" : "Unified audit logging SHALL be enabled",
    "Control" : "Defender 2.10",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-AdminAuditLogConfig"],
	"ActualValue" : CorrectLogConfigs,
    "ReportDetails" : ReportDetails(Status),
    "RequirementMet" : Status,
    "PolicyId" : "defender-2.10.1",
    "TestId": "defender-2.10.1-t1"
}] {
    Status := count(CorrectLogConfigs) >= 1
}
#--

#
# Baseline 2.10: Policy 2
#--
# Turns out audit logging is non-trivial to implement and test for.
# Would require looping through all users. See discussion in GitHub
# issue #200.
tests[{
    "Requirement" : "Advanced audit SHALL be enabled",
    "Control" : "Defender 2.10",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.10 for instructions on manual check",
    "RequirementMet" : false,
    "PolicyId" : "defender-2.10.2",
    "TestId": "defender-2.10.2-t1"
}] {
    true
}
#--

#
# Baseline 2.10: Policy 3
#--
# Dictated by OMB M-21-31: 12 months in hot storage and 18 months in cold
# It is not required to maintain these logs in the M365 cloud environment; doing so would require an additional add-on SKU.
# This requirement can be met by offloading the logs out of the cloud environment.
tests[{
    "Requirement" : "Audit logs SHALL be maintained for at least the minimum duration dictated by OMB M-21-31",
    "Control" : "Defender 2.10",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.10 for instructions on manual check",
    "RequirementMet" : false,
    "PolicyId" : "defender-2.10.3",
    "TestId": "defender-2.10.3-t1"
}] {
    true
}
#--
