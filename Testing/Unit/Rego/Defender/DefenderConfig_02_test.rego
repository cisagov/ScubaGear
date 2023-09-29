package defender
import future.keywords

# TODO: Policy Id(s) needs to be resolved

#
# Policy 1
#--
test_TargetedUsers_Correct_V1 if {
    PolicyId := "MS.DEFENDER.2.1v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.1v1" : {
                    "SensitiveUsers" : [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TargetedUsers_Correct_V2 if {
    PolicyId := "MS.DEFENDER.2.1v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.1v1" : {
                    "SensitiveUsers" : [
                        "John Doe;jdoe@someemail.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TargetedUsers_Correct_V3 if {
    PolicyId := "MS.DEFENDER.2.1v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.1v1" : {
                    "SensitiveUsers" : [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_TargetedUsers_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.2.1v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.1v1" : {
                    "SensitiveUsers" : [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all sensitive users are included for targeted protection in Standard policy."
}

test_TargetedUsers_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.2.1v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.1v1" : {
                    "SensitiveUsers" : [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all sensitive users are included for targeted protection in Strict policy."
}

test_TargetedUsers_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.2.1v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Some Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.1v1" : {
                    "SensitiveUsers" : [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all sensitive users are included for targeted protection in Strict or Standard policy."
}

test_TargetedUsers_Incorrect_V4 if {
    PolicyId := "MS.DEFENDER.2.1v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : false,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.1v1" : {
                    "SensitiveUsers" : [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all sensitive users are included for targeted protection in Standard policy."
}

test_TargetedUsers_Incorrect_V5 if {
    PolicyId := "MS.DEFENDER.2.1v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : false,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.1v1" : {
                    "SensitiveUsers" : [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all sensitive users are included for targeted protection in Standard policy."
}

test_TargetedUsers_Incorrect_V6 if {
    PolicyId := "MS.DEFENDER.2.1v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedUserProtection" : true,
                "TargetedUsersToProtect" : [
                    "John Doe;jdoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.1v1" : {
                    "SensitiveUsers" : [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all sensitive users are included for targeted protection in Strict policy."
}

#
# Policy 2
#--
# test_OrganizationDomain_Correct if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
#                 "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableOrganizationDomainsProtection" : true,
#                 "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainProtectionAction" : "Quarantine",
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_Enabled_Incorrect_V2 if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

#     Output := tests with input as {
#        "anti_phish_policies" : [
#             {
#                 "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : false,
#                 "EnableOrganizationDomainsProtection" : true,
#                 "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainProtectionAction" : "Quarantine",
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement not met"
# }

# test_EnableOrganizationDomainsProtection_Incorrect if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

#     Output := tests with input as {
#        "anti_phish_policies" : [
#             {
#                 "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableOrganizationDomainsProtection" : false,
#                 "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainProtectionAction" : "Quarantine",
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement not met"
# }

# test_EnableTargetedDomainsProtection_Incorrect if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be enabled for domains owned by the agency"

#     Output := tests with input as {
#        "anti_phish_policies" : [
#             {
#                 "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableOrganizationDomainsProtection" : true,
#                 "EnableTargetedDomainsProtection" : false,
#                 "TargetedDomainProtectionAction" : "Quarantine",
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement not met"
# }

#
# Policy 3
#--
# test_CustomDomains_Correct if {
#     ControlNumber := "Defender 2.5"
#     Requirement := "Domain impersonation protection SHOULD be added for frequent partners"

#     Output := tests with input as {
#         "anti_phish_policies" : [
#             {
#                 "Name" : "Standard Preset Security Policy1659535429826",
#                 "Enabled" : true,
#                 "EnableTargetedDomainsProtection" : true,
#                 "TargetedDomainsToProtect" : [ "test domain" ],
#                 "TargetedDomainProtectionAction" : "Quarantine"
#             }
#         ]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

test_CustomDomains_Correct_V1 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                    "PartnerDomains" : [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_CustomDomains_Correct_V2 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                    "PartnerDomains" : [
                        "random.mail.example.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_CustomDomains_Correct_V3 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                    "PartnerDomains" : [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_CustomDomains_Correct_V4 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : null,
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : null,
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_CustomDomains_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                    "PartnerDomains" : [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all partner domains are included for targeted protection in Standard policy."
}

test_CustomDomains_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                    "PartnerDomains" : [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all partner domains are included for targeted protection in Strict policy."
}

test_CustomDomains_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Some Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                    "PartnerDomains" : [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all partner domains are included for targeted protection in Strict or Standard policy."
}

test_CustomDomains_Incorrect_V4 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : false,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                    "PartnerDomains" : [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all partner domains are included for targeted protection in Standard policy."
}

test_CustomDomains_Incorrect_V5 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : false,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                    "PartnerDomains" : [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all partner domains are included for targeted protection in Standard policy."
}

test_CustomDomains_Incorrect_V6 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                    "PartnerDomains" : [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all partner domains are included for targeted protection in Strict policy."
}

test_CustomDomains_Incorrect_V7 if {
    PolicyId := "MS.DEFENDER.2.3v1"

    Output := tests with input as {
        "anti_phish_policies": [
            {
                "Identity" : "Standard Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity" : "Strict Preset Security Policy1659535429826",
                "Enabled" : true,
                "EnableTargetedDomainsProtection" : true,
                "TargetedDomainsToProtect" : [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config" : {
            "Defender" : {
                "MS.DEFENDER.2.3v1" : {
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all partner domains are included for targeted protection in Strict or Standard policy."
}