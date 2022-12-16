package teams
import future.keywords


#
# Policy 1
#--
test_3rdParty_Correct_V1 if {
    ControlNumber := "Teams 2.11"
    Requirement := "A DLP solution SHALL be enabled"

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
    ControlNumber := "Teams 2.11"
    Requirement := "Agencies SHOULD use either the native DLP solution offered by Microsoft or a DLP solution that offers comparable services"

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
    ControlNumber := "Teams 2.11"
    Requirement := "The DLP solution SHALL protect Personally Identifiable Information (PII) and sensitive information, as defined by the agency. At a minimum, the sharing of credit card numbers, taxpayer Identification Numbers (TIN), and Social Security Numbers (SSN) via email SHALL be restricted"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check"
}