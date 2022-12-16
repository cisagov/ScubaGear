package aad
import future.keywords


#
# Policy 1
#--
test_OnPremisesImmutableId_Correct if {
    ControlNumber := "AAD 2.12"
    Requirement := "Users that need to be assigned to highly privileged Azure AD roles SHALL be provisioned cloud-only accounts that are separate from the on-premises directory or other federated identity providers"

    Output := tests with input as {
        "privileged_users": {
            "User1": { 
                "DisplayName": "Alice",
                "OnPremisesImmutableId": null,
                "roles": ["Privileged Role Administrator", "Global Administrator"]
            },
            "User2": { 
                "DisplayName": "Bob",
                "OnPremisesImmutableId": null,
               "roles": ["Global Administrator"]
            }
        }
    }
    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 admin(s) that are not cloud-only found"
}

test_OnPremisesImmutableId_Incorrect_V1 if {
    ControlNumber := "AAD 2.12"
    Requirement := "Users that need to be assigned to highly privileged Azure AD roles SHALL be provisioned cloud-only accounts that are separate from the on-premises directory or other federated identity providers"

    Output := tests with input as {
        "privileged_users": {
            "User1": { 
                "DisplayName": "Alice",
                "OnPremisesImmutableId": "HelloWorld",
                "roles": ["Privileged Role Administrator", "Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 admin(s) that are not cloud-only found:<br/>Alice"
}

test_OnPremisesImmutableId_Incorrect_V2 if {
    ControlNumber := "AAD 2.12"
    Requirement := "Users that need to be assigned to highly privileged Azure AD roles SHALL be provisioned cloud-only accounts that are separate from the on-premises directory or other federated identity providers"

    Output := tests with input as {
        "privileged_users": {
            "User1": { 
                "DisplayName": "Alice",
                "OnPremisesImmutableId": "HelloWorld",
                "roles": ["Privileged Role Administrator", "Global Administrator"]
            },
            "User2": { 
                "DisplayName": "Bob",
                "OnPremisesImmutableId": null,
                "roles": ["Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 admin(s) that are not cloud-only found:<br/>Alice"
}