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