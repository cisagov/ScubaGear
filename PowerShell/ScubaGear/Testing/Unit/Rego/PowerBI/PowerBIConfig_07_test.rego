package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.POWERBI.7.1v1
#--

### Testing the "PowerBI License found and setting was found in JSON" scenarios
###
test_EimInformationProtectionEdit_Compliant_Enabled if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("EimInformationProtectionEdit")]), "value": true}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.7.1v1", Output, PASS, true) == true
}

test_EimInformationProtectionEdit_NonCompliant_Disabled if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("EimInformationProtectionEdit")]), "value": false}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.7.1v1", Output, FAIL, false) == true
}
###


### Testing the "No PowerBI license found" scenarios
###
test_EimInformationProtectionEdit_NoLicense if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.7.1v1", Output, powerbi_license_error_message, false) == true
}

test_EimInformationProtectionEdit_LicenseVariableMissing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "remove", "path": "/powerbi_license_found"}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.7.1v1", Output, powerbi_license_error_message, false) == true
}

test_EimInformationProtectionEdit_NoLicense_TakesPrecedence_OverMissingTenantSettings if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false},
        {"op": "remove", "path": "/powerbi_tenant_settings"}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.7.1v1", Output, powerbi_license_error_message, false) == true
}
###


### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_EimInformationProtectionEdit_PowerBITenantSettings_Missing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": "/powerbi_tenant_settings"}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or EimInformationProtectionEdit are missing from input JSON"
    TestResult("MS.POWERBI.7.1v1", Output, MissingError, false) == true
}

test_EimInformationProtectionEdit_Missing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": sprintf("/powerbi_tenant_settings/%v", [powerbi_setting_index("EimInformationProtectionEdit")])}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or EimInformationProtectionEdit are missing from input JSON"
    TestResult("MS.POWERBI.7.1v1", Output, MissingError, false) == true
}

test_EimInformationProtectionEdit_PowerBITenantSettings_EmptyArray if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": []}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or EimInformationProtectionEdit are missing from input JSON"
    TestResult("MS.POWERBI.7.1v1", Output, MissingError, false) == true
}

test_EimInformationProtectionEdit_PowerBITenantSettings_NullArrayElement if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": [null]}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or EimInformationProtectionEdit are missing from input JSON"
    TestResult("MS.POWERBI.7.1v1", Output, MissingError, false) == true
}

test_EimInformationProtectionEdit_PowerBITenantSettings_NonObjectArrayElement if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": ["bad-data"]}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or EimInformationProtectionEdit are missing from input JSON"
    TestResult("MS.POWERBI.7.1v1", Output, MissingError, false) == true
}

test_EimInformationProtectionEdit_MissingSettingName if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": sprintf("/powerbi_tenant_settings/%v/settingName", [powerbi_setting_index("EimInformationProtectionEdit")])}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or EimInformationProtectionEdit are missing from input JSON"
    TestResult("MS.POWERBI.7.1v1", Output, MissingError, false) == true
}
###
#--
