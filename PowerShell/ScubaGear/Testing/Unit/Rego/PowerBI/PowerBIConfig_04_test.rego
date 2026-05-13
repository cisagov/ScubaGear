package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.PASS
import data.utils.key.FAIL

#
# Policy MS.POWERBI.4.1v1
#--

### Testing the "PowerBI License found and setting was found in JSON" scenarios
###
test_ServicePrincipalAccessPermissionAPIs_Compliant_Disabled if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")]), "value": false},
        {"op": "add", "path": sprintf("/powerbi_tenant_settings/%v/enabledSecurityGroups", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")]), "value": []}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.1v1", Output, PASS, true) == true
}

test_ServicePrincipalAccessPermissionAPIs_Compliant_EnabledWithSecurityGroup if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")]), "value": true},
        {"op": "add", "path": sprintf("/powerbi_tenant_settings/%v/enabledSecurityGroups", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")]), "value": [
            {
                "graphId": "56500b38-aabf-4bb2-8b0f-60ef6a6c4dd3",
                "name": "PowerBI-Test"
            }
        ]}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.1v1", Output, PASS, true) == true
}

test_ServicePrincipalAccessPermissionAPIs_Compliant_EnabledWithTwoSecurityGroups if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")]), "value": true},
        {"op": "add", "path": sprintf("/powerbi_tenant_settings/%v/enabledSecurityGroups", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")]), "value": [
            {
                "graphId": "56500b38-aabf-4bb2-8b0f-60ef6a6c4dd3",
                "name": "PowerBI-Test"
            },
            {
                "graphId": "043036d1-b992-46e8-878d-623fbbc2a6a3",
                "name": "Power BI Service Principals"
            }
        ]}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.1v1", Output, PASS, true) == true
}

test_ServicePrincipalAccessPermissionAPIs_NonCompliant_EnabledWithNoSecurityGroups if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")]), "value": true},
        {"op": "add", "path": sprintf("/powerbi_tenant_settings/%v/enabledSecurityGroups", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")]), "value": []}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.1v1", Output, FAIL, false) == true
}
###


### Testing the "No PowerBI license found" scenarios
###
test_ServicePrincipalAccessPermissionAPIs_NoLicense if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.1v1", Output, powerbi_license_error_message, false) == true
}

test_ServicePrincipalAccessPermissionAPIs_LicenseVariableMissing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "remove", "path": "/powerbi_license_found"}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.1v1", Output, powerbi_license_error_message, false) == true
}

test_ServicePrincipalAccessPermissionAPIs_NoLicense_TakesPrecedence_OverMissingTenantSettings if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false},
        {"op": "remove", "path": "/powerbi_tenant_settings"}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.1v1", Output, powerbi_license_error_message, false) == true
}
###


### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_ServicePrincipalAccessPermissionAPIs_PowerBITenantSettings_Missing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": "/powerbi_tenant_settings"}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or ServicePrincipalAccessPermissionAPIs are missing from input JSON"
    TestResult("MS.POWERBI.4.1v1", Output, MissingError, false) == true
}

test_ServicePrincipalAccessPermissionAPIs_Missing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": sprintf("/powerbi_tenant_settings/%v", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")])}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or ServicePrincipalAccessPermissionAPIs are missing from input JSON"
    TestResult("MS.POWERBI.4.1v1", Output, MissingError, false) == true
}

test_ServicePrincipalAccessPermissionAPIs_PowerBITenantSettings_EmptyArray if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": []}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or ServicePrincipalAccessPermissionAPIs are missing from input JSON"
    TestResult("MS.POWERBI.4.1v1", Output, MissingError, false) == true
}

test_ServicePrincipalAccessPermissionAPIs_PowerBITenantSettings_NullArrayElement if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": [null]}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or ServicePrincipalAccessPermissionAPIs are missing from input JSON"
    TestResult("MS.POWERBI.4.1v1", Output, MissingError, false) == true
}

test_ServicePrincipalAccessPermissionAPIs_PowerBITenantSettings_NonObjectArrayElement if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": ["bad-data"]}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or ServicePrincipalAccessPermissionAPIs are missing from input JSON"
    TestResult("MS.POWERBI.4.1v1", Output, MissingError, false) == true
}

test_ServicePrincipalAccessPermissionAPIs_MissingSettingName if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": sprintf("/powerbi_tenant_settings/%v/settingName", [powerbi_setting_index("ServicePrincipalAccessPermissionAPIs")])}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or ServicePrincipalAccessPermissionAPIs are missing from input JSON"
    TestResult("MS.POWERBI.4.1v1", Output, MissingError, false) == true
}
###


#
# Policy MS.POWERBI.4.2v1
#--

### Testing the "PowerBI License found and setting was found in JSON" scenarios
###
test_AllowServicePrincipalsCreateAndUseProfiles_Compliant_Disabled if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")]), "value": false},
        {"op": "add", "path": sprintf("/powerbi_tenant_settings/%v/enabledSecurityGroups", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")]), "value": []}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.2v1", Output, PASS, true) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_Compliant_EnabledWithSecurityGroup if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")]), "value": true},
        {"op": "add", "path": sprintf("/powerbi_tenant_settings/%v/enabledSecurityGroups", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")]), "value": [
            {
                "graphId": "56500b38-aabf-4bb2-8b0f-60ef6a6c4dd3",
                "name": "PowerBI-Test"
            }
        ]}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.2v1", Output, PASS, true) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_Compliant_EnabledWithTwoSecurityGroups if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")]), "value": true},
        {"op": "add", "path": sprintf("/powerbi_tenant_settings/%v/enabledSecurityGroups", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")]), "value": [
            {
                "graphId": "56500b38-aabf-4bb2-8b0f-60ef6a6c4dd3",
                "name": "PowerBI-Test"
            },
            {
                "graphId": "25322f83-b243-4417-82dc-87ce0d767fb4",
                "name": "Scuba Testers"
            }
        ]}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.2v1", Output, PASS, true) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_NonCompliant_EnabledWithNoSecurityGroups if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")]), "value": true},
        {"op": "add", "path": sprintf("/powerbi_tenant_settings/%v/enabledSecurityGroups", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")]), "value": []}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.2v1", Output, FAIL, false) == true
}
###


### Testing the "No PowerBI license found" scenarios
###
test_AllowServicePrincipalsCreateAndUseProfiles_NoLicense if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.2v1", Output, powerbi_license_error_message, false) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_LicenseVariableMissing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "remove", "path": "/powerbi_license_found"}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.2v1", Output, powerbi_license_error_message, false) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_NoLicense_TakesPrecedence_OverMissingTenantSettings if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false},
        {"op": "remove", "path": "/powerbi_tenant_settings"}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.4.2v1", Output, powerbi_license_error_message, false) == true
}
###


### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_AllowServicePrincipalsCreateAndUseProfiles_PowerBITenantSettings_Missing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": "/powerbi_tenant_settings"}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or AllowServicePrincipalsCreateAndUseProfiles are missing from input JSON"
    TestResult("MS.POWERBI.4.2v1", Output, MissingError, false) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_Missing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": sprintf("/powerbi_tenant_settings/%v", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")])}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or AllowServicePrincipalsCreateAndUseProfiles are missing from input JSON"
    TestResult("MS.POWERBI.4.2v1", Output, MissingError, false) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_PowerBITenantSettings_EmptyArray if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": []}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or AllowServicePrincipalsCreateAndUseProfiles are missing from input JSON"
    TestResult("MS.POWERBI.4.2v1", Output, MissingError, false) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_PowerBITenantSettings_NullArrayElement if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": [null]}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or AllowServicePrincipalsCreateAndUseProfiles are missing from input JSON"
    TestResult("MS.POWERBI.4.2v1", Output, MissingError, false) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_PowerBITenantSettings_NonObjectArrayElement if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": ["bad-data"]}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or AllowServicePrincipalsCreateAndUseProfiles are missing from input JSON"
    TestResult("MS.POWERBI.4.2v1", Output, MissingError, false) == true
}

test_AllowServicePrincipalsCreateAndUseProfiles_MissingSettingName if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": sprintf("/powerbi_tenant_settings/%v/settingName", [powerbi_setting_index("AllowServicePrincipalsCreateAndUseProfiles")])}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or AllowServicePrincipalsCreateAndUseProfiles are missing from input JSON"
    TestResult("MS.POWERBI.4.2v1", Output, MissingError, false) == true
}
###