package powerplatform_test
import future.keywords
import data.powerplatform
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy 1
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
# Policy 2
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