package defender
import future.keywords


#
# Policy 1
#--
test_ContentContainsSensitiveInformation_Correct_V1 if {
    ControlNumber := "Defender 2.2"
    Requirement := "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: U.S. Social Security Number (SSN)"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
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
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ContentContainsSensitiveInformation_Incorrect_V1 if {
    ControlNumber := "Defender 2.2"
    Requirement := "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: U.S. Social Security Number (SSN)"

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
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No matching rule found for U.S. Social Security Number (SSN)"
}

test_ContentContainsSensitiveInformation_Correct_V2 if {
    ControlNumber := "Defender 2.2"
    Requirement := "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: U.S. Individual Taxpayer Identification Number (ITIN)"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
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
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ContentContainsSensitiveInformation_Incorrect_V2 if {
    ControlNumber := "Defender 2.2"
    Requirement := "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: U.S. Individual Taxpayer Identification Number (ITIN)"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
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
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No matching rule found for U.S. Individual Taxpayer Identification Number (ITIN)"
}

test_ContentContainsSensitiveInformation_Correct_V3 if {
    ControlNumber := "Defender 2.2"
    Requirement := "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: Credit Card Number"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
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
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ContentContainsSensitiveInformation_Incorrect_V3 if {
    ControlNumber := "Defender 2.2"
    Requirement := "A custom policy SHALL be configured to protect PII and sensitive information, as defined by the agency: Credit Card Number"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"},
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
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No matching rule found for Credit Card Number"
}

#
# Policy 2
#--
test_Exchange_Correct if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in Exchange"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "Workload":  "Exchange",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ExchangeLocation_Incorrect if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in Exchange"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  [""],
                "Workload":  "Exchange",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to Exchange."
}

test_Workload_Incorrect_V1 if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in Exchange"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "ExchangeLocation":  ["All"],
                "Workload":  "",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to Exchange."
}

test_SharePoint_Correct if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in SharePoint"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "SharePointLocation":  ["All"],
                "Workload":  "SharePoint",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SharePointLocation_Incorrect if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in SharePoint"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "SharePointLocation":  [""],
                "Workload":  "SharePoint",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to SharePoint."
}

test_Workload_Incorrect_V2 if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in SharePoint"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "SharePointLocation":  ["All"],
                "Workload":  "",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to SharePoint."
}

test_OneDrive_Correct if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in OneDrive"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "OneDriveLocation":  ["All"],
                "Workload":  "OneDrivePoint",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_OneDriveLocation_Incorrect if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in OneDrive"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "OneDriveLocation":  [""],
                "Workload":  "OneDrivePoint",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to OneDrive."
}

test_Workload_Incorrect_V3 if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in OneDrive"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "OneDriveLocation":  ["All"],
                "Workload":  "",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to OneDrive."
}

test_Teams_Correct if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in Teams"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "TeamsLocation":  ["All"],
                "Workload":  "Teams",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TeamsLocation_Incorrect if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in Teams"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "TeamsLocation":  [""],
                "Workload":  "Teams",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to Teams."
}

test_Workload_Incorrect_V4 if {
    ControlNumber := "Defender 2.2"
    Requirement := "The custom policy SHOULD be applied in Teams"

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
	            "NotifyUserType":  "NotSet"
            }
        ],
        "dlp_compliance_policies": [
            {
                "TeamsLocation":  ["All"],
                "Workload":  "",
                "Name":  "Default Office 365 DLP policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to Teams."
}

#
# Policy 3
#--
test_BlockAccess_Correct if {
    ControlNumber := "Defender 2.2"
    Requirement := "The action for the DLP policy SHOULD be set to block sharing sensitive information with everyone when DLP conditions are met"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
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
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_BlockAccess_Incorrect if {
    ControlNumber := "Defender 2.2"
    Requirement := "The action for the DLP policy SHOULD be set to block sharing sensitive information with everyone when DLP conditions are met"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
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
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 rule(s) found that do(es) not block access: Baseline Rule"
}

#
# Policy 4
#--
test_NotifyUser_Correct_V1 if {
    ControlNumber := "Defender 2.2"
    Requirement := "Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
                ],
                "Name":  "Baseline Rule",
	            "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
	            "BlockAccess":  true,
                "BlockAccessScope":  "All",
	            "NotifyUser":  [
                    "SiteAdmin"
                ],
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_NotifyUser_Correct_V2 if {
    ControlNumber := "Defender 2.2"
    Requirement := "Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
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
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_NotifyUser_Incorrect if {
    ControlNumber := "Defender 2.2"
    Requirement := "Notifications to inform users and help educate them on the proper use of sensitive information SHOULD be enabled"

    Output := tests with input as {
        "dlp_compliance_rules": [
            {
                "ContentContainsSensitiveInformation":  [
                    {"name":  "U.S. Individual Taxpayer Identification Number (ITIN)"}
                ],
                "Name":  "Baseline Rule",
	            "Disabled" : false,
                "ParentPolicyName":  "Default Office 365 DLP policy",
	            "BlockAccess":  true,
                "BlockAccessScope":  "All",
	            "NotifyUser":  [ ],
	            "NotifyUserType":  "NotSet"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 rule(s) found that do(es) not notify at least one user: Baseline Rule"
}

#
# Policy 5
#--
test_NotImplemented_Correct_V1 if {
    ControlNumber := "Defender 2.2"
    Requirement := "A list of apps that are not allowed to access files protected by DLP policy SHOULD be defined"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.2 for instructions on manual check"
}

#
# Policy 6
#--
test_NotImplemented_Correct_V2 if {
    ControlNumber := "Defender 2.2"
    Requirement := "A list of browsers that are not allowed to access files protected by DLP policy SHOULD be defined"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Defender Secure Configuration Baseline policy 2.2 for instructions on manual check"
}