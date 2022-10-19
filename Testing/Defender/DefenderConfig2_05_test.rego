package defender
import future.keywords


#
# Policy 1
#--
test_TargetedUsers_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "User impersonation protection SHOULD be enabled for key agency leaders"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "john doe;jdoe@someemail.com",
                    "jane doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Enabled_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "User impersonation protection SHOULD be enabled for key agency leaders"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : false,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "john doe;jdoe@someemail.com",
                    "jane doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No users are included for targeted user protection."
}

test_EnableTargetedUserProtection_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "User impersonation protection SHOULD be enabled for key agency leaders"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : false,
                "TargetedUsersToProtect" : [
                    "john doe;jdoe@someemail.com",
                    "jane doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No users are included for targeted user protection."
}

test_TargetedUsersToProtect_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "User impersonation protection SHOULD be enabled for key agency leaders"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [ ],
                "TargetedUserProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No users are included for targeted user protection."
}

#
# Policy 2
#--
test_OrganizationDomain_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableOrganizationDomainsProtection" : true,
	            "EnableTargetedDomainsProtection" : true,
                "TargetedDomainProtectionAction" : "Quarantine",
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Enabled_Incorrect_V2 if {
    ControlNumber := "Defender 2.5"
    Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

    Output := tests with input as {
       "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : false,
                "EnableOrganizationDomainsProtection" : true,
	            "EnableTargetedDomainsProtection" : true,
                "TargetedDomainProtectionAction" : "Quarantine",
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableOrganizationDomainsProtection_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

    Output := tests with input as {
       "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableOrganizationDomainsProtection" : false,
	            "EnableTargetedDomainsProtection" : true,
                "TargetedDomainProtectionAction" : "Quarantine",
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableTargetedDomainsProtection_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

    Output := tests with input as {
       "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableOrganizationDomainsProtection" : true,
	            "EnableTargetedDomainsProtection" : false,
                "TargetedDomainProtectionAction" : "Quarantine",
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 3
#--
test_CustomDomains_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Domain impersonation protection SHOULD be added for frequent partners"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [ "test domain" ],
	            "TargetedDomainProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Enabled_Incorrect_V3 if {
    ControlNumber := "Defender 2.5"
    Requirement := "Domain impersonation protection SHOULD be added for frequent partners"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : false,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [ "test domain" ],
	            "TargetedDomainProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "The Custom Domains protection policies: Enabled, EnableTargetedDomainsProtection, and TargetedDomainsToProtect are not set correctly"
}

test_EnableTargetedDomainsProtection_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Domain impersonation protection SHOULD be added for frequent partners"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : false,
                "TargetedDomainsToProtect" : [ "test domain" ],
	            "TargetedDomainProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "The Custom Domains protection policies: Enabled, EnableTargetedDomainsProtection, and TargetedDomainsToProtect are not set correctly"
}

test_TargetedDomainsToProtect_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Domain impersonation protection SHOULD be added for frequent partners"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [ ],
	            "TargetedDomainProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "The Custom Domains protection policies: Enabled, EnableTargetedDomainsProtection, and TargetedDomainsToProtect are not set correctly"
}

#
# Policy 4
#--
test_Email_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Intelligence for impersonation protection SHALL be enabled"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableMailboxIntelligenceProtection" : true,
	            "MailboxIntelligenceProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Enabled_Incorrect_V4 if {
    ControlNumber := "Defender 2.5"
    Requirement := "Intelligence for impersonation protection SHALL be enabled"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : false,
                "EnableMailboxIntelligenceProtection" : true,
	            "MailboxIntelligenceProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableMailboxIntelligenceProtection_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Intelligence for impersonation protection SHALL be enabled"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "Name" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableMailboxIntelligenceProtection" : false,
	            "MailboxIntelligenceProtectionAction" : "Quarantine"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 5
#--
test_TargetedUserProtectionAction_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHALL be set to quarantine if the message is detected as impersonated: users default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "TargetedUserProtectionAction" : "Quarantine",
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TargetedUserProtectionAction_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHALL be set to quarantine if the message is detected as impersonated: users default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "TargetedUserProtectionAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_TargetedUserProtectionActionCustom_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHOULD be set to quarantine if the message is detected as impersonated: users non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "TargetedUserProtectionAction" : "Quarantine",
                "Identity" : "Custom 1"
            },
            {
                "TargetedUserProtectionAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default" # The default policy should be ignored here
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TargetedUserProtectionActionCustom_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHOULD be set to quarantine if the message is detected as impersonated: users non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "TargetedUserProtectionAction" : "Quarantine",
                "Identity" : "Custom 1"
            },
            {
                "TargetedUserProtectionAction" : "Not Quarantine",
                "Identity" : "Custom 2"
            },
            {
                "TargetedUserProtectionAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default" # The default policy should be ignored here
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 non-default anti phish policy(ies) found where the action for messages detected as user impersonation is not quarantine: Custom 2"
}


test_TargetedDomainProtectionAction_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHALL be set to quarantine if the message is detected as impersonated: domains default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "TargetedDomainProtectionAction" : "Quarantine",
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TargetedDomainProtectionAction_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHALL be set to quarantine if the message is detected as impersonated: domains default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "TargetedDomainProtectionAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_TargetedDomainProtectionActionCustom_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHOULD be set to quarantine if the message is detected as impersonated: domains non-default policies"
    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "TargetedDomainProtectionAction" : "Quarantine",
                "Identity" : "Custom 1"
            },
            {
                "TargetedDomainProtectionAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default" # The default policy should be ignored here
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TargetedDomainProtectionActionCustom_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHOULD be set to quarantine if the message is detected as impersonated: domains non-default policies"
    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "TargetedDomainProtectionAction" : "Quarantine",
                "Identity" : "Custom 1"
            },
            {
                "TargetedDomainProtectionAction" : "Not Quarantine",
                "Identity" : "Custom 2"
            },
            {
                "TargetedDomainProtectionAction" : "Not Quarantine",
                "Identity" : "Custom 3"
            },
            {
                "TargetedDomainProtectionAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default" # The default policy should be ignored here
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    startswith(RuleOutput[0].ReportDetails, "2 non-default anti phish policy(ies) found where the action for messages detected as domain impersonation is not quarantine:")
    # I don't think we can assume the order rego will Output these, hence the "includes" check instead of a simple ==
    contains(RuleOutput[0].ReportDetails, "Custom 2")
    contains(RuleOutput[0].ReportDetails, "Custom 3")
}

test_MailboxIntelligenceProtectionAction_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHALL be set to quarantine if the message is detected as impersonated: mailbox default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "MailboxIntelligenceProtectionAction" : "Quarantine",
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_MailboxIntelligenceProtectionAction_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHALL be set to quarantine if the message is detected as impersonated: mailbox default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "MailboxIntelligenceProtectionAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_MailIntProtectionActionCustom_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHOULD be set to quarantine if the message is detected as impersonated: mailbox non-default policies"
    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "MailboxIntelligenceProtectionAction" : "Quarantine",
                "Identity" : "Custom 1"
            },
            {
                "MailboxIntelligenceProtectionAction" : "Quarantine",
                "Identity" : "Custom 2"
            },
            {
                "MailboxIntelligenceProtectionAction" : "something else",
                "Identity" : "Standard Preset Security Policy314195" # should be ignored
            },
            {
                "MailboxIntelligenceProtectionAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default" # The default policy should be ignored here
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails = "Requirement met"
}

test_MailIntProtectionActionCustom_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Message action SHOULD be set to quarantine if the message is detected as impersonated: mailbox non-default policies"
    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "MailboxIntelligenceProtectionAction" : "Quarantine",
                "Identity" : "Custom 1"
            },
            {
                "MailboxIntelligenceProtectionAction" : "Not Quarantine",
                "Identity" : "Custom 2"
            },
            {
                "MailboxIntelligenceProtectionAction" : "something else",
                "Identity" : "Standard Preset Security Policy314195" # should be ignored
            },
            {
                "MailboxIntelligenceProtectionAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default" # The default policy should be ignored here
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails = "1 non-default anti phish policy(ies) found where the action for messages flagged by mailbox intelligence is not quarantine: Custom 2"
}

#
# Policy 6
#--
test_AuthenticationFailAction_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Mail classified as spoofed SHALL be quarantined: default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "AuthenticationFailAction" : "Quarantine",
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AuthenticationFailAction_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Mail classified as spoofed SHALL be quarantined: default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "AuthenticationFailAction" : "Not Quarantine",
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AuthenticationFailActionNonDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "Mail classified as spoofed SHOULD be quarantined: non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "AuthenticationFailAction" : "Quarantine",
                "Identity" : "Not Standard Preset SecurityPolicy1659535429826"
            },
            {
	            "AuthenticationFailAction" : "Quarantine",
                "Identity" : "Not Standard Preset SecurityPolicy Either"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AuthenticationFailActionNonDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "Mail classified as spoofed SHOULD be quarantined: non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
	            "AuthenticationFailAction" : "Not Quarantine",
                "Identity" : "Not Standard Preset SecurityPolicy1659535429826"
            },
            {
	            "AuthenticationFailAction" : "Quarantine",
                "Identity" : "Not Standard Preset SecurityPolicy Either"
            }        
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti phish policy(ies) found where the action for spoofed emails is not set to quarantine: Not Standard Preset SecurityPolicy1659535429826"
    #Custom anti phish policy(ies) found where the action for spoofed emails is not set to quarantine.
}

#
# Policy 7
#--
test_EnableFirstContactSafetyTipsDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: first contact default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableFirstContactSafetyTips" : true,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableFirstContactSafetyTipsDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: first contact default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableFirstContactSafetyTips" : false,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableFirstContactSafetyTipsNonDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: first contact non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableFirstContactSafetyTips" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableFirstContactSafetyTips" : true,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableFirstContactSafetyTips" : true,
                "Identity" : "Custom policy 3"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableFirstContactSafetyTipsNonDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: first contact non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableFirstContactSafetyTips" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableFirstContactSafetyTips" : false,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableFirstContactSafetyTips" : true,
                "Identity" : "Custom policy 3"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti phish policy(ies) found where first contact safety tips are not enabled: Custom policy 2"
}

test_EnableSimilarUsersSafetyTipsDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: user impersonation default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableSimilarUsersSafetyTips" : true,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSimilarUsersSafetyTipsDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: user impersonation default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableSimilarUsersSafetyTips" : false,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableSimilarUserSafetyTipsNonDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: user impersonation non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableSimilarUsersSafetyTips" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableSimilarUsersSafetyTips" : true,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableSimilarUsersSafetyTips" : true,
                "Identity" : "Custom policy 3"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSimilarUserSafetyTipsNonDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: user impersonation non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableSimilarUsersSafetyTips" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableSimilarUsersSafetyTips" : false,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableSimilarUsersSafetyTips" : true,
                "Identity" : "Custom policy 3"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti phish policy(ies) found where similar user safety tips are not enabled: Custom policy 2"
}

test_EnableSimilarDomainsSafetyTipsDomains_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: domain impersonation default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableSimilarDomainsSafetyTips" : true,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSimilarDomainsSafetyTipsDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: domain impersonation default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableSimilarDomainsSafetyTips" : false,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableSimilarDomainsSafetyTipsNonDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: domain impersonation non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableSimilarDomainsSafetyTips" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableSimilarDomainsSafetyTips" : true,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableSimilarDomainsSafetyTips" : true,
                "Identity" : "Custom policy 3"
            },
            {
                "EnableSimilarDomainsSafetyTips" : false, # The default policy should be ignored
                "Identity" : "Office365 AntiPhish Default" 
            },
            {
                "EnableSimilarDomainsSafetyTips" : false, # The preset policy should be ignored too
                "Identity" : "Standard Preset Security Policy12345" 
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableSimilarDomainsSafetyTipsNonDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: domain impersonation non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableSimilarDomainsSafetyTips" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableSimilarDomainsSafetyTips" : false,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableSimilarDomainsSafetyTips" : true,
                "Identity" : "Custom policy 3"
            },
            {
                "EnableSimilarDomainsSafetyTips" : false, # The default policy should be ignored
                "Identity" : "Office365 AntiPhish Default" 
            },
            {
                "EnableSimilarDomainsSafetyTips" : false, # The preset policy should be ignored too
                "Identity" : "Standard Preset Security Policy12345" 
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti phish policy(ies) found where similar domains safety tips are not enabled: Custom policy 2"
}

test_EnableUnusualCharactersSafetyTips_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: user impersonation unusual characters default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableUnusualCharactersSafetyTips" : true,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableUnusualCharactersSafetyTips_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: user impersonation unusual characters default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableUnusualCharactersSafetyTips" : false,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableUnusualCharSafetyTipsNonDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: user impersonation unusual characters non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableUnusualCharactersSafetyTips" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableUnusualCharactersSafetyTips" : true,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableUnusualCharactersSafetyTips" : true,
                "Identity" : "Custom policy 3"
            },
            {
                "EnableUnusualCharactersSafetyTips" : false, # The default policy should be ignored
                "Identity" : "Office365 AntiPhish Default" 
            },
            {
                "EnableUnusualCharactersSafetyTips" : false, # The preset policy should be ignored too
                "Identity" : "Standard Preset Security Policy12345" 
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableUnusualCharSafetyTipsNonDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: user impersonation unusual characters non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableUnusualCharactersSafetyTips" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableUnusualCharactersSafetyTips" : false,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableUnusualCharactersSafetyTips" : true,
                "Identity" : "Custom policy 3"
            },
            {
                "EnableUnusualCharactersSafetyTips" : false, # The default policy should be ignored
                "Identity" : "Office365 AntiPhish Default" 
            },
            {
                "EnableUnusualCharactersSafetyTips" : false, # The preset policy should be ignored too
                "Identity" : "Standard Preset Security Policy12345" 
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti phish policy(ies) found where unusual character safety tips are not enabled: Custom policy 2"
}

test_EnableViaTagDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: \"via\" tag default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableViaTag" : true,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableViaTagDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: \"via\" tag default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableViaTag" : false,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableViaTagSafetyTipsNonDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: \"via\" tag non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableViaTag" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableViaTag" : true,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableViaTag" : true,
                "Identity" : "Custom policy 3"
            },
            {
                "EnableViaTag" : false, # The default policy should be ignored
                "Identity" : "Office365 AntiPhish Default" 
            },
            {
                "EnableViaTag" : false, # The preset policy should be ignored too
                "Identity" : "Standard Preset Security Policy12345" 
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableViaTagSafetyTipsNonDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: \"via\" tag non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableViaTag" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableViaTag" : false,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableViaTag" : true,
                "Identity" : "Custom policy 3"
            },
            {
                "EnableViaTag" : false, # The default policy should be ignored
                "Identity" : "Office365 AntiPhish Default" 
            },
            {
                "EnableViaTag" : false, # The preset policy should be ignored too
                "Identity" : "Standard Preset Security Policy12345" 
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti phish policy(ies) found where via tag is not enabled: Custom policy 2"
}

test_EnableUnauthenticatedSenderDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: \"?\" for unauthenticated senders for spoof default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableUnauthenticatedSender" : true,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableUnauthenticatedSenderDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHALL be enabled: \"?\" for unauthenticated senders for spoof default policy"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableUnauthenticatedSender" : false,
                "Identity" : "Office365 AntiPhish Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_EnableUnauthSenderTipsNonDefault_Correct if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: \"?\" for unauthenticated senders for spoof non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableUnauthenticatedSender" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableUnauthenticatedSender" : true,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableUnauthenticatedSender" : true,
                "Identity" : "Custom policy 3"
            },
            {
                "EnableUnauthenticatedSender" : false, # The default policy should be ignored
                "Identity" : "Office365 AntiPhish Default" 
            },
            {
                "EnableUnauthenticatedSender" : false, # The preset policy should be ignored too
                "Identity" : "Standard Preset Security Policy12345" 
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_EnableUnauthSenderTipsNonDefault_Incorrect if {
    ControlNumber := "Defender 2.5"
    Requirement := "All safety tips SHOULD be enabled: \"?\" for unauthenticated senders for spoof non-default policies"

    Output := tests with input as {
        "anti_phish_policies" : [
            {
                "EnableUnauthenticatedSender" : true,
                "Identity" : "Custom policy 1"
            },
            {
                "EnableUnauthenticatedSender" : false,
                "Identity" : "Custom policy 2"
            },
            {
                "EnableUnauthenticatedSender" : true,
                "Identity" : "Custom policy 3"
            },
            {
                "EnableUnauthenticatedSender" : false, # The default policy should be ignored
                "Identity" : "Office365 AntiPhish Default" 
            },
            {
                "EnableUnauthenticatedSender" : false, # The preset policy should be ignored too
                "Identity" : "Standard Preset Security Policy12345" 
            },
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 custom anti phish policy(ies) found where '?' for unauthenticated sender is not enabled: Custom policy 2"
}