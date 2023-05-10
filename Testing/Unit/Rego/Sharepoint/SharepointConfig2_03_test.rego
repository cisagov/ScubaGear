package sharepoint
import future.keywords


#
# Policy 1
#--
test_NotImplemented_Correct if {
    PolicyId := "MS.SHAREPOINT.2.1v1"
  
    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == sprintf("Currently cannot be checked automatically. See Sharepoint Secure Configuration Baseline policy %v for instructions on manual check", [PolicyId])
}