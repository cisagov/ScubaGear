package defender
import future.keywords

#
# Policy 1
#--
test_Identity_Correct_V1 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {  
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Enabled"
            },
            {
                "Identity" : "Strict Preset Security Policy",
                "State" : "Enabled"
            }
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Identity_Incorrect_V1 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {  
        "protection_policy_rules" : [] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    print(RuleOutput)
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Standard and Strict preset policies are both disabled"
}

test_Identity_Incorrect_V2 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {  
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Disabled"
            }
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Standard and Strict preset policies are both disabled"
}

test_Identity_Incorrect_V3 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {  
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Enabled"
            }
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Strict preset policy is disabled"
}

test_Identity_Incorrect_V4 if {
    PolicyId := "MS.DEFENDER.1.1v1"

    Output := tests with input as {  
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Disabled"
            },
            {
                "Identity" : "Strict Preset Security Policy",
                "State" : "Disabled"
            }
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
    print(RuleOutput)
    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Standard and Strict preset policies are both disabled"
}

# TODO: Policy Id needs to be resolved
# Policy 2
#--
# test_Identity_Correct_V1 if {
#     PolicyId := "MS.DEFENDER.TBD"
#     #Requirement := "Strict Preset security profiles SHOULD NOT be used"

#     Output := tests with input as {  
#         "protection_policy_rules" : [] 
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# TODO: Policy Id needs to be resolved
# test_Identity_Correct_V2 if {
#     PolicyId := "MS.DEFENDER.TBD"
#     #Requirement := "Strict Preset security profiles SHOULD NOT be used"

#     Output := tests with input as {  
#         "protection_policy_rules" : [
#             {
#                 "Identity" : "Strict Preset Security Policy",
#                 "State" : "Disabled"
#             }
#         ] 
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# TODO: Policy Id needs to be resolved
# test_Identity_Incorrect_V2 if {
#     PolicyId := "MS.DEFENDER.TBD"
#     #Requirement := "Strict Preset security profiles SHOULD NOT be used"

#     Output := tests with input as {  
#         "protection_policy_rules" : [
#             {
#                 "Identity" : "Strict Preset Security Policy",
#                 "State" : "Enabled"
#             }
#         ] 
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]
# }