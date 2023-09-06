package exo
import future.keywords


#
# Policy 1
#--
test_3rdParty_Correct_V1 if {
    PolicyId := "MS.EXO.14.1v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "A custom product can be used to fulfill this policy requirement. Use a 3rd party assessment tool or manually review to ensure compliance. If you are using Defender for Office 365 to implement this policy, ensure that you are running ScubaGear with defender included in the ProductNames parameter for an automated check. Then, review the corresponding Defender for Office 365 policy that fulfills the requirements of this EXO policy."
}

#
# Policy 2
#--
test_3rdParty_Correct_V2 if {
    PolicyId := "MS.EXO.14.2v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "A custom product can be used to fulfill this policy requirement. Use a 3rd party assessment tool or manually review to ensure compliance. If you are using Defender for Office 365 to implement this policy, ensure that you are running ScubaGear with defender included in the ProductNames parameter for an automated check. Then, review the corresponding Defender for Office 365 policy that fulfills the requirements of this EXO policy."
}

#
# Policy 3
#--
test_3rdParty_Correct_V3 if {
    PolicyId := "MS.EXO.14.3v1"

    Output := tests with input as { }

    RuleOutput := [Result | Result = Output[_]; Result.PolicyId == PolicyId]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "A custom product can be used to fulfill this policy requirement. Use a 3rd party assessment tool or manually review to ensure compliance. If you are using Defender for Office 365 to implement this policy, ensure that you are running ScubaGear with defender included in the ProductNames parameter for an automated check. Then, review the corresponding Defender for Office 365 policy that fulfills the requirements of this EXO policy."
}