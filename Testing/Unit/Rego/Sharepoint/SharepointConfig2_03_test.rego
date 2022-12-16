package sharepoint
import future.keywords


#
# Policy 1
#--
test_NotImplemented_Correct if {
    ControlNumber := "Sharepoint 2.3"
    Requirement := "Sharing settings for specific SharePoint sites SHOULD align to their sensitivity level"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Sharepoint Secure Configuration Baseline policy 2.3 for instructions on manual check"
}