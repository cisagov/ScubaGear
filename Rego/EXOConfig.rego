package exo
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.DefenderMirrorDetails
import data.report.utils.Format
import data.report.utils.ReportDetailsBoolean
import data.report.utils.Description
import data.report.utils.ReportDetailsString

ReportDetailsArray(Status, Array1, Array2) := Detail if {
    Status == true
    Detail := "Requirement met"
}

ReportDetailsArray(Status, Array1, Array2) := Detail if {
	Status == false
    Fraction := concat(" of ", [Format(Array1), Format(Array2)])
	String := concat(", ", Array1)
    Detail := Description(Fraction, "agency domain(s) found in violation:", String)
}

# this should be allowed https://github.com/StyraInc/regal/issues/415
# regal ignore:prefer-set-or-object-rule
AllDomains := {Domain.domain | Domain := input.spf_records[_]}

#
# MS.EXO.1.1v1
#--
RemoteDomainsAllowingForwarding[Domain.DomainName] {
    Domain := input.remote_domains[_]
    Domain.AutoForwardEnabled == true
}

tests[{
    "PolicyId" : "MS.EXO.1.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-RemoteDomain"],
    "ActualValue" : Domains,
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}] {
    Domains := RemoteDomainsAllowingForwarding
    ErrorMessage := Description(Format(Domains), "remote domain(s) that allows automatic forwarding:", concat(", ", Domains))
    Status := count(Domains) == 0
}
#--

#
# MS.EXO.2.1v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.2.1v1"
    true
}
#--

#
# MS.EXO.2.2v1
#--
DomainsWithoutSpf[DNSResponse.domain] {
    DNSResponse := input.spf_records[_]
    SpfRecords := {Record | Record := DNSResponse.rdata[_]; startswith(Record, "v=spf1 ")}
    count(SpfRecords) == 0
}

tests[{
    "PolicyId" : "MS.EXO.2.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-ScubaSpfRecords", "Get-AcceptedDomain"],
    "ActualValue" : Domains,
    "ReportDetails" : ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet" : Status
}] {
    Domains := DomainsWithoutSpf
    Status := count(Domains) == 0
}
#--

#
# MS.EXO.3.1v1
#--
DomainsWithDkim[DkimConfig.Domain] {
    DkimConfig := input.dkim_config[_]
    DkimConfig.Enabled == true
    DkimRecord := input.dkim_records[_]
    DkimRecord.domain == DkimConfig.Domain
    ValidAnswers := [Answer | Answer := DkimRecord.rdata[_]; startswith(Answer, "v=DKIM1;")]
    count(ValidAnswers) > 0
}

tests[{
    "PolicyId" : "MS.EXO.3.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DkimSigningConfig", "Get-ScubaDkimRecords", "Get-AcceptedDomain"],
    "ActualValue" : [input.dkim_records, input.dkim_config],
    "ReportDetails" : ReportDetailsArray(Status, DomainsWithoutDkim, AllDomains),
    "RequirementMet" : Status
}] {
    DomainsWithoutDkim := AllDomains - DomainsWithDkim
    Status := count(DomainsWithoutDkim) == 0
}
#--

#
# MS.EXO.4.1v1
#--
DomainsWithoutDmarc[DmarcRecord.domain] {
    DmarcRecord := input.dmarc_records[_]
    ValidAnswers := [Answer | Answer := DmarcRecord.rdata[_]; startswith(Answer, "v=DMARC1;")]
    count(ValidAnswers) == 0
}

tests[{
    "PolicyId" : "MS.EXO.4.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-ScubaDmarcRecords", "Get-AcceptedDomain"],
    "ActualValue" : input.dmarc_records,
    "ReportDetails" : ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet" : Status
}] {
    Domains := DomainsWithoutDmarc
    Status := count(Domains) == 0
}
#--

#
# MS.EXO.4.2v1
#--
DomainsWithoutPreject[DmarcRecord.domain] {
    DmarcRecord := input.dmarc_records[_]
    ValidAnswers := [Answer | Answer := DmarcRecord.rdata[_]; contains(Answer, "p=reject;")]
    count(ValidAnswers) == 0
}

tests[{
    "PolicyId" : "MS.EXO.4.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-ScubaDmarcRecords", "Get-AcceptedDomain"],
    "ActualValue" : input.dmarc_records,
    "ReportDetails" : ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet" : Status
}] {
    Domains := DomainsWithoutPreject
    Status := count(Domains) == 0
}
#--

#
# MS.EXO.4.3v1
#--
DomainsWithoutDHSContact[DmarcRecord.domain] {
    DmarcRecord := input.dmarc_records[_]
    Rdata := DmarcRecord.rdata[_]
    DmarcFields := split(Rdata, ";")
    RuaFields := [Rua | Rua := DmarcFields[_]; contains(Rua, "rua=")]
    ValidAnswers := [Answer | Answer := RuaFields[_]; contains(Answer, "mailto:reports@dmarc.cyber.dhs.gov")]
    count(ValidAnswers) == 0
}

DomainsWithoutDHSContact[DmarcRecord.domain] {
    DmarcRecord := input.dmarc_records[_]
    count(DmarcRecord.rdata) == 0 # failed dns query
}

tests[{
    "PolicyId" : "MS.EXO.4.3v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-ScubaDmarcRecords", "Get-AcceptedDomain"],
    "ActualValue" : input.dmarc_records,
    "ReportDetails" : ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet" : Status
}] {
    Domains := DomainsWithoutDHSContact
    Status := count(Domains) == 0
}
#--

#
# MS.EXO.4.4v1
#--
DomainsWithoutAgencyContact[DmarcRecord.domain] {
    DmarcRecord := input.dmarc_records[_]
    Rdata := DmarcRecord.rdata[_]
    DmarcFields := split(Rdata, ";")
    RuaFields := [Rua | Rua := DmarcFields[_]; contains(Rua, "rua=")]
    RufFields := [Ruf | Ruf := DmarcFields[_]; contains(Ruf, "ruf=")]
    # 2 or more emails including reports@dmarc.cyber.dhs.gov checked by policy 4.3
    RuaCountAcceptable := count([Answer | Answer := RuaFields[_]; count(split(Answer, "@")) > 2]) >= 1
    # 1 or more emails
    RufCountAcceptable := count([Answer | Answer := RufFields[_]; count(split(Answer, "@")) > 1]) >= 1
    Conditions := [RuaCountAcceptable, RufCountAcceptable]
    count([Condition | Condition := Conditions[_]; Condition == false]) > 0
}

DomainsWithoutAgencyContact[DmarcRecord.domain] {
    DmarcRecord := input.dmarc_records[_]
    count(DmarcRecord.rdata) == 0 # failed dns query
}

tests[{
    "PolicyId" : "MS.EXO.4.4v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-ScubaDmarcRecords", "Get-AcceptedDomain"],
    "ActualValue" : input.dmarc_records,
    "ReportDetails" : ReportDetailsArray(Status, Domains, AllDomains),
    "RequirementMet" : Status
}] {
    Domains := DomainsWithoutAgencyContact
    Status := count(Domains) == 0
}
#--

#
# MS.EXO.5.1v1
#--

SmtpClientAuthEnabled[TransportConfig.Name] {
    TransportConfig := input.transport_config[_]
    TransportConfig.SmtpClientAuthenticationDisabled == false
}

tests[{
    "PolicyId" : "MS.EXO.5.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-TransportConfig"],
    "ActualValue" : input.transport_config,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Status := count(SmtpClientAuthEnabled) == 0
}
#--

#
# MS.EXO.6.1v1
#--

SharingPolicyContactsAllowedAllDomains[SharingPolicy.Name] {
    SharingPolicy := input.sharing_policy[_]
    Domains := SharingPolicy.Domains[_]
    contains(Domains, "*")
    contains(Domains, "Contacts")
}

tests[{
    "PolicyId" : "MS.EXO.6.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SharingPolicy"],
    "ActualValue" : input.sharing_policy,
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}] {
    ContactsSharingPolicies := SharingPolicyContactsAllowedAllDomains
    ErrorMessage := Description(Format(ContactsSharingPolicies), "sharing polic(ies) are sharing contacts folders with all domains by default:", concat(", ", ContactsSharingPolicies))
    Status := count(ContactsSharingPolicies) == 0
}
#--

#
# MS.EXO.6.2v1
#--

SharingPolicyCalendarAllowedAllDomains[SharingPolicy.Name] {
    SharingPolicy := input.sharing_policy[_]
    Domains := SharingPolicy.Domains[_]
    contains(Domains, "*")
    contains(Domains, "Calendar")
}

tests[{
    "PolicyId" : "MS.EXO.6.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SharingPolicy"],
    "ActualValue" : input.sharing_policy,
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}] {
    CalendarSharingPolicies := SharingPolicyCalendarAllowedAllDomains
    ErrorMessage := Description(Format(CalendarSharingPolicies), "sharing polic(ies) are sharing calendar details with all domains by default:", concat(", ", CalendarSharingPolicies))
    Status := count(CalendarSharingPolicies) == 0
}
#--

#
# MS.EXO.7.1v1
#--
tests[{
    "PolicyId" : "MS.EXO.7.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-TransportRule"],
    "ActualValue" : [Rule.FromScope | Rule := Rules[_]],
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}] {
    Rules := input.transport_rule
    ErrorMessage := "No transport rule found that applies warnings to emails received from outside the organization"
    EnabledRules := [rule | rule := Rules[_]; rule.State == "Enabled"; rule.Mode == "Enforce"; count(rule.PrependSubject) >=1]
    Conditions := [IsCorrectScope | IsCorrectScope := EnabledRules[_].FromScope == "NotInOrganization"]
    Status := count([Condition | Condition := Conditions[_]; Condition == true]) > 0
}
#--

#
# MS.EXO.8.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.8.1v1"
    true
}
#--

#
# MS.EXO.8.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.8.2v1"
    true
}
#--

#
# MS.EXO.9.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.9.1v1"
    true
}
#--

#
# MS.EXO.9.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.9.2v1"
    true
}
#--

#
# MS.EXO.9.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.9.3v1"
    true
}
#--

#
# MS.EXO.10.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.10.1v1"
    true
}
#--

#
# MS.EXO.10.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.10.2v1"
    true
}
#--

#
# MS.EXO.10.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.10.3v1"
    true
}
#--

#
# MS.EXO.11.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.11.1v1"
    true
}
#--

#
# MS.EXO.11.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.11.2v1"
    true
}
#--

#
# MS.EXO.11.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.11.3v1"
    true
}
#--

#
# MS.EXO.12.1v1
#--

ConnFiltersWithIPAllowList[ConnFilter.Name] {
    ConnFilter := input.conn_filter[_]
    count(ConnFilter.IPAllowList) > 0
}

tests[{
    "PolicyId" : "MS.EXO.12.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedConnectionFilterPolicy"],
    "ActualValue" : input.conn_filter,
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}]{
    ConnFilterPolicies := ConnFiltersWithIPAllowList
    ErrorMessage := Description(Format(ConnFilterPolicies), "connection filter polic(ies) with an IP allowlist:", concat(", ", ConnFilterPolicies))
    Status := count(ConnFilterPolicies) == 0
}
#--

#
# MS.EXO.12.2v1
#--

ConnFiltersWithSafeList[ConnFilter.Name] {
    ConnFilter := input.conn_filter[_]
    ConnFilter.EnableSafeList == true
}

tests[{
    "PolicyId" : "MS.EXO.12.2v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-HostedConnectionFilterPolicy"],
    "ActualValue" : input.conn_filter,
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}]{
    ConnFilterPolicies := ConnFiltersWithSafeList
    ErrorMessage := Description(Format(ConnFilterPolicies), "connection filter polic(ies) with a safe list:", concat(", ", ConnFilterPolicies))
    Status := count(ConnFilterPolicies) == 0
}
#--

#
# MS.EXO.13.1v1
#--
AuditEnabled[OrgConfig.Name] {
    OrgConfig := input.org_config[_]
    OrgConfig.AuditDisabled == true
}

tests[{
    "PolicyId" : "MS.EXO.13.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-OrganizationConfig"],
    "ActualValue" : input.org_config,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    Status := count(AuditEnabled) == 0
}
#--

#
# MS.EXO.14.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.14.1v1"
    true
}
#--

#
# MS.EXO.14.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.14.2v1"
    true
}
#--

#
# MS.EXO.14.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.14.3v1"
    true
}
#--

#
# MS.EXO.15.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.15.1v1"
    true
}
#--

#
# MS.EXO.15.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.15.2v1"
    true
}
#--

#
# MS.EXO.15.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.15.3v1"
    true
}
#--

#
# MS.EXO.16.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.16.1v1"
    true
}
#--

#
# MS.EXO.16.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.16.2v1"
    true
}
#--

#
# MS.EXO.17.1v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.17.1v1"
    true

}
#--

#
# MS.EXO.17.2v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.17.2v1"
    true
}
#--

#
# MS.EXO.17.3v1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : DefenderMirrorDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.17.3v1"
    true
}
#--
