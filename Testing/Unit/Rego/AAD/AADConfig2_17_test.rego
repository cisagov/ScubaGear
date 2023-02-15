package aad
import future.keywords


#
# Policy 1
#--
test_ConditionalAccessPolicies_Correct if {
    ControlNumber := "AAD 2.17"
    Requirement := "Managed devices SHOULD be required for authentication"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["domainJoinedDevice"]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>AD Joined Device Authentication Policy. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Correct if {
    ControlNumber := "AAD 2.17"
    Requirement := "Managed devices SHOULD be required for authentication"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["compliantDevice"]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>AD Joined Device Authentication Policy. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect if {
    ControlNumber := "AAD 2.17"
    Requirement := "Managed devices SHOULD be required for authentication"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": [""]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["compliantDevice"]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect if {
    ControlNumber := "AAD 2.17"
    Requirement := "Managed devices SHOULD be required for authentication"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": [""]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["compliantDevice"]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect if {
    ControlNumber := "AAD 2.17"
    Requirement := "Managed devices SHOULD be required for authentication"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": [""]
                },
                "State": "enabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect if {
    ControlNumber := "AAD 2.17"
    Requirement := "Managed devices SHOULD be required for authentication"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["compliantDevice"]
                },
                "State": "disabled",
                "DisplayName": "AD Joined Device Authentication Policy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}