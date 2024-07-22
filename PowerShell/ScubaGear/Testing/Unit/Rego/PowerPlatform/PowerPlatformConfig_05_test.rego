package powerplatform_test
import rego.v1
import data.powerplatform
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS


#
# Policy MS.POWERPLATFORM.5.1v1
#--
test_disablePortalCreationByNonAdminUsers_Correct if {
    Output := powerplatform.tests with input.environment_creation as [EnvironmentCreation]

    TestResult("MS.POWERPLATFORM.5.1v1", Output, PASS, true) == true
}

test_disablePortalCreationByNonAdminUsers_Incorrect if {
    EnvCreation := json.patch(EnvironmentCreation, [{"op": "add", "path": "disablePortalsCreationByNonAdminUsers", "value": false}])

    Output := powerplatform.tests with input.environment_creation as [EnvCreation]

    TestResult("MS.POWERPLATFORM.5.1v1", Output, FAIL, false) == true
}
#--