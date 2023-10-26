package teams
import future.keywords

#--
# Policy MS.TEAMS.7.1v1
#--
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.TEAMS.7.1v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of ScubaGear. Otherwise, use a 3rd party tool OR manually check"
}

#--
# Policy MS.TEAMS.7.2v1
#--
test_3rdParty_Correct_V2 if {
    PolicyId := "MS.TEAMS.7.2v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of ScubaGear. Otherwise, use a 3rd party tool OR manually check"
}