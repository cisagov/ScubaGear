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

# Compliant: 12 month (1 year) retention, enabled
UnifiedAuditLogRetentionPolicy := {
    "Name": "12 month retention",
    "RetentionDuration": "TwelveMonths",
    "Enabled": true
}

# Compliant: 3 year retention, enabled
ThreeYearRetentionPolicy := {
    "Name": "3 year retention",
    "RetentionDuration": "ThreeYears",
    "Enabled": true
}

# Compliant: 5 year retention, enabled
FiveYearRetentionPolicy := {
    "Name": "5 year retention",
    "RetentionDuration": "FiveYears",
    "Enabled": true
}

# Compliant: 7 year retention, enabled
SevenYearRetentionPolicy := {
    "Name": "7 year retention",
    "RetentionDuration": "SevenYears",
    "Enabled": true
}

# Compliant: 10 year retention, enabled
TenYearRetentionPolicy := {
    "Name": "10 year retention",
    "RetentionDuration": "TenYears",
    "Enabled": true
}

# Non-compliant: 7 day retention (Purview portal "7 Days" option)
SevenDayRetentionPolicy := {
    "Name": "Seven day retention",
    "RetentionDuration": "SevenDays",
    "Enabled": true
}

# Non-compliant: 30 day (1 month) retention (Purview portal "30 Days" option)
OneMonthRetentionPolicy := {
    "Name": "One month retention",
    "RetentionDuration": "OneMonth",
    "Enabled": true
}

# Non-compliant: 90 day (3 month) retention (Purview portal "90 Days" option)
ThreeMonthRetentionPolicy := {
    "Name": "Three month retention",
    "RetentionDuration": "ThreeMonths",
    "Enabled": true
}

# Non-compliant: 6 month retention
SixMonthRetentionPolicy := {
    "Name": "Six month retention",
    "RetentionDuration": "SixMonths",
    "Enabled": true
}

# Non-compliant: 9 month retention
NineMonthRetentionPolicy := {
    "Name": "Nine month retention",
    "RetentionDuration": "NineMonths",
    "Enabled": true
}

# Non-compliant: 12 month retention but disabled
DisabledRetentionPolicy := {
    "Name": "12 month retention",
    "RetentionDuration": "TwelveMonths",
    "Enabled": false
}

# E5-level service plans, includes the advanced auditing plan required to
# retain audit logs beyond 180 days (E5 / E5 Compliance / E5 eDiscovery and Audit)
ServicePlansWithAdvancedAuditing := [
    {
        "ServicePlanName": "M365_ADVANCED_AUDITING",
        "ServicePlanId": "2f442157-a11c-46b9-ae5b-6e39ff4e5849",
        "ProvisioningStatus": "Success"
    },
    {
        "ServicePlanName": "EXCHANGE_S_ENTERPRISE",
        "ServicePlanId": "efb87545-963c-4e0d-99df-69c6916d9eb0",
        "ProvisioningStatus": "Success"
    }
]

# E3/G3-level service plans, does not include the advanced auditing plan
ServicePlansWithoutAdvancedAuditing := [
    {
        "ServicePlanName": "EXCHANGE_S_ENTERPRISE",
        "ServicePlanId": "efb87545-963c-4e0d-99df-69c6916d9eb0",
        "ProvisioningStatus": "Success"
    }
]

ScubaConfig := {
    "OutRegoFileName": "TestResults",
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

SafeLinksPolicies := [
    {
        "EnableSafeLinksForEmail":  true,
        "EnableSafeLinksForTeams":  true,
        "EnableSafeLinksForOffice":  true,
        "EnableForInternalSenders":  true,
        "ScanUrls":  true,
        "DeliverMessageAfterScan":  true,
        "TrackClicks":  true,
        "Identity":  "Compliant Custom Policy"
    },
    {
        "EnableSafeLinksForEmail":  false,
        "EnableSafeLinksForTeams":  false,
        "EnableSafeLinksForOffice":  false,
        "EnableForInternalSenders":  false,
        "ScanUrls":  false,
        "DeliverMessageAfterScan":  false,
        "TrackClicks":  false,
        "Identity":  "Non-Compliant Custom Policy"
    },
    {
        "EnableSafeLinksForEmail":  true,
        "EnableSafeLinksForTeams":  true,
        "EnableSafeLinksForOffice":  true,
        "EnableForInternalSenders":  false,
        "ScanUrls":  true,
        "DeliverMessageAfterScan":  true,
        "TrackClicks":  true,
        "Identity":  "Built-In Protection Policy"
    }]

SafeLinksRules := [
    {
        "SafeLinksPolicy":  "Compliant Custom Policy",
        "State":  "Enabled",
        "Priority":  0,
        "Identity":  "Compliant Custom Policy",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null
    },
    {
        "SafeLinksPolicy":  "Non-Compliant Custom Policy",
        "State":  "Enabled",
        "Priority":  1,
        "Identity":  "Non-Compliant Custom Policy",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null
    }]

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

DefaultPolicy := {
    "Identity": "Default",
    "IsDefault": true,
    "RecommendedPolicyType": "Custom",
    "SpamAction": "MoveToJmf",
    "HighConfidenceSpamAction": "MoveToJmf",
    "PhishSpamAction": "Quarantine",
    "HighConfidencePhishAction": "Quarantine",
    "AllowedSenderDomains": []
}

StandardPresetPolicy := {
    "Identity": "Standard Preset Security Policy1659535429826",
    "IsDefault": false,
    "RecommendedPolicyType": "Standard",
    "SpamAction": "MoveToJmf",
    "HighConfidenceSpamAction": "MoveToJmf",
    "PhishSpamAction": "Quarantine",
    "HighConfidencePhishAction": "Quarantine",
    "AllowedSenderDomains": []
}

StrictPresetPolicy := {
    "Identity": "Strict Preset Security Policy1659535429827",
    "IsDefault": false,
    "RecommendedPolicyType": "Strict",
    "SpamAction": "Quarantine",
    "HighConfidenceSpamAction": "Quarantine",
    "PhishSpamAction": "Quarantine",
    "HighConfidencePhishAction": "Quarantine",
    "AllowedSenderDomains": []
}

CustomPolicy := {
    "Identity": "Custom Policy A",
    "IsDefault": false,
    "RecommendedPolicyType": "Custom",
    "SpamAction": "MoveToJmf",
    "HighConfidenceSpamAction": "Quarantine",
    "PhishSpamAction": "Quarantine",
    "HighConfidencePhishAction": "Quarantine",
    "AllowedSenderDomains": []
}

# EOP preset rules with both Standard and Strict enabled, scoped to all recipients
ProtectionPolicyRulesEnabled := [
    {
        "Identity": "Standard Preset Security Policy",
        "HostedContentFilterPolicy": "Standard Preset Security Policy1659535429826",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null
    },
    {
        "Identity": "Strict Preset Security Policy",
        "HostedContentFilterPolicy": "Strict Preset Security Policy1659535429827",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null
    }
]

# Custom policy rule - enabled, scoped to all recipients (all accepted domains)
CustomPolicyRuleEnabled := [
    {
        "Identity": "Custom Policy A Rule",
        "HostedContentFilterPolicy": "Custom Policy A",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": ["example.com", "example.mail.onmicrosoft.com"],
        "ExceptIfSentTo": null,
        "ExceptIfSentToMemberOf": null,
        "ExceptIfRecipientDomainIs": null
    }
]

# Custom policy rule - disabled
CustomPolicyRuleDisabled := [
    {
        "Identity": "Custom Policy A Rule",
        "HostedContentFilterPolicy": "Custom Policy A",
        "State": "Disabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": ["example.com", "example.mail.onmicrosoft.com"],
        "ExceptIfSentTo": null,
        "ExceptIfSentToMemberOf": null,
        "ExceptIfRecipientDomainIs": null
    }
]

# Custom policy rule - enabled but scoped to a single recipient (does not cover all recipients)
CustomPolicyRulePartialRecipients := [
    {
        "Identity": "Custom Policy A Rule",
        "HostedContentFilterPolicy": "Custom Policy A",
        "State": "Enabled",
        "SentTo": ["onlyme@example.com"],
        "SentToMemberOf": null,
        "RecipientDomainIs": null,
        "ExceptIfSentTo": null,
        "ExceptIfSentToMemberOf": null,
        "ExceptIfRecipientDomainIs": null
    }
]

# EOP preset rule for Strict, enabled but scoped to a single recipient (does not cover all recipients)
ProtectionPolicyRulesStrictPartialRecipients := [
    {
        "Identity": "Standard Preset Security Policy",
        "HostedContentFilterPolicy": "Standard Preset Security Policy1659535429826",
        "State": "Enabled",
        "SentTo": null,
        "SentToMemberOf": null,
        "RecipientDomainIs": null
    },
    {
        "Identity": "Strict Preset Security Policy",
        "HostedContentFilterPolicy": "Strict Preset Security Policy1659535429827",
        "State": "Enabled",
        "SentTo": ["onlyme@example.com"],
        "SentToMemberOf": null,
        "RecipientDomainIs": null
    }
]

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
