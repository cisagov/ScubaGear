package powerplatform
import future.keywords


Format(Array) = format_int(count(Array), 10)

Description(String1, String2, String3) = trim(concat(" ", [String1, concat(" ", [String2, String3])]), " ")

ReportDetailsBoolean(Status) = "Requirement met" if {Status == true}

ReportDetailsBoolean(Status) = "Requirement not met" if {Status == false}

ReportDetailsArray(Status, Array, String1) =  Detail if {
    Status == true
    Detail := "Requirement met"
}

ReportDetailsArray(Status, Array, String1) = Detail if {
	Status == false
    String2 := concat(", ", Array)
    Detail := Description(Format(Array), String1, String2)
}
ReportDetailsString(Status, String) =  Detail if {
    Status == true
    Detail := "Requirement met"
}

ReportDetailsString(Status, String) = Detail if {
	Status == false
    Detail := String
}


################
# Baseline 2.1 #
################

#
# Baseline 2.1: Policy 1
#--
tests[{
    "Requirement" : "The ability to create production and sandbox environments SHALL be restricted to admins",
    "Control" : "Power Platform 2.1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-TenantSettings"],
    "ActualValue" : EnvironmentCreation.disableEnvironmentCreationByNonAdminUsers,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    EnvironmentCreation := input.environment_creation[_]
    Status := EnvironmentCreation.disableEnvironmentCreationByNonAdminUsers == true
}
#--

# Baseline 2.1: Policy 1 PoSh Error
#--
tests[{
    "Requirement" : "The ability to create production and sandbox environments SHALL be restricted to admins",
    "Control" : "Power Platform 2.1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-TenantSettings"],
    "ActualValue" : "PowerShell Error",
    "ReportDetails" : "PowerShell Error",
    "RequirementMet" : false
}] {
    count(input.environment_creation) <= 0
}
#--

#
# Baseline 2.1: Policy 2 
#--
tests[{
    "Requirement" : "The ability to create trial environments SHALL be restricted to admins",
    "Control" : "Power Platform 2.1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-TenantSettings"],
    "ActualValue" : EnvironmentCreation.disableTrialEnvironmentCreationByNonAdminUsers,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    EnvironmentCreation := input.environment_creation[_]
    Status := EnvironmentCreation.disableTrialEnvironmentCreationByNonAdminUsers == true
}
#--

#
# Baseline 2.1: Policy 2 PoSh Error
#--
tests[{
    "Requirement" : "The ability to create trial environments SHALL be restricted to admins",
    "Control" : "Power Platform 2.1",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-TenantSettings"],
    "ActualValue" : "PowerShell Error",
    "ReportDetails" : "PowerShell Error",
    "RequirementMet" : false
}] {
    count(input.environment_creation) <= 0
}
#--


################
# Baseline 2.2 #
################

#
# Baseline 2.2: Policy 1
#--
DefaultEnvPolicies[{"PolicyName" : Policy.displayName}]{
    TenantId := input.tenant_id
    DlpPolicies := input.dlp_policies[_]
    Policy := DlpPolicies.value[_]
    Env := Policy.environments[_]
    Env.name == concat("-", ["Default", TenantId])
}

# Note: there is only one default environment per tenant and it cannot be deleted or backed up
tests[{
    "Requirement" : "A DLP policy SHALL be created to restrict connector access in the default Power Platform environment",
    "Control" : "Power Platform 2.2",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-DlpPolicy"],
    "ActualValue" : DefaultEnvPolicies,
    "ReportDetails" : ReportDetailsString(Status, ErrorMessage),
    "RequirementMet" : Status
}] {
    ErrorMessage := "No policy found that applies to default environment"
    Status := count(DefaultEnvPolicies) > 0
}
#--

#
# Baseline 2.2: Policy 2
#--
# gets the list of all tenant environments
AllEnvironments [{ "EnvName" : EnvName }] {
    EnvironmentList := input.environment_list[_]
    EnvName := EnvironmentList.EnvironmentName
}

# gets the list of all environments with policies applied to them
EnvWithPolicies [{"EnvName" : PolicyEnvName }] {
    DlpPolicies := input.dlp_policies[_]
    Policy := DlpPolicies.value[_]
    Env := Policy.environments[_]
    PolicyEnvName := Env.name
}

# finds the environments with no policies applied to them
EnvWithoutPolicies [Env] {
    AllEnvSet := {Env.EnvName | Env = AllEnvironments[_]}
    PolicyEnvSet := {Env.EnvName | Env = EnvWithPolicies[_]}
    Difference := AllEnvSet - PolicyEnvSet
    Env := Difference[_]
}

tests[{
    "Requirement" : "Non-default environments SHOULD have at least one DLP policy that affects them",
    "Control" : "Power Platform 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpPolicy"],
    "ActualValue" : EnvWithoutPolicies,
    "ReportDetails" : ReportDetailsArray(Status, EnvWithoutPolicies, ErrorMessage),
    "RequirementMet" : Status
}] {
    DLPPolicies = input.dlp_policies[_]
    count(DLPPolicies.value) > 0
    ErrorMessage := "Subsequent environments without DLP policies:"
    Status := count(EnvWithoutPolicies) == 0
}
#--

#
# Baseline 2.2: Policy 2 No DLP Policies found
#--
tests[{
    "Requirement" : "Non-default environments SHOULD have at least one DLP policy that affects them",
    "Control" : "Power Platform 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpPolicy"],
    "ActualValue" : "No DLP Policies found",
    "ReportDetails" : "No DLP Policies found",
    "RequirementMet" : false
}] {
    DLPPolicies = input.dlp_policies[_]
    count(DLPPolicies.value) <= 0
}
#--

#
# Baseline 2.2: Policy 2 PoSh Error
#--
tests[{
    "Requirement" : "Non-default environments SHOULD have at least one DLP policy that affects them",
    "Control" : "Power Platform 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpPolicy"],
    "ActualValue" : "PowerShell Error",
    "ReportDetails" : "PowerShell Error",
    "RequirementMet" : false
}] {
    count(input.dlp_policies) <= 0
}
#--

#
# Baseline 2.2: Policy 3
#--
# gets the set of connectors that are allowed in the default environment
# general and confidential groups refer to business and non-business
ConnectorSet[Connector.id] {
    TenantId := input.tenant_id
    DlpPolicies := input.dlp_policies[_]
    Policy := DlpPolicies.value[_]
    Env := Policy.environments[_]
    Group := Policy.connectorGroups[_]
    Connector := Group.connectors[_]
    Conditions := [Group.classification == "General", Group.classification == "Confidential"]
    # Filter: only include policies that meet all the requirements
    Env.name == concat("-", ["Default", TenantId])
    count([Condition | Condition = Conditions[_]; Condition == true]) > 0
}

# set of all connectors that cannot be blocked
AllowedInBaseline := {
    "/providers/Microsoft.PowerApps/apis/shared_powervirtualagents",
    "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
    "/providers/Microsoft.PowerApps/apis/shared_onedriveforbusiness",
    "/providers/Microsoft.PowerApps/apis/shared_approvals",
    "/providers/Microsoft.PowerApps/apis/shared_cloudappsecurity",
    "/providers/Microsoft.PowerApps/apis/shared_commondataservice",
    "/providers/Microsoft.PowerApps/apis/shared_commondataserviceforapps",
    "/providers/Microsoft.PowerApps/apis/shared_excelonlinebusiness",
    "/providers/Microsoft.PowerApps/apis/shared_flowpush",
    "/providers/Microsoft.PowerApps/apis/shared_kaizala",
    "/providers/Microsoft.PowerApps/apis/shared_microsoftformspro",
    "/providers/Microsoft.PowerApps/apis/shared_office365",
    "/providers/Microsoft.PowerApps/apis/shared_office365groups",
    "/providers/Microsoft.PowerApps/apis/shared_office365groupsmail",
    "/providers/Microsoft.PowerApps/apis/shared_office365users",
    "/providers/Microsoft.PowerApps/apis/shared_onenote",
    "/providers/Microsoft.PowerApps/apis/shared_planner",
    "/providers/Microsoft.PowerApps/apis/shared_powerappsnotification",
    "/providers/Microsoft.PowerApps/apis/shared_powerappsnotificationv2",
    "/providers/Microsoft.PowerApps/apis/shared_powerbi",
    "/providers/Microsoft.PowerApps/apis/shared_shifts",
    "/providers/Microsoft.PowerApps/apis/shared_skypeforbiz",
    "/providers/Microsoft.PowerApps/apis/shared_teams",
    "/providers/Microsoft.PowerApps/apis/shared_todo",
    "/providers/Microsoft.PowerApps/apis/shared_yammer"
}

tests[{
    "Requirement" : "All connectors except those listed...[see Power Platform secure configuration baseline for list]...SHOULD be added to the Blocked category in the default environment policy",
    "Control" : "Power Platform 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpPolicy"],
    "ActualValue" : RogueConnectors,
    "ReportDetails" : ReportDetailsArray(Status, RogueConnectors, ErrorMessage),
    "RequirementMet" : Status
}] {
    DLPPolicies = input.dlp_policies[_]
    count(DLPPolicies.value) > 0
    ErrorMessage := "Connectors are allowed that should be blocked:"
    RogueConnectors := (ConnectorSet - AllowedInBaseline)
    Status := count(RogueConnectors) == 0
}
#--

#
# Baseline 2.2: Policy 3 Error No DLP policies Found
#--
tests[{
    "Requirement" : "All connectors except those listed...[see Power Platform secure configuration baseline for list]...SHOULD be added to the Blocked category in the default environment policy",
    "Control" : "Power Platform 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpPolicy"],
    "ActualValue" : "No DLP Policies found",
    "ReportDetails" : "No DLP Policies found",
    "RequirementMet" : false
}] {
    DLPPolicies = input.dlp_policies[_]
    count(DLPPolicies.value) <= 0
}
#--

#
# Baseline 2.2: Policy 3 PoSh Error
#--
tests[{
    "Requirement" : "All connectors except those listed...[see Power Platform secure configuration baseline for list]...SHOULD be added to the Blocked category in the default environment policy",
    "Control" : "Power Platform 2.2",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpPolicy"],
    "ActualValue" : "PowerShell error",
    "ReportDetails" : "PowerShell error",
    "RequirementMet" : false
}] {
    count(input.dlp_policies) <= 0
}
#--


################
# Baseline 2.3 #
################

#
# Baseline 2.3: Policy 1
#--
tests[{
    "Requirement" : "Power Platform tenant isolation SHALL be enabled",
    "Control" : "Power Platform 2.3",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-PowerAppTenantIsolationPolicy"],
    "ActualValue" : TenantIsolation.properties.isDisabled,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    TenantIsolation := input.tenant_isolation[_]
    Status := TenantIsolation.properties.isDisabled == false
}
#--

#
# Baseline 2.3: Policy 1 PoSh Error
#--
tests[{
    "Requirement" : "Power Platform tenant isolation SHALL be enabled",
    "Control" : "Power Platform 2.3",
    "Criticality" : "Shall",
    "Commandlet" : ["Get-PowerAppTenantIsolationPolicy"],
    "ActualValue" : "PowerShell Error",
    "ReportDetails" : "PowerShell Error",
    "RequirementMet" : false
}] {
    count(input.tenant_isolation) <= 0
}
#--

#
# Baseline 2.3: Policy 2
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "An inbound/outbound connection allowlist SHOULD be configured",
    "Control" : "Power Platform 2.3",
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Power Platform Secure Configuration Baseline policy 2.3 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--


################
# Baseline 2.4 #
################

#
# Baseline 2.4: Policy 1
#--
# At this time we are unable to test for X because of Y
tests[{
    "Requirement" : "Content security policies for model-driven Power Apps SHALL be enabled",
    "Control" : "Power Platform 2.4",
    "Criticality" : "Shall/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : "Currently cannot be checked automatically. See Power Platform Secure Configuration Baseline policy 2.4 for instructions on manual check",
    "RequirementMet" : false
}] {
    true
}
#--