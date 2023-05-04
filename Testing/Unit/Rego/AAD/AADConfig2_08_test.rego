package aad
import future.keywords


#
# Policy 1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.AAD.8.1v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.8 for instructions on manual check"
}