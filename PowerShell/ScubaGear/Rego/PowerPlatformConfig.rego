package powerplatform
import rego.v1
import data.utils.report.NotCheckedDetails
import data.utils.report.ReportDetailsString
import data.utils.report.ReportDetailsBoolean
import data.utils.report.ReportDetailsArray
import data.utils.key.FilterArray


######################
# MS.POWERPLATFORM.1 #
######################

#
# MS.POWERPLATFORM.1.1v1
#--

# Pass if disableEnvironmentCreationByNonAdminUsers is true
tests contains {
    "PolicyId": "MS.POWERPLATFORM.1.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-TenantSettings"],
    "ActualValue": EnvironmentCreation.disableEnvironmentCreationByNonAdminUsers,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some EnvironmentCreation in input.environment_creation
    Status := EnvironmentCreation.disableEnvironmentCreationByNonAdminUsers == true
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERPLATFORM.1.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-TenantSettings"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.environment_creation) <= 0
}
#--

#
# MS.POWERPLATFORM.1.2v1
#--
# Pass if disableTrialEnvironmentCreationByNonAdminUsers is true
tests contains {
    "PolicyId": "MS.POWERPLATFORM.1.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-TenantSettings"],
    "ActualValue": EnvironmentCreation.disableTrialEnvironmentCreationByNonAdminUsers,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some EnvironmentCreation in input.environment_creation
    Status := EnvironmentCreation.disableTrialEnvironmentCreationByNonAdminUsers == true
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERPLATFORM.1.2v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-TenantSettings"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.environment_creation) <= 0
}
#--


######################
# MS.POWERPLATFORM.2 #
######################

#
# MS.POWERPLATFORM.2.1v1
#--

# Iterate through all policies. For each, check if the environment the policy applies to
# is the default environment. If so, save the policy name to the DefaultEnvPolicies list.
DefaultEnvPolicies contains {"PolicyName": Policies.displayName} if {
    # regal ignore:prefer-some-in-iteration
    some Policies in input.dlp_policies[_].value
    some Env in Policies.environments
    Env.name == concat("-", ["Default", input.tenant_id])
}

# Note: there is only one default environment per tenant and it cannot be deleted or backed up
# Pass if at least one policy applies to the default environment
tests contains {
    "PolicyId": "MS.POWERPLATFORM.2.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-DlpPolicy"],
    "ActualValue": DefaultEnvPolicies,
    "ReportDetails": ReportDetailsString(Status, ErrorMessage),
    "RequirementMet": Status
} if {
    ErrorMessage := "No policy found that applies to default environment"
    Status := count(DefaultEnvPolicies) > 0
}
#--

#
# MS.POWERPLATFORM.2.2v1
#--

# gets the list of all tenant environments
AllEnvironments contains EnvironmentList.EnvironmentName if {
    some EnvironmentList in input.environment_list
}

# gets the list of all environments with policies applied to them
EnvWithPolicies contains Env.name if {
    # regal ignore:prefer-some-in-iteration
    some Policies in input.dlp_policies[_].value
    some Env in Policies.environments
}

# Pass if all envoirments have a policy applied to them
tests contains {
    "PolicyId": "MS.POWERPLATFORM.2.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpPolicy"],
    "ActualValue": EnvWithoutPolicies,
    "ReportDetails": ReportDetailsArray(Status, EnvWithoutPolicies, ErrorMessage),
    "RequirementMet": Status
} if {
    some DLPPolicies in input.dlp_policies
    count(DLPPolicies.value) > 0
    ErrorMessage := "Subsequent environments without DLP policies:"

    # finds the environments with no policies applied to them
    EnvWithoutPolicies := AllEnvironments - EnvWithPolicies
    Status := count(EnvWithoutPolicies) == 0
}

# Edge case where no policies are found
tests contains {
    "PolicyId": "MS.POWERPLATFORM.2.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpPolicy"],
    "ActualValue": "No DLP Policies found",
    "ReportDetails": "No DLP Policies found",
    "RequirementMet": false
} if {
    some DLPPolicies in input.dlp_policies
    count(DLPPolicies.value) <= 0
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERPLATFORM.2.2v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpPolicy"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.dlp_policies) <= 0
}
#--

#
# MS.POWERPLATFORM.2.3v1
#--

# gets the set of connectors that are allowed in the default environment
# general and confidential groups refer to business and non-business
ConnectorSet contains Connector.id if {
    # regal ignore:prefer-some-in-iteration
    some Policies in input.dlp_policies[_].value
    some Group in Policies.connectorGroups
    Conditions := [
        Group.classification == "General",
        Group.classification == "Confidential"
    ]
    count(FilterArray(Conditions, true)) > 0
    some Connector in Group.connectors

    # Filter: only include policies that meet all the requirements
    some Env in Policies.environments
    TenantId := input.tenant_id
    Env.name == concat("-", ["Default", TenantId])
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

# Pass if all connectors besides the ones allowed are blocked
tests contains {
    "PolicyId": "MS.POWERPLATFORM.2.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpPolicy"],
    "ActualValue": RogueConnectors,
    "ReportDetails": ReportDetailsArray(Status, RogueConnectors, ErrorMessage),
    "RequirementMet": Status
} if {
    some DLPPolicies in input.dlp_policies
    count(DLPPolicies.value) > 0
    ErrorMessage := "Connectors are allowed that should be blocked:"
    RogueConnectors := ConnectorSet - AllowedInBaseline
    Status := count(RogueConnectors) == 0
}

# Edge case where no policies are found
tests contains {
    "PolicyId": "MS.POWERPLATFORM.2.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpPolicy"],
    "ActualValue": "No DLP Policies found",
    "ReportDetails": "No DLP Policies found",
    "RequirementMet": false
} if {
    some DLPPolicies in input.dlp_policies
    count(DLPPolicies.value) <= 0
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERPLATFORM.2.3v1",
    "Criticality": "Should",
    "Commandlet": ["Get-DlpPolicy"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.dlp_policies) <= 0
}
#--


######################
# MS.POWERPLATFORM.3 #
######################


#
# MS.POWERPLATFORM.3.1v1
#--

# Pass if isDisabled is false
tests contains {
    "PolicyId": "MS.POWERPLATFORM.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-PowerAppTenantIsolationPolicy"],
    "ActualValue": TenantIsolation.properties.isDisabled,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some TenantIsolation in input.tenant_isolation
    Status := TenantIsolation.properties.isDisabled == false
}

# Edge case where pulling configuration from tenant fails
tests contains {
    "PolicyId": "MS.POWERPLATFORM.3.1v1",
    "Criticality": "Shall",
    "Commandlet": ["Get-PowerAppTenantIsolationPolicy"],
    "ActualValue": "PowerShell Error",
    "ReportDetails": "PowerShell Error",
    "RequirementMet": false
} if {
    count(input.tenant_isolation) <= 0
}
#--

#
# MS.POWERPLATFORM.3.2v1
#--

# At this time we are unable to test for X because of Y
tests contains {
    "PolicyId": "MS.POWERPLATFORM.3.2v1",
    "Criticality": "Should/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.POWERPLATFORM.3.2v1"),
    "RequirementMet": false
}
#--


######################
# MS.POWERPLATFORM.4 #
######################

#
# MS.POWERPLATFORM.4.1v1
#--

# At this time we are unable to test for X because of Y
tests contains {
    "PolicyId": "MS.POWERPLATFORM.4.1v1",
    "Criticality": "Shall/Not-Implemented",
    "Commandlet": [],
    "ActualValue": [],
    "ReportDetails": NotCheckedDetails("MS.POWERPLATFORM.4.1v1"),
    "RequirementMet": false
}
#--


######################
# MS.POWERPLATFORM.5 #
######################

#
# MS.POWERPLATFORM.5.1v1
#--

# Pass if disablePortalsCreationByNonAdminUsers is true
tests contains {
    "PolicyId": "MS.POWERPLATFORM.5.1v1",
    "Criticality": "Should",
    "Commandlet": ["Get-TenantSettings"],
    "ActualValue": EnvironmentCreation.disablePortalsCreationByNonAdminUsers,
    "ReportDetails": ReportDetailsBoolean(Status),
    "RequirementMet": Status
} if {
    some EnvironmentCreation in input.environment_creation
    Status := EnvironmentCreation.disablePortalsCreationByNonAdminUsers == true
}
#--