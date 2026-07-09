package securitysuite_test
import rego.v1
import data.securitysuite
import data.utils.key.TestResult
import data.utils.key.PASS

DefaultAntiMalwarePolicy := {
    "Identity": "Default",
    "EnableFileFilter": false,
    "FileTypes": [],
    "ZapEnabled": false,
}

StandardAntiMalwarePolicy := {
    "Identity": "Standard Preset Security Policy",
    "EnableFileFilter": true,
    "FileTypes": ["exe", "cmd", "vbe"],
    "ZapEnabled": true,
}

StandardProtectionPolicyRule := {
    "Identity": "Standard Preset Security Policy",
    "State": "Enabled",
    "SentTo": null,
    "SentToMemberOf": null,
    "RecipientDomainIs": null,
}

CustomAntiMalwareRule := {
    "State": "Enabled",
    "Priority": 0,
    "MalwareFilterPolicy": "FunctionalTest MalwarePolicy",
    "SentTo": null,
    "SentToMemberOf": null,
    "ExceptIfSentTo": null,
    "ExceptIfSentToMemberOf": null,
    "ExceptIfRecipientDomainIs": null,
    "RecipientDomainIs": ["contoso.com"],
}

NonCompliantCustomAntiMalwarePolicy := {
    "Identity": "FunctionalTest MalwarePolicy",
    "EnableFileFilter": true,
    "FileTypes": ["cmd", "vbe"],
    "ZapEnabled": true,
}

#
# Policy MS.SECURITYSUITE.1.1v1
#--
test_BlockClickToRun_DefaultFilterDisabled if {
    Output := securitysuite.tests
        with input.defender_license as true
        with input.protection_policy_rules as []
        with input.anti_malware_rules as []
        with input.anti_malware_policies as [DefaultAntiMalwarePolicy]
        with input.accepted_domains as AcceptedDomains

    ReportDetailString := concat("", [
        "Requirement not met. The highest priority anti-malware policy that applies to all users is the ",
        "default policy. The common attachments filter is disabled.",
    ])
    TestResult("MS.SECURITYSUITE.1.1v1", Output, ReportDetailString, false) == true
}

test_BlockClickToRun_DefaultMissingFileTypes if {
    Policy := object.union(DefaultAntiMalwarePolicy, {
        "EnableFileFilter": true,
        "FileTypes": ["cmd", "vbe"],
        "ZapEnabled": true,
    })
    Output := securitysuite.tests
        with input.defender_license as true
        with input.protection_policy_rules as []
        with input.anti_malware_rules as []
        with input.anti_malware_policies as [Policy]
        with input.accepted_domains as AcceptedDomains

    ReportDetailString := concat("", [
        "Requirement not met. The highest priority anti-malware policy that applies to all users is the ",
        "default policy. The common attachments filter does not include exe.",
    ])
    TestResult("MS.SECURITYSUITE.1.1v1", Output, ReportDetailString, false) == true
}

test_BlockClickToRun_StandardPresetCompliant if {
    Output := securitysuite.tests
        with input.defender_license as true
        with input.protection_policy_rules as [StandardProtectionPolicyRule]
        with input.anti_malware_rules as []
        with input.anti_malware_policies as [StandardAntiMalwarePolicy]
        with input.accepted_domains as AcceptedDomains

    TestResult("MS.SECURITYSUITE.1.1v1", Output, PASS, true) == true
}

test_BlockClickToRun_CustomPolicyNonCompliant if {
    Output := securitysuite.tests
        with input.defender_license as true
        with input.protection_policy_rules as []
        with input.anti_malware_rules as [CustomAntiMalwareRule]
        with input.anti_malware_policies as [NonCompliantCustomAntiMalwarePolicy]
        with input.accepted_domains as [{"DomainName": "contoso.com"}]

    ReportDetailString := concat("", [
        "Requirement not met. The highest priority anti-malware policy that applies to all users is the ",
        "FunctionalTest MalwarePolicy policy. The common attachments filter does not include exe.",
    ])
    TestResult("MS.SECURITYSUITE.1.1v1", Output, ReportDetailString, false) == true
}

test_BlockClickToRun_ReportDetailsIsString if {
    Output := securitysuite.tests
        with input.defender_license as true
        with input.protection_policy_rules as []
        with input.anti_malware_rules as []
        with input.anti_malware_policies as [DefaultAntiMalwarePolicy]
        with input.accepted_domains as AcceptedDomains

    some Result in Output
    Result.PolicyId == "MS.SECURITYSUITE.1.1v1"
    is_string(Result.ReportDetails)
}
#--
