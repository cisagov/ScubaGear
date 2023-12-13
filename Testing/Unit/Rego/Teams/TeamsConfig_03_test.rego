package teams_test
import future.keywords
import data.teams
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.PASS


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

    CorrectTestResult("MS.TEAMS.3.1v1", Output, PASS) == true
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
    IncorrectTestResult("MS.TEAMS.3.1v1", Output, ReportDetailString) == true
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

    CorrectTestResult("MS.TEAMS.3.1v1", Output, PASS) == true
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
    IncorrectTestResult("MS.TEAMS.3.1v1", Output, ReportDetailString) == true
}
#--