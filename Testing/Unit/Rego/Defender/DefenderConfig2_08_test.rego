package defender
import future.keywords


#
# Policy 1
#--
test_Domains_Correct if {
    ControlNumber := "Defender 2.8"
    Requirement := "At least one Safe Attachments Policy SHALL include all agency domains-and by extension-all users"

    Output := tests with input as {
        "safe_attachment_rules" : [
            {
                "RecipientDomainIs":  ["Test Domain"],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy Rule"
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
    ControlNumber := "Defender 2.8"
    Requirement := "At least one Safe Attachments Policy SHALL include all agency domains-and by extension-all users"

    Output := tests with input as {
        "safe_attachment_rules" : [
            {
                "RecipientDomainIs":  [""],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy Rule"
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
    ControlNumber := "Defender 2.8"
    Requirement := "At least one Safe Attachments Policy SHALL include all agency domains-and by extension-all users"

    Output := tests with input as {
        "safe_attachment_rules" : [
            {
                "RecipientDomainIs":  ["Test Domain2"],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy Rule"
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

test_DomainName_Incorrect_V3 if {
    # If no defender license is present, the provider will output "safe_attachment_rules"
    # and "safe_attachment_policies" as empty lists
    ControlNumber := "Defender 2.8"
    Requirement := "At least one Safe Attachments Policy SHALL include all agency domains-and by extension-all users"

    Output := tests with input as {
        "safe_attachment_rules" : [],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [],
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
test_Action_Correct if {
    ControlNumber := "Defender 2.8"
    Requirement := "The action for malware in email attachments SHALL be set to block"

    Output := tests with input as {
        "safe_attachment_rules": [
            {
                "RecipientDomainIs":  ["Test Domain"],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy Rule"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [
            {
                "Action" : "Block",
                "Enable" : true,
                "RedirectAddress" : "127.0.0.1",
                "Identity" : "Test Policy"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_RecipientDomainIs_Incorrect_V1 if {
    ControlNumber := "Defender 2.8"
    Requirement := "The action for malware in email attachments SHALL be set to block"

    Output := tests with input as {
        "safe_attachment_rules": [
            {
                "RecipientDomainIs":  [""],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [
            {
                "Action" : "Block",
                "Enable" : true,
                "RedirectAddress" : "127.0.0.1",
                "Identity" : "Test Policy"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found with action set to block that apply to all domains"
}

test_RecipientDomainIs_Incorrect_V2 if {
    ControlNumber := "Defender 2.8"
    Requirement := "The action for malware in email attachments SHALL be set to block"

    Output := tests with input as {
        "safe_attachment_rules": [
            {
                "RecipientDomainIs":  ["Test Domain2"],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [
            {
                "Action" : "Block",
                "Enable" : true,
                "RedirectAddress" : "127.0.0.1",
                "Identity" : "Test Policy"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found with action set to block that apply to all domains"
}

test_Action_Incorrect_V1 if {
    ControlNumber := "Defender 2.8"
    Requirement := "The action for malware in email attachments SHALL be set to block"

    Output := tests with input as {
        "safe_attachment_rules": [
            {
                "RecipientDomainIs":  ["Test Domain"],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [
            {
                "Action" : "Not Block",
                "Enable" : true,
                "RedirectAddress" : "127.0.0.1",
                "Identity" : "Test Policy"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found with action set to block that apply to all domains"
}

test_Action_Incorrect_V2 if {
    # If no defender license is present, the provider will output "safe_attachment_rules"
    # and "safe_attachment_policies" as empty lists
    ControlNumber := "Defender 2.8"
    Requirement := "The action for malware in email attachments SHALL be set to block"

    Output := tests with input as {
        "safe_attachment_rules" : [],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [],
        "defender_license" : false
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

test_Enable_Incorrect if {
    ControlNumber := "Defender 2.8"
    Requirement := "The action for malware in email attachments SHALL be set to block"

    Output := tests with input as {
        "safe_attachment_rules": [
            {
                "RecipientDomainIs":  ["Test Domain"],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy "
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [
            {
                "Action" : "Block",
                "Enable" : false,
                "RedirectAddress" : "127.0.0.1",
                "Identity" : "Test Policy"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found with action set to block that apply to all domains"
}

test_Identity_Incorrect if {
    ControlNumber := "Defender 2.8"
    Requirement := "The action for malware in email attachments SHALL be set to block"

    Output := tests with input as {
        "safe_attachment_rules": [
            {
                "RecipientDomainIs":  ["Test Domain"],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [
            {
                "Action" : "Block",
                "Enable" : true,
                "RedirectAddress" : "127.0.0.1",
                "Identity" : ""
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found with action set to block that apply to all domains"
}

#
# Policy 3
#--
test_RedirectPolicies_Correct if {
    ControlNumber := "Defender 2.8"
    Requirement := "Redirect emails with detected attachments to an agency-specified email SHOULD be enabled"

    Output := tests with input as {
        "safe_attachment_rules": [
            {
                "RecipientDomainIs":  ["Test Domain"],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy Rule"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [
            {
                "Action" : "Block",
                "Enable" : true,
                "RedirectAddress" : "127.0.0.1",
                "Identity" : "Test Policy"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_RedirectAddress_Incorrect if {
    ControlNumber := "Defender 2.8"
    Requirement := "Redirect emails with detected attachments to an agency-specified email SHOULD be enabled"

    Output := tests with input as {
        "safe_attachment_rules": [
            {
                "RecipientDomainIs":  ["Test Domain"],
                "SafeAttachmentPolicy": "Test Policy",
                "Identity" : "Test Policy Rule"
            }
        ],
        "all_domains" : [
            {
                "DomainName" : "Test Domain"
            }
        ],
        "safe_attachment_policies" : [
            {
                "Action" : "Block",
                "Enable" : true,
                "RedirectAddress" : "",
                "Identity" : "Test Policy"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No enabled policy found with action set to block and at least one contact specified"
}

#
# Policy 4
#--
test_Spot_Correct if {
    ControlNumber := "Defender 2.8"
    Requirement := "Safe attachments SHOULD be enabled for SharePoint, OneDrive, and Microsoft Teams"

    Output := tests with input as {
        "atp_policy_for_o365" : [
            {
                "EnableATPForSPOTeamsODB" : true,
                "Identity" : "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Spot_Incorrect if {
    ControlNumber := "Defender 2.8"
    Requirement := "Safe attachments SHOULD be enabled for SharePoint, OneDrive, and Microsoft Teams"

    Output := tests with input as {
        "atp_policy_for_o365" : [
            {
                "EnableATPForSPOTeamsODB" : false,
                "Identity" : "Default"
            }
        ],
        "defender_license" : true
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
