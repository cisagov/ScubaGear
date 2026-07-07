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
import data.utils.report.ReportDetailsArray
import data.utils.securitysuite.DLPLicenseWarningString
import data.utils.key.FilterArray


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
SensitiveRule |
    some SensitiveRule in SensitiveRules
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

tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-DlpComplianceRule"],
    "ActualValue": Rules,
    "ReportDetails": DLPLicenseWarningString(Status, ErrorMessage),
    "RequirementMet": Status 
} if {
    error_rule := "No matching rules found for:"
    ErrorMessage := concat(" ", [error_rule, concat(", ", error_rules)])
    Status := count(error_rules) == 0
}
#--

#
# MS.SECURITYSUITE.3.2v1
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
} |
    some Policy in input.dlp_compliance_policies
    some PolicyWithProtection in PoliciesWithFullProtection
    Policy.Name in PolicyWithProtection
    "All" in Policy[Location]
    contains(Policy.Workload, Name)
}

Policies := {
    "Exchange": ProductEnableSensitiveProtection("Exchange", "ExchangeLocation"),
    "SharePoint": ProductEnableSensitiveProtection("SharePoint", "SharePointLocation"),
    "OneDrive": ProductEnableSensitiveProtection("OneDriveForBusiness", "OneDriveLocation"),
    "Teams": ProductEnableSensitiveProtection("Teams", "TeamsLocation"),
    "Devices": ProductEnableSensitiveProtection("EndpointDevices", "EndpointDlpLocation")
}

# Create a set of locations missing from the set of policies
# protecting sensitive info types
MissingLocations contains "Exchange" if count(Policies.Exchange) == 0
MissingLocations contains "SharePoint" if count(Policies.SharePoint) == 0
MissingLocations contains "OneDrive" if count(Policies.OneDrive) == 0
MissingLocations contains "Teams" if count(Policies.Teams) == 0
MissingLocations contains "Devices" if count(Policies.Devices) == 0

# Empty license warning string when both Devices and Teams present
DLPLicenseWarning4_2(AbsentLocations) := LicenseWarning if {
    not "Devices" in AbsentLocations
    not "Teams" in AbsentLocations
    LicenseWarning := ""
}

DLPLicenseWarning4_2(AbsentLocations) := LicenseWarning if {
    # Add license warning when only Teams is missing
    not "Devices" in AbsentLocations
    "Teams" in AbsentLocations
    LicenseWarning := "Teams location requires DLP for Teams included in E5/G5 licenses."
}

DLPLicenseWarning4_2(AbsentLocations) := LicenseWarning if {
    # Add license warning when only Devices is missing
    "Devices" in AbsentLocations
    not "Teams" in AbsentLocations
    LicenseWarning := "Devices location requires DLP for Endpoint licensing and at least one registered device."
}

DLPLicenseWarning4_2(AbsentLocations) := LicenseWarning if {
    # Add both license warnings when Devices and Teams are missing
    "Devices" in AbsentLocations
    "Teams" in AbsentLocations
    LicenseWarning := concat(
        " ",
        [
            "Devices location requires DLP for Endpoint licensing and at least one registered device.",
            "Teams location requires DLP for Teams included in E5/G5 licenses."
        ]
    )
}

# Return results file path when no custom config defined
ResultsFilePath := Path if {
    not input.scuba_config.OutputPath
    not input.scuba_config.OutRegoFileName
    Path := "./RegoOutput.json"
}

# Return results file path when only file name is defined
ResultsFilePath := Path if {
    not input.scuba_config.OutputPath
    Filename := input.scuba_config.OutRegoFileName
    Path := concat("", ["./", Filename,".json"])
}

# Return results file path when only file path is defined
ResultsFilePath := Path if {
    not input.scuba_config.OutRegoFileName
    FilePath := input.scuba_config.OutputPath
    Path := concat("", [FilePath, "/RegoOutput",".json"])
}

# Return results file path when custom config defined
ResultsFilePath := Path if {
    input.scuba_config.OutputPath
    input.scuba_config.OutputRegoFileName
    Path := concat("", [
        input.scuba_config.OutPath, "/",
        input.scuba_config.OutRegoFileName,
        ".json"
    ])
}

# DLP policy contains at least one required location
ErrorMessage3_2(PresentLocations) := ErrorMessage if {
    count(PresentLocations) != 0
    LocationsAppliedMsg := "DLP custom policy applied to the following locations: "
    LocationsMissingMsg := ". Custom policy protecting sensitive info types NOT applied to: "
    LicenseNotice := DLPLicenseWarning4_2(MissingLocations)
    FullPolicyDetailsMsg := concat("", [
        " For full policy details, see the ActualValue field in the results file: ",
        ResultsFilePath
    ])
    ErrorMessage := concat("", [
        LocationsAppliedMsg, concat(", ", PresentLocations),
        LocationsMissingMsg, concat(", ", MissingLocations),
        ". ",
        LicenseNotice,
        FullPolicyDetailsMsg
    ])
}

# Matching DLP policy does not contain any of the required locations
ErrorMessage3_2(PresentLocations) := ErrorMessage if {
    count(PresentLocations) == 0
    LocationsMissingMsg := "Custom policy protecting sensitive info types NOT applied to: "
    LicenseNotice := DLPLicenseWarning4_2(MissingLocations)
    FullPolicyDetailsMsg := concat("", [
        " For full policy details, see the ActualValue field in the results file: ",
        ResultsFilePath
    ])
    ErrorMessage := concat("", [
        LocationsMissingMsg, concat(", ", MissingLocations),
        ". ",
        LicenseNotice,
        FullPolicyDetailsMsg
    ])
}

# If MissingLocations contains any value, then some M365 product does not
# have a policy protectig sensitive content & check should fail.
# Check should also fail if there are no policies that protect all sensitive
# content.

tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DLPCompliancePolicy"],
    "ActualValue": Policies,
    "ReportDetails": DLPLicenseWarningString(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    PresentLocations := {"Devices", "Exchange", "OneDrive", "SharePoint", "Teams"} - MissingLocations
    Conditions := [
        count(MissingLocations) == 0,
        input.defender_dlp_license == true
    ]
    ErrorMessage := ErrorMessage3_2(PresentLocations)
    Status := count(FilterArray(Conditions, false)) == 0
}
#--

#
# MS.SECURITYSUITE.3.3v1
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
ErrorMessage3_3(Rules) := ReportDetailsArray(false, Rules, ErrorMessage) if {
    count(PoliciesWithFullProtection) > 0
    ErrorMessage := "rule(s) found that do(es) not block access or associated policy not set to enforce block action:"
}

ErrorMessage3_3(_) := ErrorMessage if {
    count(PoliciesWithFullProtection) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

# if there is any policy that protects all sensitive content &
# does not block access, the check should fail. The check should
# also fail if there are no policies that protect all sensitive content.
tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpComplianceRule"],
    "ActualValue": SensitiveRulesNotBlocking,
    "ReportDetails": DLPLicenseWarningString(Status, ErrorMessage3_3(SensitiveRulesNotBlocking)),
    "RequirementMet": Status
} if {
    Conditions := [
        count(SensitiveRulesNotBlocking) == 0,
        count(PoliciesWithFullProtection) > 0
    ]
    Status := count(FilterArray(Conditions, true)) == 2
}
#--

#
# MS.SECURITYSUITE.3.4v1
#--
# Step 4: ensure that some user is notified in the event of a DLP violation
# Save policies that protect all sensitive content & do not have a user
# to notify,
SensitiveRulesNotNotifying contains Rule.Name if {
    some Rule in PoliciesWithFullProtection
    some _ in SensitiveRules
    Rule.ParentPolicyName in Rule
    count(Rule.NotifyUser) == 0
}

# Create the Report details message for policy
ErrorMessage3_4(Rules) := ReportDetailsArray(false, Rules, ErrorMessage) if {
    count(PoliciesWithFullProtection) > 0
    ErrorMessage := "rule(s) found that do(es) not notify at least one user:"
}

ErrorMessage3_4(_) := ErrorMessage if {
    count(PoliciesWithFullProtection) == 0
    ErrorMessage := "No DLP policy matching all types found for evaluation."
}

# if there is any policy that protects all sensitive content &
# does not have a user to notify, the check should fail. The check should
# also fail if there are no policies that protect all sensitive content.
tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.4v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpComplianceRule"],
    "ActualValue":  SensitiveRulesNotNotifying,
    "ReportDetails": DLPLicenseWarningString(Status, ErrorMessage3_4(SensitiveRulesNotNotifying)),
    "RequirementMet": Status
} if {
    Conditions := [
        count(SensitiveRulesNotNotifying) == 0,
        count(PoliciesWithFullProtection) > 0
    ]
    Status := count(FilterArray(Conditions, true)) == 2
}
#--

#
# MS.SECURITYSUITE.3.5v1
#--

# Return true when a DLP rule has the requested endpoint restriction set to Block.
EndpointRestrictionBlocks(Rule, Setting) if {
    some Restriction in object.get(Rule, "EndpointDlpRestrictions", [])

    Restriction.setting == Setting
    Restriction.value == "Block"
}

# Save the rule name if a single DLP Endpoint restriction rule blocks
# both restricted apps and unwanted Bluetooth transfer apps.
RulesBlockingUnallowedAppsAndBluetooth contains Rule.Name if {
    some Rule in input.dlp_compliance_rules

    EndpointRestrictionBlocks(Rule, "UnallowedApps")
    EndpointRestrictionBlocks(Rule, "UnallowedBluetoothTransferApps")
}

# Check tenant-level setting: Include Bluetooth apps recommended by Microsoft.
# This is retrieved from Get-PolicyConfig via endpoint_dlp_global_settings[0].value.
default BluetoothRecommendedAppsEnabled := false

BluetoothRecommendedAppsEnabled if {
    lower(sprintf("%v", [input.endpoint_dlp_global_settings[0].value])) == "true"
}

# Each case is mutually exclusive by RulesBlocking/BluetoothOK boolean arguments.
ErrorMessage3_5(false, false) := concat(" ", [
    "No DLP rule(s) found that block both unallowed apps and unallowed Bluetooth transfer apps.",
    "Tenant-level 'Include Bluetooth apps recommended by Microsoft' is not enabled in DLP settings."
])

ErrorMessage3_5(false, true) := "No DLP rule(s) found that block both unallowed apps and unallowed Bluetooth transfer apps."

ErrorMessage3_5(true, false) := "Tenant-level 'Include Bluetooth apps recommended by Microsoft' is not enabled in DLP settings."

ErrorMessage3_5(true, true) := ""

tests contains {
    "PolicyId": "MS.SECURITYSUITE.3.5v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DLPComplianceRule", "Get-PolicyConfig"],
    "ActualValue": {
        "RulesBlockingEndpointApps": RulesBlockingUnallowedAppsAndBluetooth,
        "BluetoothRecommendedAppsEnabled": BluetoothRecommendedAppsEnabled
    },
    "ReportDetails": DLPLicenseWarningString(Status, ErrorMsg),
    "RequirementMet": Status
} if {
    RulesBlocking := count(RulesBlockingUnallowedAppsAndBluetooth) > 0
    Conditions := [RulesBlocking, BluetoothRecommendedAppsEnabled]
    Status := count(FilterArray(Conditions, false)) == 0
    ErrorMsg := ErrorMessage3_5(RulesBlocking, BluetoothRecommendedAppsEnabled)
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
