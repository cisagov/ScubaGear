package aad
import future.keywords
import data.report.utils.NotCheckedDetails


#
# MS.AAD.7.1v1
#--
test_PrivilegedUsers_Correct if {
    PolicyId := "MS.AAD.7.1v1"

    Output := tests with input as {
        "privileged_users" : {
            "User1" : {
                "DisplayName" : "Test Name1",
                "roles" : ["Privileged Role Administrator", "Global Administrator"]
            },
            "User2" : {
                "DisplayName" : "Test Name2",
                "roles" : ["Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "2 global admin(s) found:<br/>Test Name1, Test Name2"
}

test_PrivilegedUsers_Incorrect_V1 if {
    PolicyId := "MS.AAD.7.1v1"

    Output := tests with input as {
        "privileged_users" : {
            "User1" : {
                "DisplayName" : "Test Name1",
                "roles" : ["Privileged Role Administrator", "Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 global admin(s) found:<br/>Test Name1"
}

test_PrivilegedUsers_Incorrect_V2 if {
    PolicyId := "MS.AAD.7.1v1"

    Output := tests with input as {
        "privileged_users" : {
            "User1" : {
                "DisplayName" : "Test Name1",
                "roles" : ["Privileged Role Administrator", "Global Administrator"]
            },
            "User2" : {
                "DisplayName" : "Test Name2",
                "roles" : ["Global Administrator"]
            },
            "User3" : {
                "DisplayName" : "Test Name3",
                "roles" : ["Global Administrator"]
            },
            "User4" : {
                "DisplayName" : "Test Name4",
                "roles" : ["Global Administrator"]
            },
            "User5" : {
                "DisplayName" : "Test Name5",
                "roles" : ["Global Administrator"]
            },
            "User6" : {
                "DisplayName" : "Test Name6",
                "roles" : ["Global Administrator"]
            },
            "User7" : {
                "DisplayName" : "Test Name7",
                "roles" : ["Global Administrator"]
            },
            "User8" : {
                "DisplayName" : "Test Name8",
                "roles" : ["Global Administrator"]
            },
            "User9" : {
                "DisplayName" : "Test Name9",
                "roles" : ["Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "9 global admin(s) found:<br/>Test Name1, Test Name2, Test Name3, Test Name4, Test Name5, Test Name6, Test Name7, Test Name8, Test Name9"
}
#--

#
# MS.AAD.7.2v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.7.2v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--

#
# MS.AAD.7.3v1
#--
test_OnPremisesImmutableId_Correct if {
    PolicyId := "MS.AAD.7.3v1"

    Output := tests with input as {
        "privileged_users" : {
            "User1" : {
                "DisplayName" : "Alice",
                "OnPremisesImmutableId" : null,
                "roles" : ["Privileged Role Administrator", "Global Administrator"]
            },
            "User2" : {
                "DisplayName" : "Bob",
                "OnPremisesImmutableId" : null,
               "roles" : ["Global Administrator"]
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 admin(s) that are not cloud-only found"
}

test_OnPremisesImmutableId_Incorrect_V1 if {
    PolicyId := "MS.AAD.7.3v1"

    Output := tests with input as {
        "privileged_users" : {
            "User1" : {
                "DisplayName" : "Alice",
                "OnPremisesImmutableId" : "HelloWorld",
                "roles" : ["Privileged Role Administrator", "Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 admin(s) that are not cloud-only found:<br/>Alice"
}

test_OnPremisesImmutableId_Incorrect_V2 if {
    PolicyId := "MS.AAD.7.3v1"

    Output := tests with input as {
        "privileged_users" : {
            "User1" : {
                "DisplayName" : "Alice",
                "OnPremisesImmutableId" : "HelloWorld",
                "roles" : ["Privileged Role Administrator", "Global Administrator"]
            },
            "User2" : {
                "DisplayName" : "Bob",
                "OnPremisesImmutableId" : null,
                "roles" : ["Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 admin(s) that are not cloud-only found:<br/>Alice"
}
#--

#
# MS.AAD.7.4v1
#--
test_AdditionalProperties_Correct_V1 if {
    PolicyId := "MS.AAD.7.4v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" : "Expiration_Admin_Assignment",
                        "AdditionalProperties" : {
                            "isExpirationRequired" : true,
                            "maximumDuration" : "P15D"
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 role(s) configured to allow permanent active assignment or expiration period too long"
}

test_AdditionalProperties_Incorrect_V1 if {
    PolicyId := "MS.AAD.7.4v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" : "Expiration_Admin_Assignment",
                        "AdditionalProperties" : {
                            "isExpirationRequired" : false,
                            "maximumDuration" : "P30D"
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) configured to allow permanent active assignment or expiration period too long:<br/>Global Administrator"
}

test_AdditionalProperties_Incorrect_V2 if {
    PolicyId := "MS.AAD.7.4v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" : "Expiration_Admin_Assignment",
                        "AdditionalProperties" : {
                            "isExpirationRequired" : true,
                            "maximumDuration" : "P30D"
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) configured to allow permanent active assignment or expiration period too long:<br/>Global Administrator"
}
#--

#
# MS.AAD.7.5v1
#--
test_Assignments_Correct if {
    PolicyId := "MS.AAD.7.5v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "DisplayName" : "Global Administrator",
                "Assignments" : [
                    {
                        "StartDateTime" : "/Date(1660328610000)/"
                    }
                ],
                "Rules" : [
                    {
                        "Id" : "Expiration_Admin_Assignment",
                        "AdditionalProperties" : {
                            "isExpirationRequired" : true,
                            "maximumDuration" : "P30D"
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 role(s) assigned to users outside of PIM"
}

test_Assignments_Incorrect if {
    PolicyId := "MS.AAD.7.5v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "DisplayName" : "Global Administrator",
                "Assignments" : [
                    {
                        "StartDateTime" : null
                    }
                ],
                "Rules" : [
                    {
                        "Id" : "Expiration_Admin_Assignment",
                        "AdditionalProperties" : {
                            "isExpirationRequired" : true,
                            "maximumDuration" : "P30D"
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) assigned to users outside of PIM:<br/>Global Administrator"
}
#--

#
# MS.AAD.7.6v1
#--
test_AdditionalProperties_Correct_V2 if {
    PolicyId := "MS.AAD.7.6v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Approval_EndUser_Assignment",
                        "AdditionalProperties" :  {
                            "setting" : {
                                "isApprovalRequired" : true
                            }
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AdditionalProperties_Correct_V3 if {
    PolicyId := "MS.AAD.7.6v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Approval_EndUser_Assignment",
                        "AdditionalProperties" :  {
                            "setting" : {
                                "isApprovalRequired" : true
                            }
                        }
                    }
                ]
            },
            {
                "DisplayName" : "Groups Administrator",
                "Rules" : [
                    {
                        "Id" :  "Approval_EndUser_Assignment",
                        "AdditionalProperties" :  {
                            "setting" : {
                                "isApprovalRequired" : false # this shouldn't matter, only Global Admin matters for this control
                            }
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AdditionalProperties_Incorrect_V3 if {
    PolicyId := "MS.AAD.7.6v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Approval_EndUser_Assignment",
                        "AdditionalProperties" :  {
                            "setting" : {
                                "isApprovalRequired" : false
                            }
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--

#
# MS.AAD.7.7v1
#--
test_notificationRecipients_Correct if {
    PolicyId := "MS.AAD.7.7v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "RoleTemplateId" : "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties" :  {
                            "notificationRecipients" :  ["test@example.com"]
                        }
                    },
                    {
                        "Id" :  "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties" :  {
                        "notificationRecipients" :  ["test@example.com"]
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 role(s) without notification e-mail configured for role assignments found"
}

test_notificationRecipients_Incorrect_V1 if {
    PolicyId := "MS.AAD.7.7v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "RoleTemplateId" : "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties" :  {
                            "notificationRecipients" :  []
                        }
                    },
                    {
                        "Id" :  "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties" :  {
                        "notificationRecipients" :  ["test@example.com"]
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) without notification e-mail configured for role assignments found:<br/>Global Administrator"
}

test_notificationRecipients_Incorrect_V2 if {
    PolicyId := "MS.AAD.7.7v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "RoleTemplateId" : "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties" :  {
                            "notificationRecipients" :  ["test@example.com"]
                        }
                    },
                    {
                        "Id" :  "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties" :  {
                        "notificationRecipients" :  []
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) without notification e-mail configured for role assignments found:<br/>Global Administrator"
}

test_notificationRecipients_Incorrect_V3 if {
    PolicyId := "MS.AAD.7.7v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "RoleTemplateId" : "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties" :  {
                            "notificationRecipients" :  []
                        }
                    },
                    {
                        "Id" :  "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties" :  {
                        "notificationRecipients" :  []
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) without notification e-mail configured for role assignments found:<br/>Global Administrator"
}
#--

#
# MS.AAD.7.8v1
#--
test_Id_Correct_V1 if {
    PolicyId := "MS.AAD.7.8v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "RoleTemplateId" : "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties" :  {
                        "notificationType" :  "Email",
                        "notificationRecipients" :  ["test@example.com"]
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Id_Correct_V2 if {
    PolicyId := "MS.AAD.7.8v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "RoleTemplateId" : "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties" :  {
                        "notificationType" :  "",
                        "notificationRecipients" :  ["test@example.com"]
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Id_Incorrect if {
    PolicyId := "MS.AAD.7.8v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "RoleTemplateId" : "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties" :  {
                        "notificationType" :  "Email",
                        "notificationRecipients" :  []
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}
#--

#
# MS.AAD.7.9v1
#--

test_DisplayName_Correct if {
    PolicyId := "MS.AAD.7.9v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "RoleTemplateId" : "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName" : "Global Administrator",
                "Rules" : [
                    {
                        "Id" :  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties" :  {
                        "notificationType" :  "Email",
                        "notificationRecipients" :  []
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 role(s) without notification e-mail configured for role activations found"
}

test_DisplayName_Incorrect if {
    PolicyId := "MS.AAD.7.9v1"

    Output := tests with input as {
        "privileged_roles" : [
            {
                "RoleTemplateId" : "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName" : "Cloud Administrator",
                "Rules" : [
                    {
                        "Id" :  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties" :  {
                        "notificationType" :  "Email",
                        "notificationRecipients" :  []
                        }
                    }
                ]
            }
        ],
        "service_plans" : [
            { "ServicePlanName" : "EXCHANGE_S_FOUNDATION",
                "ServicePlanId" : "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName" : "AAD_PREMIUM_P2",
                "ServicePlanId" : "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) without notification e-mail configured for role activations found:<br/>Cloud Administrator"
}
#--