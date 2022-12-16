package exo
import future.keywords


#
# Policy 1
#--
test_3rdParty_Correct_V1 if {
    ControlNumber := "EXO 2.15"
    Requirement := "URL comparison with a block-list SHOULD be enabled"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check"
}

#
# Policy 2
#--
test_3rdParty_Correct_V2 if {
    ControlNumber := "EXO 2.15"
    Requirement := "Direct download links SHOULD be scanned for malware"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check"
}

#
# Policy 3
#--
test_3rdParty_Correct_V3 if {
    ControlNumber := "EXO 2.15"
    Requirement := "User click tracking SHOULD be enabled"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check"
}