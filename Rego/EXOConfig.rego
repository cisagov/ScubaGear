package exo
import future.keywords
import data.report.utils.notCheckedDetails

Format(Array) = format_int(count(Array), 10)

Description(String1, String2, String3) = trim(concat(" ", [String1, concat(" ", [String2, String3])]), " ")

ReportDetailsBoolean(Status) = "Requirement met" if {Status == true}

ReportDetailsBoolean(Status) = "Requirement not met" if {Status == false}

ReportDetailsArray(Status, Array1, Array2) =  Detail if {
    Status == true
    Detail := "Requirement met"
}

ReportDetailsArray(Status, Array1, Array2) = Detail if {
	Status == false
    Fraction := concat(" of ", [Format(Array1), Format(Array2)])
	String := concat(", ", Array1)
    Detail := Description(Fraction, "agency domain(s) found in violation:", String)
}

ReportDetailsString(Status, String) =  Detail if {
    Status == true
    Detail := "Requirement met"
}

ReportDetailsString(Status, String) =  Detail if {
    Status == false
    Detail := String
}

AllDomains := {Domain.domain | Domain = input.spf_records[_]}

CustomDomains[Domain.domain] {
    Domain = input.spf_records[_]
    not endswith( Domain.domain, "onmicrosoft.com")
}


################
# Baseline 2.1 #
################

#
# Baseline 2.1: Policy 1
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


################
# Baseline 2.2 #
################

#
# Baseline 2.2: Policy 1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : notCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.EXO.2.1v1"
    true
}
#--

#
# Baseline 2.2: Policy 2
#--
DomainsWithoutSpf[DNSResponse.domain] {
    DNSResponse := input.spf_records[_]
    SpfRecords := {Record | Record = DNSResponse.rdata[_]; startswith(Record, "v=spf1 ")}
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


################
# Baseline 2.3 #
################

#
# Baseline 2.3: Policy 1
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
    "ReportDetails" : ReportDetailsArray(Status, DomainsWithoutDkim, CustomDomains),
    "RequirementMet" : Status
}] {
    DomainsWithoutDkim := CustomDomains - DomainsWithDkim
    Status := count(DomainsWithoutDkim) == 0
}
#--


################
# Baseline 2.4 #
################

#
# Baseline 2.4: Policy 1
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
# Baseline 2.4: Policy 2
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
# Baseline 2.4: Policy 3
#--
DomainsWithoutDHSContact[DmarcRecord.domain] {
    DmarcRecord := input.dmarc_records[_]
    ValidAnswers := [Answer | Answer := DmarcRecord.rdata[_]; contains(Answer, "mailto:reports@dmarc.cyber.dhs.gov")]
    count(ValidAnswers) == 0
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
# Baseline 2.4: Policy 4
#--
DomainsWithoutAgencyContact[DmarcRecord.domain] {
    DmarcRecord := input.dmarc_records[_]
    EnoughContacts := [Answer | Answer := DmarcRecord.rdata[_]; count(split(Answer, "@")) >= 3]
    count(EnoughContacts) == 0
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


################
# Baseline 2.5 #
################

#
# Baseline 2.5: Policy 1
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


################
# Baseline 2.6 #
################

# Are both the tests supposed to be the same?

#
# Baseline 2.6: Policy 1
#--

SharingPolicyAllowedSharing[SharingPolicy.Name] {
    SharingPolicy := input.sharing_policy[_]
    InList := "*" in SharingPolicy.Domains
    InList == true
}


tests[{
    "PolicyId" : "MS.EXO.6.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SharingPolicy"],
    "ActualValue" : input.sharing_policy,
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}] {
    ErrorMessage := "Wildcard domain (\"*\") in shared domains list, enabling sharing with all domains by default"

    Status := count(SharingPolicyAllowedSharing) == 0
}
#--

#
# Baseline 2.6: Policy 2
#--

tests[{
    "PolicyId" : "MS.EXO.6.2v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-SharingPolicy"],
    "ActualValue" : input.sharing_policy,
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}] {
    ErrorMessage := "Wildcard domain (\"*\") in shared domains list, enabling sharing with all domains by default"
    Status := count(SharingPolicyAllowedSharing) == 0
}
#--


################
# Baseline 2.7 #
################
#
# Baseline 2.7: Policy 1
#--
tests[{
    "PolicyId" : "MS.EXO.7.1v1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-TransportRule"],
    "ActualValue" : [Rule.FromScope | Rule = Rules[_]],
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}] {
    Rules := input.transport_rule
    ErrorMessage := "No transport rule found that applies warnings to emails received from outside the organization"
    EnabledRules := [rule | rule = Rules[_]; rule.State == "Enabled"; rule.Mode == "Enforce"]
    Conditions := [IsCorrectScope | IsCorrectScope = EnabledRules[_].FromScope == "NotInOrganization"]
    Status := count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}
#--


################
# Baseline 2.8 #
################

#
# Baseline 2.8: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.8.1v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.8: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.8.2v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--


################
# Baseline 2.9 #
################

#
# Baseline 2.9: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.9.1v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.9: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.9.2v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.9: Policy 3
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.9.3v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--


#################
# Baseline 2.10 #
#################

#
# Baseline 2.10: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.10.1v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.10: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.10.2v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.10: Policy 3
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.10.3v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--


#################
# Baseline 2.11 #
#################

#
# Baseline 2.11: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.11.1v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.11: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.11.2v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.11: Policy 3
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.11.3v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--


#################
# Baseline 2.12 #
#################

#
# Baseline 2.12: Policy 1
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
    ErrorMessage := "Allow-list is in use"
    Status := count(ConnFiltersWithIPAllowList) == 0
}
#--

#
# Baseline 2.12: Policy 2
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
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}]{
    Status := count(ConnFiltersWithSafeList) == 0
}
#--


#################
# Baseline 2.13 #
#################

#
# Baseline 2.13: Policy 1
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


#################
# Baseline 2.14 #
#################

#
# Baseline 2.14: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.14.1v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.14: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.14.2v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.14: Policy 3
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.14.3v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--


#################
# Baseline 2.15 #
#################

#
# Baseline 2.15: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.15.1v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.15: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.15.2v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.15: Policy 3
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.15.3v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--


#################
# Baseline 2.16 #
#################

#
# Baseline 2.16: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.16.1v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.16: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.16.2v1",
    "Criticality" : "Should/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--


#################
# Baseline 2.17 #
#################

#
# Baseline 2.17: Policy 1
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.17.1v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.17: Policy 2
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.17.2v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--

#
# Baseline 2.17: Policy 3
#--
# At this time we are unable to test because settings are configured in M365 Defender or using a third-party app
tests[{
    "PolicyId" : "MS.EXO.17.3v1",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--