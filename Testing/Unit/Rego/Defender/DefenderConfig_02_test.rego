package defender
import future.keywords

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
test_AgencyDomains_Correct_V1 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                    "AgencyDomains" : [
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

test_AgencyDomains_Correct_V2 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                    "AgencyDomains" : [
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

test_AgencyDomains_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                    "AgencyDomains" : [
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
    RuleOutput[0].ReportDetails == "Not all agency domains are included for targeted protection in Standard policy."
}

test_AgencyDomains_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                    "AgencyDomains" : [
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
    RuleOutput[0].ReportDetails == "Not all agency domains are included for targeted protection in Strict policy."
}

test_AgencyDomains_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                    "AgencyDomains" : [
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
    RuleOutput[0].ReportDetails == "Not all agency domains are included for targeted protection in Strict or Standard policy."
}

test_AgencyDomains_Incorrect_V4 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                    "AgencyDomains" : [
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
    RuleOutput[0].ReportDetails == "Not all agency domains are included for targeted protection in Standard policy."
}

test_AgencyDomains_Incorrect_V5 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                    "AgencyDomains" : [
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
    RuleOutput[0].ReportDetails == "Not all agency domains are included for targeted protection in Standard policy."
}

test_AgencyDomains_Incorrect_V6 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                    "AgencyDomains" : [
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
    RuleOutput[0].ReportDetails == "Not all agency domains are included for targeted protection in Strict policy."
}

test_AgencyDomains_Incorrect_V7 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Not all agency domains are included for targeted protection in Strict or Standard policy."
}

test_AgencyDomains_Incorrect_V8 if {
    PolicyId := "MS.DEFENDER.2.2v1"

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
                "MS.DEFENDER.2.2v1" : {
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "No agency domains defined for impersonation protection assessment. See configuration file documentation for details on how to define."
}

#
# Policy 3
#--
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