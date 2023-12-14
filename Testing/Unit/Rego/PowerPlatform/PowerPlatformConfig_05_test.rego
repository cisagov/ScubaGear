package powerplatform_test
import future.keywords
import data.powerplatform
import data.utils.policy.TestResult
import data.utils.policy.FAIL
import data.utils.policy.PASS


#
# Policy 1
#--
test_disablePortalCreationByNonAdminUsers_Correct if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disablePortalsCreationByNonAdminUsers": true
            }
        ]
    }

    TestResult("MS.POWERPLATFORM.5.1v1", Output, PASS, true) == true
}

test_disablePortalCreationByNonAdminUsers_Incorrect if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disablePortalsCreationByNonAdminUsers": false
            }
        ]
    }

    TestResult("MS.POWERPLATFORM.5.1v1", Output, FAIL, false) == true
}
#--