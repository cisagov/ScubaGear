package teams_test
import rego.v1
import data.teams
import data.utils.key.TestResult
import data.utils.key.PASS


#
# Policy MS.TEAMS.3.1v1
#--
test_AllowPublicUsers_Correct if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowPublicUsers": false
            }
        ]
    }

    TestResult("MS.TEAMS.3.1v1", Output, PASS, true) == true
}

test_AllowPublicUsers_Incorrect if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowPublicUsers": true
            }
        ]
    }

    ReportDetailString := "1 domains that allows contact with Skype users: Global"
    TestResult("MS.TEAMS.3.1v1", Output, ReportDetailString, false) == true
}

test_AllowPublicUsers_Correct_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowPublicUsers": false
            },
            {
                "Identity": "Tag:AllOn",
                "AllowPublicUsers": false
            }
        ]
    }

    TestResult("MS.TEAMS.3.1v1", Output, PASS, true) == true
}

test_AllowPublicUsers_Incorrect_multi if {
    Output := teams.tests with input as {
        "federation_configuration": [
            {
                "Identity": "Global",
                "AllowPublicUsers": true
            },
            {
                "Identity": "Tag:AllOn",
                "AllowPublicUsers": true
            }
        ]
    }

    ReportDetailString := "2 domains that allows contact with Skype users: Global, Tag:AllOn"
    TestResult("MS.TEAMS.3.1v1", Output, ReportDetailString, false) == true
}
#--