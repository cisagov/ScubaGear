package powerbi_test
import rego.v1
import data.powerbi
import data.utils.key.TestResult
import data.utils.key.FAIL
import data.utils.key.PASS

#
# Policy MS.POWERBI.1.1v1
#--

### Testing the "PowerBI License found and setting was found in JSON" scenarios
###
test_PublishToWeb_Compliant if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [GetPowerBISettingIndex("PublishToWeb")]), "value": false}
        ])

    # print("patched_input:", patched_input)
    Output := powerbi.tests with input as patched_input
    # print("Output:", Output)
    TestResult("MS.POWERBI.1.1v1", Output, PASS, true) == true
}

test_PublishToWeb_NonCompliant if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": sprintf("/powerbi_tenant_settings/%v/enabled", [GetPowerBISettingIndex("PublishToWeb")]), "value": true}
        ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.1.1v1", Output, FAIL, false) == true
}
###


### Testing the "No PowerBI license found" scenarios
###
test_PublishToWeb_NoLicense if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false}
        ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.1.1v1", Output, PowerbiLicenseErrorMessage, false) == true
}

test_PublishToWeb_LicenseVariableMissing if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "remove", "path": "/powerbi_license_found"}
        ])

    Output := powerbi.tests with input as patched_input
    TestResult("MS.POWERBI.1.1v1", Output, PowerbiLicenseErrorMessage, false) == true
}

test_NoLicense_TakesPrecedence_OverMissingTenantSettings if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false},
        {"op": "remove", "path": "/powerbi_tenant_settings"}
    ])

    Output := powerbi.tests with input as patched_input

    TestResult("MS.POWERBI.1.1v1", Output, PowerbiLicenseErrorMessage, false) == true
}
###

### Testing that the specific license reason from Connect-Tenant reaches the report details.
### The reason distinguishes a tenant with no Power BI licenses from a running user who has
### none assigned - two different fixes, owned by different people.
###
test_NoLicense_TenantReasonSurfaced if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false},
        {"op": "add", "path": "/powerbi_license_reason", "value": "No Power BI or Fabric license found in the tenant."}
    ])

    Output := powerbi.tests with input as patched_input

    TestResult(
        "MS.POWERBI.1.1v1",
        Output,
        "Unable to evaluate tenant setting. No Power BI or Fabric license found in the tenant.",
        false
    ) == true
}

test_NoLicense_UserReasonSurfaced if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false},
        {"op": "add", "path": "/powerbi_license_reason", "value": "Current user does not have a Power BI or Fabric license assigned. Assign a license (e.g., Microsoft Fabric (Free), Power BI Pro) to the running user."}
    ])

    Output := powerbi.tests with input as patched_input

    TestResult(
        "MS.POWERBI.1.1v1",
        Output,
        "Unable to evaluate tenant setting. Current user does not have a Power BI or Fabric license assigned. Assign a license (e.g., Microsoft Fabric (Free), Power BI Pro) to the running user.",
        false
    ) == true
}

# An empty reason must fall back to the original generic message, which is what keeps every
# pre-existing no-license assertion in this suite valid.
test_NoLicense_EmptyReasonFallsBackToGenericMessage if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false},
        {"op": "add", "path": "/powerbi_license_reason", "value": ""}
    ])

    Output := powerbi.tests with input as patched_input

    TestResult("MS.POWERBI.1.1v1", Output, PowerbiLicenseErrorMessage, false) == true
}

# A reason present while the license IS found must not leak into the report details.
test_LicenseFound_ReasonIgnored if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "add", "path": "/powerbi_license_reason", "value": "stale reason that should not appear"},
        {"op": "replace", "path": "/powerbi_tenant_settings/0/enabled", "value": false}
    ])

    Output := powerbi.tests with input as patched_input

    TestResult("MS.POWERBI.1.1v1", Output, PASS, true) == true
}

# A 401/403 from the Power BI Admin API surfaces the provider's fix instead of "Setting Not Found in JSON"
test_AccessDenied_ReasonSurfaced if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": []},
        {"op": "add", "path": "/powerbi_access_denied_reason", "value": "The Power BI Admin API denied access (403 Forbidden)."}
    ])

    Output := powerbi.tests with input as patched_input
    RuleOutput := [Result | some Result in Output; Result.PolicyId == "MS.POWERBI.1.1v1"]

    count(RuleOutput) == 1
    RuleOutput[0].ActualValue == "Access Denied"
    RuleOutput[0].ErrorDetails == "Unable to evaluate tenant setting. The Power BI Admin API denied access (403 Forbidden)."
}

# Access denied wins over any tenant settings present, so the core policy never adds a second result
test_AccessDenied_IgnoresTenantSettings if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "add", "path": "/powerbi_access_denied_reason", "value": "The Power BI Admin API denied access (401 Unauthorized)."}
    ])

    Output := powerbi.tests with input as patched_input
    RuleOutput := [Result | some Result in Output; Result.PolicyId == "MS.POWERBI.1.1v1"]

    count(RuleOutput) == 1
    RuleOutput[0].ActualValue == "Access Denied"
}

# No license is reported over access denied, since a 401/403 is only meaningful once a license was found
test_NoLicense_TakesPrecedence_OverAccessDenied if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": false},
        {"op": "add", "path": "/powerbi_access_denied_reason", "value": "The Power BI Admin API denied access (403 Forbidden)."}
    ])

    Output := powerbi.tests with input as patched_input
    RuleOutput := [Result | some Result in Output; Result.PolicyId == "MS.POWERBI.1.1v1"]

    count(RuleOutput) == 1
    RuleOutput[0].ActualValue == "No License"
    RuleOutput[0].ReportDetails == PowerbiLicenseErrorMessage
}
###


### Testing the "Missing the specific setting that this policy expects" scenarios
###
test_PowerBITenantSettings_Missing if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "remove", "path": "/powerbi_tenant_settings"}
        ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or PublishToWeb are missing from input JSON"
    TestResult("MS.POWERBI.1.1v1", Output, MissingError, false) == true
}

test_PublishToWeb_Missing if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "remove", "path": sprintf("/powerbi_tenant_settings/%v", [GetPowerBISettingIndex("PublishToWeb")])}
        ])

    Output := powerbi.tests with input as patched_input
    MissingError := "powerbi_tenant_settings or PublishToWeb are missing from input JSON"
    TestResult("MS.POWERBI.1.1v1", Output, MissingError, false) == true
}

test_PowerBITenantSettings_EmptyArray if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": []}
    ])

    Output := powerbi.tests with input as patched_input

    MissingError := "powerbi_tenant_settings or PublishToWeb are missing from input JSON"

    TestResult("MS.POWERBI.1.1v1", Output, MissingError, false) == true
}

test_PowerBITenantSettings_NullArrayElement if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": [null]}
    ])

    Output := powerbi.tests with input as patched_input

    MissingError := "powerbi_tenant_settings or PublishToWeb are missing from input JSON"

    TestResult("MS.POWERBI.1.1v1", Output, MissingError, false) == true
}

test_PowerBITenantSettings_NonObjectArrayElement if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "replace", "path": "/powerbi_tenant_settings", "value": ["bad-data"]}
    ])

    Output := powerbi.tests with input as patched_input

    MissingError := "powerbi_tenant_settings or PublishToWeb are missing from input JSON"

    TestResult("MS.POWERBI.1.1v1", Output, MissingError, false) == true
}

test_PublishToWeb_MissingSettingName if {
    patched_input := json.patch(PowerbiTenantSettingsJson, [
        {"op": "replace", "path": "/powerbi_license_found", "value": true},
        {"op": "remove", "path": "/powerbi_tenant_settings/0/settingName"}
    ])

    Output := powerbi.tests with input as patched_input

    MissingError := "powerbi_tenant_settings or PublishToWeb are missing from input JSON"

    TestResult("MS.POWERBI.1.1v1", Output, MissingError, false) == true
}
###


#--
