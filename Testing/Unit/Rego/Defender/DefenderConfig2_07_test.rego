package defender
import future.keywords


#
# Policy 1
#--
test_Domains_Correct if {
    ControlNumber := "Defender 2.7"
    Requirement := "The Safe Links Policy SHALL include all agency domains-and by extension-all users"

    Output := tests with input as {
        "safe_links_rules" : [
            {
                "RecipientDomainIs":  ["Test Domain"],
                "Identity" : "Test Policy Rule",
                "SafeLinksPolicy": "Test Policy",
                "State" : "Enabled"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DomainName_Incorrect_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "The Safe Links Policy SHALL include all agency domains-and by extension-all users"

    Output := tests with input as {
        "safe_links_rules" : [
            {
                "RecipientDomainIs":  [""],
                "Identity" : "Test Policy",
                "SafeLinksPolicy": "Test Policy",
                "State" : "Enabled"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to all domains: Test Domain"
}

test_DomainName_Incorrect_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "The Safe Links Policy SHALL include all agency domains-and by extension-all users"

    Output := tests with input as {
        "safe_links_rules" : [
            {
                "RecipientDomainIs":  ["Test Domain2"],
                "Identity" : "Test Policy",
                "SafeLinksPolicy": "Test Policy",
                "State" : "Enabled"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to all domains: Test Domain"
}

test_Domains_Incorrect_v3 if {
    ControlNumber := "Defender 2.7"
    Requirement := "The Safe Links Policy SHALL include all agency domains-and by extension-all users"

    Output := tests with input as {
        "safe_links_rules" : [
            {
                "RecipientDomainIs":  ["Test Domain"],
                "Identity" : "Test Policy",
                "SafeLinksPolicy": "Test Policy",
                "State" : "Disabled"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No policy found that applies to all domains: Test Domain"
}

test_Domains_Incorrect_V4 if {
    # If no defender license is present, the provider will output "safe_links_rules"
    # and "safe_links_policies" as empty lists
    ControlNumber := "Defender 2.7"
    Requirement := "The Safe Links Policy SHALL include all agency domains-and by extension-all users"

    Output := tests with input as {
        "safe_links_rules": [],
        "safe_links_policies": [],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# Policy 2
#--
test_EnableSafeLinksForEmail_Correct_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "URL rewriting and malicious link click checking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            },
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b rule"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForEmail" : true,
                "Identity": "a"
            },
            {
                "EnableSafeLinksForEmail" : false,
                "Identity": "b"
            },
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSafeLinksForEmail_Correct_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "URL rewriting and malicious link click checking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "a"
            },
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b rule"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForEmail" : true,
                "Identity": "a"
            },
            {
                "EnableSafeLinksForEmail" : true,
                "Identity": "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSafeLinksForEmail_Incorrect_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "URL rewriting and malicious link click checking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default Rule",
                "SafeLinksPolicy": "Default",
                "State" : "Enabled"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForEmail" : false,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableSafeLinksForEmail_Incorrect_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "URL rewriting and malicious link click checking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default Rule",
                "SafeLinksPolicy": "Default",
                "State" : "Disabled"
            }        
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForEmail" : true,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableSafeLinksForEmail_Incorrect_V3 if {
    # If no defender license is present, the provider will output "safe_links_rules"
    # and "safe_links_policies" as empty lists
    ControlNumber := "Defender 2.7"
    Requirement := "URL rewriting and malicious link click checking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules" : [],
        "safe_links_policies" : [],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# Policy 3
#--
test_EnableSafeLinksForTeams_Correct_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Malicious link click checking SHALL be enabled with Microsoft Teams"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a rule"
            },
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "a"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForTeams" : true,
                "Identity": "a"
            },
            {
                "EnableSafeLinksForTeams" : false,
                "Identity": "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSafeLinksForTeams_Correct_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Malicious link click checking SHALL be enabled with Microsoft Teams"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Disabled",
                "Identity" : "a",
                "SafeLinksPolicy": "a"
            },
            {
                "State" : "Enabled",
                "Identity" : "b rule",
                "SafeLinksPolicy": "b"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForTeams" : true,
                "Identity": "a"
            },
            {
                "EnableSafeLinksForTeams" : true,
                "Identity": "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSafeLinksForTeams_Incorrect_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Malicious link click checking SHALL be enabled with Microsoft Teams"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "SafeLinksPolicy": "Default",
                "State" : "Enabled"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForTeams" : false,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableSafeLinksForTeams_Incorrect_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Malicious link click checking SHALL be enabled with Microsoft Teams"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "SafeLinksPolicy": "Default",
                "State" : "Disabled"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForTeams" : false,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableSafeLinksForTeams_Incorrect_V3 if {
    # If no defender license is present, the provider will output "safe_links_rules"
    # and "safe_links_policies" as empty lists
    ControlNumber := "Defender 2.7"
    Requirement := "Malicious link click checking SHALL be enabled with Microsoft Teams"

    Output := tests with input as {
        "safe_links_rules" : [],
        "safe_links_policies" : [],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# Policy 4
#--
test_ScanUrls_Correct_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Real-time suspicious URL and file-link scanning SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            },
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b"
            }
        ],
        "safe_links_policies": [
            {
                "ScanUrls" : false,
                "Identity": "a"
            },
            {
                "ScanUrls" : true,
                "Identity": "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ScanUrls_Correct_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Real-time suspicious URL and file-link scanning SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            },
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b"
            }
        ],
        "safe_links_policies": [
            {
                "ScanUrls" : true,
                "Identity": "a"
            },
            {
                "ScanUrls" : true,
                "Identity": "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ScanUrls_Incorrect_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Real-time suspicious URL and file-link scanning SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "SafeLinksPolicy": "Default",
                "State" : "Enabled"
            }
        ],
        "safe_links_policies": [
            {
                "ScanUrls" : false,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_ScanUrls_Incorrect_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Real-time suspicious URL and file-link scanning SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "SafeLinksPolicy": "Default",
                "State" : "Disabled"
            }
        ],
        "safe_links_policies": [
            {
                "ScanUrls" : false,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_ScanUrls_Incorrect_V3 if {
    # If no defender license is present, the provider will output "safe_links_rules"
    # and "safe_links_policies" as empty lists
    ControlNumber := "Defender 2.7"
    Requirement := "Real-time suspicious URL and file-link scanning SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules" : [],
        "safe_links_policies" : [],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# Policy 5
#--
test_DeliverMessageAfterScan_Correct_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "URLs SHALL be scanned completely before message delivery"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a rule"
            },
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b"
            }
        ],
        "safe_links_policies": [
            {
                "DeliverMessageAfterScan" : true,
                "Identity": "a"
            },
            {
                "DeliverMessageAfterScan" : false,
                "Identity": "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DeliverMessageAfterScan_Correct_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "URLs SHALL be scanned completely before message delivery"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            },
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b rule"
            }
        ],
        "safe_links_policies": [
            {
                "DeliverMessageAfterScan" : true,
                "Identity": "a"
            },
            {
                "DeliverMessageAfterScan" : true,
                "Identity": "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_DeliverMessageAfterScan_Incorrect_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "URLs SHALL be scanned completely before message delivery"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "SafeLinksPolicy": "Default",
                "State" : "Enabled"
            }
        ],
        "safe_links_policies": [
            {
                "DeliverMessageAfterScan" : false,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_DeliverMessageAfterScan_Incorrect_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "URLs SHALL be scanned completely before message delivery"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "SafeLinksPolicy": "Default",
                "State" : "Disabled"
            }
        ],
        "safe_links_policies": [
            {
                "DeliverMessageAfterScan" : false,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_DeliverMessageAfterScan_Incorrect_V3 if {
    # If no defender license is present, the provider will output "safe_links_rules"
    # and "safe_links_policies" as empty lists
    ControlNumber := "Defender 2.7"
    Requirement := "URLs SHALL be scanned completely before message delivery"

    Output := tests with input as {
        "safe_links_rules" : [],
        "safe_links_policies" : [],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# Policy 6
#--
test_EnableForInternalSenders_Correct_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Internal agency email messages SHALL have safe links enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            },
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b"
            }
        ],
        "safe_links_policies": [
            {
                "Identity" : "a",
                "EnableForInternalSenders" : false
            },
            {
                "Identity" : "b",
                "EnableForInternalSenders" : true
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableForInternalSenders_Correct_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Internal agency email messages SHALL have safe links enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            },
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b rule"
            }
        ],
        "safe_links_policies": [
            {
                "Identity" : "a",
                "EnableForInternalSenders" : true
            },
            {
                "Identity" : "b",
                "EnableForInternalSenders" : true
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableForInternalSenders_Incorrect_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Internal agency email messages SHALL have safe links enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "SafeLinksPolicy": "Default",
                "State" : "Enabled"
            }
        ],
        "safe_links_policies": [
            {
                "Identity" : "Not Built-in Protection Policy",
                "EnableForInternalSenders" : false
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableForInternalSenders_Incorrect_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Internal agency email messages SHALL have safe links enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "SafeLinksPolicy": "Default",
                "State" : "Disabled"
            }
        ],
        "safe_links_policies": [
            {
                "Identity" : "Not Built-in Protection Policy",
                "EnableForInternalSenders" : false
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableForInternalSenders_Incorrect_V3 if {
    # If no defender license is present, the provider will output "safe_links_rules"
    # and "safe_links_policies" as empty lists
    ControlNumber := "Defender 2.7"
    Requirement := "Internal agency email messages SHALL have safe links enabled"

    Output := tests with input as {
        "safe_links_rules" : [],
        "safe_links_policies" : [],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# Policy 7
#--
test_TrackClicks_Correct_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "User click tracking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            },
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b"
            }
        ],
        "safe_links_policies": [
            {
                "TrackClicks" : false,
                "Identity": "a"
            },
            {
                "TrackClicks" : true,
                "Identity": "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TrackClicks_Correct_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "User click tracking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            },
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b"
            }
        ],
        "safe_links_policies": [
            {
                "TrackClicks" : true,
                "Identity": "a"
            },
            {
                "TrackClicks" : true,
                "Identity": "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TrackClicks_Incorrect_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "User click tracking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "State" : "Enabled",
                "SafeLinksPolicy": "Default"
            }
        ],
        "safe_links_policies": [
            {
                "TrackClicks" : false,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_TrackClicks_Incorrect_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "User click tracking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "Default",
                "State" : "Disabled",
                "SafeLinksPolicy": "Default"
            }
        ],
        "safe_links_policies": [
            {
                "TrackClicks" : false,
                "Identity": "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_TrackClicks_Incorrect_V3 if {
    # If no defender license is present, the provider will output "safe_links_rules"
    # and "safe_links_policies" as empty lists
    ControlNumber := "Defender 2.7"
    Requirement := "User click tracking SHALL be enabled"

    Output := tests with input as {
        "safe_links_rules" : [],
        "safe_links_policies" : [],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# Policy 8
#--
test_EnableSafeLinksForOffice_Correct_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Safe Links in Office 365 apps SHALL be turned on"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "a rule",
                "SafeLinksPolicy": "a",
                "State" : "Enabled"
            },
            {
                "Identity" : "b",
                "SafeLinksPolicy": "b",
                "State" : "Enabled"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForOffice" : true,
                "Identity" : "a"
            },
            {
                # Only one policy needs to be true.
                "EnableSafeLinksForOffice" : false,
                "Identity" : "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSafeLinksForOffice_Correct_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Safe Links in Office 365 apps SHALL be turned on"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "Identity" : "a rule",
                "SafeLinksPolicy": "a",
                "State" : "Enabled"
            },
            {
                # Only one policy needs to be true.
                "Identity" : "b",
                "SafeLinksPolicy": "b",
                "State" : "Disabled"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForOffice" : true,
                "Identity" : "a"
            },
            {
                "EnableSafeLinksForOffice" : true,
                "Identity" : "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSafeLinksForOffice_Incorrect_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Safe Links in Office 365 apps SHALL be turned on"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForOffice" : false,
                "Identity" : "a"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableSafeLinksForOffice_Incorrect_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Safe Links in Office 365 apps SHALL be turned on"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForOffice" : true,
                "Identity" : "a"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableSafeLinksForOffice_Incorrect_V3 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Safe Links in Office 365 apps SHALL be turned on"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            }
        ],
        "safe_links_policies": [
            {
                "EnableSafeLinksForOffice" : false,
                "Identity" : "a"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableSafeLinksForOffice_Incorrect_V4 if {
    # If no defender license is present, the provider will output "safe_links_rules"
    # and "safe_links_policies" as empty lists
    ControlNumber := "Defender 2.7"
    Requirement := "Safe Links in Office 365 apps SHALL be turned on"

    Output := tests with input as {
        "safe_links_rules" : [],
        "safe_links_policies" : [],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# Policy 9
#--
test_AllowClickThrough_Correct_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Users SHALL NOT be enabled to click through to the original URL"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a rule"
            },
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b"
            }
        ],
        "safe_links_policies": [
            {
                "AllowClickThrough" : false,
                "Identity" : "a"
            },
            {
                "AllowClickThrough" : true,
                "Identity" : "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowClickThrough_Correct_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Users SHALL NOT be enabled to click through to the original URL"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a rule"
            },
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "b",
                "Identity" : "b"
            }
        ],
        "safe_links_policies": [
            {
                "AllowClickThrough" : false,
                "Identity" : "a"
            },
            {
                "AllowClickThrough" : false,
                "Identity" : "b"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowClickThrough_Incorrect_V1 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Users SHALL NOT be enabled to click through to the original URL"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            }
        ],
        "safe_links_policies": [
            {
                "AllowClickThrough" : true,
                "Identity" : "a"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllowClickThrough_Incorrect_V2 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Users SHALL NOT be enabled to click through to the original URL"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Disabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            }
        ],
        "safe_links_policies": [
            {
                "AllowClickThrough" : false,
                "Identity" : "a"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllowClickThrough_Incorrect_V3 if {
    ControlNumber := "Defender 2.7"
    Requirement := "Users SHALL NOT be enabled to click through to the original URL"

    Output := tests with input as {
        "safe_links_rules": [
            {
                "State" : "Enabled",
                "SafeLinksPolicy": "a",
                "Identity" : "a"
            }
        ],
        "safe_links_policies": [
            {
                "AllowClickThrough" : true,
                "Identity" : "a"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllowClickThrough_Incorrect_V4 if {
    # If no defender license is present, the provider will output "safe_links_rules"
    # and "safe_links_policies" as empty lists
    ControlNumber := "Defender 2.7"
    Requirement := "Users SHALL NOT be enabled to click through to the original URL"

    Output := tests with input as {
        "safe_links_rules" : [],
        "safe_links_policies" : [],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}
