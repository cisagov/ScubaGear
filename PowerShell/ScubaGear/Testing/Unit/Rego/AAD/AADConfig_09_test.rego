package aad_test
import rego.v1
import data.aad
import data.utils.report.NotCheckedDetails
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

    ReportDetailString := "0 conditional access policy(s) found that meet(s) all requirements. <a href='#caps'>View all CA policies</a>."
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
#--



