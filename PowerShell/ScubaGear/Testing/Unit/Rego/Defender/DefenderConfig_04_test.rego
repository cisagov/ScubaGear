package defender_test

import data.defender
import data.utils.defender.DLPLICENSEWARNSTR
import data.utils.key.FAIL
import data.utils.key.PASS
import data.utils.key.TestResult
import data.utils.report.NotCheckedDetails
import rego.v1

#
# Policy MS.DEFENDER.4.1v1
#--
test_ContentContainsSensitiveInformation_Correct_V1 if {
    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    TestResult("MS.DEFENDER.4.1v1", Output, PASS, true) == true
}

test_AdvancedRule_Correct_V2 if {
    # regal ignore:line-length
    AdvancedRule := "{rn  'Version': '1.0',rn  'Condition': {rn    'Operator': 'And',rn    'SubConditions': [rn      {rn        'ConditionName': 'ContentContainsSensitiveInformation',rn        'Value': [rn          {rn            'Groups': [rn              {rn                'Name': 'Default',rn                'Operator': 'Or',rn                'Sensitivetypes': [rn                  {rn                    'Name': 'Credit Card Number',rn                    'Id': '50842eb7-edc8-4019-85dd-5a5c1f2bb085',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'High',rn                    'Minconfidence': 85,rn                    'Maxconfidence': 100rn                  },rn                  {rn                    'Name': 'U.S. Individual Taxpayer Identification Number (ITIN)',rn                    'Id': 'e55e2a32-f92d-4985-a35d-a0b269eb687b',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'Medium',rn                    'Minconfidence': 75,rn                    'Maxconfidence': 100rn                  },rn                  {rn                    'Name': 'U.S. Social Security Number (SSN)',rn                    'Id': 'a44669fe-0d48-453d-a9b1-2cc83f2cba77',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'Medium',rn                    'Minconfidence': 75,rn                    'Maxconfidence': 100rn                  }rn                ]rn              }rn            ],rn            'Operator': 'And'rn          }rn        ]rn      }rn    ]rn  }rn}"
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "ContentContainsSensitiveInformation", "value": null},
                                {"op": "add", "path": "IsAdvancedRule", "value": true},
                                {"op": "add", "path": "AdvancedRule", "value": AdvancedRule}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    TestResult("MS.DEFENDER.4.1v1", Output, PASS, true) == true
}

test_ContentContainsSensitiveInformation_Incorrect_V1 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "remove", "path": "ContentContainsSensitiveInformation/0"}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := "No matching rules found for: U.S. Social Security Number (SSN)"
    TestResult("MS.DEFENDER.4.1v1", Output, ReportDetailString, false) == true
}

test_ContentContainsSensitiveInformation_Incorrect_V2 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "remove", "path": "ContentContainsSensitiveInformation/1"}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := "No matching rules found for: U.S. Individual Taxpayer Identification Number (ITIN)"
    TestResult("MS.DEFENDER.4.1v1", Output, ReportDetailString, false) == true
}

test_ContentContainsSensitiveInformation_Incorrect_V3 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "remove", "path": "ContentContainsSensitiveInformation/2"}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := "No matching rules found for: Credit Card Number"
    TestResult("MS.DEFENDER.4.1v1", Output, ReportDetailString, false) == true
}

test_ContentContainsSensitiveInformation_Incorrect_V4 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "ContentContainsSensitiveInformation", "value": []}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat(" ", [
        "No matching rules found for: Credit Card Number,",
        "U.S. Individual Taxpayer Identification Number (ITIN), U.S. Social Security Number (SSN)"
    ])

    TestResult("MS.DEFENDER.4.1v1", Output, ReportDetailString, false) == true
}

test_ContentContainsSensitiveInformation_Incorrect_V5 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "Enabled", "value": false}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat(" ", [
        "No matching rules found for: Credit Card Number,",
        "U.S. Individual Taxpayer Identification Number (ITIN), U.S. Social Security Number (SSN)"
    ])

    TestResult("MS.DEFENDER.4.1v1", Output, ReportDetailString, false) == true
}

test_ContentContainsSensitiveInformation_Incorrect_V6 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "Mode", "value": "TestWithNotifications"}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat(" ", [
        "No matching rules found for: Credit Card Number,",
        "U.S. Individual Taxpayer Identification Number (ITIN), U.S. Social Security Number (SSN)"
    ])

    TestResult("MS.DEFENDER.4.1v1", Output, ReportDetailString, false) == true
}

test_NoDLPLicense_Incorrect_4_1_V1 if {
    Output := defender.tests with input.defender_license as false
                            with input.defender_dlp_license as false

    ReportDetailString := concat(" ", [FAIL, DLPLICENSEWARNSTR])
    TestResult("MS.DEFENDER.4.1v1", Output, ReportDetailString, false) == true
}

#--

#
# Policy MS.DEFENDER.4.2v1
#--
test_Locations_Correct_V1 if {
    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    TestResult("MS.DEFENDER.4.2v1", Output, PASS, true) == true
}

test_Locations_Correct_V2 if {
    # regal ignore:line-length
    AdvancedRule := "{rn  'Version': '1.0',rn  'Condition': {rn    'Operator': 'And',rn    'SubConditions': [rn      {rn        'ConditionName': 'ContentContainsSensitiveInformation',rn        'Value': [rn          {rn            'Groups': [rn              {rn                'Name': 'Default',rn                'Operator': 'Or',rn                'Sensitivetypes': [rn                  {rn                    'Name': 'Credit Card Number',rn                    'Id': '50842eb7-edc8-4019-85dd-5a5c1f2bb085',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'High',rn                    'Minconfidence': 85,rn                    'Maxconfidence': 100rn                  },rn                  {rn                    'Name': 'U.S. Individual Taxpayer Identification Number (ITIN)',rn                    'Id': 'e55e2a32-f92d-4985-a35d-a0b269eb687b',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'Medium',rn                    'Minconfidence': 75,rn                    'Maxconfidence': 100rn                  },rn                  {rn                    'Name': 'U.S. Social Security Number (SSN)',rn                    'Id': 'a44669fe-0d48-453d-a9b1-2cc83f2cba77',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'Medium',rn                    'Minconfidence': 75,rn                    'Maxconfidence': 100rn                  }rn                ]rn              }rn            ],rn            'Operator': 'And'rn          }rn        ]rn      }rn    ]rn  }rn}"
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "ContentContainsSensitiveInformation", "value": null},
                                {"op": "add", "path": "IsAdvancedRule", "value": true},
                                {"op": "add", "path": "AdvancedRule", "value": AdvancedRule}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    TestResult("MS.DEFENDER.4.2v1", Output, PASS, true) == true
}

test_Locations_Correct_V3 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "Name", "value": "Baseline Rule 2"},
                                {"op": "add", "path": "ParentPolicyName", "value": "Some Office 365 DLP policy"}])
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "Name", "value": "Some Office 365 DLP policy"}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules, DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies, DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    TestResult("MS.DEFENDER.4.2v1", Output, PASS, true) == true
}

# Policy exists, but Exchange location is null
test_Locations_Incorrect_V1 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "ExchangeLocation", "value": [""]}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat("", [
        "DLP custom policy applied to the following locations: Devices, OneDrive, SharePoint, Teams",
        ". Custom policy protecting sensitive info types NOT applied to: Exchange",
        ".  For full policy details, see the ActualValue field in the results file: ./TestResults.json"
    ])

    TestResult("MS.DEFENDER.4.2v1", Output, ReportDetailString, false) == true
}

# Policy exists, but SharePoint is not included
test_Locations_Incorrect_V2 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "SharePointLocation", "value": [""]}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat("", [
        "DLP custom policy applied to the following locations: Devices, Exchange, OneDrive, Teams",
        ". Custom policy protecting sensitive info types NOT applied to: SharePoint",
        ".  For full policy details, see the ActualValue field in the results file: ./TestResults.json"
    ])

    TestResult("MS.DEFENDER.4.2v1", Output, ReportDetailString, false) == true
}

# Policy exists, but OneDrive location not included
test_Locations_Incorrect_V3 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "OneDriveLocation", "value": [""]}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat("", [
        "DLP custom policy applied to the following locations: Devices, Exchange, SharePoint, Teams",
        ". Custom policy protecting sensitive info types NOT applied to: OneDrive",
        ".  For full policy details, see the ActualValue field in the results file: ./TestResults.json"
    ])

    TestResult("MS.DEFENDER.4.2v1", Output, ReportDetailString, false) == true
}

# Policy exists, but Teams location not included
test_Locations_Incorrect_V4 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "TeamsLocation", "value": [""]}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat("", [
        "DLP custom policy applied to the following locations: Devices, Exchange, OneDrive, SharePoint",
        ". Custom policy protecting sensitive info types NOT applied to: Teams",
        ". Teams location requires DLP for Teams included in E5/G5 licenses",
        ". For full policy details, see the ActualValue field in the results file: ./TestResults.json"
    ])

    TestResult("MS.DEFENDER.4.2v1", Output, ReportDetailString, false) == true
}

# Policy exists, but Devices location not included
test_Locations_Incorrect_V5 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "EndpointDlpLocation", "value": [""]}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat("", [
        "DLP custom policy applied to the following locations: Exchange, OneDrive, SharePoint, Teams",
        ". Custom policy protecting sensitive info types NOT applied to: Devices",
        ". Devices location requires DLP for Endpoint licensing and at least one registered device",
        ". For full policy details, see the ActualValue field in the results file: ./TestResults.json"
    ])

    TestResult("MS.DEFENDER.4.2v1", Output, ReportDetailString, false) == true
}

# Policy exists, but is not enabled
test_Locations_Incorrect_V6 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "Enabled", "value": false}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat("", [
        "Custom policy protecting sensitive info types NOT applied to: Devices, Exchange, OneDrive, SharePoint, Teams",
        ". Devices location requires DLP for Endpoint licensing and at least one registered device",
        ". Teams location requires DLP for Teams included in E5/G5 licenses",
        ". For full policy details, see the ActualValue field in the results file: ./TestResults.json"
    ])
    TestResult("MS.DEFENDER.4.2v1", Output, ReportDetailString, false) == true
}

# Policy exists and is enabled, but block rules are disabled
test_Locations_Incorrect_V7 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "Disabled", "value": true}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat("", [
        "Custom policy protecting sensitive info types NOT applied to: Devices, Exchange, OneDrive, SharePoint, Teams",
        ". Devices location requires DLP for Endpoint licensing and at least one registered device",
        ". Teams location requires DLP for Teams included in E5/G5 licenses",
        ". For full policy details, see the ActualValue field in the results file: ./TestResults.json"
    ])

    TestResult("MS.DEFENDER.4.2v1", Output, ReportDetailString, false) == true
}

# Policy exists but set to TestWithNotifications rather than Enable
test_Locations_Incorrect_V8 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "Mode", "value": "TestWithNotifications"}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat("", [
        "Custom policy protecting sensitive info types NOT applied to: Devices, Exchange, OneDrive, SharePoint, Teams",
        ". Devices location requires DLP for Endpoint licensing and at least one registered device",
        ". Teams location requires DLP for Teams included in E5/G5 licenses",
        ". For full policy details, see the ActualValue field in the results file: ./TestResults.json"
    ])

    TestResult("MS.DEFENDER.4.2v1", Output, ReportDetailString, false) == true
}

test_NoDLPLicense_Incorrect_4_2_V1 if {
    Output := defender.tests with input.defender_license as false
                            with input.defender_dlp_license as false

    ReportDetailString := concat(" ", [FAIL, DLPLICENSEWARNSTR])
    TestResult("MS.DEFENDER.4.2v1", Output, ReportDetailString, false) == true
}

#--

#
# Policy MS.DEFENDER.4.3v1
#--

# All sensitive rules present and blocking
test_BlockAccess_Correct_V1 if {
    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    TestResult("MS.DEFENDER.4.3v1", Output, PASS, true) == true
}

# Sensitive rules present, but not blocking
test_BlockAccess_Incorrect_V1 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "BlockAccess", "value": false}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat(" ", [
        "1 rule(s) found that do(es) not block access or",
        "associated policy not set to enforce block action: Baseline Rule"
    ])

    TestResult("MS.DEFENDER.4.3v1", Output, ReportDetailString, false) == true
}

# Sensitive rules present and blocking, but only to people outside org
test_BlockAccess_Incorrect_V2 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "BlockAccessScope", "value": "PerUser"}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := concat(" ", [
        "1 rule(s) found that do(es) not block access or associated policy not set to enforce block action:",
        "Baseline Rule"
    ])

    TestResult("MS.DEFENDER.4.3v1", Output, ReportDetailString, false) == true
}

# Sensitive rules present and blocking, but policy set to test
test_BlockAccess_Incorrect_V3 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "Mode", "value": "TestWithNotifications"}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := "No DLP policy matching all types found for evaluation."
    TestResult("MS.DEFENDER.4.3v1", Output, ReportDetailString, false) == true
}

# All rules are blocking, but don't contain all sensitive types
test_BlockAccess_Incorrect_V4 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "remove", "path": "ContentContainsSensitiveInformation/2"}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := "No DLP policy matching all types found for evaluation."
    TestResult("MS.DEFENDER.4.3v1", Output, ReportDetailString, false) == true
}

# Multiple policies combined that contain all sensitive rules blocking
test_BlockAccess_Incorrect_V5 if {
    DlpComplianceRule1 := json.patch(DlpComplianceRules,
                                [{"op": "remove", "path": "ContentContainsSensitiveInformation/1"}])
    DlpComplianceRule2 := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "ContentContainsSensitiveInformation",
                                    "value": [{"name": "U.S. Individual Taxpayer Identification Number (ITIN)"}]}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule1, DlpComplianceRule2]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := "No DLP policy matching all types found for evaluation."
    TestResult("MS.DEFENDER.4.3v1", Output, ReportDetailString, false) == true
}

test_BlockAccess_Incorrect_V6 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "Enabled", "value": false}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := "No DLP policy matching all types found for evaluation."
    TestResult("MS.DEFENDER.4.3v1", Output, ReportDetailString, false) == true
}

test_NoDLPLicense_Incorrect_4_3_V1 if {
    Output := defender.tests with input.defender_license as false
                            with input.defender_dlp_license as false

    ReportDetailString := concat(" ", [FAIL, DLPLICENSEWARNSTR])
    TestResult("MS.DEFENDER.4.3v1", Output, ReportDetailString, false) == true
}

#--

#
# Policy MS.DEFENDER.4.4v1
#--

# Sensitive policy present, and set to notify site admin
test_NotifyUser_Correct_V1 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "NotifyUser", "value": ["SiteAdmin"]}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    TestResult("MS.DEFENDER.4.4v1", Output, PASS, true) == true
}

# Sensitive policy present, and set to notify multiple users
test_NotifyUser_Correct_V2 if {
    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    TestResult("MS.DEFENDER.4.4v1", Output, PASS, true) == true
}

# Sensitive policy not enabled
test_NotifyUser_Incorrect_V1 if {
    DlpCompliancePolicy := json.patch(DlpCompliancePolicies,
                                [{"op": "add", "path": "Enabled", "value": false}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRules]
                            with input.dlp_compliance_policies as [DlpCompliancePolicy]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := "No DLP policy matching all types found for evaluation."
    TestResult("MS.DEFENDER.4.4v1", Output, ReportDetailString, false) == true
}

# Sensitive policy enabled, no users set to notify
test_NotifyUser_Incorrect_V2 if {
    DlpComplianceRule := json.patch(DlpComplianceRules,
                                [{"op": "add", "path": "NotifyUser", "value": []}])

    Output := defender.tests with input.dlp_compliance_rules as [DlpComplianceRule]
                            with input.dlp_compliance_policies as [DlpCompliancePolicies]
                            with input.scuba_config as ScubaConfig
                            with input.defender_license as true
                            with input.defender_dlp_license as true

    ReportDetailString := "1 rule(s) found that do(es) not notify at least one user: Baseline Rule"
    TestResult("MS.DEFENDER.4.4v1", Output, ReportDetailString, false) == true
}

test_NoDLPLicense_Incorrect_4_4_V1 if {
    Output := defender.tests with input.defender_license as false
                            with input.defender_dlp_license as false

    ReportDetailString := concat(" ", [FAIL, DLPLICENSEWARNSTR])
    TestResult("MS.DEFENDER.4.4v1", Output, ReportDetailString, false) == true
}

#--

#
# Policy MS.DEFENDER.4.5v1
#--
test_NotImplemented_Correct_V1 if {
    PolicyId := "MS.DEFENDER.4.5v1"

    Output := defender.tests with input as {}

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}

#--

#
# Policy MS.DEFENDER.4.6v1
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.DEFENDER.4.6v1"

    Output := defender.tests with input as {}

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}

#--
