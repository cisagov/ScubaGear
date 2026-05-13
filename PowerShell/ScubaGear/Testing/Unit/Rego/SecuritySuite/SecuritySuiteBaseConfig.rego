package securitysuite_test
import rego.v1



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

