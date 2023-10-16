package defender
import future.keywords

# TODO: Policy Id(s) needs to be resolved

#
# Policy 1
#--
test_ContentContainsSensitiveInformation_Correct_V1 if {
    PolicyId := "MS.DEFENDER.4.1v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Social Security Number (SSN)"},
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "Name": "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AdvancedRule_Correct_V2 if {
    PolicyId := "MS.DEFENDER.4.1v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  null,
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": true,
                "AdvancedRule": "{rn  'Version': '1.0',rn  'Condition': {rn    'Operator': 'And',rn    'SubConditions': [rn      {rn        'ConditionName': 'ContentContainsSensitiveInformation',rn        'Value': [rn          {rn            'Groups': [rn              {rn                'Name': 'Default',rn                'Operator': 'Or',rn                'Sensitivetypes': [rn                  {rn                    'Name': 'Credit Card Number',rn                    'Id': '50842eb7-edc8-4019-85dd-5a5c1f2bb085',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'High',rn                    'Minconfidence': 85,rn                    'Maxconfidence': 100rn                  },rn                  {rn                    'Name': 'U.S. Individual Taxpayer Identification Number (ITIN)',rn                    'Id': 'e55e2a32-f92d-4985-a35d-a0b269eb687b',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'Medium',rn                    'Minconfidence': 75,rn                    'Maxconfidence': 100rn                  },rn                  {rn                    'Name': 'U.S. Social Security Number (SSN)',rn                    'Id': 'a44669fe-0d48-453d-a9b1-2cc83f2cba77',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'Medium',rn                    'Minconfidence': 75,rn                    'Maxconfidence': 100rn                  }rn                ]rn              }rn            ],rn            'Operator': 'And'rn          }rn        ]rn      }rn    ]rn  }rn}",
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "SharePointLocation":  ["All"],
                "TeamsLocation":  ["All"],
                "EndpointDlpLocation":  ["All"],
                "OneDriveLocation":  ["All"],
                "Workload":  "Exchange, SharePoint, OneDriveForBusiness, Teams, EndpointDevices",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ContentContainsSensitiveInformation_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.4.1v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "Name": "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No matching rules found for: U.S. Social Security Number (SSN)"
}

test_ContentContainsSensitiveInformation_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.4.1v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Social Security Number (SSN)"},
                    {"name":  "Credit Card Number"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "Name": "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No matching rules found for: U.S. Individual Taxpayer Identification Number (ITIN)"
}

test_ContentContainsSensitiveInformation_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.4.1v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Social Security Number (SSN)"},
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "Name": "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No matching rules found for: Credit Card Number"
}

test_ContentContainsSensitiveInformation_Incorrect_V4 if {
    PolicyId := "MS.DEFENDER.4.1v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "Name": "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No matching rules found for: Credit Card Number, U.S. Individual Taxpayer Identification Number (ITIN), U.S. Social Security Number (SSN)"
}

#
# Policy 2
#--
test_Locations_Correct_V1 if {
    PolicyId := "MS.DEFENDER.4.2v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"},
                    {"name":  "U.S. Social Security Number (SSN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "SharePointLocation":  ["All"],
                "TeamsLocation":  ["All"],
                "EndpointDlpLocation":  ["All"],
                "OneDriveLocation":  ["All"],
                "Workload":  "Exchange, SharePoint, OneDriveForBusiness, Teams, EndpointDevices",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Locations_Correct_V2 if {
    PolicyId := "MS.DEFENDER.4.2v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  null,
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": true,
                "AdvancedRule": "{rn  'Version': '1.0',rn  'Condition': {rn    'Operator': 'And',rn    'SubConditions': [rn      {rn        'ConditionName': 'ContentContainsSensitiveInformation',rn        'Value': [rn          {rn            'Groups': [rn              {rn                'Name': 'Default',rn                'Operator': 'Or',rn                'Sensitivetypes': [rn                  {rn                    'Name': 'Credit Card Number',rn                    'Id': '50842eb7-edc8-4019-85dd-5a5c1f2bb085',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'High',rn                    'Minconfidence': 85,rn                    'Maxconfidence': 100rn                  },rn                  {rn                    'Name': 'U.S. Individual Taxpayer Identification Number (ITIN)',rn                    'Id': 'e55e2a32-f92d-4985-a35d-a0b269eb687b',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'Medium',rn                    'Minconfidence': 75,rn                    'Maxconfidence': 100rn                  },rn                  {rn                    'Name': 'U.S. Social Security Number (SSN)',rn                    'Id': 'a44669fe-0d48-453d-a9b1-2cc83f2cba77',rn                    'Mincount': 1,rn                    'Maxcount': -1,rn                    'Confidencelevel': 'Medium',rn                    'Minconfidence': 75,rn                    'Maxconfidence': 100rn                  }rn                ]rn              }rn            ],rn            'Operator': 'And'rn          }rn        ]rn      }rn    ]rn  }rn}",
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "SharePointLocation":  ["All"],
                "TeamsLocation":  ["All"],
                "EndpointDlpLocation":  ["All"],
                "OneDriveLocation":  ["All"],
                "Workload":  "Exchange, SharePoint, OneDriveForBusiness, Teams, EndpointDevices",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

# Policy exists, but Exchange location is null
test_Locations_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.4.2v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"},
                    {"name":  "U.S. Social Security Number (SSN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  [""],
                "SharePointLocation":  ["All"],
                "TeamsLocation":  ["All"],
                "EndpointDlpLocation":  ["All"],
                "OneDriveLocation":  ["All"],
                "Workload":  "SharePoint, OneDriveForBusiness, Teams, EndpointDevices",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found that applies to: Exchange"
}

# Policy exists, but SharePoint is not included
test_Locations_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.4.2v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"},
                    {"name":  "U.S. Social Security Number (SSN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "SharePointLocation":  [""],
                "TeamsLocation":  ["All"],
                "EndpointDlpLocation":  ["All"],
                "OneDriveLocation":  ["All"],
                "Workload":  "Exchange, OneDriveForBusiness, Teams, EndpointDevices",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found that applies to: SharePoint"
}

# Policy exists, but OneDrive location not included
test_Locations_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.4.2v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"},
                    {"name":  "U.S. Social Security Number (SSN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "SharePointLocation":  ["All"],
                "TeamsLocation":  ["All"],
                "EndpointDlpLocation":  ["All"],
                "OneDriveLocation":  [""],
                "Workload":  "Exchange, SharePoint, Teams, EndpointDevices",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found that applies to: OneDrive"
}

# Policy exists, but OneDrive location not included
test_Locations_Incorrect_V4 if {
    PolicyId := "MS.DEFENDER.4.2v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"},
                    {"name":  "U.S. Social Security Number (SSN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "SharePointLocation":  ["All"],
                "TeamsLocation":  [""],
                "EndpointDlpLocation":  ["All"],
                "OneDriveLocation":  ["All"],
                "Workload":  "Exchange, SharePoint, OneDriveForBusiness, EndpointDevices",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found that applies to: Teams"
}

# Policy exists, but Devices location not included
test_Locations_Incorrect_V5 if {
    PolicyId := "MS.DEFENDER.4.2v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"},
                    {"name":  "U.S. Social Security Number (SSN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "SharePointLocation":  ["All"],
                "TeamsLocation":  ["All"],
                "EndpointDlpLocation":  [""],
                "OneDriveLocation":  ["All"],
                "Workload":  "Exchange, SharePoint, OneDriveForBusiness, Teams",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found that applies to: Devices"
}

# Policy exists, but is not enabled
test_Locations_Incorrect_V6 if {
    PolicyId := "MS.DEFENDER.4.2v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"},
                    {"name":  "U.S. Social Security Number (SSN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "SharePointLocation":  ["All"],
                "TeamsLocation":  ["All"],
                "EndpointDlpLocation":  ["All"],
                "OneDriveLocation":  ["All"],
                "Workload":  "Exchange, SharePoint, OneDriveForBusiness, Teams, EndpointDevices",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found that applies to: Devices, Exchange, OneDrive, SharePoint, Teams"
}

# Policy exists and is enabled, but block rules are disabled
test_Locations_Incorrect_V7 if {
    PolicyId := "MS.DEFENDER.4.2v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
                    {"name":  "Credit Card Number"},
                    {"name":  "U.S. Social Security Number (SSN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : true,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "SharePointLocation":  ["All"],
                "TeamsLocation":  ["All"],
                "EndpointDlpLocation":  ["All"],
                "OneDriveLocation":  ["All"],
                "Workload":  "Exchange, SharePoint, OneDriveForBusiness, Teams, EndpointDevices",
                "Name":  "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found that applies to: Devices, Exchange, OneDrive, SharePoint, Teams"
}

#
# Policy 3
test_ContentContainsSensitiveInformation_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.4.3v1"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Social Security Number (SSN)"},
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
                ],
                "Name":  "Baseline Rule",
                "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
                "BlockAccess":  true,
                "BlockAccessScope":  "All",
                "NotifyUser":  [
                    "SiteAdmin",
                    "LastModifier",
                    "Owner"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "Name": "Default Office 365 DLP policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    Not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 rule(s) found that do(es) not block access or associated policy not set to enforce block action: Baseline Rule"
}
#--
# test_BlockAccess_Correct if {
#     ControlNumber := "Defender 2.2"
#     Requirement := "The action for the DLP policy SHOULD be set to block sharing sensitive information with everyone when DLP conditions are met"

#     Output := tests with input as {
#         "dlp_compliance_rules": [
#             {
#                 "ContentContainsSensitiveInformation":  [
#                     {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
#                 ],
#                 "Name":  "Baseline Rule",
# 	            "Disabled" : false,
#                 "ParentPolicyName":  "Default Office 365 DLP policy",
# 	            "BlockAccess":  true,
#                 "BlockAccessScope":  "All",
# 	            "NotifyUser":  [
#                     "SiteAdmin",
#                     "LastModifier",
#                     "Owner"
#                 ],
# 	            "NotifyUserType":  "NotSet"
#             }
#         ],
#         "dlp_compliance_policies": [
#             {
#                 "Name": "Default Office 365 DLP policy",
#                 "Mode": "Enable",
#                 "Enabled": true
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_BlockAccess_IncorrectV1 if {
#     ControlNumber := "Defender 2.2"
#     Requirement := "The action for the DLP policy SHOULD be set to block sharing sensitive information with everyone when DLP conditions are met"

#     Output := tests with input as {
#         "dlp_compliance_rules": [
#             {
#                 "ContentContainsSensitiveInformation":  [
#                     {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
#                 ],
#                 "Name":  "Baseline Rule",
# 	            "Disabled" : false,
#                 "ParentPolicyName":  "Default Office 365 DLP policy",
# 	            "BlockAccess":  false,
#                 "BlockAccessScope":  "All",
# 	            "NotifyUser":  [
#                     "SiteAdmin",
#                     "LastModifier",
#                     "Owner"
#                 ],
# 	            "NotifyUserType":  "NotSet"
#             }
#         ],
#         "dlp_compliance_policies": [
#             {
#                 "Name": "Default Office 365 DLP policy",
#                 "Mode": "Enable",
#                 "Enabled": true
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "1 rule(s) found that do(es) not block access or associated policy not set to enforce block action: Baseline Rule"
# }

# test_BlockAccess_IncorrectV2 if {
#     ControlNumber := "Defender 2.2"
#     Requirement := "The action for the DLP policy SHOULD be set to block sharing sensitive information with everyone when DLP conditions are met"

#     Output := tests with input as {
#         "dlp_compliance_rules": [
#             {
#                 "ContentContainsSensitiveInformation":  [
#                     {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
#                 ],
#                 "Name":  "Baseline Rule",
# 	            "Disabled" : false,
#                 "ParentPolicyName":  "Default Office 365 DLP policy",
# 	            "BlockAccess":  true,
#                 "BlockAccessScope":  "All",
# 	            "NotifyUser":  [
#                     "SiteAdmin",
#                     "LastModifier",
#                     "Owner"
#                 ],
# 	            "NotifyUserType":  "NotSet"
#             }
#         ],
#         "dlp_compliance_policies": [
#             {
#                 "Name": "Default Office 365 DLP policy",
#                 "Mode": "TestWithNotifications",
#                 "Enabled": true
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "1 rule(s) found that do(es) not block access or associated policy not set to enforce block action: Baseline Rule"
# }

#
# Policy 4
#--
# test_NotifyUser_Correct_V1 if {
#     ControlNumber := "Defender 2.2"
#     Requirement := "Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled"

#     Output := tests with input as {
#         "dlp_compliance_rules": [
#             {
#                 "ContentContainsSensitiveInformation":  [
#                     {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
#                 ],
#                 "Name":  "Baseline Rule",
# 	            "Disabled" : false,
#                 "ParentPolicyName":  "Default Office 365 DLP policy",
# 	            "BlockAccess":  true,
#                 "BlockAccessScope":  "All",
# 	            "NotifyUser":  [
#                     "SiteAdmin"
#                 ],
# 	            "NotifyUserType":  "NotSet"
#             }
#         ],
#         "dlp_compliance_policies": [
#             {
#                 "Name": "Default Office 365 DLP policy",
#                 "Mode": "Enable",
#                 "Enabled": true
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_NotifyUser_Correct_V2 if {
#     ControlNumber := "Defender 2.2"
#     Requirement := "Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled"

#     Output := tests with input as {
#         "dlp_compliance_rules": [
#             {
#                 "ContentContainsSensitiveInformation":  [
#                     {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
#                 ],
#                 "Name":  "Baseline Rule",
# 	            "Disabled" : false,
#                 "ParentPolicyName":  "Default Office 365 DLP policy",
# 	            "BlockAccess":  true,
#                 "BlockAccessScope":  "All",
# 	            "NotifyUser":  [
#                     "SiteAdmin",
#                     "LastModifier",
#                     "Owner"
#                 ],
# 	            "NotifyUserType":  "NotSet"
#             }
#         ],
#         "dlp_compliance_policies": [
#             {
#                 "Name": "Default Office 365 DLP policy",
#                 "Mode": "Enable",
#                 "Enabled": true
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_NotifyUser_Incorrect if {
#     ControlNumber := "Defender 2.2"
#     Requirement := "Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled"

#     Output := tests with input as {
#         "dlp_compliance_rules": [
#             {
#                 "ContentContainsSensitiveInformation":  [
#                     {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
#                 ],
#                 "Name":  "Baseline Rule",
# 	            "Disabled" : false,
#                 "ParentPolicyName":  "Default Office 365 DLP policy",
# 	            "BlockAccess":  true,
#                 "BlockAccessScope":  "All",
# 	            "NotifyUser":  [ ],
# 	            "NotifyUserType":  "NotSet"
#             }
#         ],
#         "dlp_compliance_policies": [
#             {
#                 "Name": "Default Office 365 DLP policy",
#                 "Mode": "Enable",
#                 "Enabled": true
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "1 rule(s) found that do(es) not notify at least one user: Baseline Rule"
# }

#
# Policy 5
#--
# test_NotImplemented_Correct_V1 if {
#     ControlNumber := "Defender 2.2"
#     PolicyId := "TBD"
#     Requirement := "A list of apps that are not allowed to access files protected by DLP policy SHOULD be defined"

#     Output := tests with input as { }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == sprintf("Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy %v for instructions on manual check", [PolicyId])
# }

#
# Policy 6
#--
# test_NotImplemented_Correct_V2 if {
#     ControlNumber := "Defender 2.2"
#     PolicyId := "TBD"
#     Requirement := "A list of browsers that are not allowed to access files protected by DLP policy SHOULD be defined"

#     Output := tests with input as { }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == sprintf("Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy %v for instructions on manual check", [PolicyId])
# }
