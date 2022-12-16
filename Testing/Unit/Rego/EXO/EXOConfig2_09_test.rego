package exo
import future.keywords


#
# Policy 1
#--
test_3rdParty_Correct_V1 if {
    ControlNumber := "EXO 2.9"
    Requirement := "Emails SHALL be filtered by the file types of included attachments. The selected filtering solution SHOULD offer services comparable to Microsoft Defender's Common Attachment Filter"

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
    ControlNumber := "EXO 2.9"
    Requirement := "The attachment filter SHOULD attempt to determine the true file type and assess the file extension"

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
    ControlNumber := "EXO 2.9"
    Requirement := "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked (e.g., .exe, .cmd, and .vbe)"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check"
}