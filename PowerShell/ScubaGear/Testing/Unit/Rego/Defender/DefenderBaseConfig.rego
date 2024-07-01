package defender_test
import rego.v1

ProtectionPolicyRules := [
    {
        "Identity": "Standard Preset Security Policy",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null
    },
    {
        "Identity": "Strict Preset Security Policy",
        "State": "Enabled"
    }
]

AtpPolicyRules := [
    {
        "Identity": "Standard Preset Security Policy",
        "State": "Enabled"
    },
    {
        "Identity": "Strict Preset Security Policy",
        "State": "Enabled"
    }
]