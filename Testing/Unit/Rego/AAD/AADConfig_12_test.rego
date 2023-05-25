package aad
import future.keywords


#
# Policy 1
#--
test_OnPremisesImmutableId_Correct if {
    PolicyId := "MS.AAD.12.1v1"
    
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
    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "0 admin(s) that are not cloud-only found"
}

test_OnPremisesImmutableId_Incorrect_V1 if {
    PolicyId := "MS.AAD.12.1v1"

    Output := tests with input as {
        "privileged_users": {
            "User1": { 
                "DisplayName": "Alice",
                "OnPremisesImmutableId": "HelloWorld",
                "roles": ["Privileged Role Administrator", "Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 admin(s) that are not cloud-only found:<br/>Alice"
}

test_OnPremisesImmutableId_Incorrect_V2 if {
    PolicyId := "MS.AAD.12.1v1"
    
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

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 admin(s) that are not cloud-only found:<br/>Alice"
}