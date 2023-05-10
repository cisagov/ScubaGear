package aad
import future.keywords


#
# Policy 1
#--
test_PrivilegedUsers_Correct if {
    PolicyId := "MS.AAD.11.1v1"

    Output := tests with input as {
        "privileged_users" : {
            "User1": { 
                "DisplayName": "Test Name1", 
                "roles": ["Privileged Role Administrator", "Global Administrator"] 
            },
            "User2": { 
                "DisplayName": "Test Name2", 
                "roles": ["Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "2 global admin(s) found:<br/>Test Name1, Test Name2"
}

test_PrivilegedUsers_Incorrect_V1 if {
    PolicyId := "MS.AAD.11.1v1"

    Output := tests with input as {
        "privileged_users" : {
            "User1": { 
                "DisplayName": "Test Name1", 
                "roles": ["Privileged Role Administrator", "Global Administrator"] 
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 global admin(s) found:<br/>Test Name1"
}

test_PrivilegedUsers_Incorrect_V2 if {
    PolicyId := "MS.AAD.11.1v1"

    Output := tests with input as {
        "privileged_users" : {
            "User1": { 
                "DisplayName": "Test Name1", 
                "roles": ["Privileged Role Administrator", "Global Administrator"] 
            },
            "User2": { 
                "DisplayName": "Test Name2", 
                "roles": ["Global Administrator"]
            },
            "User3": { 
                "DisplayName": "Test Name3", 
                "roles": ["Global Administrator"]
            },
            "User4": { 
                "DisplayName": "Test Name4", 
                "roles": ["Global Administrator"]
            },
            "User5": { 
                "DisplayName": "Test Name5", 
                "roles": ["Global Administrator"]
            }
        }
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "5 global admin(s) found:<br/>Test Name1, Test Name2, Test Name3, Test Name4, Test Name5"
}