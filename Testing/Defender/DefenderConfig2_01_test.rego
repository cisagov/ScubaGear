package defender
import future.keywords


#
# Policy 1
#--
test_Identity_Correct_V1 if {
    ControlNumber := "Defender 2.1"
    Requirement := "Standard Preset security profiles SHOULD NOT be used"

    Output := tests with input as {  
        "protection_policy_rules" : [] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Identity_Correct_V2 if {
    ControlNumber := "Defender 2.1"
    Requirement := "Standard Preset security profiles SHOULD NOT be used"

    Output := tests with input as {  
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Disabled"
            }
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Identity_Incorrect_V1 if {
    ControlNumber := "Defender 2.1"
    Requirement := "Standard Preset security profiles SHOULD NOT be used"

    Output := tests with input as {  
        "protection_policy_rules" : [
            {
                "Identity" : "Standard Preset Security Policy",
                "State" : "Enabled"
            }
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "The Standard Preset Security Policy is present and not disabled"
}

#
# Policy 2
#--
test_Identity_Correct_V1 if {
    ControlNumber := "Defender 2.1"
    Requirement := "Strict Preset security profiles SHOULD NOT be used"

    Output := tests with input as {  
        "protection_policy_rules" : [] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Identity_Correct_V2 if {
    ControlNumber := "Defender 2.1"
    Requirement := "Strict Preset security profiles SHOULD NOT be used"

    Output := tests with input as {  
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "State" : "Disabled"
            }
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_Identity_Incorrect_V2 if {
    ControlNumber := "Defender 2.1"
    Requirement := "Strict Preset security profiles SHOULD NOT be used"

    Output := tests with input as {  
        "protection_policy_rules" : [
            {
                "Identity" : "Strict Preset Security Policy",
                "State" : "Enabled"
            }
        ] 
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "The Strict Preset Security Policy is present and not disabled"
}