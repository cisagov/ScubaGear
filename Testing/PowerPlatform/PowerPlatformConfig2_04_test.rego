package powerplatform
import future.keywords


#
# Policy 1
#--
test_NotImplemented_Correct if {
    ControlNumber := "Power Platform 2.4"
    Requirement := "Content security policies for model-driven Power Apps SHALL be enabled"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Power Platform Secure Configuration Baseline policy 2.4 for instructions on manual check"
}