package defender
import future.keywords

#
# Policy 1
#--
test_Enabled_Correct_V1 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Enabled"
            },
            {
                "Identity" : "Strict Preset Security Policy",
                "State" : "Enabled"
            }
        ],
        "atp_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Enabled"
            },
            {
                "Identity" : "Strict Preset Security Policy",
                "State" : "Enabled"
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Enabled_Correct_V2 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Enabled"
            },
            {
                "Identity" : "Strict Preset Security Policy",
                "State" : "Enabled"
            }
        ],
        "atp_policy_rules" : [],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Enabled_Correct_V3 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {
        "protection_policy_rules" : [],
        "atp_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Enabled"
            },
            {
                "Identity" : "Strict Preset Security Policy",
                "State" : "Enabled"
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Enabled_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {
        "protection_policy_rules" : [],
        "atp_policy_rules" : [],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Standard and Strict preset policies are both disabled"
}

test_Enabled_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Disabled"
            }
        ],
        "atp_policy_rules" : [],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Standard and Strict preset policies are both disabled"
}

test_Enabled_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Enabled"
            }
        ],
        "atp_policy_rules" : [],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Strict preset policy is disabled"
}

test_Enabled_Incorrect_V4 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Disabled"
            },
            {
                "Identity" : "Strict Preset Security Policy",
                "State" : "Disabled"
            }
        ],
        "atp_policy_rules" : [],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Standard and Strict preset policies are both disabled"
}
#--

#
# Policy 2
#--
test_AllEOP_Correct_V1 if {
    PolicyId := "MS.DEFENDER.1.2v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllEOP_Correct_V2 if {
    PolicyId := "MS.DEFENDER.1.2v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllEOP_Correct_V3 if {
    PolicyId := "MS.DEFENDER.1.2v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            },
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": ["user@example.com"],
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllEOP_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.1.2v1"

    Output := tests with input as {
        "protection_policy_rules" : []
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllEOP_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.1.2v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": ["user@example.com"],
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllEOP_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.1.2v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": ["user@example.com"],
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            },
            {
                "Identity" : "Standard Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": ["example.com"]
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--

#
# Policy 3
#--
test_AllDefender_Correct_V1 if {
    PolicyId := "MS.DEFENDER.1.3v1"

    Output := tests with input as {
        "atp_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllDefender_Correct_V2 if {
    PolicyId := "MS.DEFENDER.1.3v1"

    Output := tests with input as {
        "atp_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllDefender_Correct_V3 if {
    PolicyId := "MS.DEFENDER.1.3v1"

    Output := tests with input as {
        "atp_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            },
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": ["user@example.com"],
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllDefender_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.1.3v1"

    Output := tests with input as {
        "atp_policy_rules" : [],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllDefender_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.1.3v1"

    Output := tests with input as {
        "atp_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": ["user@example.com"],
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllDefender_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.1.3v1"

    Output := tests with input as {
        "atp_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": ["user@example.com"],
                "SentToMemberOf": null,
                "RecipientDomainIs": null
            },
            {
                "Identity" : "Standard Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": ["example.com"]
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_AllDefender_Incorrect_V4 if {
    PolicyId := "MS.DEFENDER.1.3v1"

    Output := tests with input as {
        "atp_policy_rules" : [],
        "defender_license": false
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}

#
# Policy 4
#--

### Case 1 & 2###
test_SensitiveEOP_Correct_V1 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [],
                        "IncludedGroups" : [],
                        "IncludedDomains" : [],
                        "ExcludedUsers" : [],
                        "ExcludedGroups" : [],
                        "ExcludedDomains" : []
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V2 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {}
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V3 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V4 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V5 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V6 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "ExcludedUsers" : [
                            "johndoe@random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V7 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "ExcludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V8 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "ExcludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V9 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ],
                        "ExcludedUsers" : [
                            "janedoe@random.mail.example.com"
                        ],
                        "ExcludedGroups" : [
                            "Dune12"
                        ],
                        "ExcludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [],
                        "IncludedGroups" : [],
                        "IncludedDomains" : [],
                        "ExcludedUsers" : [],
                        "ExcludedGroups" : [],
                        "ExcludedDomains" : []
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [],
                        "IncludedGroups" : [],
                        "IncludedDomains" : [],
                        "ExcludedUsers" : [],
                        "ExcludedGroups" : [],
                        "ExcludedDomains" : []
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 3 ###
test_SensitiveEOP_Correct_V10 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V11 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V4 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 4 ###
test_SensitiveEOP_Correct_V12 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is part of Dune group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V13 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is part of Dune group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V5 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V6 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V7 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V8 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 5 ###
test_SensitiveEOP_Correct_V14 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V15 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Incorrect_V9 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V10 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V11 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.mail.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V12 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.mail.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V13 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.mail.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V14 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 6 ###
test_SensitiveEOP_Correct_V16 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is part of Dune group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V17 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is part of Dune group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V18 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is part of Dune group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V19 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is part of Dune group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V15 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V16 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V17 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.mail.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V18 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.mail.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V19 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.mail.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V20 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V21 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V22 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V23 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V24 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 7 ###
test_SensitiveEOP_Correct_V20 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is not part of Dune12 group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V21 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is not part of Dune12 group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V25 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V26 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V27 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 8 ###
test_SensitiveEOP_Correct_V22 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V23 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Incorrect_V28 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.mail.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V29 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.mail.example.com",
                    "janedoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V30 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.mail.example.com",
                    "janedoe@random.mail.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V31 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.mail.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V32 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.mail.example.com",
                    "janedoe@random.mail.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.mail.example.com",
                            "janedoe@random.mail.example.com"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 9 ###
test_SensitiveEOP_Correct_V24 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is not part of Dune12 group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V25 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is not part of Dune12 group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V26 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is part of Dune group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V27 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is part of Dune group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V28 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is not part of Dune12 group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V29 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that user is not part of Dune12 group, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V33 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V34 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com",
                    "janedoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V35 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": [
                    "janedoe@random.example.com"
                ],
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": [
                    "johndoe@random.example.com"
                ],
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedUsers" : [
                            "johndoe@random.example.com",
                            "janedoe@random.example.com"
                        ],
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 10 ###
test_SensitiveEOP_Correct_V30 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V31 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Incorrect_V36 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V37 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune12"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V38 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 11 ###
test_SensitiveEOP_Correct_V32 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that Dune group has users in domain, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V33 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that Dune group has users in domain, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V39 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune"
                ],
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune12"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V40 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V41 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 12 ###
test_SensitiveEOP_Correct_V33 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that Dune group does not have users in domain, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Correct_V34 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    # Test is set so that Dune group does not have users in domain, so the test should pass;
    # However, do not currently posses the ability to check users against group so test fails
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V42 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V43 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune",
                    "Dune12"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V44 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": [
                    "Dune12"
                ],
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": [
                    "Dune"
                ],
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedGroups" : [
                            "Dune",
                            "Dune12"
                        ],
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

### Case 13 ###
test_SensitiveEOP_Correct_V36 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Correct_V37 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": null,
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedDomains" : [
                            "random.mail.example.com",
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveEOP_Incorrect_V45 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": [
                    "random.mail.example.com"
                ],
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedDomains" : [
                            "random.mail.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V46 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": [
                    "random.mail.example.com"
                ],
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": [
                    "random.example.com"
                ],
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedDomains" : [
                            "random.mail.example.com",
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveEOP_Incorrect_V47 if {
    PolicyId := "MS.DEFENDER.1.4v1"

    Output := tests with input as {
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "SentTo": null,
                "SentToMemberOf": null,
                "RecipientDomainIs": null,
                "ExceptIfSentTo": null,
                "ExceptIfSentToMemberOf": null,
                "ExceptIfRecipientDomainIs": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.1.4v1" : {
                    "SensitiveAccounts" : {
                        "IncludedDomains" : [
                            "random.mail.example.com",
                            "random.example.com"
                        ]
                    }
                }
            }
        },
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--

#
# Policy 5
#--
test_SensitiveAtp_Correct_V1 if {
    PolicyId := "MS.DEFENDER.1.5v1"

    Output := tests with input as {
        "atp_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy"
            }
        ],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_SensitiveAtp_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.1.5v1"

    Output := tests with input as {
        "atp_policy_rules" : [],
        "defender_license": true
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_SensitiveAtp_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.1.5v1"

    Output := tests with input as {
        "atp_policy_rules" : [],
        "defender_license": false
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met **NOTE: Either you do not have sufficient permissions or your tenant does not have a license for Microsoft Defender for Office 365 Plan 1, which is required for this feature.**"
}
#--