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
        $IncludedUsers = @()
        if ($Cap.Conditions.Users.IncludeUsers -Contains "All") {
            $IncludedUsers += "All"
        }
        elseif ($Cap.Conditions.Users.IncludeUsers -Contains "None") {
            $IncludedUsers += "None"
        }
        else {
            # Users
            if ($Cap.Conditions.Users.IncludeUsers.Length -eq 1) {
                $IncludedUsers += "1 specific user"
            }
            elseif ($Cap.Conditions.Users.IncludeUsers.Length -gt 1) {
                $IncludedUsers += "$($Cap.Conditions.Users.IncludeUsers.Length) specific users"
            }

            # Roles
            if ($Cap.Conditions.Users.IncludeRoles.Length -eq 1) {
                $IncludedUsers += "1 specific role"
            }
            elseif ($Cap.Conditions.Users.IncludeRoles.Length -gt 1) {
                $IncludedUsers += "$($Cap.Conditions.Users.IncludeRoles.Length) specific roles"
            }

            # Groups
            if ($Cap.Conditions.Users.IncludeGroups.Length -eq 1) {
                $IncludedUsers += "1 specific group"
            }
            elseif ($Cap.Conditions.Users.IncludeGroups.Length -gt 1) {
                $IncludedUsers += "$($Cap.Conditions.Users.IncludeGroups.Length) specific groups"
            }

            # External/guests
            if ($null -ne $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.ExternalTenants.MembershipKind) {
                $GuestOrExternalUserTypes = $Cap.Conditions.Users.IncludeGuestsOrExternalUsers.GuestOrExternalUserTypes -Split ","
                $IncludedUsers += @($GuestOrExternalUserTypes | ForEach-Object {$this.ExternalUserStrings[$_]})
            }
        }
        return $IncludedUsers
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
        $ExcludedUsers = @()
        # Users
        if ($Cap.Conditions.Users.ExcludeUsers.Length -eq 1) {
            $ExcludedUsers += "1 specific user"
        }
        elseif ($Cap.Conditions.Users.ExcludeUsers.Length -gt 1) {
            $ExcludedUsers += "$($Cap.Conditions.Users.ExcludeUsers.Length) specific users"
        }

        # Roles
        if ($Cap.Conditions.Users.ExcludeRoles.Length -eq 1) {
            $ExcludedUsers += "1 specific role"
        }
        elseif ($Cap.Conditions.Users.ExcludeRoles.Length -gt 1) {
            $ExcludedUsers += "$($Cap.Conditions.Users.ExcludeRoles.Length) specific roles"
        }

        # Groups
        if ($Cap.Conditions.Users.ExcludeGroups.Length -eq 1) {
            $ExcludedUsers += "1 specific group"
        }
        elseif ($Cap.Conditions.Users.ExcludeGroups.Length -gt 1) {
            $ExcludedUsers += "$($Cap.Conditions.Users.ExcludeGroups.Length) specific groups"
        }

        # External/guests
        if ($null -ne $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.ExternalTenants.MembershipKind) {
            $GuestOrExternalUserTypes = $Cap.Conditions.Users.ExcludeGuestsOrExternalUsers.GuestOrExternalUserTypes -Split ","
            $ExcludedUsers += @($GuestOrExternalUserTypes | ForEach-Object {$this.ExternalUserStrings[$_]})
        }

        # If no users are excluded, rather than display an empty cell, display "None"
        if ($ExcludedUsers.Length -eq 0) {
            $ExcludedUsers += "None"
        }
        return $ExcludedUsers
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
            $Actions += "User action: $($this.ActionStrings[$Cap.Conditions.Applications.IncludeUserActions[0]])"
            # While "IncludeUserActions" is a list, the GUI doesn't actually let you select more than one
            # item at a time, hence "IncludeUserActions[0]" above
        }
        else {
            # For "Select what this policy applies to", "Authentication context" was selected
            $AuthContexts = $Cap.Conditions.Applications.IncludeAuthenticationContextClassReferences
            if ($AuthContexts.Length -eq 1) {
                $Actions += "Policy applies to: 1 authentication context"
            }
            else {
                $Actions += "Policy applies to: $($AuthContexts.Length) authentication contexts"
            }
        }
        return $Actions
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
        $ClientApps += @($Cap.Conditions.ClientAppTypes | ForEach-Object {$this.ClientAppStrings[$_]})
        $Conditions += "Client apps included: $($ClientApps -Join ', ')"
        # Filter for devices
        if ($null -ne $Cap.Conditions.Devices.DeviceFilter.Mode) {
            if ($Cap.Conditions.Devices.DeviceFilter.Mode -eq "include") {
                $Conditions += "Custom device filter in include mode active"
            }
            else {
                $Conditions += "Custom device filter in exclude mode active"
            }
        }

        return $Conditions
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
        "BuiltInControls", "CustomAuthenticationFactors", "Operator"))
        $Missing += $this.GetMissingKeys($Cap.GrantControls.AuthenticationStrength, @("DisplayName"))
        if ($Missing.Length -gt 0) {
            Write-Warning "Conditional access policy structure not as expected. The following keys are missing: $($Missing -Join ', ')"
            return @()
        }

        # Begin processing the CAP
        $AccessControls = ""
        if ($null -ne $Cap.GrantControls.BuiltInControls) {
            if ($Cap.GrantControls.BuiltInControls -Contains "block") {
                $AccessControls = "Block access"
            }
            else {
                $GrantControls = @($Cap.GrantControls.BuiltInControls | ForEach-Object {$this.GrantControlStrings[$_]})
                if ($null -ne $Cap.GrantControls.AuthenticationStrength.DisplayName) {
                    $GrantControls += "authentication strength ($($Cap.GrantControls.AuthenticationStrength.DisplayName))"
                }

                $AccessControls = "Allow access but require $($GrantControls -Join ', ')"
                if ($GrantControls.Length -gt 1) {
                    # If multiple access controls are in place, insert the AND or the OR
                    # before the final access control
                    $AccessControls = $AccessControls.Insert($AccessControls.LastIndexOf(',')+1, " $($Cap.GrantControls.Operator)")
                }
            }
        }

        if ($AccessControls -eq "") {
            $AccessControls = "None"
        }
        return $AccessControls
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
        $SessionControls = @()
        if ($Cap.SessionControls.ApplicationEnforcedRestrictions.IsEnabled) {
            $SessionControls += "Use app enforced restrictions"
        }
        if ($Cap.SessionControls.CloudAppSecurity.IsEnabled) {
            $Mode = $this.CondAccessAppControlStrings[$Cap.SessionControls.CloudAppSecurity.CloudAppSecurityType]
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
        return $SessionControls
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