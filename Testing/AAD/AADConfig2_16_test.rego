package aad
import future.keywords


#
# Policy 1
#--
test_notificationRecipients_Correct if {
    ControlNumber := "AAD 2.16"
    Requirement := "Eligible and Active highly privileged role assignments SHALL trigger an alert"

    Output := tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties":  {
                            "notificationRecipients":  ["test@example.com"]
                        }
                    },
                    {
                        "Id":  "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties":  {
                        "notificationRecipients":  ["test@example.com"]
                        }
                    }
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 role(s) without notification e-mail configured for role assignments found"
}

test_notificationRecipients_Incorrect_V1 if {
    ControlNumber := "AAD 2.16"
    Requirement := "Eligible and Active highly privileged role assignments SHALL trigger an alert"

    Output := tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties":  {
                            "notificationRecipients":  []
                        }
                    },
                    {
                        "Id":  "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties":  {
                        "notificationRecipients":  ["test@example.com"]
                        }
                    }
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) without notification e-mail configured for role assignments found:<br/>Global Administrator"
}

test_notificationRecipients_Incorrect_V2 if {
    ControlNumber := "AAD 2.16"
    Requirement := "Eligible and Active highly privileged role assignments SHALL trigger an alert"

    Output := tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties":  {
                            "notificationRecipients":  ["test@example.com"]
                        }
                    },
                    {
                        "Id":  "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties":  {
                        "notificationRecipients":  []
                        }
                    }
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) without notification e-mail configured for role assignments found:<br/>Global Administrator"
}

test_notificationRecipients_Incorrect_V3 if {
    ControlNumber := "AAD 2.16"
    Requirement := "Eligible and Active highly privileged role assignments SHALL trigger an alert"

    Output := tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Notification_Admin_Admin_Assignment",
                        "AdditionalProperties":  {
                            "notificationRecipients":  []
                        }
                    },
                    {
                        "Id":  "Notification_Admin_Admin_Eligibility",
                        "AdditionalProperties":  {
                        "notificationRecipients":  []
                        }
                    }
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) without notification e-mail configured for role assignments found:<br/>Global Administrator"
}

test_Id_Correct_V1 if {
    ControlNumber := "AAD 2.16"
    Requirement := "User activation of the Global Administrator role SHALL trigger an alert"

    Output := tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties":  {
                        "notificationType":  "Email",
                        "notificationRecipients":  ["test@example.com"]
                        }
                    }
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Id_Correct_V2 if {
    ControlNumber := "AAD 2.16"
    Requirement := "User activation of the Global Administrator role SHALL trigger an alert"

    Output := tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties":  {
                        "notificationType":  "",
                        "notificationRecipients":  ["test@example.com"]
                        }
                    }
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Id_Incorrect if {
    ControlNumber := "AAD 2.16"
    Requirement := "User activation of the Global Administrator role SHALL trigger an alert"

    Output := tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties":  {
                        "notificationType":  "Email",
                        "notificationRecipients":  []
                        }
                    }
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

test_DisplayName_Correct if {
    ControlNumber := "AAD 2.16"
    Requirement := "User activation of other highly privileged roles SHOULD trigger an alert"

    Output := tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Global Administrator",
                "Rules": [
                    {
                        "Id":  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties":  {
                        "notificationType":  "Email",
                        "notificationRecipients":  []
                        }
                    }
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 role(s) without notification e-mail configured for role activations found"
}

test_DisplayName_Incorrect if {
    ControlNumber := "AAD 2.16"
    Requirement := "User activation of other highly privileged roles SHOULD trigger an alert"

    Output := tests with input as {
        "privileged_roles": [
            {
                "RoleTemplateId": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71",
                "DisplayName": "Cloud Administrator",
                "Rules": [
                    {
                        "Id":  "Notification_Admin_EndUser_Assignment",
                        "AdditionalProperties":  {
                        "notificationType":  "Email",
                        "notificationRecipients":  []
                        }
                    }
                ]
            }
        ],
        "service_plans": [
            { "ServicePlanName": "EXCHANGE_S_FOUNDATION",
                "ServicePlanId": "31a0d5b2-13d0-494f-8e42-1e9c550a1b24"
            },
            { "ServicePlanName": "AAD_PREMIUM_P2",
                "ServicePlanId": "c7d91867-e1ce-4402-8d4f-22188b44b6c2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 role(s) without notification e-mail configured for role activations found:<br/>Cloud Administrator"
}