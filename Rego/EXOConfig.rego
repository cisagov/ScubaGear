package exo
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.DefenderMirrorDetails
import data.report.utils.Format
import data.report.utils.ReportDetailsBoolean
import data.report.utils.Description
import data.report.utils.ReportDetailsString

ReportDetailsArray(true, _, _) := ReportDetailsBoolean(true) if {}

ReportDetailsArray(false, Array1, Array2) := Description(Fraction, "agency domain(s) found in violation:", String) if {
    Fraction := concat(" of ", [Format(Array1), Format(Array2)])
    String := concat(", ", Array1)
}

FilterArray(Conditions, Boolean) := [Condition | some Condition in Conditions; Condition == Boolean]

# this should be allowed https://github.com/StyraInc/regal/issues/415
# regal ignore:prefer-set-or-object-rule
AllDomains := {Domain.domain | some Domain in input.spf_records}

#
# MS.EXO.1.1v1
#--
RemoteDomainsAllowingForwarding contains Domain.DomainName if {
    some Domain in input.remote_domains
    Domain.AutoForwardEnabled == true
}

tests contains {
    "PolicyId": "MS.EXO.1.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-RemoteDomain"],
    "ActualValue": Domains,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    Domains := RemoteDomainsAllowingForwarding
    ErrString := "remote domain(s) that allows automatic forwarding:"
    ErrMessage := Description(Format(Domains), ErrString , concat(", ", Domains))
    Status := count(Domains) == 0
}

#--

#
# MS.EXO.2.1v1
#--
# At this time we are unable to test for X because of Y
tests contains {
    "PolicyId": "MS.EXO.2.1v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.EXO.2.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.2.2v1
#--
DomainsWithoutSpf contains DNSResponse.domain if {
    some DNSResponse in input.spf_records
    SpfRecords := {Record | some Record in DNSResponse.rdata; startswith(Record, "v=spf1 ")}
    count(SpfRecords) == 0
}

tests contains {
    "PolicyId": "MS.EXO.2.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ScubaSpfRecords", "Get-AcceptedDomain"],
    "ActualValue": Domains,
    "ReportDetails": ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet": Status
} if {
    Domains := DomainsWithoutSpf
    Status := count(Domains) == 0
}

#--

#
# MS.EXO.3.1v1
#--
DomainsWithDkim contains DkimConfig.Domain if {
    some DkimConfig in input.dkim_config
    DkimConfig.Enabled == true
    some DkimRecord in input.dkim_records
    DkimRecord.domain == DkimConfig.Domain
    ValidAnswers := [Answer | some Answer in DkimRecord.rdata; startswith(Answer, "v=DKIM1;")]
    count(ValidAnswers) > 0
}

tests contains {
    "PolicyId": "MS.EXO.3.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DkimSigningConfig", "Get-ScubaDkimRecords", "Get-AcceptedDomain"],
    "ActualValue": [input.dkim_records, input.dkim_config],
    "ReportDetails": ReportDetailsArray(Status, DomainsWithoutDkim, AllDomains),
    "RequirementMet": Status
} if {
    DomainsWithoutDkim := AllDomains - DomainsWithDkim
    Status := count(DomainsWithoutDkim) == 0
}

#--

#
# MS.EXO.4.1v1
#--
DomainsWithoutDmarc contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    ValidAnswers := [Answer | some Answer in DmarcRecord.rdata; startswith(Answer, "v=DMARC1;")]
    count(ValidAnswers) == 0
}

tests contains {
    "PolicyId": "MS.EXO.4.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ScubaDmarcRecords", "Get-AcceptedDomain"],
    "ActualValue": input.dmarc_records,
    "ReportDetails": ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet": Status
} if {
    Domains := DomainsWithoutDmarc
    Status := count(Domains) == 0
}

#--

#
# MS.EXO.4.2v1
#--
DomainsWithoutPreject contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    ValidAnswers := [Answer | some Answer in DmarcRecord.rdata; contains(Answer, "p=reject;")]
    count(ValidAnswers) == 0
}

tests contains {
    "PolicyId": "MS.EXO.4.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ScubaDmarcRecords", "Get-AcceptedDomain"],
    "ActualValue": input.dmarc_records,
    "ReportDetails": ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet": Status
} if {
    Domains := DomainsWithoutPreject
    Status := count(Domains) == 0
}

#--

#
# MS.EXO.4.3v1
#--
DomainsWithoutDHSContact contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    some Rdata in DmarcRecord.rdata
    RuaFields := [Rua | some Rua in split(Rdata, ";"); contains(Rua, "rua=")]
    ValidAnswers := [Answer | some Answer in RuaFields; contains(Answer, "mailto:reports@dmarc.cyber.dhs.gov")]
    count(ValidAnswers) == 0
}

DomainsWithoutDHSContact contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    count(DmarcRecord.rdata) == 0 # failed dns query
}

tests contains {
    "PolicyId": "MS.EXO.4.3v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-ScubaDmarcRecords", "Get-AcceptedDomain"],
    "ActualValue": input.dmarc_records,
    "ReportDetails": ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet": Status
} if {
    Domains := DomainsWithoutDHSContact
    Status := count(Domains) == 0
}

#--

#
# MS.EXO.4.4v1
#--
DomainsWithoutAgencyContact contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    some Rdata in DmarcRecord.rdata
    DmarcFields := split(Rdata, ";")
    RuaFields := [Rua | some Rua in DmarcFields; contains(Rua, "rua=")]
    RufFields := [Ruf | some Ruf in DmarcFields; contains(Ruf, "ruf=")]

    # 2 or more emails including reports@dmarc.cyber.dhs.gov checked by policy 4.3
    RuaCountAcceptable := count([Answer | some Answer in RuaFields; count(split(Answer, "@")) > 2]) >= 1

    # 1 or more emails
    RufCountAcceptable := count([Answer | some Answer in RufFields; count(split(Answer, "@")) > 1]) >= 1
    Conditions := [
        RuaCountAcceptable,
        RufCountAcceptable
    ]
    count(FilterArray(Conditions, false)) > 0
}

DomainsWithoutAgencyContact contains DmarcRecord.domain if {
    some DmarcRecord in input.dmarc_records
    count(DmarcRecord.rdata) == 0 # failed dns query
}

tests contains {
    "PolicyId": "MS.EXO.4.4v1",
    "Criticality": "Should",
    "Commandlet": ["Get-ScubaDmarcRecords", "Get-AcceptedDomain"],
    "ActualValue": input.dmarc_records,
    "ReportDetails": ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet": Status
} if {
    Domains := DomainsWithoutAgencyContact
    Status := count(Domains) == 0
}

#--

#
# MS.EXO.5.1v1
#--

SmtpClientAuthEnabled contains TransportConfig.Name if {
    some TransportConfig in input.transport_config
    TransportConfig.SmtpClientAuthenticationDisabled == false
}

tests contains {
    "PolicyId": "MS.EXO.5.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-TransportConfig"],
    "ActualValue": input.transport_config,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Status := count(SmtpClientAuthEnabled) == 0
}

#--

#
# MS.EXO.6.1v1
#--

SharingPolicyContactsAllowedAllDomains contains SharingPolicy.Name if {
    some SharingPolicy in input.sharing_policy
    some Domains in SharingPolicy.Domains
    contains(Domains, "*")
    contains(Domains, "Contacts")
}

tests contains {
    "PolicyId": "MS.EXO.6.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SharingPolicy"],
    "ActualValue": input.sharing_policy,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    ContactsSharingPolicies := SharingPolicyContactsAllowedAllDomains
    ErrString := "sharing polic(ies) are sharing contacts folders with all domains by default:"
    ErrMessage := Description(Format(ContactsSharingPolicies), ErrString , concat(", ", ContactsSharingPolicies))
    Status := count(ContactsSharingPolicies) == 0
}

#--

#
# MS.EXO.6.2v1
#--

SharingPolicyCalendarAllowedAllDomains contains SharingPolicy.Name if {
    some SharingPolicy in input.sharing_policy
    some Domains in SharingPolicy.Domains
    contains(Domains, "*")
    contains(Domains, "Calendar")
}

tests contains {
    "PolicyId": "MS.EXO.6.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-SharingPolicy"],
    "ActualValue": input.sharing_policy,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    CalendarSharingPolicies := SharingPolicyCalendarAllowedAllDomains
    ErrString := "sharing polic(ies) are sharing calendar details with all domains by default:"
    ErrMessage := Description(Format(CalendarSharingPolicies), ErrString , concat(", ", CalendarSharingPolicies))
    Status := count(CalendarSharingPolicies) == 0
}

#--

#
# MS.EXO.7.1v1
#--
tests contains {
    "PolicyId": "MS.EXO.7.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-TransportRule"],
    "ActualValue": [Rule.FromScope | some Rule in Rules],
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    Rules := input.transport_rule
    ErrMessage := "No transport rule found that applies warnings to emails received from outside the organization"
    EnabledRules := [
        Rule | some Rule in Rules;
        Rule.State == "Enabled";
        Rule.Mode == "Enforce";
        count(Rule.PrependSubject) >= 1
    ]
    Conditions := [IsCorrectScope | IsCorrectScope := EnabledRules[_].FromScope == "NotInOrganization"]
    Status := count(FilterArray(Conditions, true)) > 0
}

#--

#
# MS.EXO.8.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.8.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.8.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.8.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.8.2v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.8.2v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.9.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.9.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.9.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.9.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.9.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.9.2v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.9.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.9.3v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.9.3v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.10.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.10.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.10.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.10.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.10.2v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.10.2v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.10.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.10.3v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.10.3v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.11.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.11.1v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.11.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.11.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.11.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.11.2v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.11.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.11.3v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.11.3v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.12.1v1
#--

ConnFiltersWithIPAllowList contains ConnFilter.Name if {
    some ConnFilter in input.conn_filter
    count(ConnFilter.IPAllowList) > 0
}

tests contains {
    "PolicyId": "MS.EXO.12.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-HostedConnectionFilterPolicy"],
    "ActualValue": input.conn_filter,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    ConnFilterPolicies := ConnFiltersWithIPAllowList
    ErrString := "connection filter polic(ies) with an IP allowlist:"
    ErrMessage := Description(Format(ConnFilterPolicies), ErrString , concat(", ", ConnFilterPolicies))
    Status := count(ConnFilterPolicies) == 0
}

#--

#
# MS.EXO.12.2v1
#--

ConnFiltersWithSafeList contains ConnFilter.Name if {
    some ConnFilter in input.conn_filter
    ConnFilter.EnableSafeList == true
}

tests contains {
    "PolicyId": "MS.EXO.12.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-HostedConnectionFilterPolicy"],
    "ActualValue": input.conn_filter,
    "ReportDetails": ReportDetailsString(Status, ErrMessage),
    "RequirementMet": Status
} if {
    ConnFilterPolicies := ConnFiltersWithSafeList
    ErrString := "connection filter polic(ies) with a safe list:"
    ErrMessage := Description(Format(ConnFilterPolicies), ErrString , concat(", ", ConnFilterPolicies))
    Status := count(ConnFilterPolicies) == 0
}

#--

#
# MS.EXO.13.1v1
#--
AuditEnabled contains OrgConfig.Name if {
    some OrgConfig in input.org_config
    OrgConfig.AuditDisabled == true
}

tests contains {
    "PolicyId": "MS.EXO.13.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-OrganizationConfig"],
    "ActualValue": input.org_config,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    Status := count(AuditEnabled) == 0
}

#--

#
# MS.EXO.14.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.14.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.14.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.14.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.14.2v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.14.2v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.14.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.14.3v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.14.3v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.15.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.15.1v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.15.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.15.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.15.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.15.2v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.15.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.15.3v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.15.3v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.16.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.16.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.16.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.16.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.16.2v1",
    "Criticality": "Should/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.16.2v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.17.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.17.1v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.17.1v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.17.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.17.2v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.17.2v1"),
    "RequirementMet": false
}

#--

#
# MS.EXO.17.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests contains {
    "PolicyId": "MS.EXO.17.3v1",
    "Criticality": "Shall/3rd Party",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": DefenderMirrorDetails("MS.EXO.17.3v1"),
    "RequirementMet": false
}

#--
