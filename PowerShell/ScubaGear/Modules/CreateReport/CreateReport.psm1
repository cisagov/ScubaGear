# Dictionaries used to map the codes used in the provider output to
# human-friendly strings
$ExternalUserStrings = @{"b2bCollaborationGuest" = "B2B collaboration guest users";
        "b2bCollaborationMember" = "B2B collaboration member users";
        "b2bDirectConnectUser" = "B2B direct connect users";
        "internalGuest" = "Local guest users";
        "serviceProvider" = "Service provider users";
        "otherExternalUser" = "Other external users"}

$StateStrings = @{"enabled" = "On";
    "enabledForReportingButNotEnforced" = "Report-only";
    "disabled" = "Off"}

$ActionStrings = @{"urn:user:registersecurityinfo" = "Register security info";
    "urn:user:registerdevice" = "Register or join devices"}

$ClientAppStrings = @{"exchangeActiveSync" = "Exchange ActiveSync Clients";
    "browser" = "Browser";
    "mobileAppsAndDesktopClients" = "Mobile apps and desktop clients";
    "other" = "Other clients";
    "all" = "all"}

$GrantControlStrings = @{"mfa" = "multifactor authentication";
    "compliantDevice" = "device to be marked compliant";
    "domainJoinedDevice" = "Hybrid Azure AD joined device";
    "approvedApplication" = "approved client app";
    "compliantApplication" = "app protection policy";
    "passwordChange" = "password change"}

$CondAccessAppControlStrings = @{"monitorOnly" = "Monitor only";
    "blockDownloads" = "Block downloads";
    "mcasConfigured" = "Use custom policy"}

function Get-IncludedUsers {
    <#
    .Description
    Parses the provider output to generate a list of included users for a given conditional access policy (Cap).
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object]
        $Cap
    )
    process {

        $IncludedUsers = @()
            if ($Cap.Conditions.Users.IncludeUsers -Contains "All") {
                $IncludedUsers += "All"
            }
            elseif ($Cap.Conditions.Users.IncludeUsers -Contains "None") {
                $IncludedUsers += "None"
            }
            else {
                # Users
                # TODO add JS button that enumerates the users
                if ($Cap.Conditions.Users.IncludeUsers.Length -eq 1) {
                    $IncludedUsers += "1 specific user"
                }
                elseif ($Cap.Conditions.Users.IncludeUsers.Length -gt 1) {
                    $IncludedUsers += "$($Cap.Conditions.Users.IncludeUsers.Length) specific users"
                }

                # Roles
                # TODO add JS button that enumerates the roles
                if ($Cap.Conditions.Users.IncludeRoles.Length -eq 1) {
                    $IncludedUsers += "1 specific role"
                }
                elseif ($Cap.Conditions.Users.IncludeRoles.Length -gt 1) {
                    $IncludedUsers += "$($Cap.Conditions.Users.IncludeRoles.Length) specific roles"
                }

                # Groups
                # TODO add JS button that enumerates the groups
                if ($Cap.Conditions.Users.IncludeGroups.Length -eq 1) {
                    $IncludedUsers += "1 specific group"
                }
                elseif ($Cap.Conditions.Users.IncludeGroups.Length -gt 1) {
                    $IncludedUsers += "$($Cap.Conditions.Users.IncludeGroups.Length) specific groups"
                }

                # External/guests
                if ($null -ne $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.ExternalTenants.MembershipKind) {
                    $GuestOrExternalUserTypes = $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes -Split ","
                    $IncludedUsers += @($GuestOrExternalUserTypes | ForEach-Object {$ExternalUserStrings[$_]})
                }
            }
        $IncludedUsers
    }
}

function Get-ExcludedUsers {
    <#
    .Description
    Parses the provider output to generate a list of excluded users for a given conditional access policy (Cap).
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object]
        $Cap
    )
    process {
        $ExcludedUsers = @()
        # Users
        # TODO add JS button that enumerates the users
        if ($Cap.Conditions.Users.ExcludeUsers.Length -eq 1) {
            $ExcludedUsers += "1 specific user"
        }
        elseif ($Cap.Conditions.Users.ExcludeUsers.Length -gt 1) {
            $ExcludedUsers += "$($Cap.Conditions.Users.ExcludeUsers.Length) specific users"
        }

        # Roles
        # TODO add JS button that enumerates the roles
        if ($Cap.Conditions.Users.ExcludeRoles.Length -eq 1) {
            $ExcludedUsers += "1 specific role"
        }
        elseif ($Cap.Conditions.Users.ExcludeRoles.Length -gt 1) {
            $ExcludedUsers += "$($Cap.Conditions.Users.ExcludeRoles.Length) specific roles"
        }

        # Groups
        # TODO add JS button that enumerates the groups
        if ($Cap.Conditions.Users.ExcludeGroups.Length -eq 1) {
            $ExcludedUsers += "1 specific group"
        }
        elseif ($Cap.Conditions.Users.ExcludeGroups.Length -gt 1) {
            $ExcludedUsers += "$($Cap.Conditions.Users.ExcludeGroups.Length) specific groups"
        }

        # External/guests
        if ($null -ne $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.ExternalTenants.MembershipKind) {
            $GuestOrExternalUserTypes = $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.GuestOrExternalUserTypes -Split ","
            $ExcludedUsers += @($GuestOrExternalUserTypes | ForEach-Object {$ExternalUserStrings[$_]})
        }

        # If no users are excluded, rather than display an empty cell, display "None"
        if ($ExcludedUsers.Length -eq 0) {
            $ExcludedUsers += "None"
        }
        $ExcludedUsers
    }
}

function Get-Applications {
    <#
    .Description
    Parses the provider output to generate a list of included/excluded applications/actions for a given conditional access policy (Cap).
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object]
        $Cap
    )
    process {
        $Actions = @()
        if ($Cap.Conditions.Applications.IncludeApplications.Length -gt 0) {
            # For "Select what this policy applies to", "Cloud Apps" was  selected
            $Actions += "Policy applies to: apps"
            # Included apps:
            if ($Cap.Conditions.Applications.IncludeApplications -Contains "All") {
                $Actions += "Apps included: All"
            }
            elseif ($Cap.Conditions.Applications.IncludeApplications -Contains "None") {
                $Actions += "Apps included: None"
            }
            elseif ($Cap.Conditions.Applications.IncludeApplications.Length -eq 1) {
                $Actions += "Apps included: 1 specific app"
            }
            else {
                $Actions += "Apps included: $($Cap.Conditions.Applications.IncludeApplications.Length) specific apps"
            }

            # Excluded apps: # TODO FILTERs
            if ($Cap.Conditions.Applications.ExcludeApplications.Length -eq 0) {
                $Actions += "Apps excluded: None"
            }
            elseif ($Cap.Conditions.Applications.ExcludeApplications.Length -eq 1) {
                $Actions += "Apps excluded: 1 specific app"
            }
            else {
                $Actions += "Apps excluded: $($Cap.Conditions.Applications.ExcludeApplications.Length) specific apps"
            }
        }
        elseif ($Cap.Conditions.Applications.IncludeUserActions.Length -gt 0) {
            # For "Select what this policy applies to", "User actions" was selected
            $Actions += "Policy applies to: actions"
            $Actions += "User action: $($ActionStrings[$Cap.Conditions.Applications.IncludeUserActions[0]])"
            # While "IncludeUserActions" is a list, the GUI doesn't actually let you select more than one
            # item at a time, hence "IncludeUserActions[0]" above
        }
        else {
            # For "Select what this policy applies to", "Authentication context" was selected
            # TODO Add JS button that enumerates the contexts
            $AuthContexts = $Cap.Conditions.Applications.IncludeAuthenticationContextClassReferences
            if ($AuthContexts.Length -eq 1) {
                $Actions += "Policy applies to: 1 authentication context"
            }
            else {
                $Actions += "Policy applies to: $($AuthContexts.Length) authentication contexts"
            }
        }
        $Actions = @($Actions | ForEach-Object {"<li>$_</li>"})
        "<ul>$($Actions -Join '')</ul>"
    }
}

function Get-Conditions {
    <#
    .Description
    Parses the provider output to generate a list of conditions for a given conditional access policy (Cap).
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object]
        $Cap
    )
    process {
        $Conditions = @()
        # User risk
        if ($Cap.Conditions.UserRiskLevels.Length -gt 0) {
            $Conditions += "User risk levels: $($Cap.Conditions.UserRiskLevels -Join ', ')"
        }
        # Sign-in risk
        if ($Cap.Conditions.SignInRiskLevels.Length -gt 0) {
            $Conditions += "Sign-in risk levels: $($Cap.Conditions.SignInRiskLevels -Join ', ')"
        }
        # Device platforms
        if ($null -ne $Cap.Conditions.Platforms.IncludePlatforms) {
            $Conditions += "Device platforms included: $($Cap.Conditions.Platforms.IncludePlatforms -Join ', ')"
            if ($Cap.Conditions.Platforms.ExcludePlatforms.Length -eq 0) {
                $Conditions += "Device platforms excluded: none"
            }
            else {
                $Conditions += "Device platforms excluded: $($Cap.Conditions.Platforms.ExcludePlatforms -Join ', ')"
            }
        }
        # Locations
        if ($null -ne $Cap.Conditions.Locations.IncludeLocations) {
            if ($Cap.Conditions.Locations.IncludeLocations -Contains "All") {
                $Conditions += "Locations included: all locations"
            }
            elseif ($Cap.Conditions.Locations.IncludeLocations -Contains "AllTrusted") {
                $Conditions += "Locations included: all trusted locations"
            }
            elseif ($Cap.Conditions.Locations.IncludeLocations.Length -eq 1) {
                $Conditions += "Locations included: 1 specific location"
            }
            else {
                $Conditions += "Locations included: $($Cap.Conditions.Locations.IncludeLocations.Length) specific locations"
            }

            if ($Cap.Conditions.Locations.ExcludeLocations -Contains "AllTrusted") {
                $Conditions += "Locations excluded: all trusted locations"
            }
            elseif ($Cap.Conditions.Locations.ExcludeLocations.Length -eq 0) {
                $Conditions += "Locations excluded: none"
            }
            elseif ($Cap.Conditions.Locations.ExcludeLocations.Length -eq 1) {
                $Conditions += "Locations excluded: 1 specific location"
            }
            else {
                $Conditions += "Locations excluded: $($Cap.Conditions.Locations.ExcludeLocations.Length) specific locations"
            }
        }
        # Client Apps
        $ClientApps += @($Cap.Conditions.ClientAppTypes | ForEach-Object {$ClientAppStrings[$_]})
        $Conditions += "Client apps included: $($ClientApps -Join ', ')"
        # Filter for devices
        if ($null -ne $Cap.Conditions.Devices.DeviceFilter.Mode) {
            if ($null -ne $Cap.Conditions.Devices.DeviceFilter.Mode -eq "include") {
                $Conditions += "Custom device filter in include mode active"
            }
            else {
                $Conditions += "Custom device filter in exclude mode active"
            }
        }

        $Conditions = @($Conditions | ForEach-Object {"<li>$_</li>"})
        "<ul>$($Conditions -Join '')</ul>"
    }
}

function Get-AccessControls {
    <#
    .Description
    Parses the provider output to generate a list of access controls for a given conditional access policy (Cap).
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object]
        $Cap
    )
    process {
        $AccessControls = ""
        if ($null -ne $Cap.GrantControls.BuiltInControls) {
            if ($Cap.GrantControls.BuiltInControls -Contains "block") {
                $AccessControls = "Block access"
            }
            else {
                $GrantControls = @($Cap.GrantControls.BuiltInControls | ForEach-Object {$GrantControlStrings[$_]})
                if ($null -ne $Cap.GrantControls.AuthenticationStrength.DisplayName) {
                    $GrantControls += "authentication strength ($($Cap.GrantControls.AuthenticationStrength.DisplayName))"
                }

                $AccessControls = "Allow access but require $($GrantControls -Join ', ')"
                if ($GrantControls.Length -gt 1) {
                    $AccessControls = $AccessControls.Insert($AccessControls.LastIndexOf(',')+1, " $($Cap.GrantControls.Operator)")
                }
            }
        }

        if ($AccessControls -eq "") {
            $AccessControls = "None"
        }
        $AccessControls
    }
}

function Get-SessionControls {
    <#
    .Description
    Parses the provider output to generate a list of session controls for a given conditional access policy (Cap).
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object]
        $Cap
    )
    process {
        $SessionControls = @()
        if ($Cap.SessionControls.ApplicationEnforcedRestrictions.IsEnabled) {
            $SessionControls += "Use app enforced restrictions"
        }
        if ($Cap.SessionControls.CloudAppSecurity.IsEnabled) {
            $Mode = $CondAccessAppControlStrings[$Cap.SessionControls.CloudAppSecurity.CloudAppSecurityType]
            $SessionControls += "Use Conditional Access App Control ($($Mode))"
        }
        if ($Cap.SessionControls.SignInFrequency.IsEnabled) {
            if ($Cap.SessionControls.SignInFrequency.FrequencyInterval -eq "everyTime") {
                $SessionControls += "Sign-in frequency (every time)"
            }
            else {
                $Value = $Cap.SessionControls.SignInFrequency.Value
                $Unit = $Cap.SessionControls.SignInFrequency.Type
                $SessionControls += "Sign-in frequency (every $($Value) $($Unit))"
            }
        }
        if ($Cap.SessionControls.PersistentBrowser.IsEnabled) {
            $Mode = $Cap.SessionControls.PersistentBrowser.Mode
            $SessionControls += "Persistent browser session ($($Mode) persistent)"
        }
        if ($Cap.SessionControls.ContinuousAccessEvaluation.Mode -eq "disabled") {
            $SessionControls += "Customize continuous access evaluation"
        }
        if ($Cap.SessionControls.DisableResilienceDefaults) {
            $SessionControls += "Disable resilience defaults"
        }
        if ($SessionControls.Length -eq 0) {
            $SessionControls += "None"
        }
        $SessionControls = @($SessionControls | ForEach-Object {"<li>$_</li>"})
        "<ul>$($SessionControls -Join '')</ul>"
    }
}

function Get-CapTable {
    $FileName = Join-Path -Path $OutPath -ChildPath "$($OutProviderFileName).json"
    $SettingsExport =  Get-Content $FileName | ConvertFrom-Json
    $Caps = $SettingsExport.conditional_access_policies

    $Table = @()

    foreach ($Cap in $Caps) {
        $UsersIncluded = $(Get-IncludedUsers -Cap $Cap) -Join ", "
        $UsersExcluded = $(Get-ExcludedUsers -Cap $Cap) -Join ", "
        $Apps = Get-Applications -Cap $Cap
        $Conditions = Get-Conditions -Cap $Cap
        $AccessControls = Get-AccessControls -Cap $Cap
        $SessionControls = Get-SessionControls -Cap $Cap
        $CapDetails = [pscustomobject]@{
            "Name" = $Cap.DisplayName;
            "State" = $StateStrings[$Cap.State];
            "Users" = "<ul><li>Users included: $($UsersIncluded)</li><li>Users excluded: $($UsersExcluded)</li></ul>";
            "Apps/Actions" = $Apps;
            "Conditions" = $Conditions;
            "Block/Grant Access" = $AccessControls;
            "Session Controls" = $SessionControls;
        }

        $Table += $CapDetails
    }

    $TableHtml = $Table | ConvertTo-Html -Fragment
    $TableHtml = "
    <div id=caps>
        <hr>
        <h2>Conditional Access Policies</h2>
        $($TableHtml)
    </div>"
    $TableHtml
}

function New-Report {
     <#
    .Description
    This function creates the individual HTML report using the TestResults.json.
    Output will be stored as an HTML file in the InvidualReports folder in the OutPath Folder.
    The report Home page and link tree will be named BaselineReports.html
    .Functionality
    Internal
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $BaselineName,

        [Parameter(Mandatory=$true)]
        [string]
        $FullName,

        # The location to save the html report in.
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $IndividualReportPath,

        # The location to save the html report in.
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $OutPath,

        [Parameter(Mandatory=$true)]
        [string]
        $OutProviderFileName,

        [Parameter(Mandatory=$true)]
        [string]
        $OutRegoFileName
    )

    $FileName = Join-Path -Path $PSScriptRoot -ChildPath "BaselineTitles.json"
    $AllTitles =  Get-Content $FileName | ConvertFrom-Json
    $Titles = $AllTitles.$BaselineName

    $FileName = Join-Path -Path $OutPath -ChildPath "$($OutProviderFileName).json"
    $SettingsExport =  Get-Content $FileName | ConvertFrom-Json

    $FileName = Join-Path -Path $OutPath -ChildPath "$($OutRegoFileName).json"
    $TestResults =  Get-Content $FileName | ConvertFrom-Json

    $Fragments = @()

    $MetaData += [pscustomobject]@{
        "Tenant Display Name" = $SettingsExport.tenant_details.DisplayName;
        "Report Date" = $SettingsExport.date;
        "Baseline Version" = $SettingsExport.baseline_version;
        "Module Version" = $SettingsExport.module_version
    }

    $MetaDataTable = $MetaData | ConvertTo-HTML -Fragment
    $MetaDataTable = $MetaDataTable -replace '^(.*?)<table>','<table style = "text-align:center;">'
    $Fragments += $MetaDataTable
    $ReportSummary = @{
        "Warnings" = 0;
        "Failures" = 0;
        "Passes" = 0;
        "Manual" = 0;
        "Errors" = 0;
        "Date" = $SettingsExport.date;
    }

    foreach ($Title in $Titles) {
        $Fragment = @()
        foreach ($test in $TestResults | Where-Object -Property Control -eq $Title.Number) {
            $MissingCommands = @()

            if ($SettingsExport."$($BaselineName)_successful_commands" -or $SettingsExport."$($BaselineName)_unsuccessful_commands") {
                # If neither of these keys are present, it means the provider for that baseline
                # hasn't been updated to the updated error handling method. This check
                # here ensures backwards compatibility until all providers are udpated.
                $MissingCommands = $test.Commandlet | Where-Object {$SettingsExport."$($BaselineName)_successful_commands" -notcontains $_}
            }

            if ($MissingCommands.Count -gt 0) {
                $Result = "Error"
                $ReportSummary.Errors += 1
                $MissingString = $MissingCommands -Join ", "
                $test.ReportDetails = "This test depends on the following command(s) which did not execute successfully: $($MissingString). See terminal output for more details."
            }
            elseif ($test.RequirementMet) {
                $Result = "Pass"
                $ReportSummary.Passes += 1
            }
            elseif ($test.Criticality -eq "Should") {
                $Result = "Warning"
                $ReportSummary.Warnings += 1
            }
            elseif ($test.Criticality.EndsWith('3rd Party') -or $test.Criticality.EndsWith('Not-Implemented')) {
                $Result = "N/A"
                $ReportSummary.Manual += 1
            }
            else {
                $Result = "Fail"
                $ReportSummary.Failures += 1
            }

            $Fragment += [pscustomobject]@{
                "Requirement"=$test.Requirement;
                "Result"=$Result;
                "Criticality"=$test.Criticality;
                "Details"=$test.ReportDetails}
        }

        $Number = $Title.Number
        $Name = $Title.Title
        $Fragments += $Fragment | ConvertTo-Html -PreContent "<h2>$Number $Name</h2>" -Fragment

    }

    $Title = "$($FullName) Baseline Report"
    $AADWarning = "<p> Note: Conditional Access Policy exclusions and additional policy conditions
    may limit a policy's scope more narrowly than desired. Recommend reviewing matching policies
    against the baseline statement to ensure a match between intent and implementation. </p>"
    $NoWarning = "<p><br/></p>"
    Add-Type -AssemblyName System.Web

    $ReporterPath = $PSScriptRoot
    $ReportHTML = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "ReportTemplate.html")
    $ReportHTML = $ReportHTML.Replace("{TITLE}", $Title)
    if ($BaselineName -eq "aad") {
        $ReportHTML = $ReportHTML.Replace("{AADWARNING}", $AADWarning)
        $ReportHTML = $ReportHTML.Replace("{CAPTABLES}", $(Get-CapTable))
    }
    else {
        $ReportHTML = $ReportHTML.Replace("{AADWARNING}", $NoWarning)
        $ReportHTML = $ReportHTML.Replace("{CAPTABLES}", "")
    }

    $MainCSS = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "main.css")
    $ReportHTML = $ReportHTML.Replace("{MAIN_CSS}", "<style>$($MainCSS)</style>")

    $MainJS = Get-Content $(Join-Path -Path $ReporterPath -ChildPath "main.js")
    $ReportHTML = $ReportHTML.Replace("{MAIN_JS}", "<script>$($MainJS)</script>")

    $ReportHTML = $ReportHTML.Replace("{TABLES}", $Fragments)
    $FileName = Join-Path -Path $IndividualReportPath -ChildPath "$($BaselineName)Report.html"
    [System.Web.HttpUtility]::HtmlDecode($ReportHTML) | Out-File $FileName

    $ReportSummary
}

Export-ModuleMember -Function @(
    'New-Report'
)
