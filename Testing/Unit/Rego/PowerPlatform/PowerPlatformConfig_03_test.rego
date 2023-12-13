package powerplatform_test
import future.keywords
import data.powerplatform
import data.utils.report.NotCheckedDetails
import data.utils.policy.CorrectTestResult
import data.utils.policy.IncorrectTestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# Policy 1
#--
test_isDisabled_Correct if {
    Output := powerplatform.tests with input as {
        "tenant_isolation": [
            {
                "properties": {
                    "isDisabled": false
                }
            }
        ]
    }

    CorrectTestResult("MS.POWERPLATFORM.3.1v1", Output, PASS) == true
}

test_isDisabled_Incorrect if {
    Output := powerplatform.tests with input as {
        "tenant_isolation": [
            {
                "properties": {
                    "isDisabled": true
                }
            }
        ]
    }

    IncorrectTestResult("MS.POWERPLATFORM.3.1v1", Output, FAIL) == true
}
#--

#
# Policy 2
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.POWERPLATFORM.3.2v1"

    Output := powerplatform.tests with input as { }

    IncorrectTestResult(PolicyId, Output, NotCheckedDetails(PolicyId)) == true
}
#--