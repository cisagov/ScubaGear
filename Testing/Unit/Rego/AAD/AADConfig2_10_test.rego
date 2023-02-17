package aad
import future.keywords


#
# Policy 1
#--
test_ConditionalAccessPolicies_Correct if {
    ControlNumber := "AAD 2.10"
    Requirement := "Browser sessions SHALL not be persistent"

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
                    "PersistentBrowser": {
                        "IsEnabled" : true,
                        "Mode" : "never"
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
    ControlNumber := "AAD 2.10"
    Requirement := "Browser sessions SHALL not be persistent"

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
                    "PersistentBrowser": {
                        "IsEnabled" : true,
                        "Mode" : "never"
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
    ControlNumber := "AAD 2.10"
    Requirement := "Browser sessions SHALL not be persistent"

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
                    "PersistentBrowser": {
                        "IsEnabled" : true,
                        "Mode" : "never"
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
    ControlNumber := "AAD 2.10"
    Requirement := "Browser sessions SHALL not be persistent"

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
                    "PersistentBrowser": {
                        "IsEnabled" : false,
                        "Mode" : "never"
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

test_Mode_Incorrect if {
    ControlNumber := "AAD 2.10"
    Requirement := "Browser sessions SHALL not be persistent"

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
                    "PersistentBrowser": {
                        "IsEnabled" : true,
                        "Mode" : "always"
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
    ControlNumber := "AAD 2.10"
    Requirement := "Browser sessions SHALL not be persistent"

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
                    "PersistentBrowser": {
                        "IsEnabled" : true,
                        "Mode" : "never"
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