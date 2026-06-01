package aad_test
import rego.v1
import data.aad
import data.utils.key.TestResult


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
        " <a href='#caps'>View all CA policies</a>."
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
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, true) == true
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
        " <a href='#caps'>View all CA policies</a>."
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
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
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
        " <a href='#caps'>View all CA policies</a>."
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
        " <a href='#caps'>View all CA policies</a>."
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_EnvironmentNotSupportedGCCHigh_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "gcchigh"},])
    Output := aad.tests with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf

    ReportDetailString := concat("", [
        "This policy is not applicable to GCC High or DOD environments. See <a href=",
        "\"https://github.com/cisagov/ScubaGear/blob/vmain/PowerShell/ScubaGear/baselines/aad.md#msaad91v1\"",
        " target=\"_blank\">Secure Configuration Baseline policy</a> for more info"
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, false) == true
}

test_EnvironmentNotSupportedDoD_Incorrect_V1 if {
    ScubaConf := json.patch(ScubaConfig,
                [{"op": "add", "path": "M365Environment", "value": "dod"},])
    Output := aad.tests with input.service_plans as ServicePlans
                        with input.scuba_config as ScubaConf
    
    ReportDetailString := concat("", [
        "This policy is not applicable to GCC High or DOD environments. See <a href=",
        "\"https://github.com/cisagov/ScubaGear/blob/vmain/PowerShell/ScubaGear/baselines/aad.md#msaad91v1\"",
        " target=\"_blank\">Secure Configuration Baseline policy</a> for more info"
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
        "<br/>Test Policy. <a href='#caps'>View all CA policies</a>."
    ])
    TestResult("MS.AAD.9.1v1", Output, ReportDetailString, true) == true
}

#--