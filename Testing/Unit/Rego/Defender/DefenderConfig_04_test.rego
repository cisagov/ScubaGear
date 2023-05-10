package defender
import future.keywords


#
# Policy 1
#--
test_ZapEnabled_Correct if {
    ControlNumber := "Defender 2.4"
    Requirement := "Zero-hour Auto Purge (ZAP) for malware SHOULD be enabled in the default anti-malware policy and in all existing custom policies"

    Output := tests with input as {
        "malware_filter_policies": [
            {
                "ZapEnabled" : true,
                "Name": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "Requirement met"
}

test_ZapEnabled_Incorrect if {
    ControlNumber := "Defender 2.4"
    Requirement := "Zero-hour Auto Purge (ZAP) for malware SHOULD be enabled in the default anti-malware policy and in all existing custom policies"

    Output := tests with input as {
        "malware_filter_policies": [
            {
                "ZapEnabled" : false,
                "Name": "Default"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 malware policy(ies) found without ZAP for malware enabled: Default"
}

test_ZapEnabledMultiple_Incorrect if {
    ControlNumber := "Defender 2.4"
    Requirement := "Zero-hour Auto Purge (ZAP) for malware SHOULD be enabled in the default anti-malware policy and in all existing custom policies"

    Output := tests with input as {
        "malware_filter_policies": [
            {
                "ZapEnabled" : true,
                "Name": "Default"
            },
            {
                "ZapEnabled" : false,
                "Name": "Custom 1"
            }
        ]
    }

    RuleOutput := [Result | Result = Output[_]; Result.Control == ControlNumber; Result.Requirement == Requirement]

    count(RuleOutput) == 1
    not RuleOutput[0].RequirementMet
    RuleOutput[0].ReportDetails == "1 malware policy(ies) found without ZAP for malware enabled: Custom 1"
}