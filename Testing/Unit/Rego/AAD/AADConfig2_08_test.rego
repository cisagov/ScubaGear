package aad
import future.keywords


#
# Policy 1
#--
test_NotImplemented_Correct if {
    ControlNumber := "AAD 2.8"
    Requirement := "User passwords SHALL NOT expire"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Currently cannot be checked automatically. See Azure Active Directory Secure Configuration Baseline policy 2.8 for instructions on manual check"
}