package exo
import future.keywords

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
    "Requirement" : "Automatic forwarding to external domains SHALL be disabled",
    "Control" : "EXO 2.1",
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
    "Requirement" : "A list of approved IP addresses for sending mail SHALL be maintained",
    "Control" : "EXO 2.2",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Exchange Online Secure Configuration Baseline policy 2.# for instructions on manual check",
    "RequirementMet" : false
}] {
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
    "Requirement" : "An SPF policy(s) that designates only these addresses as approved senders SHALL be published",
    "Control" : "EXO 2.2",
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
    startswith(DkimRecord.rdata, "v=DKIM1;")
}

tests[{
    "Requirement" : "DKIM SHOULD be enabled for any custom domain",
    "Control" : "EXO 2.3",
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
    not startswith(DmarcRecord.rdata, "v=DMARC1;")
}

tests[{
    "Requirement" : "A DMARC policy SHALL be published for every second-level domain",
    "Control" : "EXO 2.4",
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
    not contains(DmarcRecord.rdata, "p=reject;")
}

tests[{
    "Requirement" : "The DMARC message rejection option SHALL be \"p=reject\"",
    "Control" : "EXO 2.4",
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
    not contains(DmarcRecord.rdata, "mailto:reports@dmarc.cyber.dhs.gov")
}

tests[{
    "Requirement" : "The DMARC point of contact for aggregate reports SHALL include reports@dmarc.cyber.dhs.gov",
    "Control" : "EXO 2.4",
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
    count(split(DmarcRecord.rdata, "@")) < 3
}

tests[{
    "Requirement" : "An agency point of contact SHOULD be included for aggregate and/or failure reports",
    "Control" : "EXO 2.4",
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
    "Requirement" : "SMTP AUTH SHALL be disabled in Exchange Online",
    "Control" : "EXO 2.5",
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
    "Requirement" : "Contact folders SHALL NOT be shared with all domains, although they MAY be shared with specific domains",
    "Control" : "EXO 2.6",
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
    "Requirement" : "Calendar details SHALL NOT be shared with all domains, although they MAY be shared with specific domains",
    "Control" : "EXO 2.6",
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
    "Requirement" : "External sender warnings SHALL be implemented",
    "Control" : "EXO 2.7",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-TransportRule"],
    "ActualValue" : [Rule.FromScope | Rule = Rules[_]],
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}] {
    Rules := input.transport_rule
    ErrorMessage := "No transport rule found with that applies to emails received from outside the organization"
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
    "Requirement" : "A DLP solution SHALL be used. The selected DLP solution SHOULD offer services comparable to the native DLP solution offered by Microsoft",
    "Control" : "EXO 2.8",
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
    "Requirement" : "The DLP solution SHALL protect PII and sensitive information, as defined by the agency. At a minimum, the sharing of credit card numbers, Taxpayer Identification Numbers (TIN), and Social Security Numbers (SSN) via email SHALL be restricted",
    "Control" : "EXO 2.8",
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
    "Requirement" : "Emails SHALL be filtered by the file types of included attachments. The selected filtering solution SHOULD offer services comparable to Microsoft Defender's Common Attachment Filter",
    "Control" : "EXO 2.9",
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
    "Requirement" : "The attachment filter SHOULD attempt to determine the true file type and assess the file extension",
    "Control" : "EXO 2.9",
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
    "Requirement" : "Disallowed file types SHALL be determined and set. At a minimum, click-to-run files SHOULD be blocked (e.g., .exe, .cmd, and .vbe)",
    "Control" : "EXO 2.9",
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
    "Requirement" : "Emails SHALL be scanned for malware",
    "Control" : "EXO 2.10",
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
    "Requirement" : "Emails identified as containing malware SHALL be quarantined or dropped",
    "Control" : "EXO 2.10",
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
    "Requirement" : "Email scanning SHOULD be capable of reviewing emails after delivery",
    "Control" : "EXO 2.10",
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
    "Requirement" : "Impersonation protection checks SHOULD be used",
    "Control" : "EXO 2.11",
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
    "Requirement" : "User warnings, comparable to the user safety tips included with EOP, SHOULD be displayed",
    "Control" : "EXO 2.11",
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
    "Requirement" : "The phishing protection solution SHOULD include an AI-based phishing detection tool comparable to EOP Mailbox Intelligence",
    "Control" : "EXO 2.11",
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
    "Requirement" : "IP allow lists SHOULD NOT be created",
    "Control" : "EXO 2.12",
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
    "Requirement" : "Safe lists SHOULD NOT be enabled",
    "Control" : "EXO 2.12",
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
    "Requirement" : "Mailbox auditing SHALL be enabled",
    "Control" : "EXO 2.13",
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
    "Requirement" : "A spam filter SHALL be enabled. The filtering solution selected SHOULD offer services comparable to the native spam filtering offered by Microsoft",
    "Control" : "EXO 2.14",
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
    "Requirement" : "Spam and high confidence spam SHALL be moved to either the junk email folder or the quarantine folder",
    "Control" : "EXO 2.14",
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
    "Requirement" : "Allowed senders MAY be added, but allowed domains SHALL NOT be added",
    "Control" : "EXO 2.14",
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
    "Requirement" : "URL comparison with a block-list SHOULD be enabled",
    "Control" : "EXO 2.15",
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
    "Requirement" : "Direct download links SHOULD be scanned for malware",
    "Control" : "EXO 2.15",
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
    "Requirement" : "User click tracking SHOULD be enabled",
    "Control" : "EXO 2.15",
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
    "Requirement" : "At a minimum, the following alerts SHALL be enabled...[see Exchange Online secure baseline for list]",
    "Control" : "EXO 2.16",
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
    "Requirement" : "The alerts SHOULD be sent to a monitored address or incorporated into a SIEM",
    "Control" : "EXO 2.16",
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
    "Requirement" : "Unified audit logging SHALL be enabled",
    "Control" : "EXO 2.17",
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
    "Requirement" : "Advanced audit SHALL be enabled",
    "Control" : "EXO 2.17",
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
    "Requirement" : "Audit logs SHALL be maintained for at least the minimum duration dictated by OMB M-21-31",
    "Control" : "EXO 2.17",
    "Criticality" : "Shall/3rd Party",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Custom implementation allowed. If you are using Defender to fulfill this requirement, run the Defender version of this script. Otherwise, use a 3rd party tool OR manually check",
    "RequirementMet" : false
}] {
    true
}
#--