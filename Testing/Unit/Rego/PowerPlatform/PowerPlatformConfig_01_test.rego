package powerplatform
import future.keywords


#
# Policy 1
#--
test_disableProductionEnvironmentCreationByNonAdminUsers_Correct if {
    PolicyId := "MS.POWERPLATFORM.1.1v1"

    Output := tests with input as {
        "environment_creation": [{
            "disableEnvironmentCreationByNonAdminUsers" : true
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_disableProductionEnvironmentCreationByNonAdminUsers_Incorrect if {
    PolicyId := "MS.POWERPLATFORM.1.1v1"

    Output := tests with input as {
        "environment_creation": [{
            "disableEnvironmentCreationByNonAdminUsers" : false
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 2
#--
test_disableTrialEnvironmentCreationByNonAdminUsers_Correct if {
    PolicyId := "MS.POWERPLATFORM.1.2v1"

    Output := tests with input as {
        "environment_creation": [{
            "disableTrialEnvironmentCreationByNonAdminUsers" : true
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_disableTrialEnvironmentCreationByNonAdminUsers_Incorrect if {
    PolicyId := "MS.POWERPLATFORM.1.2v1"

    Output := tests with input as {
        "environment_creation": [{
            "disableTrialEnvironmentCreationByNonAdminUsers" : false
        }]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

# TODO: Need to resolve Policy ID
# 
#--
# test_disableTrialEnvironmentCreationByNonAdminUsers_Correct if {
#     ControlNumber := "Power Platform 2.1"
#     Requirement := "The ability to create trial environments SHALL be restricted to admins"

#     Output := tests with input as {
#         "environment_creation": [{
#             "disableTrialEnvironmentCreationByNonAdminUsers" : true
#         }]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement met"
# }

# test_disableTrialEnvironmentCreationByNonAdminUsers_Incorrect if {
#     ControlNumber := "Power Platform 2.1"
#     Requirement := "The ability to create trial environments SHALL be restricted to admins"

#     Output := tests with input as {
#         "environment_creation": [{
#             "disableTrialEnvironmentCreationByNonAdminUsers" : false
#         }]
#     }

#     RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

#     count(RuleOutput) == 1
#     not RuleOutput[0].RequirementMet
#     RuleOutput[0].ReportDetails == "Requirement not met"
# }