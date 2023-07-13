package aad
import future.keywords
import data.report.utils.NotCheckedDetails


#
# MS.AAD.3.1v1
#--
test_PhishingResistantAllMFA_Correct if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantSingleMFA_Correct if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}


test_PhishingResistantNoneMFA_Incorrect if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
"conditional_access_policies": [
    {
        "Conditions":  {
                           "Applications":  {
                                                "ApplicationFilter":  {
                                                                          "Mode":  null,
                                                                          "Rule":  null
                                                                      },
                                                "ExcludeApplications":  [

                                                                        ],
                                                "IncludeApplications":  [
                                                                            "All"
                                                                        ],
                                                "IncludeAuthenticationContextClassReferences":  [],
                                                "IncludeUserActions":  []
                                            },
                           "ClientAppTypes":  [
                                                  "all"
                                              ],
                           "ClientApplications":  {
                                                      "ExcludeServicePrincipals":  null,
                                                      "IncludeServicePrincipals":  null,
                                                      "ServicePrincipalFilter":  {
                                                                                     "Mode":  null,
                                                                                     "Rule":  null
                                                                                 }
                                                  },
                           "DeviceStates":  {
                                                "ExcludeStates":  null,
                                                "IncludeStates":  null
                                            },
                           "Devices":  {
                                           "DeviceFilter":  {
                                                                "Mode":  null,
                                                                "Rule":  null
                                                            },
                                           "ExcludeDeviceStates":  null,
                                           "ExcludeDevices":  null,
                                           "IncludeDeviceStates":  null,
                                           "IncludeDevices":  null
                                       },
                           "Locations":  {
                                             "ExcludeLocations":  null,
                                             "IncludeLocations":  null
                                         },
                           "Platforms":  {
                                             "ExcludePlatforms":  null,
                                             "IncludePlatforms":  null
                                         },
                           "ServicePrincipalRiskLevels":  null,
                           "SignInRiskLevels":  [

                                                ],
                           "UserRiskLevels":  [

                                              ],
                           "Users":  {
                                         "ExcludeGroups":  [

                                                           ],
                                         "ExcludeGuestsOrExternalUsers":  {
                                                                              "ExternalTenants":  {
                                                                                                      "MembershipKind":  null
                                                                                                  },
                                                                              "GuestOrExternalUserTypes":  null
                                                                          },
                                         "ExcludeRoles":  [

                                                          ],
                                         "ExcludeUsers":  [
                                                              "66b4d5c2-71c9-4644-8728-74e3a8324d81"
                                                          ],
                                         "IncludeGroups":  [

                                                           ],
                                         "IncludeGuestsOrExternalUsers":  {
                                                                              "ExternalTenants":  {
                                                                                                      "MembershipKind":  null
                                                                                                  },
                                                                              "GuestOrExternalUserTypes":  null
                                                                          },
                                         "IncludeRoles":  [
                                                              "62e90394-69f5-4237-9190-012177145e10",
                                                              "e8611ab8-c189-46e8-94e1-60213ab1f814",
                                                              "fe930be7-5e62-47db-91af-98c3a49a38b1",
                                                              "f28a1f50-f6e7-4571-818b-6a12f2af6b6c",
                                                              "29232cdf-9323-42fd-ade2-1d097af3e4de",
                                                              "8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2",
                                                              "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3",
                                                              "158c047a-c907-4556-b7ef-446551a6b5f7",
                                                              "b0f54661-2d74-4c50-afa3-1ec803f12efe"
                                                          ],
                                         "IncludeUsers":  []
                                     }
                       },
        "CreatedDateTime":  "/Date(1668112094045)/",
        "Description":  null,
        "DisplayName":  "Live - MFA required for Highly Privileged Roles",
        "GrantControls":  {
                              "AuthenticationStrength":  {
                                                             "AllowedCombinations":  [],
                                                             "CombinationConfigurations":  null,
                                                             "CreatedDateTime":  null,
                                                             "Description":  null,
                                                             "DisplayName":  null,
                                                             "Id":  null,
                                                             "ModifiedDateTime":  null,
                                                             "PolicyType":  null,
                                                             "RequirementsSatisfied":  null
                                                         },
                              "BuiltInControls":  [
                                                      "mfa"
                                                  ],
                              "CustomAuthenticationFactors":  [

                                                              ],
                              "Operator":  "OR",
                              "TermsOfUse":  [

                                             ]
                          },
        "Id":  "9e174715-5697-4695-ac39-92f4af6ac2c4",
        "ModifiedDateTime":  "/Date(1668112265652)/",
        "SessionControls":  {
                                "ApplicationEnforcedRestrictions":  {
                                                                        "IsEnabled":  null
                                                                    },
                                "CloudAppSecurity":  {
                                                         "CloudAppSecurityType":  null,
                                                         "IsEnabled":  null
                                                     },
                                "ContinuousAccessEvaluation":  {
                                                                   "Mode":  null
                                                               },
                                "DisableResilienceDefaults":  null,
                                "PersistentBrowser":  {
                                                          "IsEnabled":  null,
                                                          "Mode":  null
                                                      },
                                "SecureSignInSession":  {
                                                            "IsEnabled":  null
                                                        },
                                "SignInFrequency":  {
                                                        "AuthenticationType":  null,
                                                        "FrequencyInterval":  null,
                                                        "IsEnabled":  null,
                                                        "Type":  null,
                                                        "Value":  null
                                                    }
                            },
        "State":  "enabled",
        "AdditionalProperties":  {

                                 }
    }
]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    #RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantMFAExcludeApp_Incorrect if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : ["Some App"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantMFAExcludeUser_Incorrect if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["me"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_PhishingResistantMFAExcludeGroup_Incorrect if {
    PolicyId := "MS.AAD.3.1v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"],
                        "ExcludeApplications" : []
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["some"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "AuthenticationStrength" : {
                        "AllowedCombinations":  [
                            "windowsHelloForBusiness",
                            "fido2",
                            "x509CertificateMultiFactor"
                        ]
                    }
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
#--

#
# MS.AAD.3.2v1
#--
test_NoExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExemptUsers_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_NoExclusionsExemptGroups_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                        "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# User exclusions test
test_UserExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsNoExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_MultiUserExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "Groups" : []
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# Group Exclusion tests
test_GroupExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsNoExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_GroupExclusionsSingleExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_MultiGroupExclusionsConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

# User and group exclusions tests
test_UserGroupExclusionConditions_Correct if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test name. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionNoExempt_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionUserExemptOnly_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "Groups" : []
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionGroupExemptOnly_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a7c3609b425-9dd7-5e3"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : [],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_UserGroupExclusionTooFewUserExempts_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423", "65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "ExcludeGroups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test name"
            }
        ],
        "scuba_config" : {
            "Aad" : {
                "MS.AAD.3.2v1" : {
                    "CapExclusions" : {
                        "Users" : ["65fea286-22d3-42f9-b4ca-93a6f75817d4"],
                        "Groups" : ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    }
                }
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

# Other conditions
test_ConditionalAccessPolicies_Correct_V1 if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test Policy require MFA for All Users. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["Office365"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Users, but not all Apps"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeUsers_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeGroups_Incorrect if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeRoles_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : [""]
                },
                "State" : "enabled",
                "DisplayName" : "Test Policy does not require MFA"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.2v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"],
                        "ExcludeUsers" : [],
                        "ExcludeGroups" : [],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "disabled",
                "DisplayName" : "Test Policy is correct, but not enabled"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
#--

#
# MS.AAD.3.3v1
#--
test_NotImplemented_Correct_V2 if {
    PolicyId := "MS.AAD.3.3v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--

#
# MS.AAD.3.4v1
#--
test_NotImplemented_Correct_V3 if {
    PolicyId := "MS.AAD.3.4v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--

#
# MS.AAD.3.5v1
#--
test_NotImplemented_Correct_V4 if {
    PolicyId := "MS.AAD.3.5v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--

#
# MS.AAD.3.6v1
#--
test_ConditionalAccessPolicies_Correct_V2 if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect_V2 if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : [""]
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect_V2 if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : [""]
                },
                "State" : "enabled",
                "DisplayName" : {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect_V2 if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2" ],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "disabled",
                "DisplayName" : {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeRoles_Incorrect_V1 if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            },
            {
                "RoleTemplateId" : "Role2",
                "DisplayName" : "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeRoles_Incorrect_V3 if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role2"],
                        "ExcludeRoles" : []
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeRoles_Incorrect_V2 if {
    PolicyId := "MS.AAD.3.6v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeRoles" : ["Role1", "Role2"],
                        "ExcludeRoles" : ["Role1"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["mfa"]
                },
                "State" : "enabled",
                "DisplayName" : {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles" : [
            {
                "RoleTemplateId" : "Role1",
                "DisplayName" : "Global Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
#--

#
# MS.AAD.3.7v1
#--
test_ConditionalAccessPolicies_Correct_V3 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["domainJoinedDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>AD Joined Device Authentication Policy. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Correct if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>AD Joined Device Authentication Policy. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect_V3 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : [""]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect_V2 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : [""]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice"]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect_V3 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : [""]
                },
                "State" : "enabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect_V3 if {
    PolicyId := "MS.AAD.3.7v1"

    Output := tests with input as {
        "conditional_access_policies" : [
            {
                "Conditions" : {
                    "Applications" : {
                        "IncludeApplications" : ["All"]
                    },
                    "Users" : {
                        "IncludeUsers" : ["All"]
                    }
                },
                "GrantControls" : {
                    "BuiltInControls" : ["compliantDevice"]
                },
                "State" : "disabled",
                "DisplayName" : "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}
#--

#
# MS.AAD.3.8v1
#--
test_NotImplemented_Correct_V5 if {
    PolicyId := "MS.AAD.3.8v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--