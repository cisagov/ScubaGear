package securitysuite_test
import rego.v1

ConnFilter:= {
    "IPAllowList": [],
    "EnableSafeList": false,
    "Name": "A"
}
    
AdminAuditLogConfig := {
    "Identity": "Admin Audit Log Settings",
    "UnifiedAuditLogIngestionEnabled": true
}

ScubaConfig := {
    "SecuritySuite": {
        "MS.SECURITYSUITE.2.1v1": {
            "SensitiveUsers": [
                "John Doe;jdoe@someemail.com",
                "Jane Doe;jadoe@someemail.com"
            ]
        },
        "MS.SECURITYSUITE.2.3v1": {
            "PartnerDomains": [
                "random.mail.example.com",
                "random.example.com"
            ]
        }
    }
}

AcceptedDomains := [
    {
        "DomainName": "example.com",
        "Name": "example.com"
    },
    {
        "DomainName": "example.mail.onmicrosoft.com",
        "Name": "example.mail.onmicrosoft.com"
    }
]

ProtectionPolicyRules := [
    {
        "Identity": "Standard Preset Security Policy",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null,
        "ExceptIfSentTo": null,
        "ExceptIfSentToMemberOf": null,
        "ExceptIfRecipientDomainIs": null
    },
    {
        "Identity": "Strict Preset Security Policy",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null,
        "ExceptIfSentTo": null,
        "ExceptIfSentToMemberOf": null,
        "ExceptIfRecipientDomainIs": null
    }
]

AntiPhishPolicies := [
    {
        "Identity": "Standard Preset Security Policy1659535429826",
        "Name": "Standard Preset Security Policy",
        "Enabled": true,
        "IsDefault": false,
        "EnableTargetedUserProtection": true,
        "TargetedUsersToProtect": [
            "John Doe;jdoe@someemail.com",
            "Jane Doe;jadoe@someemail.com"
        ],
        "TargetedUserProtectionAction": "Quarantine",
        "EnableTargetedDomainsProtection": true,
        "EnableOrganizationDomainsProtection": true,
        "TargetedDomainsToProtect": [
            "random.mail.example.com",
            "random.example.com"
        ],
        "TargetedDomainProtectionAction": "Quarantine"
    },
    {
        "Identity": "Strict Preset Security Policy1659535429826",
        "Name": "Strict Preset Security Policy",
        "Enabled": true,
        "IsDefault": false,
        "EnableTargetedUserProtection": true,
        "TargetedUsersToProtect": [
            "John Doe;jdoe@someemail.com",
            "Jane Doe;jadoe@someemail.com"
        ],
        "TargetedUserProtectionAction": "Quarantine",
        "EnableTargetedDomainsProtection": true,
        "EnableOrganizationDomainsProtection": true,
        "TargetedDomainsToProtect": [
            "random.mail.example.com",
            "random.example.com"
        ],
        "TargetedDomainProtectionAction": "Quarantine"
    }
]

SafetyTipsEnabled := {
    "EnableFirstContactSafetyTips": true,
    "EnableSimilarUsersSafetyTips": true,
    "EnableSimilarDomainsSafetyTips": true,
    "EnableUnusualCharactersSafetyTips": true,
    "EnableViaTag": true,
    "EnableUnauthenticatedSender": true,
}

DefaultAntiPhishPolicy := {
    "Identity": "Office365 AntiPhish Default",
    "Name": "Office365 AntiPhish Default",
    "Enabled": true,
    "IsDefault": true,
    "EnableTargetedUserProtection": true,
    "TargetedUsersToProtect": [
        "John Doe;jdoe@someemail.com",
        "Jane Doe;jadoe@someemail.com"
    ],
    "TargetedUserProtectionAction": "Quarantine",
    "EnableTargetedDomainsProtection": true,
    "EnableOrganizationDomainsProtection": true,
    "TargetedDomainsToProtect": [
        "random.mail.example.com",
        "random.example.com"
    ],
    "TargetedDomainProtectionAction": "Quarantine",
    "EnableFirstContactSafetyTips": SafetyTipsEnabled.EnableFirstContactSafetyTips,
    "EnableSimilarUsersSafetyTips": SafetyTipsEnabled.EnableSimilarUsersSafetyTips,
    "EnableSimilarDomainsSafetyTips": SafetyTipsEnabled.EnableSimilarDomainsSafetyTips,
    "EnableUnusualCharactersSafetyTips": SafetyTipsEnabled.EnableUnusualCharactersSafetyTips,
    "EnableViaTag": SafetyTipsEnabled.EnableViaTag,
    "EnableUnauthenticatedSender": SafetyTipsEnabled.EnableUnauthenticatedSender,
}

CustomAntiPhishPolicy := {
    "Identity": "Custom AntiPhish",
    "Name": "Custom AntiPhish",
    "Enabled": true,
    "IsDefault": false,
    "EnableTargetedUserProtection": true,
    "TargetedUsersToProtect": [
        "John Doe;jdoe@someemail.com",
        "Jane Doe;jadoe@someemail.com"
    ],
    "TargetedUserProtectionAction": "Quarantine",
    "EnableTargetedDomainsProtection": true,
    "EnableOrganizationDomainsProtection": true,
    "TargetedDomainsToProtect": [
        "random.mail.example.com",
        "random.example.com"
    ],
    "TargetedDomainProtectionAction": "Quarantine",
    "EnableFirstContactSafetyTips": SafetyTipsEnabled.EnableFirstContactSafetyTips,
    "EnableSimilarUsersSafetyTips": SafetyTipsEnabled.EnableSimilarUsersSafetyTips,
    "EnableSimilarDomainsSafetyTips": SafetyTipsEnabled.EnableSimilarDomainsSafetyTips,
    "EnableUnusualCharactersSafetyTips": SafetyTipsEnabled.EnableUnusualCharactersSafetyTips,
    "EnableViaTag": SafetyTipsEnabled.EnableViaTag,
    "EnableUnauthenticatedSender": SafetyTipsEnabled.EnableUnauthenticatedSender,
}

AntiPhishRules := [
    {
        "AntiPhishPolicy": "Custom AntiPhish",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": [
            "example.com",
            "example.mail.onmicrosoft.com"
        ],
        "ExceptIfSentTo": null,
        "ExceptIfSentToMemberOf": null,
        "ExceptIfRecipientDomainIs": null
    }
]

ProtectionAlerts := [
    {
        "Name": "Suspicious email sending patterns detected",
        "Disabled": false
    },
    {
        "Name": "Suspicious Email Forwarding Activity",
        "Disabled": false
    },
    {
        "Name": "Messages have been delayed",
        "Disabled": false
    },
    {
        "Name": "Tenant restricted from sending unprovisioned email",
        "Disabled": false
    },
    {
        "Name": "Tenant restricted from sending email",
        "Disabled": false
    },
    {
        "Name": "A potentially malicious URL click was detected",
        "Disabled": false
    },
    {
        "Name": "Suspicious connector activity",
        "Disabled": false
    }
]

