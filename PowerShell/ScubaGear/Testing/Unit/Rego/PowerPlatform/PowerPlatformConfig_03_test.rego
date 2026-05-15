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
    Output := powerplatform.tests with input.tenant_isolation as [TenantIsolation]

    TestResult("MS.POWERPLATFORM.3.1v1", Output, PASS, true) == true
}

test_isDisabled_Incorrect if {
    Tenant := json.patch(TenantIsolation, [{"op": "add", "path": "properties/isDisabled", "value": true}])

    Output := powerplatform.tests with input.tenant_isolation as [Tenant]

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