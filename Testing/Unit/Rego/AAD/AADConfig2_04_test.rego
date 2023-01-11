package aad
import future.keywords


#
# Policy 1
#--
test_ConditionalAccessPolicies_Correct if {
    ControlNumber := "AAD 2.4"
    Requirement := "MFA SHALL be required for all users"

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
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput)>= 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 conditional access policy(s) found that meet(s) all requirements:<br/>Test Policy require MFA for All Users"
}

test_IncludeApplications_Incorrect if {
    ControlNumber := "AAD 2.4"
    Requirement := "MFA SHALL be required for all users"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["Office365"]
                    },
                    "Users": {
                        "IncludeUsers": ["All"]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Users, but not all Apps"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements"
}

test_IncludeUsers_Incorrect if {
    ControlNumber := "AAD 2.4"
    Requirement := "MFA SHALL be required for all users"

    Output := tests with input as {
        "conditional_access_policies": [
            {
                "Conditions": {
                    "Applications": {
                        "IncludeApplications": ["All"]
                    },
                    "Users": {
                        "IncludeUsers": ["8bc7c6ee-39a2-42a5-a31b-f77fb51db652"]
                    }
                },
                "GrantControls": {
                    "BuiltInControls": ["mfa"]
                },
                "State": "enabled",
                "DisplayName": "Test Policy require MFA for All Apps, but not All Users"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements"
}

test_BuiltInControls_Incorrect if {
    ControlNumber := "AAD 2.4"
    Requirement := "MFA SHALL be required for all users"

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
                "DisplayName": "Test Policy does not require MFA"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements"
}

test_State_Incorrect if {
    ControlNumber := "AAD 2.4"
    Requirement := "MFA SHALL be required for all users"

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
                    "BuiltInControls": ["mfa"]
                },
                "State": "disabled",
                "DisplayName": "Test Policy is correct, but not enabled"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 conditional access policy(s) found that meet(s) all requirements"
}

#
# Policy 2
#--
test_NotImplemented_Correct_V1 if {
    ControlNumber := "AAD 2.4"
    Requirement := "Phishing-resistant MFA SHALL be used for all users"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.4 for instructions on manual check"
}

#
# Policy 3
#--
test_NotImplemented_Correct_V2 if {
    ControlNumber := "AAD 2.4"
    Requirement := "If phishing-resistant MFA cannot be used, an MFA method from the list [see AAD baseline 2.4] SHALL be used in the interim"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.4 for instructions on manual check"
}

#
# Policy 4
#--
test_NotImplemented_Correct_V3 if {
    ControlNumber := "AAD 2.4"
    Requirement := "SMS or Voice as the MFA method SHALL NOT be used"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.4 for instructions on manual check"
}