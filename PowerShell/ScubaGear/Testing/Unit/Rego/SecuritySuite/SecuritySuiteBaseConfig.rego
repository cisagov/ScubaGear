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
    "OutPath": ".",
    "OutRegoFileName": "TestResults",
    "SecuritySuite": {
    }
}

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
