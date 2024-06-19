package aad_test
import rego.v1
import data.aad
import data.utils.aad.P2WARNINGSTR
import data.utils.key.TestResult

#
# Policy MS.AAD.7.1v1
#--
test_PrivilegedUsers_Correct if {
    Output := aad.tests with input.privileged_users as PrivilegedUsers

    ReportDetailString := "2 global admin(s) found:<br/>Test Name 1, Test Name 2"
    TestResult("MS.AAD.7.1v1", Output, ReportDetailString, true) == true
}

test_PrivilegedUsers_Incorrect_V1 if {
    Users := json.patch(PrivilegedUsers, [{"op": "remove", "path": "User2",}])

    Output := aad.tests with input.privileged_users as Users

    ReportDetailString := "1 global admin(s) found:<br/>Test Name 1"
    TestResult("MS.AAD.7.1v1", Output, ReportDetailString, false) == true
}

test_PrivilegedUsers_Incorrect_V2 if {
    Output := aad.tests with input.privileged_users as PrivilegedUsers
                        with input.privileged_users.User3 as {"DisplayName": "Test Name 3", "roles": ["Global Administrator"]}
                        with input.privileged_users.User4 as {"DisplayName": "Test Name 4", "roles": ["Global Administrator"]}
                        with input.privileged_users.User5 as {"DisplayName": "Test Name 5", "roles": ["Global Administrator"]}
                        with input.privileged_users.User6 as {"DisplayName": "Test Name 6", "roles": ["Global Administrator"]}
                        with input.privileged_users.User7 as {"DisplayName": "Test Name 7", "roles": ["Global Administrator"]}
                        with input.privileged_users.User8 as {"DisplayName": "Test Name 8", "roles": ["Global Administrator"]}
                        with input.privileged_users.User9 as {"DisplayName": "Test Name 9", "roles": ["Global Administrator"]}

    ReportDetailString := concat(" ", [
        "9 global admin(s) found:<br/>Test Name 1, Test Name 2, Test Name 3,",
        "Test Name 4, Test Name 5, Test Name 6, Test Name 7, Test Name 8, Test Name 9"
    ])

    TestResult("MS.AAD.7.1v1", Output, ReportDetailString, false) == true
}
#--

#--
# Policy MS.AAD.7.2v1
#--
# Correct because the ratio of global admins to non global admins is less than 1
test_SecureScore_Correct_V1 if {
    Output := aad.tests with input.privileged_users as PrivilegedUsers
                        with input.privileged_users.User2.roles as ["Cloud Application Administrator", "Global Administrator"]
                        with input.privileged_users.User3 as {"DisplayName": "Test Name 3", "roles": ["Application Administrator"]}
                        with input.privileged_users.User4 as {"DisplayName": "Test Name 4", "roles": ["User Administrator"]}
                        with input.privileged_users.User5 as {"DisplayName": "Test Name 5", "roles": ["Privileged Role Administrator"]}

    ReportDetailStr := "Requirement met: Least Privilege Score = 0.66 (should be 1 or less)"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, true) == true
}

# Correct because the ratio of global admins to non global admins is equal to 1
test_SecureScore_Incorrect_V1 if {
    Users := json.patch(PrivilegedUsers, [{"op": "add", "path": "User2/roles/0", "value": "User Administrator"}])

    Output := aad.tests with input.privileged_users as Users
                        with input.privileged_users.User3 as {"DisplayName": "Test Name 3", "roles": ["Application Administrator"]}
                        with input.privileged_users.User4 as {"DisplayName": "Test Name 4", "roles": ["Privileged Role Administrator"]}

    ReportDetailStr := "Requirement met: Least Privilege Score = 1 (should be 1 or less)"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, true) == true
}

# Incorrect because the ratio of global admins to non global admins is more than 1
test_SecureScore_Incorrect_V2 if {
    Users := json.patch(PrivilegedUsers,
                [{"op": "add", "path": "User2/roles/0", "value": "Application Administrator"},
                {"op": "add", "path": "User1/roles", "value": ["User Administrator", "Global Administrator"]}])

    Output := aad.tests with input.privileged_users as Users
                        with input.privileged_users.User3 as {"DisplayName": "Test Name 3", "roles": ["Privileged Role Administrator"]}

    ReportDetailStr := "Requirement not met: Least Privilege Score = 2 (should be 1 or less)"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, false) == true
}

# Incorrect because the ratio of global admins to non global admins is undefined (all are global admins)
test_SecureScore_Incorrect_V3 if {
    Users := json.patch(PrivilegedUsers, [{"op": "add", "path": "User2/roles/0", "value": "User Administrator"}])

    Output := aad.tests with input.privileged_users as Users
                        with input.privileged_users.User3 as {"DisplayName": "Test Name 3", "roles": [
                                                                                                "Hybrid Identity Administrator",
                                                                                                "Global Administrator"
                                                                                            ]}

    ReportDetailStr := "Requirement not met: All privileged users are Global Admin"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, false) == true
}

# Incorrect because the total number of global admins is greater than eight
test_SecureScore_Incorrect_V4 if {
    Users := json.patch(PrivilegedUsers, [{"op": "add", "path": "User2/roles/0", "value": "Exchange Administrator"}])

    Output := aad.tests with input.privileged_users as Users
                        with input.privileged_users.User3 as {"DisplayName": "Test Name 3", "roles": ["Global Administrator"]}
                        with input.privileged_users.User4 as {"DisplayName": "Test Name 4", "roles": ["Global Administrator"]}
                        with input.privileged_users.User5 as {"DisplayName": "Test Name 5", "roles": ["Global Administrator"]}
                        with input.privileged_users.User6 as {"DisplayName": "Test Name 6", "roles": ["Global Administrator"]}
                        with input.privileged_users.User7 as {"DisplayName": "Test Name 7", "roles": ["Global Administrator"]}
                        with input.privileged_users.User8 as {"DisplayName": "Test Name 8", "roles": ["Global Administrator"]}
                        with input.privileged_users.User9 as {"DisplayName": "Test Name 9", "roles": ["Global Administrator"]}

    ReportDetailStr := "Requirement not met: Policy MS.AAD.7.1 failed so score not computed"

    TestResult("MS.AAD.7.2v1", Output, ReportDetailStr, false) == true
}

#--
# Policy MS.AAD.7.3v1
#--
test_OnPremisesImmutableId_Correct if {
    Output := aad.tests with input.privileged_users as PrivilegedUsers

    ReportDetailString := "0 admin(s) that are not cloud-only found"
    TestResult("MS.AAD.7.3v1", Output, ReportDetailString, true) == true
}

test_OnPremisesImmutableId_Incorrect_V1 if {
    Users := json.patch(PrivilegedUsers,
                [{"op": "add", "path": "User1/OnPremisesImmutableId", "value": "HelloWorld"},
                {"op": "remove", "path": "User2"}])

    Output := aad.tests with input.privileged_users as Users

    ReportDetailString := "1 admin(s) that are not cloud-only found:<br/>Test Name 1"
    TestResult("MS.AAD.7.3v1", Output, ReportDetailString, false) == true
}

test_OnPremisesImmutableId_Incorrect_V2 if {
    Users := json.patch(PrivilegedUsers,
                [{"op": "add", "path": "User1/OnPremisesImmutableId", "value": "HelloWorld"},
                {"op": "add", "path": "User2/OnPremisesImmutableId", "value": null}])

    Output := aad.tests with input.privileged_users as Users

    ReportDetailString := "1 admin(s) that are not cloud-only found:<br/>Test Name 1"
    TestResult("MS.AAD.7.3v1", Output, ReportDetailString, false) == true
}
#--

# Policy MS.AAD.7.4v1
#--
test_AdditionalProperties_Correct_V1 if {
    Output := aad.tests with input.privileged_roles as PrivilegedRoles
                        with input.service_plans as ServicePlans

    ReportDetailString := "0 role(s) that contain users with permanent active assignment"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, true) == true
}

test_AdditionalProperties_Correct_V2 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "remove", "path": "1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Users as ["ae71e61c-f465-4db6-8d26-5f3e52bdd800"]

    ReportDetailString := "0 role(s) that contain users with permanent active assignment"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, true) == true
}

test_AdditionalProperties_Correct_V3 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "remove", "path": "1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Groups as ["ae71e61c-f465-4db6-8d26-5f3e52bdd800"]

    ReportDetailString := "0 role(s) that contain users with permanent active assignment"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, true) == true
}

test_AdditionalProperties_LicenseMissing_V1 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Groups as ["ae71e61c-f465-4db6-8d26-5f3e52bdd800"]

    ReportDetailString :=
        "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license, which is required for this feature**"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V1 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "remove", "path": "1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V2 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V3 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"},
                {"op": "add", "path": "1/Assignments/0/EndDateTime", "value": null}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V4 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "0/Assignments/1", "value": {"EndDateTime": null, "PrincipalId":"38035edd-63a1-4c08-8bd2-ad78d0624057"}},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"},
                {"op": "add", "path": "1/Assignments/0/EndDateTime", "value": null}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V5 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "remove", "path": "1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Users as ["7b36d094-0211-400b-aabd-3793e9a30fc6"]

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V6 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Users as ["7b36d094-0211-400b-aabd-3793e9a30fc6"]

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V7 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"},
                {"op": "add", "path": "1/Assignments/0/EndDateTime", "value": null}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Users as ["7b36d094-0211-400b-aabd-3793e9a30fc6"]

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V8 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "0/Assignments/1", "value": {"EndDateTime": null, "PrincipalId":"38035edd-63a1-4c08-8bd2-ad78d0624057"}},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"},
                {"op": "add", "path": "1/Assignments/0/EndDateTime", "value": null}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Users as ["7b36d094-0211-400b-aabd-3793e9a30fc6"]

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V9 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Users as ["e54ac846-1f5a-4afe-aa69-273b42c3b0c1"]

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V10 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "remove", "path": "1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Groups as ["7b36d094-0211-400b-aabd-3793e9a30fc6"]

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V11 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Groups as ["7b36d094-0211-400b-aabd-3793e9a30fc6"]

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V12 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"},
                {"op": "add", "path": "1/Assignments/0/EndDateTime", "value": null}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Groups as ["7b36d094-0211-400b-aabd-3793e9a30fc6"]

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V13 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "0/Assignments/1", "value": {"EndDateTime": null, "PrincipalId":"38035edd-63a1-4c08-8bd2-ad78d0624057"}},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"},
                {"op": "add", "path": "1/Assignments/0/EndDateTime", "value": null}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Groups as ["7b36d094-0211-400b-aabd-3793e9a30fc6"]

    ReportDetailString := concat("", [
        "2 role(s) that contain users with permanent active assignment:",
        "<br/>Application Administrator, Global Administrator"
    ])

    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}

test_AdditionalProperties_Incorrect_V14 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/EndDateTime", "value": null},
                {"op": "add", "path": "1/DisplayName", "value": "Application Administrator"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans
                        with input.scuba_config.Aad["MS.AAD.7.4v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.7.4v1"].RoleExclusions.Groups as ["e54ac846-1f5a-4afe-aa69-273b42c3b0c1"]

    ReportDetailString := "1 role(s) that contain users with permanent active assignment:<br/>Global Administrator"
    TestResult("MS.AAD.7.4v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.7.5v1
#--
test_Assignments_Correct if {
    Roles := json.patch(PrivilegedRoles, [{"op": "remove", "path": "1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := "0 role(s) assigned to users outside of PIM"
    TestResult("MS.AAD.7.5v1", Output, ReportDetailString, true) == true
}

test_Assignments_Incorrect if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/Assignments/0/StartDateTime", "value": null},
                {"op": "remove", "path": "1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := "1 role(s) assigned to users outside of PIM:<br/>Global Administrator"
    TestResult("MS.AAD.7.5v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.7.6v1
#--
test_AdditionalProperties_Correct_V4 if {
    Roles := json.patch(PrivilegedRoles, [{"op": "remove", "path": "1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := "0 role(s) or group(s) allowing activation without approval found"
    TestResult("MS.AAD.7.6v1", Output, ReportDetailString, true) == true
}

test_AdditionalProperties_Correct_V5 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "1/DisplayName", "value": "Groups Administrator"},
                {"op": "add", "path": "1/Rules/0/AdditionalProperties/setting/isApprovalRequired", "value": false},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Approval_EndUser_Assignment"},
                {"op": "add", "path": "1/Rules/0/Id", "value": "Approval_EndUser_Assignment"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := "0 role(s) or group(s) allowing activation without approval found"
    TestResult("MS.AAD.7.6v1", Output, ReportDetailString, true) == true
}

test_AdditionalProperties_Incorrect_V15 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/setting/isApprovalRequired", "value": false},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Approval_EndUser_Assignment"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "1 role(s) or group(s) allowing activation without approval found:",
        "<br/>Global Administrator(Directory Role)"
    ])

    TestResult("MS.AAD.7.6v1", Output, ReportDetailString, false) == true
}

test_PIM_Group_Incorrect_V15 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "1/Rules/0/AdditionalProperties/setting/isApprovalRequired", "value": false},
                {"op": "add", "path": "1/DisplayName", "value": "Global Administrator"},
                {"op": "add", "path": "1/Rules/0/Id", "value": "Approval_EndUser_Assignment"},
                {"op": "add", "path": "1/Rules/0/RuleSource", "value": "My PIM GROUP"},
                {"op": "add", "path": "1/Rules/0/RuleSourceType", "value": "PIM Group"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Approval_EndUser_Assignment"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "1 role(s) or group(s) allowing activation without approval found:",
        "<br/>My PIM GROUP(PIM Group)"
    ])

    TestResult("MS.AAD.7.6v1", Output, ReportDetailString, false) == true
}

test_NoP2License_Incorrect if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/setting/isApprovalRequired", "value": false},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Approval_EndUser_Assignment"}])

    Service := json.patch(ServicePlans,[{"op": "remove", "path": "1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as Service

    TestResult("MS.AAD.7.6v1", Output, P2WARNINGSTR, false) == true
}
#--

#
# Policy MS.AAD.7.7v1
#--
test_notificationRecipients_Correct if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_Admin_Assignment"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := "0 role(s) or group(s) without notification e-mail configured for role assignments found"
    TestResult("MS.AAD.7.7v1", Output, ReportDetailString, true) == true
}

test_notificationRecipients_Incorrect_V1 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_Admin_Assignment"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/notificationRecipients", "value": []}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    DescriptionString := concat("", [
        "1 role(s) or group(s) without notification e-mail configured for role assignments found:",
        "<br/>Global Administrator(Directory Role)"
    ])

    TestResult("MS.AAD.7.7v1", Output, DescriptionString, false) == true
}

test_notificationRecipients_Incorrect_V2 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_Admin_Assignment"},
                {"op": "add", "path": "0/Rules/1/AdditionalProperties/notificationRecipients", "value": []}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "1 role(s) or group(s) without notification e-mail configured for role assignments found:",
        "<br/>Global Administrator(Directory Role)"
    ])

    TestResult("MS.AAD.7.7v1", Output, ReportDetailString, false) == true
}

test_notificationRecipients_Incorrect_V3 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_Admin_Assignment"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/notificationRecipients", "value": []},
                {"op": "add", "path": "0/Rules/1/AdditionalProperties/notificationRecipients", "value": []}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "1 role(s) or group(s) without notification e-mail configured for role assignments found:",
        "<br/>Global Administrator(Directory Role)"
    ])

    TestResult("MS.AAD.7.7v1", Output, ReportDetailString, false) == true
}

test_notificationRecipients_PIM_Incorrect_V3 if {
    TmpRule := {
        "Id": "Notification_Admin_Admin_Assignment",
        "RuleSource":  "My PIM GRoup",
        "RuleSourceType":  "PIM Group",
        "AdditionalProperties": {
            "notificationRecipients": []
        }
    }

    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_Admin_Assignment"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/notificationRecipients", "value": []},
                {"op": "add", "path": "0/Rules/1/AdditionalProperties/notificationRecipients", "value": []},
                {"op": "add", "path": "0/Rules/2", "value": TmpRule},
                {"op": "add", "path": "0/Rules/3", "value": TmpRule},
                {"op": "add", "path": "0/Rules/3/Id", "value": "Notification_Admin_Admin_Eligibility"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "2 role(s) or group(s) without notification e-mail configured for role assignments found:",
        "<br/>Global Administrator(Directory Role), My PIM GRoup(PIM Group)"
    ])

    TestResult("MS.AAD.7.7v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.7.8v1
#--
test_Id_Correct_V1 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "remove", "path": "0/Rules/1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString :=
        "0 role(s) or group(s) without notification e-mail configured for Global Administrator activations found"
    TestResult("MS.AAD.7.8v1", Output, ReportDetailString, true) == true
}

test_Id_Correct_V2 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/notificationType", "value": ""},
                {"op": "remove", "path": "0/Rules/1"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString :=
        "0 role(s) or group(s) without notification e-mail configured for Global Administrator activations found"
    TestResult("MS.AAD.7.8v1", Output, ReportDetailString, true) == true
}

test_Id_PIM_Correct_V2 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/notificationType", "value": ""},
                {"op": "add", "path": "0/Rules/1/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "add", "path": "0/Rules/1/RuleSource", "value": "My PIM Group"},
                {"op": "add", "path": "0/Rules/1/RuleSourceType", "value": "PIM Group"},
                {"op": "add", "path": "0/Rules/1/AdditionalProperties/notificationType", "value": ""}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString :=
        "0 role(s) or group(s) without notification e-mail configured for Global Administrator activations found"
    TestResult("MS.AAD.7.8v1", Output, ReportDetailString, true) == true
}

test_Id_PIM_Incorrect_V2 if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "add", "path": "0/Rules/1/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "add", "path": "0/Rules/1/RuleSource", "value": "My PIM Group"},
                {"op": "add", "path": "0/Rules/1/RuleSourceType", "value": "PIM Group"},
                {"op": "add", "path": "0/Rules/1/AdditionalProperties/notificationRecipients", "value": []}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "1 role(s) or group(s) without notification e-mail configured for Global Administrator activations found:",
        "<br/>My PIM Group(PIM Group)"
    ])

    TestResult("MS.AAD.7.8v1", Output, ReportDetailString, false) == true
}

test_Id_Incorrect if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/notificationRecipients", "value": []}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "1 role(s) or group(s) without notification e-mail configured for Global Administrator activations found:",
        "<br/>Global Administrator(Directory Role)"
    ])

    TestResult("MS.AAD.7.8v1", Output, ReportDetailString, false) == true
}
#--

#
# Policy MS.AAD.7.9v1
#--

test_DisplayName_Correct if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/DisplayName", "value": "Cloud Administrator"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Cloud Administrator"},
                {"op": "add", "path": "0/Rules/0/RuleSource", "value": "Cloud Administrator"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString :=
        "0 role(s) or group(s) without notification e-mail configured for role activations found"
    TestResult("MS.AAD.7.9v1", Output, ReportDetailString, true) == true
}

test_DisplayName_PIM_Correct if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/DisplayName", "value": "Cloud Administrator"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Cloud Administrator"},
                {"op": "add", "path": "0/Rules/0/RuleSource", "value": "Cloud Administrator"},
                {"op": "add", "path": "1/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "1/DisplayName", "value": "Cloud Administrator 2"},
                {"op": "add", "path": "1/Rules/0/Id", "value": "Cloud Administrator"},
                {"op": "add", "path": "1/Rules/0/AdditionalProperties/notificationType", "value": "Email"},
                {"op": "add", "path": "1/Rules/0/RuleSource", "value": "MY PIM Group"},
                {"op": "add", "path": "1/Rules/0/RuleSourceType", "value": "PIM Group"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString :=
        "0 role(s) or group(s) without notification e-mail configured for role activations found"
    TestResult("MS.AAD.7.9v1", Output, ReportDetailString, true) == true
}


test_DisplayName_Incorrect if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/DisplayName", "value": "Cloud Administrator"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "add", "path": "0/Rules/0/RuleSource", "value": "Cloud Administrator"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/notificationRecipients", "value": []}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "1 role(s) or group(s) without notification e-mail configured for role activations found:",
        "<br/>Cloud Administrator(Directory Role)"
    ])

    TestResult("MS.AAD.7.9v1", Output, ReportDetailString, false) == true
}

test_DisplayName_PIM_Incorrect if {
    Roles := json.patch(PrivilegedRoles,
                [{"op": "remove", "path": "1"},
                {"op": "add", "path": "0/RoleTemplateId", "value": "1D2EE3F0-90D3-4764-8AF8-BE81FE9D4D71"},
                {"op": "add", "path": "0/DisplayName", "value": "Cloud Administrator"},
                {"op": "add", "path": "0/Rules/0/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "add", "path": "0/Rules/0/RuleSource", "value": "Cloud Administrator"},
                {"op": "add", "path": "0/Rules/0/AdditionalProperties/notificationRecipients", "value": []},
                {"op": "add", "path": "0/Rules/1/Id", "value": "Notification_Admin_EndUser_Assignment"},
                {"op": "add", "path": "0/Rules/1/RuleSource", "value": "MY PIM Group"},
                {"op": "add", "path": "0/Rules/1/RuleSourceType", "value": "PIM Group"}])

    Output := aad.tests with input.privileged_roles as Roles
                        with input.service_plans as ServicePlans

    ReportDetailString := concat("", [
        "1 role(s) or group(s) without notification e-mail configured for role activations found:",
        "<br/>Cloud Administrator(Directory Role)"
    ])

    TestResult("MS.AAD.7.9v1", Output, ReportDetailString, false) == true
}
#--