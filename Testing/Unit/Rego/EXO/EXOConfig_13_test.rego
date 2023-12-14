package exo_test
import future.keywords
import data.exo
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# Policy 1
#--
test_AuditDisabled_Correct if {
    Output := exo.tests with input as {
        "org_config": [
            {
                "AuditDisabled": false,
                "Identity": "Test name",
                "Name": "A"
            }
        ]
    }

    CorrectTestResult("MS.EXO.13.1v1", Output, PASS) == true
}

test_AuditDisabled_Incorrect if {
    Output := exo.tests with input as {
        "org_config": [
            {
                "AuditDisabled": true,
                "Identity": "Test name",
                "Name": "A"
            }
        ]
    }

    IncorrectTestResult("MS.EXO.13.1v1", Output, FAIL) == true
}
#--