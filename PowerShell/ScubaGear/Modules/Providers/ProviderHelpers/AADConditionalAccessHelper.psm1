class CapHelper {
    <#
    .description
        Class for parsing conditional access policies (Caps) to generate a
        pre-processed version that can be used to generate the HTML table
        of the condiational access policies in the report.
    #>

    <#  The following hashtables are used to map the codes used in the
        API output to human-friendly strings #>
    [System.Collections.Hashtable] $ExternalUserStrings = @{"b2bCollaborationGuest" = "B2B collaboration guest users";
        "b2bCollaborationMember" = "B2B collaboration member users";
        "b2bDirectConnectUser" = "B2B direct connect users";
        "internalGuest" = "Local guest users";
        "serviceProvider" = "Service provider users";
        "otherExternalUser" = "Other external users"}

    [System.Collections.Hashtable] $StateStrings = @{"enabled" = "On";
        "enabledForReportingButNotEnforced" = "Report-only";
        "disabled" = "Off"}

    [System.Collections.Hashtable] $ActionStrings = @{"urn:user:registersecurityinfo" = "Register security info";
        "urn:user:registerdevice" = "Register or join devices"}

    [System.Collections.Hashtable] $ClientAppStrings = @{"exchangeActiveSync" = "Exchange ActiveSync Clients";
        "browser" = "Browser";
        "mobileAppsAndDesktopClients" = "Mobile apps and desktop clients";
        "other" = "Other clients";
        "all" = "all"}

    [System.Collections.Hashtable] $GrantControlStrings = @{"mfa" = "multifactor authentication";
        "compliantDevice" = "device to be marked compliant";
        "domainJoinedDevice" = "Hybrid Azure AD joined device";
        "approvedApplication" = "approved client app";
        "compliantApplication" = "app protection policy";
        "passwordChange" = "password change"}

    [System.Collections.Hashtable] $CondAccessAppControlStrings = @{"monitorOnly" = "Monitor only";
        "blockDownloads" = "Block downloads";
        "mcasConfigured" = "Use custom policy"}

    [string[]] GetMissingKeys([System.Object]$Obj, [string[]] $Keys) {
        <#
        .Description
        Returns a list of the keys in $Keys are not members of $Obj. Used
        to validate the structure of the conditonal access policies.
        .Functionality
        Internal
        #>
        $Missing = @()
        if ($null -eq $Obj) {
            # Note that $null needs to come first in the above check to keep the
            # linter happy. "$null should be on the left side of equality comparisons"
            return $Missing
        }
        foreach ($Key in $Keys) {
            $HasKey = [bool]($Obj.PSobject.Properties.name -match $Key)
            if (-not $HasKey) {
                $Missing += $Key
            }
        }
        return $Missing
    }

    [string[]] GetIncludedUsers([System.Object]$Cap) {
        <#
        .Description
        Parses a given conditional access policy (Cap) to generate the list of included users/roles used in the policy.
        .Functionality
        Internal
        #>

        # Perform some basic validation of the CAP. If some of these values
        # are missing it could indicate that the API has been restructured.
        $Missing = @()
        $Missing += $this.GetMissingKeys($Cap, @("Conditions"))
        $Missing += $this.GetMissingKeys($Cap.Conditions, @("Users"))
        $Missing += $this.GetMissingKeys($Cap.Conditions.Users, @("IncludeGroups",
        "IncludeGuestsOrExternalUsers", "IncludeRoles", "IncludeUsers"))
        if ($Missing.Length -gt 0) {
            Write-Warning "Conditional access policy structure not as expected. The following keys are missing: $($Missing -Join ', ')"
            return @()
        }

        # Begin processing the CAP
        $Output = @()

        $CapIncludedUsers = $Cap.Conditions.Users.IncludeUsers
        if ($CapIncludedUsers -Contains "All") {
            $Output += "All"
        }
        elseif ($CapIncludedUsers -Contains "None") {
            $Output += "None"
        }
        else {
            # Users
            if ($CapIncludedUsers.Length -eq 1) {
                $Output += "1 specific user"
            }
            elseif ($CapIncludedUsers.Length -gt 1) {
                $Output += "$($CapIncludedUsers.Length) specific users"
            }

            # Roles
            $CapIncludedRoles = $Cap.Conditions.Users.IncludeRoles
            if ($Cap.Conditions.Users.IncludeRoles.Length -eq 1) {
                $Output += "1 specific role"
            }
            elseif ($CapIncludedRoles.Length -gt 1) {
                $Output += "$($CapIncludedRoles.Length) specific roles"
            }

            # Groups
            $CapIncludedGroups = $Cap.Conditions.Users.IncludeGroups
            if ($CapIncludedGroups.Length -eq 1) {
                $Output += "1 specific group"
            }
            elseif ($CapIncludedGroups.Length -gt 1) {
                $Output += "$($CapIncludedGroups.Length) specific groups"
            }

            # External/guests
            if ($null -ne $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.ExternalTenants.MembershipKind) {
                $GuestOrExternalUserTypes = $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes -Split ","
                $Output += @($GuestOrExternalUserTypes | ForEach-Object {$this.ExternalUserStrings[$_]})
            }
        }
        return $Output
    }

    [string[]] GetExcludedUsers([System.Object]$Cap) {
        <#
        .Description
        Parses a given conditional access policy (Cap) to generate the list of excluded users/roles used in the policy.
        .Functionality
        Internal
        #>

        # Perform some basic validation of the CAP. If some of these values
        # are missing it could indicate that the API has been restructured.
        $Missing = @()
        $Missing += $this.GetMissingKeys($Cap, @("Conditions"))
        $Missing += $this.GetMissingKeys($Cap.Conditions, @("Users"))
        $Missing += $this.GetMissingKeys($Cap.Conditions.Users, @("ExcludeGroups",
            "ExcludeGuestsOrExternalUsers", "ExcludeRoles", "ExcludeUsers"))
        if ($Missing.Length -gt 0) {
            Write-Warning "Conditional access policy structure not as expected. The following keys are missing: $($Missing -Join ', ')"
            return @()
        }

        # Begin processing the CAP
        $Output = @()

        # Users
        $CapExcludedUsers = $Cap.Conditions.Users.ExcludeUsers
        if ($CapExcludedUsers.Length -eq 1) {
            $Output += "1 specific user"
        }
        elseif ($CapExcludedUsers.Length -gt 1) {
            $Output += "$($CapExcludedUsers.Length) specific users"
        }

        # Roles
        $CapExcludedRoles = $Cap.Conditions.Users.ExcludeRoles
        if ($CapExcludedRoles.Length -eq 1) {
            $Output += "1 specific role"
        }
        elseif ($CapExcludedRoles.Length -gt 1) {
            $Output += "$($CapExcludedRoles.Length) specific roles"
        }

        # Groups
        $CapExcludedGroups = $Cap.Conditions.Users.ExcludeGroups
        if ($CapExcludedGroups.Length -eq 1) {
            $Output += "1 specific group"
        }
        elseif ($CapExcludedGroups.Length -gt 1) {
            $Output += "$($CapExcludedGroups.Length) specific groups"
        }

        # External/guests
        if ($null -ne $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.ExternalTenants.MembershipKind) {
            $GuestOrExternalUserTypes = $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.GuestOrExternalUserTypes -Split ","
            $Output += @($GuestOrExternalUserTypes | ForEach-Object {$this.ExternalUserStrings[$_]})
        }

        # If no users are excluded, rather than display an empty cell, display "None"
        if ($Output.Length -eq 0) {
            $Output += "None"
        }
        return $Output
    }

    [string[]] GetApplications([System.Object]$Cap) {
        <#
        .Description
        Parses a given conditional access policy (Cap) to generate the list of included/excluded applications/actions used in the policy.
        .Functionality
        Internal
        #>

        # Perform some basic validation of the CAP. If some of these values
        # are missing it could indicate that the API has been restructured.
        $Missing = @()
        $Missing += $this.GetMissingKeys($Cap, @("Conditions"))
        $Missing += $this.GetMissingKeys($Cap.Conditions, @("Applications"))
        $Missing += $this.GetMissingKeys($Cap.Conditions.Applications, @("ApplicationFilter",
            "ExcludeApplications", "IncludeApplications",
            "IncludeAuthenticationContextClassReferences", "IncludeUserActions"))
        if ($Missing.Length -gt 0) {
            Write-Warning "Conditional access policy structure not as expected. The following keys are missing: $($Missing -Join ', ')"
            return @()
        }

        # Begin processing the CAP
        $Output = @()

        $CapIncludedActions = $Cap.Conditions.Applications.IncludeUserActions
        $CapAppFilterMode = $Cap.Conditions.Applications.ApplicationFilter.Mode
        $CapIncludedApps = $Cap.Conditions.Applications.IncludeApplications
        if ($CapIncludedApps.Length -gt 0 -or
            $null -ne $CapAppFilterMode) {
            # For "Select what this policy applies to", "Cloud Apps" was  selected
            $Output += "Policy applies to: apps"
            # Included apps:
            if ($CapIncludedApps -Contains "All") {
                $Output += "Apps included: All"
            }
            elseif ($CapIncludedApps -Contains "None") {
                $Output += "Apps included: None"
            }
            elseif ($CapIncludedApps.Length -eq 1) {
                $Output += "Apps included: 1 specific app"
            }
            elseif ($CapIncludedApps.Length -gt 1) {
                $Output += "Apps included: $($CapIncludedApps.Length) specific apps"
            }
            if ($CapAppFilterMode -eq "include") {
                $Output += "Apps included: custom application filter"
            }

            $CapExcludedApps = $Cap.Conditions.Applications.ExcludeApplications
            if ($CapExcludedApps.Length -eq 1) {
                $Output += "Apps excluded: 1 specific app"
            }
            elseif ($CapExcludedApps.Length -gt 1) {
                $Output += "Apps excluded: $($CapExcludedApps.Length) specific apps"
            }
            if ($CapAppFilterMode -eq "exclude") {
                $Output += "Apps excluded: custom application filter"
            }
            if ($CapAppFilterMode -ne "exclude" -and
                $CapExcludedApps.Length -eq 0) {
                    $Output += "Apps excluded: None"
            }
        }
        elseif ($CapIncludedActions.Length -gt 0) {
            # For "Select what this policy applies to", "User actions" was selected
            $Output += "Policy applies to: actions"
            $Output += "User action: $($this.ActionStrings[$CapIncludedActions[0]])"
            # While "IncludeUserActions" is a list, the GUI doesn't actually let you select more than one
            # item at a time, hence "IncludeUserActions[0]" above
        }
        else {
            # For "Select what this policy applies to", "Authentication context" was selected
            $AuthContexts = $Cap.Conditions.Applications.IncludeAuthenticationContextClassReferences
            if ($AuthContexts.Length -eq 1) {
                $Output += "Policy applies to: 1 authentication context"
            }
            else {
                $Output += "Policy applies to: $($AuthContexts.Length) authentication contexts"
            }
        }
        return $Output
    }

    [string[]] GetConditions([System.Object]$Cap) {
        <#
        .Description
        Parses a given conditional access policy (Cap) to generate the list of conditions used in the policy.
        .Functionality
        Internal
        #>

        # Perform some basic validation of the CAP. If some of these values
        # are missing it could indicate that the API has been restructured.
        $Missing = @()
        $Missing += $this.GetMissingKeys($Cap, @("Conditions"))
        $Missing += $this.GetMissingKeys($Cap.Conditions, @("UserRiskLevels",
            "SignInRiskLevels", "Platforms", "Locations", "ClientAppTypes", "Devices"))
        $Missing += $this.GetMissingKeys($Cap.Conditions.Platforms, @("ExcludePlatforms", "IncludePlatforms"))
        $Missing += $this.GetMissingKeys($Cap.Conditions.Locations, @("ExcludeLocations", "IncludeLocations"))
        $Missing += $this.GetMissingKeys($Cap.Conditions.Devices, @("DeviceFilter"))
        if ($Missing.Length -gt 0) {
            Write-Warning "Conditional access policy structure not as expected. The following keys are missing: $($Missing -Join ', ')"
            return @()
        }

        # Begin processing the CAP
        $Output = @()

        # User risk
        $CapUserRiskLevels = $Cap.Conditions.UserRiskLevels
        if ($CapUserRiskLevels.Length -gt 0) {
            $Output += "User risk levels: $($CapUserRiskLevels -Join ', ')"
        }
        # Sign-in risk
        $CapSignInRiskLevels = $Cap.Conditions.SignInRiskLevels
        if ($CapSignInRiskLevels.Length -gt 0) {
            $Output += "Sign-in risk levels: $($CapSignInRiskLevels -Join ', ')"
        }
        # Device platforms
        $CapIncludedPlatforms = $Cap.Conditions.Platforms.IncludePlatforms
        if ($null -ne $CapIncludedPlatforms) {
            $Output += "Device platforms included: $($CapIncludedPlatforms -Join ', ')"
            $CapExcludedPlatforms = $Cap.Conditions.Platforms.ExcludePlatforms
            if ($CapExcludedPlatforms.Length -eq 0) {
                $Output += "Device platforms excluded: none"
            }
            else {
                $Output += "Device platforms excluded: $($CapExcludedPlatforms -Join ', ')"
            }
        }
        # Locations
        $CapIncludedLocations = $Cap.Conditions.Locations.IncludeLocations
        if ($null -ne $CapIncludedLocations) {
            if ($CapIncludedLocations -Contains "All") {
                $Output += "Locations included: all locations"
            }
            elseif ($CapIncludedLocations -Contains "AllTrusted") {
                $Output += "Locations included: all trusted locations"
            }
            elseif ($CapIncludedLocations.Length -eq 1) {
                $Output += "Locations included: 1 specific location"
            }
            else {
                $Output += "Locations included: $($CapIncludedLocations.Length) specific locations"
            }

            $CapExcludedLocations = $Cap.Conditions.Locations.ExcludeLocations
            if ($CapExcludedLocations -Contains "AllTrusted") {
                $Output += "Locations excluded: all trusted locations"
            }
            elseif ($CapExcludedLocations.Length -eq 0) {
                $Output += "Locations excluded: none"
            }
            elseif ($CapExcludedLocations.Length -eq 1) {
                $Output += "Locations excluded: 1 specific location"
            }
            else {
                $Output += "Locations excluded: $($CapExcludedLocations.Length) specific locations"
            }
        }
        # Client Apps
        $ClientApps += @($Cap.Conditions.ClientAppTypes | ForEach-Object {$this.ClientAppStrings[$_]})
        $Output += "Client apps included: $($ClientApps -Join ', ')"
        # Filter for devices
        if ($null -ne $Cap.Conditions.Devices.DeviceFilter.Mode) {
            if ($Cap.Conditions.Devices.DeviceFilter.Mode -eq "include") {
                $Output += "Custom device filter in include mode active"
            }
            else {
                $Output += "Custom device filter in exclude mode active"
            }
        }

        return $Output
    }

    [string] GetAccessControls([System.Object]$Cap) {
        <#
        .Description
        Parses a given conditional access policy (Cap) to generate the list of access controls used in the policy.
        .Functionality
        Internal
        #>

        # Perform some basic validation of the CAP. If some of these values
        # are missing it could indicate that the API has been restructured.
        $Missing = @()
        $Missing += $this.GetMissingKeys($Cap, @("GrantControls"))
        $Missing += $this.GetMissingKeys($Cap.GrantControls, @("AuthenticationStrength",
        "BuiltInControls", "CustomAuthenticationFactors", "Operator", "TermsOfUse"))
        $Missing += $this.GetMissingKeys($Cap.GrantControls.AuthenticationStrength, @("DisplayName"))
        if ($Missing.Length -gt 0) {
            Write-Warning "Conditional access policy structure not as expected. The following keys are missing: $($Missing -Join ', ')"
            return @()
        }

        # Begin processing the CAP
        $Output = ""
        if ($null -ne $Cap.GrantControls.BuiltInControls) {
            if ($Cap.GrantControls.BuiltInControls -Contains "block") {
                $Output = "Block access"
            }
            else {
                $GrantControls = @($Cap.GrantControls.BuiltInControls | ForEach-Object {$this.GrantControlStrings[$_]})
                if ($null -ne $Cap.GrantControls.AuthenticationStrength.DisplayName) {
                    $GrantControls += "authentication strength ($($Cap.GrantControls.AuthenticationStrength.DisplayName))"
                }

                if ($Cap.GrantControls.TermsOfUse.Length -gt 0) {
                    $GrantControls += "terms of use"
                }

                $Output = "Allow access but require $($GrantControls -Join ', ')"
                if ($GrantControls.Length -gt 1) {
                    # If multiple access controls are in place, insert the AND or the OR
                    # before the final access control
                    $Output = $Output.Insert($Output.LastIndexOf(',')+1, " $($Cap.GrantControls.Operator)")
                }
            }
        }

        if ($Output -eq "") {
            $Output = "None"
        }
        return $Output
    }

    [string[]] GetSessionControls([System.Object]$Cap) {
        <#
        .Description
        Parses a given conditional access policy (Cap) to generate the list of session controls used in the policy.
        .Functionality
        Internal
        #>

        # Perform some basic validation of the CAP. If some of these values
        # are missing it could indicate that the API has been restructured.
        $Missing = @()
        $Missing += $this.GetMissingKeys($Cap, @("SessionControls"))
        $Missing += $this.GetMissingKeys($Cap.SessionControls, @("ApplicationEnforcedRestrictions",
            "CloudAppSecurity", "ContinuousAccessEvaluation", "DisableResilienceDefaults",
            "PersistentBrowser", "SignInFrequency"))
        $Missing += $this.GetMissingKeys($Cap.SessionControls.ApplicationEnforcedRestrictions, @("IsEnabled"))
        $Missing += $this.GetMissingKeys($Cap.SessionControls.CloudAppSecurity, @("CloudAppSecurityType",
            "IsEnabled"))
        $Missing += $this.GetMissingKeys($Cap.SessionControls.ContinuousAccessEvaluation, @("Mode"))
        $Missing += $this.GetMissingKeys($Cap.SessionControls.PersistentBrowser, @("IsEnabled", "Mode"))
        $Missing += $this.GetMissingKeys($Cap.SessionControls.SignInFrequency, @("IsEnabled",
            "FrequencyInterval", "Type", "Value"))
        if ($Missing.Length -gt 0) {
            Write-Warning "Conditional access policy structure not as expected. The following keys are missing: $($Missing -Join ', ')"
            return @()
        }

        # Begin processing the CAP
        $Output = @()
        if ($Cap.SessionControls.ApplicationEnforcedRestrictions.IsEnabled) {
            $Output += "Use app enforced restrictions"
        }
        if ($Cap.SessionControls.CloudAppSecurity.IsEnabled) {
            $Mode = $this.CondAccessAppControlStrings[$Cap.SessionControls.CloudAppSecurity.CloudAppSecurityType]
            $Output += "Use Conditional Access App Control ($($Mode))"
        }
        if ($Cap.SessionControls.SignInFrequency.IsEnabled) {
            if ($Cap.SessionControls.SignInFrequency.FrequencyInterval -eq "everyTime") {
                $Output += "Sign-in frequency (every time)"
            }
            else {
                $Value = $Cap.SessionControls.SignInFrequency.Value
                $Unit = $Cap.SessionControls.SignInFrequency.Type
                $Output += "Sign-in frequency (every $($Value) $($Unit))"
            }
        }
        if ($Cap.SessionControls.PersistentBrowser.IsEnabled) {
            $Mode = $Cap.SessionControls.PersistentBrowser.Mode
            $Output += "Persistent browser session ($($Mode) persistent)"
        }
        if ($Cap.SessionControls.ContinuousAccessEvaluation.Mode -eq "disabled") {
            $Output += "Customize continuous access evaluation"
        }
        if ($Cap.SessionControls.DisableResilienceDefaults) {
            $Output += "Disable resilience defaults"
        }
        if ($Output.Length -eq 0) {
            $Output += "None"
        }
        return $Output
    }

    [string] ExportCapPolicies([System.Object]$Caps) {
        <#
        .Description
        Parses the conditional access policies (Caps) to generate a pre-processed version that can be used to
        generate the HTML of the condiational access policies in the report.
        .Functionality
        Internal
        #>
            $Table = @()

            foreach ($Cap in $Caps) {
                $State = $this.StateStrings[$Cap.State]
                $UsersIncluded = $($this.GetIncludedUsers($Cap)) -Join ", "
                $UsersExcluded = $($this.GetExcludedUsers($Cap)) -Join ", "
                $Users = @("Users included: $($UsersIncluded)", "Users excluded: $($UsersExcluded)")
                $Apps = $this.GetApplications($Cap)
                $Conditions = $this.GetConditions($Cap)
                $AccessControls = $this.GetAccessControls($Cap)
                $SessionControls = $this.GetSessionControls($Cap)
                $CapDetails = [pscustomobject]@{
                    "Name" = $Cap.DisplayName;
                    "State" = $State;
                    "Users" = $Users
                    "Apps/Actions" = $Apps;
                    "Conditions" = $Conditions;
                    "Block/Grant Access" = $AccessControls;
                    "Session Controls" = $SessionControls;
                }

                $Table += $CapDetails
            }

            $CapTableJson = ConvertTo-Json $Table
            return $CapTableJson
    }
}

function Get-CapTracker {
    [CapHelper]::New()
}