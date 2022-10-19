package aad
import future.keywords


#
# Policy 1
#--
test_AllowInvitesFrom_Correct if {
    ControlNumber := "AAD 2.18"
    Requirement := "Only users with the Guest Inviter role SHOULD be able to invite guest users"

    Output := tests with input as {
        "authorization_policies":
            {
                "AllowInvitesFrom": "adminsAndGuestInviters"
            }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_AllowInvitesFrom_Incorrect if {
    ControlNumber := "AAD 2.18"
    Requirement := "Only users with the Guest Inviter role SHOULD be able to invite guest users"

    Output := tests with input as {
        "authorization_policies":
            {
                "AllowInvitesFrom": ""
            }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement not met"
}

#
# Policy 2
#--
test_NotImplemented_Correct if {
    ControlNumber := "AAD 2.18"
    Requirement := "Guest invites SHOULD only be allowed to specific external domains that have been authorized by the agency for legitimate business purposes"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.18 for instructions on manual check"
}

#
# Policy 3
#--
test_GuestUserRoleId_Correct_V1 if {
    ControlNumber := "AAD 2.18"
    Requirement := "Guest users SHOULD have limited access to Azure AD directory objects"

    Output := tests with input as {
        "authorization_policies":
            {
                "GuestUserRoleId" : "2af84b1e-32c8-42b7-82bc-daa82404023b"
            }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"Restricted access\""
}

test_GuestUserRoleId_Correct_V2 if {
    ControlNumber := "AAD 2.18"
    Requirement := "Guest users SHOULD have limited access to Azure AD directory objects"

    Output := tests with input as {
        "authorization_policies":
            {
                "GuestUserRoleId" : "10dae51f-b6af-4016-8d66-8c2a99b929b3"
            }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"Limited access\""
}

test_GuestUserRoleId_Incorrect_V1 if {
    ControlNumber := "AAD 2.18"
    Requirement := "Guest users SHOULD have limited access to Azure AD directory objects"

    Output := tests with input as {
        "authorization_policies":
            {
                "GuestUserRoleId" : "a0b1b346-4d3e-4e8b-98f8-753987be4970"
            }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"Same as member users\""
}

test_GuestUserRoleId_Incorrect_V2 if {
    ControlNumber := "AAD 2.18"
    Requirement := "Guest users SHOULD have limited access to Azure AD directory objects"

    Output := tests with input as {
        "authorization_policies":
            {
                "GuestUserRoleId" : "Hello World"
            }
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Permission level set to \"Unknown\""
}