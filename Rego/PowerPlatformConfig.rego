package powerplatform
import future.keywords
import data.report.utils.NotCheckedDetails
import data.report.utils.Format
import data.report.utils.ReportDetailsBoolean
import data.report.utils.Description
import data.report.utils.ReportDetailsString

ReportDetailsArray(Status, Array, String1) :=  Detail if {
    Status == true
    Detail := "Requirement met"
}

ReportDetailsArray(Status, Array, String1) := Detail if {
	Status == false
    String2 := concat(", ", Array)
    Detail := Description(Format(Array), String1, String2)
}

#
# MS.POWERPLATFORM.1.1v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.1.1v1",
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

# MS.POWERPLATFORM.1.1v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.1.1v1",
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
# MS.POWERPLATFORM.1.2v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.1.2v1",
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
# MS.POWERPLATFORM.1.2v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.1.2v1",
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
# MS.POWERPLATFORM.2.1v1
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
    "PolicyId" : "MS.POWERPLATFORM.2.1v1",
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
# MS.POWERPLATFORM.2.2v1
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
    "PolicyId" : "MS.POWERPLATFORM.2.2v1",
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
# MS.POWERPLATFORM.2.2v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.2.2v1",
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
# MS.POWERPLATFORM.2.2v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.2.2v1",
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
# MS.POWERPLATFORM.2.3v1
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
    "PolicyId" : "MS.POWERPLATFORM.2.3v1",
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
# MS.POWERPLATFORM.2.3v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.2.3v1",
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
# MS.POWERPLATFORM.2.3v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.2.3v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-DlpPolicy"],
    "ActualValue" : "PowerShell error",
    "ReportDetails" : "PowerShell error",
    "RequirementMet" : false
}] {
    count(input.dlp_policies) <= 0
}
#--

#
# MS.POWERPLATFORM.3.1v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.3.1v1",
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
# MS.POWERPLATFORM.3.1v1
#--
tests[{
    "PolicyId" : "MS.POWERPLATFORM.3.1v1",
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
# MS.POWERPLATFORM.3.2v1
#--
# At this time we are unable to test for X because of Y
tests[{
    "PolicyId" : PolicyId,
    "Criticality" : "Should/Not-Implemented",
    "Commandlet" : [],
    "ActualValue" : [],
    "ReportDetails" : NotCheckedDetails(PolicyId),
    "RequirementMet" : false
}] {
    PolicyId := "MS.POWERPLATFORM.3.2v1"
    true
}
#--

#
# MS.POWERPLATFORM.4.1v1
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
    PolicyId := "MS.POWERPLATFORM.4.1v1"
    true
}
#--

#
# MS.POWERPLATFORM.5.1v1
#--
#
tests[{
    "PolicyId" : "MS.POWERPLATFORM.5.1v1",
    "Criticality" : "Should",
    "Commandlet" : ["Get-TenantSettings"],
    "ActualValue" : EnvironmentCreation.disablePortalsCreationByNonAdminUsers,
    "ReportDetails" : ReportDetailsBoolean(Status),
    "RequirementMet" : Status
}] {
    EnvironmentCreation := input.environment_creation[_]
    Status := EnvironmentCreation.disablePortalsCreationByNonAdminUsers == true
}
#--