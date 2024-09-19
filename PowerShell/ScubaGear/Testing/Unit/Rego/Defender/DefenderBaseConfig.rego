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
        "Exceptions": null,
        "State": "Enabled"
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
        "Exceptions": null,
        "State": "Enabled"
    }
]

AtpPolicyRules := [
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

ScubaConfig := {
    "OutPath": ".",
    "OutRegoFileName": "TestResults",
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
        },
        "MS.DEFENDER.1.5v1": {
            "SensitiveAccounts": {
                "IncludedUsers": [],
                "IncludedGroups": [],
                "IncludedDomains": [],
                "ExcludedUsers": [],
                "ExcludedGroups": [],
                "ExcludedDomains": []
            }
        },
        "MS.DEFENDER.2.1v1": {
            "SensitiveUsers": [
                "John Doe;jdoe@someemail.com",
                "Jane Doe;jadoe@someemail.com"
            ]
        },
        "MS.DEFENDER.2.2v1": {
            "AgencyDomains": [
                "random.mail.example.com",
                "random.example.com"
            ]
        },
        "MS.DEFENDER.2.3v1": {
            "PartnerDomains": [
                "random.mail.example.com",
                "random.example.com"
            ]
        }
    }
}

AntiPhishPolicies := [
    {
        "Identity": "Standard Preset Security Policy1659535429826",
        "Enabled": true,
        "EnableTargetedUserProtection": true,
        "TargetedUsersToProtect": [
            "John Doe;jdoe@someemail.com",
            "Jane Doe;jadoe@someemail.com"
        ],
        "TargetedUserProtectionAction": "Quarantine",
        "EnableTargetedDomainsProtection": true,
        "TargetedDomainsToProtect": [
            "random.mail.example.com",
            "random.example.com"
        ],
        "TargetedDomainProtectionAction": "Quarantine"
    },
    {
        "Identity": "Strict Preset Security Policy1659535429826",
        "Enabled": true,
        "EnableTargetedUserProtection": true,
        "TargetedUsersToProtect": [
            "John Doe;jdoe@someemail.com",
            "Jane Doe;jadoe@someemail.com"
        ],
        "TargetedUserProtectionAction": "Quarantine",
        "EnableTargetedDomainsProtection": true,
        "TargetedDomainsToProtect": [
            "random.mail.example.com",
            "random.example.com"
        ],
        "TargetedDomainProtectionAction": "Quarantine"
    }
]

AtpPolicyForO365 := {
    "EnableATPForSPOTeamsODB": true,
    "Identity": "Default"
}

ProtectionAlerts := [
    {
        "Name": "Suspicious email sending patterns detected",
        "Disabled": false
    },
    {
        "Name": "Unusual increase in email reported as phish",
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
        "Name": "User restricted from sending email",
        "Disabled": false
    },
    {
        "Name": "Malware campaign detected after delivery",
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

AdminAuditLogConfig := {
    "Identity": "Admin Audit Log Settings",
    "UnifiedAuditLogIngestionEnabled": true
}

DlpComplianceRules := {
    "ContentContainsSensitiveInformation": [
        {"name": "U.S. Social Security Number (SSN)"},
        {"name": "U.S. Individual Taxpayer Identification Number (ITIN)"},
        {"name": "Credit Card Number"}
    ],
    "Name": "Baseline Rule",
    "Disabled": false,
    "ParentPolicyName": "Default Office 365 DLP policy",
    "BlockAccess": true,
    "BlockAccessScope": "All",
    "NotifyUser": [
        "SiteAdmin",
        "LastModifier",
        "Owner"
    ],
    "NotifyUserType": "NotSet",
    "IsAdvancedRule": false
}

DlpCompliancePolicies := {
    "ExchangeLocation": ["All"],
    "SharePointLocation": ["All"],
    "TeamsLocation": ["All"],
    "EndpointDlpLocation": ["All"],
    "OneDriveLocation": ["All"],
    "Workload": "Exchange, SharePoint, OneDriveForBusiness, Teams, EndpointDevices",
    "Name": "Default Office 365 DLP policy",
    "Mode": "Enable",
    "Enabled": true
}