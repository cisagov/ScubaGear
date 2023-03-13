package aad
import future.keywords

#
# Policy 1
#--
test_ConditionalAccessPolicies_Correct if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : true,
                        "Type" : "hours",
                        "Value" : 12
                    }
                },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test Name. <a href='#caps'>View all CA policies</a>."
}

test_IncludeApplications_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": []
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    }
                },
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : true,
                        "Type" : "hours",
                        "Value" : 12
                    }
                },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IncludeUsers_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": []
                    }
                },
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : true,
                        "Type" : "hours",
                        "Value" : 12
                    }
                },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_IsEnabled_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : false,
                        "Type" : "hours",
                        "Value" : 12
                    }
                },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_Type_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : true,
                        "Type" : "Hello World",
                        "Value" : 12
                    }
                },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_Value_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : true,
                        "Type" : "hours",
                        "Value" : 24
                    }
                },
                "State": "enabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}

test_State_Incorrect if {
    ControlNumber := "AAD 2.9"
    Requirement := "Sign-in frequency SHALL be configured to 12 hours"

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
                "SessionControls": {
                    "SignInFrequency": {
                        "IsEnabled" : true,
                        "Type" : "hours",
                        "Value" : 12
                    }
                },
                "State": "disabled",
                "DisplayName" : "Test Name"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
}