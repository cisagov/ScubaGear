package defender_test
import rego.v1

ProtectionPolicyRules := [
    {
        "Identity": "Standard Preset Security Policy",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null,
        "ExceptIfSentTo": null,
        "ExceptIfSentToMemberOf": null,
        "ExceptIfRecipientDomainIs": null,
        "Conditions": null,
        "Exceptions": null
    },
    {
        "Identity": "Strict Preset Security Policy",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null,
        "ExceptIfSentTo": null,
        "ExceptIfSentToMemberOf": null,
        "ExceptIfRecipientDomainIs": null,
        "Conditions": null,
        "Exceptions": null
    }
]

AtpPolicyRules := [
    {
        "Identity": "Standard Preset Security Policy",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null
    },
    {
        "Identity": "Strict Preset Security Policy",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null
    }
]

ScubaConfig := {
    "Defender": {
        "MS.DEFENDER.1.4v1": {
            "SensitiveAccounts": {
                "IncludedUsers": [],
                "IncludedGroups": [],
                "IncludedDomains": [],
                "ExcludedUsers": [],
                "ExcludedGroups": [],
                "ExcludedDomains": []
            }
        }
    }
}