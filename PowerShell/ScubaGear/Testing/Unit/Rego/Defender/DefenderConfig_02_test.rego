package defender_test
import rego.v1
import data.defender
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.DEFENDER.2.1v1
#--
test_TargetedUsers_Correct_V1 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.1v1": {
                    "SensitiveUsers": [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    TestResult("MS.DEFENDER.2.1v1", Output, PASS, true) == true
}

test_TargetedUsers_Correct_V2 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.1v1": {
                    "SensitiveUsers": [
                        "John Doe;jdoe@someemail.com"
                    ]
                }
            }
        }
    }

    TestResult("MS.DEFENDER.2.1v1", Output, PASS, true) == true
}

test_TargetedUsers_Correct_V3 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.1v1": {
                    "SensitiveUsers": [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    TestResult("MS.DEFENDER.2.1v1", Output, PASS, true) == true
}

test_TargetedUsers_Incorrect_V1 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.1v1": {
                    "SensitiveUsers": [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all sensitive users are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V2 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.1v1": {
                    "SensitiveUsers": [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all sensitive users are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V3 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Some Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.1v1": {
                    "SensitiveUsers": [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all sensitive users are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V4 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": false,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.1v1": {
                    "SensitiveUsers": [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all sensitive users are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V5 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": false,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.1v1": {
                    "SensitiveUsers": [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all sensitive users are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}

test_TargetedUsers_Incorrect_V6 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com",
                    "Jane Doe;jadoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedUserProtection": true,
                "TargetedUsersToProtect": [
                    "John Doe;jdoe@someemail.com"
                ],
                "TargetedUserProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.1v1": {
                    "SensitiveUsers": [
                        "John Doe;jdoe@someemail.com",
                        "Jane Doe;jadoe@someemail.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all sensitive users are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.DEFENDER.2.2v1
#--
test_AgencyDomains_Correct_V1 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {
                    "AgencyDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    TestResult("MS.DEFENDER.2.2v1", Output, PASS, true) == true
}

test_AgencyDomains_Correct_V2 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {
                    "AgencyDomains": [
                        "random.mail.example.com"
                    ]
                }
            }
        }
    }

    TestResult("MS.DEFENDER.2.2v1", Output, PASS, true) == true
}

test_AgencyDomains_Incorrect_V1 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {
                    "AgencyDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all agency domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V2 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {
                    "AgencyDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all agency domains are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V3 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Some Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {
                    "AgencyDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all agency domains are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V4 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": false,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {
                    "AgencyDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all agency domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V5 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": false,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {
                    "AgencyDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all agency domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V6 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {
                    "AgencyDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all agency domains are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V7 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {}
            }
        }
    }

    ReportDetailString := "Not all agency domains are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}

test_AgencyDomains_Incorrect_V8 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": null,
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": null,
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.2v1": {}
            }
        }
    }

    ReportDetailString := concat(" ", [
        "No agency domains defined for impersonation protection assessment.",
        "See configuration file documentation for details on how to define."
    ])
    TestResult("MS.DEFENDER.2.2v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.DEFENDER.2.3v1
#--
test_CustomDomains_Correct_V1 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {
                    "PartnerDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    TestResult("MS.DEFENDER.2.3v1", Output, PASS, true) == true
}

test_CustomDomains_Correct_V2 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {
                    "PartnerDomains": [
                        "random.mail.example.com"
                    ]
                }
            }
        }
    }

    TestResult("MS.DEFENDER.2.3v1", Output, PASS, true) == true
}

test_CustomDomains_Correct_V3 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {
                    "PartnerDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    TestResult("MS.DEFENDER.2.3v1", Output, PASS, true) == true
}

test_CustomDomains_Correct_V4 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": null,
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": null,
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {}
            }
        }
    }

    TestResult("MS.DEFENDER.2.3v1", Output, PASS, true) == true
}

test_CustomDomains_Incorrect_V1 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {
                    "PartnerDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all partner domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V2 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {
                    "PartnerDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all partner domains are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V3 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Some Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {
                    "PartnerDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all partner domains are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V4 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": false,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {
                    "PartnerDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all partner domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V5 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": false,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {
                    "PartnerDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all partner domains are included for targeted protection in Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V6 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {
                    "PartnerDomains": [
                        "random.mail.example.com",
                        "random.example.com"
                    ]
                }
            }
        }
    }

    ReportDetailString := "Not all partner domains are included for targeted protection in Strict policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}

test_CustomDomains_Incorrect_V7 if {
    Output := defender.tests with input as {
        "anti_phish_policies": [
            {
                "Identity": "Standard Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            },
            {
                "Identity": "Strict Preset Security Policy1659535429826",
                "Enabled": true,
                "EnableTargetedDomainsProtection": true,
                "TargetedDomainsToProtect": [
                    "random.mail.example.com",
                    "random.example.com"
                ],
                "TargetedDomainProtectionAction": "Quarantine"
            }
        ],
        "scuba_config": {
            "Defender": {
                "MS.DEFENDER.2.3v1": {}
            }
        }
    }

    ReportDetailString := "Not all partner domains are included for targeted protection in Strict or Standard policy."
    TestResult("MS.DEFENDER.2.3v1", Output, ReportDetailString, false) == true
}
#--