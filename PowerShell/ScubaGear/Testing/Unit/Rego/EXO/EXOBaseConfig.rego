package exo_test
import rego.v1

RemoteDomains := {
    "AutoForwardEnabled": false,
    "DomainName": "Test name"
}
SpfRecords := {
    "rdata": [
        "v=spf1 -all"
    ],
    "domain": "Test name"
}
DkimConfig := {
    "Enabled": true,
    "Domain": "test.name"
}
DkimRecords := {
    "rdata": [
        "v=DKIM1;"
    ],
    "domain": "test.name"
}
DmarcRecords:= {
    "rdata": [
        "v=DMARC1; p=reject; pct=100; rua=mailto:DMARC@hq.dhs.gov, mailto:reports@dmarc.cyber.dhs.gov"
    ],
    "domain": "test.name"
}
TransportConfig:= {
    "SmtpClientAuthenticationDisabled": true,
    "Name": "A"
}
SharingPolicy:= {
    "Domains": [
        "domain1",
        "domain2"
    ],
    "Name": "A"
}
TransportRule:= {
    "FromScope": "NotInOrganization",
    "State": "Enabled",
    "Mode": "Enforce",
    "PrependSubject": "External"
}
ConnFilter:= {
    "IPAllowList": [],
    "EnableSafeList": false,
    "Name": "A"
}
OrgConfig:={
    "AuditDisabled": false,
    "Identity": "Test name",
    "Name": "A"
}