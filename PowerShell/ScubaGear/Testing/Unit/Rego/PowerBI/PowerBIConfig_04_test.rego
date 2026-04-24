package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.PASS

#
# Policy MS.POWERBI.4.1v1
#--
test_ServicePrincipalAPI_Correct if {
    Output := powerbi.tests with input.service_principal_api_setting as [ServicePrincipalAPI]

    TestResult("MS.POWERBI.4.1v1", Output, PASS, true) == true
}

test_ServicePrincipalAPI_Incorrect_Disabled if {
    Setting := json.patch(ServicePrincipalAPI, [{"op": "add", "path": "enabled", "value": false}])

    Output := powerbi.tests with input.service_principal_api_setting as [Setting]

    TestResult("MS.POWERBI.4.1v1", Output, "Service principal API access must be enabled and restricted to security groups", false) == true
}

test_ServicePrincipalAPI_Incorrect_NoSecurityGroups if {
    Setting := json.patch(ServicePrincipalAPI, [{"op": "add", "path": "canSpecifySecurityGroups", "value": false}])

    Output := powerbi.tests with input.service_principal_api_setting as [Setting]

    TestResult("MS.POWERBI.4.1v1", Output, "Service principal API access must be enabled and restricted to security groups", false) == true
}

test_ServicePrincipalAPI_Empty if {
    Output := powerbi.tests with input.service_principal_api_setting as []

    TestResult("MS.POWERBI.4.1v1", Output, "PowerShell Error", false) == true
}

#
# Policy MS.POWERBI.4.2v1
#--
test_ServicePrincipalProfile_Correct if {
    Output := powerbi.tests with input.service_principal_profile_setting as [ServicePrincipalProfile]

    TestResult("MS.POWERBI.4.2v1", Output, PASS, true) == true
}

test_ServicePrincipalProfile_Incorrect_Disabled if {
    Setting := json.patch(ServicePrincipalProfile, [{"op": "add", "path": "enabled", "value": false}])

    Output := powerbi.tests with input.service_principal_profile_setting as [Setting]

    TestResult("MS.POWERBI.4.2v1", Output, "Service principal profile creation must be enabled and restricted to security groups", false) == true
}

test_ServicePrincipalProfile_Incorrect_NoSecurityGroups if {
    Setting := json.patch(ServicePrincipalProfile, [{"op": "add", "path": "canSpecifySecurityGroups", "value": false}])

    Output := powerbi.tests with input.service_principal_profile_setting as [Setting]

    TestResult("MS.POWERBI.4.2v1", Output, "Service principal profile creation must be enabled and restricted to security groups", false) == true
}

test_ServicePrincipalProfile_Empty if {
    Output := powerbi.tests with input.service_principal_profile_setting as []

    TestResult("MS.POWERBI.4.2v1", Output, "PowerShell Error", false) == true
}
#--
