package powerplatform_test
import rego.v1
import data.powerplatform
import data.utils.report.NotCheckedDetails
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.POWERPLATFORM.3.1v1
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

    TestResult("MS.POWERPLATFORM.3.1v1", Output, PASS, true) == true
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

    TestResult("MS.POWERPLATFORM.3.1v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.POWERPLATFORM.3.2v1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.POWERPLATFORM.3.2v1"

    Output := powerplatform.tests with input as { }

    TestResult(PolicyId, Output, NotCheckedDetails(PolicyId), false) == true
}
#--