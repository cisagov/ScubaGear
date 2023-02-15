package aad
import future.keywords


#
# Policy 1
#--
test_Conditions_Correct if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test block Legacy Authentication. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["Office365"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["49b4dcdf-1f90-41a5-9dd7-5e7c3609b423"]
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_ClientAppTypes_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    },
                    "ClientAppTypes": [""]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_BuiltInControls_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": null
                },
                "State": "enabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect if {
    ControlNumber := "AAD 2.1"
    Requirement := "Legacy authentication SHALL be blocked"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    },
                    "ClientAppTypes": ["other", "exchangeActiveSync"]
                },
                "GrantControls": {
                    "BuiltInControls": ["block"]
                },
                "State": "disabled",
                "DisplayName": "Test block Legacy Authentication"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}