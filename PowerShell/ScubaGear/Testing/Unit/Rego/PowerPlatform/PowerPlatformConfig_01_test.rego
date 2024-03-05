package powerplatform_test
import rego.v1
import data.powerplatform
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.POWERPLATFORM.1.1v1
#--
test_disableProductionEnvironmentCreationByNonAdminUsers_Correct if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disableEnvironmentCreationByNonAdminUsers": true
            }
        ]
    }

    TestResult("MS.POWERPLATFORM.1.1v1", Output, PASS, true) == true
}

test_disableProductionEnvironmentCreationByNonAdminUsers_Incorrect if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disableEnvironmentCreationByNonAdminUsers": false
            }
        ]
    }

    TestResult("MS.POWERPLATFORM.1.1v1", Output, FAIL, false) == true
}
#--

#
# Policy MS.POWERPLATFORM.1.2v1
#--
test_disableTrialEnvironmentCreationByNonAdminUsers_Correct if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disableTrialEnvironmentCreationByNonAdminUsers": true
            }
        ]
    }

    TestResult("MS.POWERPLATFORM.1.2v1", Output, PASS, true) == true
}

test_disableTrialEnvironmentCreationByNonAdminUsers_Incorrect if {
    Output := powerplatform.tests with input as {
        "environment_creation": [
            {
                "disableTrialEnvironmentCreationByNonAdminUsers": false
            }
        ]
    }

    TestResult("MS.POWERPLATFORM.1.2v1", Output, FAIL, false) == true
}
#--