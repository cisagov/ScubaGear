package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.POWERBI.6.1v1
#--

### Testing the "PowerBI License found and setting was found in JSON" scenarios
###
test_RScriptVisual_Compliant_Disabled if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("RScriptVisual")]), "value": false}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.6.1v1", Output, PASS, true) == true
}

test_RScriptVisual_NonCompliant_Enabled if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [powerbi_setting_index("RScriptVisual")]), "value": true}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.6.1v1", Output, FAIL, false) == true
}
###


### Testing the "No PowerBI license found" scenarios
###
test_RScriptVisual_NoLicense if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.6.1v1", Output, powerbi_license_error_message, false) == true
}

test_RScriptVisual_LicenseVariableMissing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "remove", "path": "/powerbi_license_found"}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.6.1v1", Output, powerbi_license_error_message, false) == true
}

test_RScriptVisual_NoLicense_TakesPrecedence_OverMissingTenantSettings if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false},
        {"op": "remove", "path": "/powerbi_tenant_settings"}
    ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.6.1v1", Output, powerbi_license_error_message, false) == true
}
###


### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_RScriptVisual_PowerBITenantSettings_Missing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": "/powerbi_tenant_settings"}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or RScriptVisual are missing from input JSON"
    TestResult("MS.POWERBI.6.1v1", Output, MissingError, false) == true
}

test_RScriptVisual_Missing if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": sprintf("/powerbi_tenant_settings/%v", [powerbi_setting_index("RScriptVisual")])}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or RScriptVisual are missing from input JSON"
    TestResult("MS.POWERBI.6.1v1", Output, MissingError, false) == true
}

test_RScriptVisual_PowerBITenantSettings_EmptyArray if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": []}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or RScriptVisual are missing from input JSON"
    TestResult("MS.POWERBI.6.1v1", Output, MissingError, false) == true
}

test_RScriptVisual_PowerBITenantSettings_NullArrayElement if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": [null]}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or RScriptVisual are missing from input JSON"
    TestResult("MS.POWERBI.6.1v1", Output, MissingError, false) == true
}

test_RScriptVisual_PowerBITenantSettings_NonObjectArrayElement if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": ["bad-data"]}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or RScriptVisual are missing from input JSON"
    TestResult("MS.POWERBI.6.1v1", Output, MissingError, false) == true
}

test_RScriptVisual_MissingSettingName if {
    patched_input := json.patch(powerbi_tenant_settings_json, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": sprintf("/powerbi_tenant_settings/%v/settingName", [powerbi_setting_index("RScriptVisual")])}
    ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or RScriptVisual are missing from input JSON"
    TestResult("MS.POWERBI.6.1v1", Output, MissingError, false) == true
}
###