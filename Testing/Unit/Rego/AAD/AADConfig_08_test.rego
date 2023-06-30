package aad
import future.keywords
import data.report.utils.NotCheckedDetails


#
# MS.AAD.8.1v1
#--
test_GuestUserRoleId_Correct_V1 if {
    PolicyId := "MS.AAD.8.1v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "GuestUserRoleId" : "2af84b1e-32c8-42b7-82bc-daa82404023b",
                "Id" : "authorizationPolicy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"Restricted access\" (authorizationPolicy)"
}

test_GuestUserRoleId_Correct_V2 if {
    PolicyId := "MS.AAD.8.1v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "GuestUserRoleId" : "10dae51f-b6af-4016-8d66-8c2a99b929b3",
                "Id" : "authorizationPolicy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"Limited access\" (authorizationPolicy)"
}

test_GuestUserRoleId_Incorrect_V1 if {
    PolicyId := "MS.AAD.8.1v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "GuestUserRoleId" : "a0b1b346-4d3e-4e8b-98f8-753987be4970",
                "Id" : "authorizationPolicy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"Same as member users\" (authorizationPolicy)"
}

test_GuestUserRoleId_Incorrect_V2 if {
    PolicyId := "MS.AAD.8.1v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "GuestUserRoleId" : "Hello world",
                "Id" : "authorizationPolicy"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"Unknown\" (authorizationPolicy)"
}

test_GuestUserRoleId_Incorrect_V3 if {
    PolicyId := "MS.AAD.8.1v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "GuestUserRoleId" : "Hello world",
                "Id" : "policy 1"
            },
            {
                "GuestUserRoleId" : "2af84b1e-32c8-42b7-82bc-daa82404023b",
                "Id" : "policy 2"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
}
#--

#
# MS.AAD.8.2v1
#--
test_AllowInvitesFrom_Correct if {
    PolicyId := "MS.AAD.8.2v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "Id" : "authorizationPolicy",
                "AllowInvitesFrom" : "adminsAndGuestInviters"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"adminsAndGuestInviters\" (authorizationPolicy)"
}

test_AllowInvitesFrom_Incorrect if {
    PolicyId := "MS.AAD.8.2v1"

    Output := tests with input as {
        "authorization_policies" : [
            {
                "Id" : "authorizationPolicy",
                "AllowInvitesFrom" : "Bad value"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"Bad value\" (authorizationPolicy)"
}
#--

#
# MS.AAD.8.3v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.8.3v1"
    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == NotCheckedDetails(PolicyId)
}
#--