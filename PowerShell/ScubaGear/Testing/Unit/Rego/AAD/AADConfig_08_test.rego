package aad_test
import rego.v1
import data.aad
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult


#
# Policy MS.AAD.8.1v1
#--
test_GuestUserRoleId_Correct_V1 if {
    Output := aad.tests with input as {
        "authorization_policies": [
            {
                "GuestUserRoleId": "2af84b1e-32c8-42b7-82bc-daa82404023b",
                "Id": "authorizationPolicy"
            }
        ]
    }

    ReportDetailString := "Permission level set to \"Restricted access\" (authorizationPolicy)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, true) == true
}

test_GuestUserRoleId_Correct_V2 if {
    Output := aad.tests with input as {
        "authorization_policies" : [
            {
                "GuestUserRoleId" : "10dae51f-b6af-4016-8d66-8c2a99b929b3",
                "Id" : "authorizationPolicy"
            }
        ]
    }

    ReportDetailString := "Permission level set to \"Limited access\" (authorizationPolicy)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, true) == true
}

test_GuestUserRoleId_Incorrect_V1 if {
    Output := aad.tests with input as {
        "authorization_policies" : [
            {
                "GuestUserRoleId" : "a0b1b346-4d3e-4e8b-98f8-753987be4970",
                "Id" : "authorizationPolicy"
            }
        ]
    }

    ReportDetailString := "Permission level set to \"Same as member users\" (authorizationPolicy)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, false) == true
}

test_GuestUserRoleId_Incorrect_V2 if {
    Output := aad.tests with input as {
        "authorization_policies" : [
            {
                "GuestUserRoleId" : "Hello world",
                "Id" : "authorizationPolicy"
            }
        ]
    }

    ReportDetailString := "Permission level set to \"Unknown\" (authorizationPolicy)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, false) == true
}

test_GuestUserRoleId_Incorrect_V3 if {
    Output := aad.tests with input as {
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

    ReportDetailString := "Permission level set to \"Restricted access\" (policy 2), \"Unknown\" (policy 1)"
    TestResult("MS.AAD.8.1v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.8.2v1
#--
test_AllowInvitesFrom_Correct if {
    Output := aad.tests with input as {
        "authorization_policies" : [
            {
                "Id" : "authorizationPolicy",
                "AllowInvitesFrom" : "adminsAndGuestInviters"
            }
        ]
    }

    ReportDetailString := "Permission level set to \"adminsAndGuestInviters\" (authorizationPolicy)"
    TestResult("MS.AAD.8.2v1", Output, ReportDetailString, true) == true
}

test_AllowInvitesFrom_Incorrect if {
    Output := aad.tests with input as {
        "authorization_policies" : [
            {
                "Id" : "authorizationPolicy",
                "AllowInvitesFrom" : "Bad value"
            }
        ]
    }

    ReportDetailString := "Permission level set to \"Bad value\" (authorizationPolicy)"
    TestResult("MS.AAD.8.2v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.8.3v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.8.3v1"

    Output := aad.tests with input as { }

    ReportDetailString := NotCheckedDetails(PolicyId)
    TestResult(PolicyId, Output, ReportDetailString, false) == true
}
#--