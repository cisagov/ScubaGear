package defender
import future.keywords
import data.report.utils.NotCheckedDetails

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

test_ContentContainsSensitiveInformation_Incorrect_V5 if {
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
                "Enabled": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No matching rules found for: Credit Card Number, U.S. Individual Taxpayer Identification Number (ITIN), U.S. Social Security Number (SSN)"
}

test_ContentContainsSensitiveInformation_Incorrect_V6 if {
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
                "Mode": "TestWithNotifications",
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
    RuleOutput[0].ReportDetails == "No DLP policy matching all types found for evaluation."
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
    RuleOutput[0].ReportDetails == "No DLP policy matching all types found for evaluation."
}

# Policy exists but set to TestWithNotifications rather than Enable
test_Locations_Incorrect_V8 if {
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
                "Mode": "TestWithNotifications",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No DLP policy matching all types found for evaluation."
}

#
# Policy 3

# All sensitive rules present and blocking
test_BlockAccess_Correct_V1 if {
    PolicyId := "MS.DEFENDER.4.3v1"

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

# Sensitive rules present, but not blocking
test_BlockAccess_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.4.3v1"

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
                "BlockAccess":  false,
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
    RuleOutput[0].ReportDetails == "1 rule(s) found that do(es) not block access or associated policy not set to enforce block action: Baseline Rule"
}

# Sensitive rules present and blocking, but only to people outside org
test_BlockAccess_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.4.3v1"

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
                "BlockAccessScope":  "PerUser",
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
    RuleOutput[0].ReportDetails == "1 rule(s) found that do(es) not block access or associated policy not set to enforce block action: Baseline Rule"
}

# Sensitive rules present and blocking, but policy set to test
test_BlockAccess_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.4.3v1"

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
                "Mode": "TestWithNotifications",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No DLP policy matching all types found for evaluation."
}

# All rules are blocking, but don't contain all sensitive types
test_BlockAccess_Incorrect_V4 if {
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
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No DLP policy matching all types found for evaluation."
}

# Multiple policies combined that contain all sensitive rules blocking
test_BlockAccess_Incorrect_V5 if {
    PolicyId := "MS.DEFENDER.4.3v1"

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
            },
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
                ],
                "Name":  "Baseline Rule2",
                "Disabled" : false,
                "ParentPolicyName":  "ITIN specific policy",
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
            },
            {
                "Name": "ITIN specific policy",
                "Mode": "Enable",
                "Enabled": true
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No DLP policy matching all types found for evaluation."
}

test_BlockAccess_Incorrect_V6 if {
    PolicyId := "MS.DEFENDER.4.3v1"

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
                "Enabled": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No DLP policy matching all types found for evaluation."
}

#
# Policy 4
#--

# Sensitive policy present, and set to notify site admin
test_NotifyUser_Correct_V1 if {
    PolicyId := "MS.DEFENDER.4.4v1"

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
                    "SiteAdmin"
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

# Sensitive policy present, and set to notify multiple users
test_NotifyUser_Correct_V2 if {
    PolicyId := "MS.DEFENDER.4.4v1"

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
                    "Owners"
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

# Sensitive policy not enabled
test_NotifyUser_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.4.4v1"

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
                    "Owners"
                ],
                "NotifyUserType":  "NotSet",
                "IsAdvancedRule": false
            }
        ],
        "dlp_compliance_policies": [
            {
                "Name": "Default Office 365 DLP policy",
                "Mode": "Disable",
                "Enabled": false
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No DLP policy matching all types found for evaluation."
}

# Sensitive policy enabled, no users set to notify
test_NotifyUser_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.4.4v1"

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
                "NotifyUser":  [],
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
    RuleOutput[0].ReportDetails == "1 rule(s) found that do(es) not notify at least one user: Baseline Rule"
}

#
# Policy 5
#--
test_NotImplemented_Correct_V1 if {
    PolicyId := "MS.DEFENDER.4.5v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}

#
# Policy 6
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.DEFENDER.4.6v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
