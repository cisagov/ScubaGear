package aad_test
import rego.v1
import data.aad
import data.utils.key.TestResult
import data.utils.aad.AgentExclusionsFullyExempt

# SKU entries shaped like the provider's license_information export
LicenseSku(PartNumber, EnabledUnits) := {
    "SkuPartNumber": PartNumber,
    "SkuId": concat("-", ["sku", PartNumber]),
    "ConsumedUnits": 1,
    "PrepaidUnits": {"Enabled": EnabledUnits, "Suspended": 0, "Warning": 0, "LockedOut": 0},
}

LicensesWithoutAgents := [LicenseSku("SPE_E5", 25), LicenseSku("POWER_BI_STANDARD", 1000000)]

LicensesWithE7 := [LicenseSku("SPE_E5", 25), LicenseSku("MICROSOFT_365_E7", 10)]

NoAgentLicenseDetails := concat("", [
    "This policy requires a Microsoft Agent 365 or Microsoft 365 E7 license, which was not found ",
    "in this tenant. See <a href=\"https://github.com/cisagov/ScubaGear/blob/vmain/PowerShell/ScubaGear",
    "/baselines/aad.md#msaad91v1\" target=\"_blank\">Secure Configuration Baseline policy</a> for more info"
])

test_NoAgentLicense_NotApplicable_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    Output := aad.tests with input.service_plans as ServicePlans
                        with input.license_information as LicensesWithoutAgents
                        with input.scuba_config as ScubaConf

    TestResult("MS.AAD.9.1v1", Output, NoAgentLicenseDetails, false) == true
    some Result in Output
    Result.PolicyId == "MS.AAD.9.1v1"
    Result.Criticality == "Shall/Not-Implemented"
}

test_NoAgentLicense_SingleSkuObject_NotApplicable_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    Output := aad.tests with input.service_plans as ServicePlans
                        with input.license_information as LicenseSku("SPE_E5", 25)
                        with input.scuba_config as ScubaConf

    TestResult("MS.AAD.9.1v1", Output, NoAgentLicenseDetails, false) == true
}

test_AgentLicense_Evaluated_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    ReportDetailString := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    every Licenses in [
        LicensesWithE7,
        [LicenseSku("AGENT_365", 1)],
        LicenseSku("MICROSOFT_365_E7", 3)
    ] {
        Output := aad.tests with input.service_plans as ServicePlans
                            with input.license_information as Licenses
                            with input.scuba_config as ScubaConf
        TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
    }
}

test_AgentLicenseWithNoEnabledUnits_NotApplicable_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    Output := aad.tests with input.service_plans as ServicePlans
                        with input.license_information as [LicenseSku("MICROSOFT_365_E7", 0)]
                        with input.scuba_config as ScubaConf

    TestResult("MS.AAD.9.1v1", Output, NoAgentLicenseDetails, false) == true
}

# Missing license data must not be treated as a missing license
test_NoLicenseData_Evaluated_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    ReportDetailString := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    every Licenses in [[], null] {
        Output := aad.tests with input.service_plans as ServicePlans
                            with input.license_information as Licenses
                            with input.scuba_config as ScubaConf
        TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
    }
}

test_NoAgentLicense_P2WarningTakesPrecedence_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    ServPlans := json.patch(ServicePlans, [{"op": "replace", "path": "", "value": []},])
    Output := aad.tests with input.service_plans as ServPlans
                        with input.license_information as LicensesWithoutAgents
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license,",
        " which is required for this feature**"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

# GCC High and DoD report the environment message once, not the license message as well
test_NoAgentLicense_GovernmentReportsEnvironmentOnly_V1 if {
    every Environment in ["gcchigh", "dod"] {
        ScubaConf := json.patch(ScubaConfig,
                    [{"op": "add", "path": "M365Environment", "value": Environment},])
        Output := aad.tests with input.service_plans as ServicePlans
                            with input.license_information as LicensesWithoutAgents
                            with input.scuba_config as ScubaConf
        ReportDetailString := concat("", [
            "This policy is not applicable to GCC High or DOD environments because the feature is not yet ",
            "available. See <a href=\"https://github.com/cisagov/ScubaGear/blob/vmain/PowerShell/ScubaGear",
            "/baselines/aad.md#msaad91v1\" target=\"_blank\">Secure Configuration Baseline policy</a> for more info"
        ])
        TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
    }
}

# A valid agent policy is evaluated even if no agent license is found
test_ValidPolicyWithoutLicenseData_Correct_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "high"},
                {"op": "add", "path": "Conditions/ClientApplications", "value": {} },
                {"op": "add", "path": "Conditions/ClientApplications/IncludeAgentIdServicePrincipals", "value": ["All"] },
                {"op": "add", "path": "Conditions/ClientAppTypes", "value": ["all"] },])
    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.license_information as LicensesWithoutAgents
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, true) == true
}

test_AgentExclusions_Empty if {
    every raw in [null, "", " \t\r\n ", []] {
        AgentExclusionsFullyExempt({"Conditions": {"ClientApplications": {"ExcludeAgentIdServicePrincipals": raw}}}, "MS.AAD.9.1v1")
            with input.scuba_config as {}
    }
    AgentExclusionsFullyExempt({"Conditions": {}}, "MS.AAD.9.1v1") with input.scuba_config as {}
}

test_AgentExclusions_ApprovedStringAndArray if {
    ids := ["aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"]
    every raw in [ids, concat(" \t\n ", ids)] {
        AgentExclusionsFullyExempt({"Conditions": {"ClientApplications": {"ExcludeAgentIdServicePrincipals": raw}}}, "MS.AAD.9.1v1")
            with input.scuba_config.Aad["MS.AAD.9.1v1"].AgentExclusions.Agents as ids
    }
}

test_AgentExclusions_Unapproved if {
    ids := ["aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"]
    every raw in [ids, concat(" ", ids)] {
        not AgentExclusionsFullyExempt({"Conditions": {"ClientApplications": {"ExcludeAgentIdServicePrincipals": raw}}}, "MS.AAD.9.1v1")
            with input.scuba_config as {}
        not AgentExclusionsFullyExempt({"Conditions": {"ClientApplications": {"ExcludeAgentIdServicePrincipals": raw}}}, "MS.AAD.9.1v1")
            with input.scuba_config.Aad["MS.AAD.9.1v1"].AgentExclusions.Agents as [ids[0]]
    }
}

test_AgentExclusions_UnexpectedTypeFails if {
    not AgentExclusionsFullyExempt({"Conditions": {"ClientApplications": {"ExcludeAgentIdServicePrincipals": 42}}}, "MS.AAD.9.1v1")
        with input.scuba_config as {}
}

test_AgentPolicy_PreviewScopeAndExclusions if {
    id := "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    policy := json.patch(ConditionalAccessPolicies, [
        {"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "medium, high"},
        {"op": "add", "path": "Conditions/ClientAppTypes", "value": ["all"]},
        {"op": "add", "path": "Conditions/Applications/IncludeApplications", "value": "AllAgentIdResources"},
        {"op": "add", "path": "Conditions/ClientApplications", "value": {
            "IncludeAgentIdServicePrincipals": "All",
            "ExcludeAgentIdServicePrincipals": id,
        }},
    ])
    result := aad.AIAgentsEval(policy)
        with input.scuba_config.Aad["MS.AAD.9.1v1"].AgentExclusions.Agents as [id]
    result.status == "pass"
    near_miss := aad.AIAgentsEval(policy) with input.scuba_config as {}
    near_miss.status == "near_miss"
    near_miss.MissingExclusionTypes == ["agent exclusions"]
    wrong_scope := json.patch(policy, [{"op": "replace", "path": "Conditions/Applications/IncludeApplications", "value": ["Office365"]}])
    not aad.AIAgentsBaseCheck(wrong_scope)
}


#
# Policy MS.AAD.9.1v1
#--
test_NoBlockRiskyAgentsCAP_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    Output := aad.tests with input.conditional_access_policies as [ConditionalAccessPolicies]
                        with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_BlockRiskyAgentsCAP_Correct_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "high"},
                {"op": "add", "path": "Conditions/ClientApplications", "value": {} },
                {"op": "add", "path": "Conditions/ClientApplications/IncludeAgentIdServicePrincipals", "value": ["All"] },
                {"op": "add", "path": "Conditions/ClientAppTypes", "value": ["all"] },])
    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, true) == true
}

test_BlockRiskyAgentsCAPNearMiss_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "high"},
                {"op": "add", "path": "Conditions/ClientApplications", "value": {} },
                {"op": "add", "path": "Conditions/ClientApplications/IncludeAgentIdServicePrincipals", "value": ["All"] },
                {"op": "add", "path": "Conditions/ClientAppTypes", "value": ["all"] },
                {"op": "add", "path": "Conditions/ClientApplications/ExcludeAgentIdServicePrincipals", "value": ["aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"]}])
    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf
                        with input.scuba_config.Aad["MS.AAD.9.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.9.1v1"].AgentExclusions.Agents as ["bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"]

    ReportDetailString := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <br/><br/><strong>Near miss: </strong> Test Policy would pass if ",
        "the config file is updated to include:",
        " agent exclusions. <a href='#caps'>View all CA policies</a>. ",
        "<a href=\"https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/scubaconfiganalyzer.md\" ",
        "target=\"_blank\">Run the Start-SCuBAConfigAnalyzer cmdlet</a> ",
        "and import your ScubaResults JSON file to determine which specific exclusions to add to the configuration file."
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_MissingHighRisk_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "medium"},
                {"op": "add", "path": "Conditions/ClientApplications", "value": {} },
                {"op": "add", "path": "Conditions/ClientApplications/IncludeAgentIdServicePrincipals", "value": ["All"] },
                {"op": "add", "path": "Conditions/ClientAppTypes", "value": ["all"] },])
    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_MultipleRiskLevels_Correct_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "medium,high"},
                {"op": "add", "path": "Conditions/ClientApplications", "value": {} },
                {"op": "add", "path": "Conditions/ClientApplications/IncludeAgentIdServicePrincipals", "value": ["All"] },
                {"op": "add", "path": "Conditions/ClientAppTypes", "value": ["all"] },])
    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, true) == true
}

test_MissingAgentIdServicePrincipals_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "high"},
                {"op": "add", "path": "Conditions/ClientApplications", "value": {} },
                {"op": "add", "path": "Conditions/ClientApplications/IncludeAgentIdServicePrincipals", "value": [] },
                {"op": "add", "path": "Conditions/ClientAppTypes", "value": ["all"] },])
    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_MissingClientAppTypes_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "high"},
                {"op": "add", "path": "Conditions/ClientApplications", "value": {} },
                {"op": "add", "path": "Conditions/ClientApplications/IncludeAgentIdServicePrincipals", "value": ["All"] },
                {"op": "add", "path": "Conditions/ClientAppTypes", "value": [] },])
    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "0 conditional access policy(s) found that meet(s) all requirements.",
        " <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_EnvironmentNotSupportedGCCHigh_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "gcchigh"},])
    Output := aad.tests with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "This policy is not applicable to GCC High or DOD environments because the feature is not yet ",
        "available. See <a href=\"https://github.com/cisagov/ScubaGear/blob/vmain/PowerShell/ScubaGear",
        "/baselines/aad.md#msaad91v1\" target=\"_blank\">Secure Configuration Baseline policy</a> for more info"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_EnvironmentNotSupportedDoD_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "dod"},])
    Output := aad.tests with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf
    
    ReportDetailString := concat("", [
        "This policy is not applicable to GCC High or DOD environments because the feature is not yet ",
        "available. See <a href=\"https://github.com/cisagov/ScubaGear/blob/vmain/PowerShell/ScubaGear",
        "/baselines/aad.md#msaad91v1\" target=\"_blank\">Secure Configuration Baseline policy</a> for more info"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_NoP2License_Incorrect_V1 if {
    ServPlans := json.patch(ServicePlans,
                [{"op": "replace", "path": "", "value": []},])
    Output := aad.tests with input.service_plans as ServPlans

    ReportDetailString := concat("", [
        "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license,",
        " which is required for this feature**"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_PrioritizeLicenseOverEnvironment_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "gcchigh"},])
    ServPlans := json.patch(ServicePlans,
                [{"op": "replace", "path": "", "value": []},])
    Output := aad.tests with input.service_plans as ServPlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "**NOTE: Your tenant does not have a Microsoft Entra ID P2 license,",
        " which is required for this feature**"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

# Future proofing test to ensure that if the policy is applied properly, it will pass based on that 
# and not pass due to the environment. GCCHigh and DoD tenants may acquire this feature in the future
test_PrioritizePolicyOverEnvironment_Correct_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "gcchigh"},])
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "high"},
                {"op": "add", "path": "Conditions/ClientApplications", "value": {} },
                {"op": "add", "path": "Conditions/ClientApplications/IncludeAgentIdServicePrincipals", "value": ["All"] },
                {"op": "add", "path": "Conditions/ClientAppTypes", "value": ["all"] },])
    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, true) == true
}

test_AppExclusions_Correct_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "commercial"},])
    CAP := json.patch(ConditionalAccessPolicies,
                [{"op": "add", "path": "Conditions/AgentIdRiskLevels", "value": "high"},
                {"op": "add", "path": "Conditions/ClientApplications", "value": {} },
                {"op": "add", "path": "Conditions/ClientApplications/IncludeAgentIdServicePrincipals", "value": ["All"] },
                {"op": "add", "path": "Conditions/ClientAppTypes", "value": ["all"] },
                {"op": "add", "path": "Conditions/Applications/ExcludeApplications", "value": ["testapp"]},])
    Output := aad.tests with input.conditional_access_policies as [CAP]
                        with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf
                        with input.scuba_config.Aad["MS.AAD.9.1v1"] as ScubaConfig
                        with input.scuba_config.Aad["MS.AAD.9.1v1"].CapExclusions.Applications as ["testapp"]

    ReportDetailString := concat("", [
        "1 conditional access policy(s) found that meet(s) all requirements:",
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, true) == true
}

#--