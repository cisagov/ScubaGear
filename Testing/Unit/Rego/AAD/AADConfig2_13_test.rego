package aad
import future.keywords


#
# Policy 1
#--
test_ConditionalAccessPolicies_Correct if {
    PolicyId := "MS.AAD.13.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeRoles": ["Role1", "Role2" ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "MFA required for all highly Privileged Roles Policy"
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>MFA required for all highly Privileged Roles Policy. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect if {
    PolicyId := "MS.AAD.13.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [""]
                    },
                    "Users": {
                        "IncludeRoles": ["Role1", "Role2" ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect if {
    PolicyId := "MS.AAD.13.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeRoles": ["Role1", "Role2" ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [""]
                },
                "State": "enabled",
                "DisplayName": {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect if {
    PolicyId := "MS.AAD.13.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeRoles": ["Role1", "Role2" ],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "disabled",
                "DisplayName": {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeRoles_Incorrect_V1 if {
    PolicyId := "MS.AAD.13.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeRoles": ["Role1"],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            },
            {
                "RoleTemplateId": "Role2",
                "DisplayName": "Privileged Role Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeRoles_Incorrect_V2 if {
    PolicyId := "MS.AAD.13.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeRoles": ["Role2"],
                        "ExcludeRoles": []
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ExcludeRoles_Incorrect if {
    PolicyId := "MS.AAD.13.1v1"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeRoles": ["Role1", "Role2"],
                        "ExcludeRoles": ["Role1"]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": {"MFA required for all highly Privileged Roles Policy"}
            }
        ],
        "privileged_roles": [
            {
                "RoleTemplateId": "Role1",
                "DisplayName": "Global Administrator"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}