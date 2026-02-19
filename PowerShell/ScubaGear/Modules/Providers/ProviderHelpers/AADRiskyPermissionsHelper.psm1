Import-Module -Name $PSScriptRoot/../../Utility/Utility.psm1 -Function Invoke-GraphDirectly, ConvertFrom-GraphHashtable

function Get-ResourcePermissions {
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [hashtable]
        $ResourcePermissionCache,

        [string]
        $ResourceAppId
    )
    try {
        if ($null -eq $ResourcePermissionCache) {
            $ResourcePermissionCache = @{}
        }

        if (-not $ResourcePermissionCache.ContainsKey($ResourceAppId)) {
            # v1.0 Graph endpoint is used here because it contains the oauth2PermissionScopes property
            $result = (
                Invoke-GraphDirectly `
                    -Commandlet "Get-MgServicePrincipal" `
                    -M365Environment $M365Environment `
                    -QueryParams @{
                        '$filter' = "appId eq '$ResourceAppId'"
                        '$select' = "appRoles,oauth2PermissionScopes"
                    }
            ).Value

            $ResourcePermissionCache[$ResourceAppId] = $result
        }
        return $ResourcePermissionCache[$ResourceAppId]
    }
    catch {
        Write-Warning "An error occurred in Get-ResourcePermissions: $($_.Exception.Message)"
        Write-Warning "Stack trace: $($_.ScriptStackTrace)"
        throw $_
    }
}

function Get-RiskyPermissionsJson {
    process {
        try {
            $PermissionsPath = Join-Path -Path ((Get-Item -Path $PSScriptRoot).Parent.Parent.FullName) -ChildPath "Permissions"
            $PermissionsJson = Get-Content -Path (
                Join-Path -Path (Get-Item -Path $PermissionsPath) -ChildPath "RiskyPermissions.json"
            ) | ConvertFrom-Json
        }
        catch {
            Write-Warning "An error occurred in Get-RiskyPermissionsJson: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $PermissionsJson
    }
}

function Format-Permission {
    <#
    .Description
    Returns an API permission from either application/service principal which maps
    to the list of permissions declared in RiskyPermissions.json
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $Json,

        [ValidateNotNullOrEmpty()]
        [string]
        $AppDisplayName,

        [ValidateNotNullOrEmpty()]
        [string]
        $Id,

        [string]
        $RoleType,

        [string]
        $RoleDisplayName,

        [ValidateNotNullOrEmpty()]
        [boolean]
        $IsAdminConsented,

        [ValidateNotNullOrEmpty()]
        [boolean]
        $RequiresAdminConsent
    )
    $Map = @()
    if ($null -ne $RoleType) {
        $RiskyPermissions = $Json.permissions.$AppDisplayName.$RoleType.PSObject.Properties.Name
        $IsRisky = $RiskyPermissions -contains $Id
        $RiskLevel = $Json.permissions.$AppDisplayName.$RoleType.$Id.RiskLevel

        $Map += [PSCustomObject]@{
            RoleId                 = $Id
            RoleType               = if ($null -ne $RoleType) { $RoleType } else { $null }
            RoleDisplayName        = if ($null -ne $RoleDisplayName) { $RoleDisplayName } else { $null }
            ApplicationDisplayName = $AppDisplayName
            IsAdminConsented       = $IsAdminConsented
            RequiresAdminConsent   = $RequiresAdminConsent
            IsRisky                = $IsRisky
            RiskLevel              = $RiskLevel
        }
    }
    return $Map
}

function Format-Credentials {
    <#
    .Description
    Returns an array of valid/expired credentials
    .Functionality
    #Internal
    ##>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSReviewUnusedParameter", "IsFromApplication", Justification = "False positive due to variable scoping"
    )]
    param (
        [Object[]]
        $AccessKeys,

        [ValidateNotNullOrEmpty()]
        [boolean]
        $IsFromApplication
    )

    process {
        $ValidCredentials = @()
        $RequiredKeys = @("KeyId", "DisplayName", "StartDateTime", "EndDateTime")
        foreach ($Credential in $AccessKeys) {
            # Only format credentials with the correct keys
            $MissingKeys = $RequiredKeys | Where-Object { -not ($Credential.PSObject.Properties.Name -contains $_) }
            if ($MissingKeys.Count -eq 0) {
                # $Credential is of type PSCredential which is immutable, create a copy
                $CredentialCopy = $Credential | Select-Object -Property `
                    KeyId, DisplayName, StartDateTime, EndDateTime, `
                    @{ Name = "IsFromApplication"; Expression = { $IsFromApplication }}
                $ValidCredentials += $CredentialCopy
            }
        }

        if ($null -eq $AccessKeys -or $AccessKeys.Count -eq 0 -or $ValidCredentials.Count -eq 0) {
            return $null
        }
        return $ValidCredentials
    }
}

function Merge-Credentials {
    <#
    .Description
    Merge credentials from multiple resources into a single resource
    .Functionality
    #Internal
    ##>
    param (
        [Object[]]
        $ApplicationAccessKeys,

        [Object[]]
        $ServicePrincipalAccessKeys
    )

    # Both application/sp objects have key and federated credentials.
    # Conditionally merge the two together, select only application/service principal creds, or none.
    $MergedCredentials = @()
    if ($null -ne $ServicePrincipalAccessKeys -and $null -ne $ApplicationAccessKeys) {
        # Both objects valid
        $MergedCredentials = @($ServicePrincipalAccessKeys) + @($ApplicationAccessKeys)
    }
    elseif ($null -eq $ServicePrincipalAccessKeys -and $null -ne $ApplicationAccessKeys) {
        # Only application credentials valid
        $MergedCredentials = @($ApplicationAccessKeys)
    }
    elseif ($null -ne $ServicePrincipalAccessKeys -and $null -eq $ApplicationAccessKeys) {
        # Only service principal credentials valid
        $MergedCredentials = @($ServicePrincipalAccessKeys)
    }
    else {
        # Neither credentials are valid
        $MergedCredentials = $null
    }
    return $MergedCredentials
}

function Get-ApplicationsWithRiskyPermissions {
    <#
    .Description
    Returns an array of applications where each item contains its Object ID, App ID, Display Name,
    Key/Password/Federated Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [hashtable]
        $ResourcePermissionCache
    )
    process {
        try {
            $RiskyPermissionsJson = Get-RiskyPermissionsJson
            # Get all applications in the tenant
            $Applications = (Invoke-GraphDirectly -commandlet "Get-MgBetaApplication" -M365Environment $M365Environment).Value
            $ApplicationResults = @()
            foreach ($App in $Applications) {
                # `AzureADMyOrg` = single tenant; `AzureADMultipleOrgs` = multi tenant
                $IsMultiTenantEnabled = $false
                if ($App.SignInAudience -eq "AzureADMultipleOrgs") { $IsMultiTenantEnabled = $true }

                # Map application permissions against RiskyPermissions.json
                $MappedPermissions = @()
                foreach ($Resource in $App.RequiredResourceAccess) {
                    # Returns both application and delegated permissions
                    $Roles = $Resource.ResourceAccess
                    $ResourceAppId = $Resource.ResourceAppId

                    $ResourceAppPermissions = Get-ResourcePermissions `
                        -M365Environment $M365Environment `
                        -ResourcePermissionCache $ResourcePermissionCache `
                        -ResourceAppId $ResourceAppId

                    if ($null -eq $ResourceAppPermissions) {
                        Write-Warning "No permissions found for resource app ID: $ResourceAppId"
                        continue
                    }

                    # Additional processing is required to determine if a permission is admin consented.
                    # Initially assume admin consent is false since we reference the application's manifest,
                    # then update the value later when its compared to service principal permissions.
                    $IsAdminConsented = $false

                    # Only map on resources stored in RiskyPermissions.json file
                    if ($RiskyPermissionsJson.resources.PSObject.Properties.Name -contains $ResourceAppId) {
                        foreach ($Role in $Roles) {
                            $ResourceDisplayName = $RiskyPermissionsJson.resources.$ResourceAppId
                            $RoleId = $Role.Id

                            if ($Role.Type -eq "Role") {
                                $ReadableRoleType = "Application"
                                $RoleDisplayName = ($ResourceAppPermissions.appRoles | Where-Object { $_.id -eq $RoleId }).value
                                # Application permissions always require admin consent
                                $RequiresAdminConsent = $true
                            }
                            else {
                                $ReadableRoleType = "Delegated"
                                $OauthScope = $ResourceAppPermissions.oauth2PermissionScopes | Where-Object { $_.id -eq $RoleId }
                                $RoleDisplayName = $OauthScope.value
                                # Delegated permissions require admin consent if oauth2PermissionScopes.type equals "Admin"
                                $RequiresAdminConsent = $OauthScope.type -eq "Admin"
                            }

                            $MappedPermissions += Format-Permission `
                                -Json $RiskyPermissionsJson `
                                -AppDisplayName $ResourceDisplayName `
                                -Id $RoleId `
                                -RoleType $ReadableRoleType `
                                -RoleDisplayName $RoleDisplayName `
                                -IsAdminConsented $IsAdminConsented `
                                -RequiresAdminConsent $RequiresAdminConsent
                        }
                    }
                }

                # Get the application credentials via Invoke-GraphDirectly
                $FederatedCredentials = (Invoke-GraphDirectly -commandlet "Get-MgBetaApplicationFederatedIdentityCredential" -M365Environment $M365Environment -Id $App.Id).Value
                $FederatedCredentialsResults = @()

                if ($FederatedCredentials -is [System.Collections.IEnumerable] -and $FederatedCredentials.Count -gt 0) {
                    foreach ($FederatedCredential in $FederatedCredentials) {
                        $FederatedCredentialsResults += [PSCustomObject]@{
                            Id          = $FederatedCredential.Id
                            Name        = $FederatedCredential.Name
                            Description = $FederatedCredential.Description
                            Issuer      = $FederatedCredential.Issuer
                            Subject     = $FederatedCredential.Subject
                            Audiences   = $FederatedCredential.Audiences | Out-String
                        }
                    }
                }
                else {
                    $FederatedCredentialsResults = $null
                }

                $RiskyPermissions = @($MappedPermissions | Where-Object { $_.IsRisky -eq $true })

                # Exclude applications without risky permissions
                if ($RiskyPermissions.Count -gt 0) {
                    $ApplicationResults += [PSCustomObject]@{
                        ObjectId             = $App.Id
                        AppId                = $App.AppId
                        DisplayName          = $App.DisplayName
                        IsMultiTenantEnabled = $IsMultiTenantEnabled
                        # Credentials from application and service principal objects may get merged in other cmdlets.
                        # Differentiate between the two by setting IsFromApplication=$true
                        KeyCredentials       = Format-Credentials -AccessKeys $App.KeyCredentials -IsFromApplication $true
                        PasswordCredentials  = Format-Credentials -AccessKeys $App.PasswordCredentials -IsFromApplication $true
                        FederatedCredentials = $FederatedCredentialsResults
                        Permissions          = $MappedPermissions
                    }
                }
            }
        } catch {
            Write-Warning "An error occurred in Get-ApplicationsWithRiskyPermissions: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $ApplicationResults
    }
}

function Get-ServicePrincipalsWithRiskyPermissions {
    <#
    .Description
    Returns an array of service principals where each item contains its Object ID, App ID, Display Name,
    Key/Password Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        [hashtable]
        $ResourcePermissionCache
    )
    process {
        try {
            $RiskyPermissionsJson = Get-RiskyPermissionsJson
            $ServicePrincipalResults = @()
            # Get all service principals
            $ServicePrincipals = (Invoke-GraphDirectly -commandlet "Get-MgBetaServicePrincipal" -M365Environment $M365Environment).Value

            # Prepare service principal IDs for batch processing
            $ServicePrincipalIds = $ServicePrincipals.Id

            # Split the service principal IDs into chunks of 20
            $Chunks = [System.Collections.Generic.List[System.Object]]::new()
            $ChunkSize = 20
            for ($i = 0; $i -lt $ServicePrincipalIds.Count; $i += $ChunkSize) {
                $Chunks.Add($ServicePrincipalIds[$i..([math]::Min($i + $ChunkSize - 1, $ServicePrincipalIds.Count - 1))])
            }

            $endpoint = '/beta/$batch'
            $endpoint = (Get-ScubaGearPermissions -CmdletName Connect-MgGraph -Environment $M365Environment -OutAs endpoint) + $endpoint

            # Process each chunk
            foreach ($Chunk in $Chunks) {
                $BatchBody = @{
                    Requests = @()
                }

                foreach ($ServicePrincipalId in $Chunk) {
                    $BatchBody.Requests += @{
                        id     = $ServicePrincipalId
                        method = "GET"
                        url    = "/servicePrincipals/$ServicePrincipalId/appRoleAssignments"
                    }
                }

                # Send the batch request
                $Response = Invoke-MgGraphRequest -Method POST -Uri $endpoint -Body (
                    $BatchBody | ConvertTo-Json -Depth 5
                )

                # Check the response
                if ($Response.responses) {
                    foreach ($Result in $Response.responses) {
                        $ServicePrincipalId = $Result.id
                        $ServicePrincipal = $ServicePrincipals | Where-Object { $_.Id -eq $ServicePrincipalId }
                        $MappedPermissions = @()

                        if ($Result.status -eq 200) {
                            $AppRoleAssignments = $Result.body.value
                            if ($AppRoleAssignments.Count -gt 0) {
                                foreach ($Role in $AppRoleAssignments) {
                                    $ResourceDisplayName = $Role.ResourceDisplayName
                                    $RoleId = $Role.AppRoleId

                                    # Default to true,
                                    # `Get-MgBetaServicePrincipalAppRoleAssignment` only returns admin consented permissions
                                    $IsAdminConsented = $true

                                    # Only map on resources stored in RiskyPermissions.json file
                                    if ($RiskyPermissionsJson.permissions.PSObject.Properties.Name -contains $ResourceDisplayName) {
                                        $ResourceAppId = $RiskyPermissionsJson.resources.PSObject.Properties | Where-Object {
                                            $_.Value -eq $ResourceDisplayName
                                        } | Select-Object -ExpandProperty Name

                                        $ResourceAppPermissions = Get-ResourcePermissions `
                                            -M365Environment $M365Environment `
                                            -ResourcePermissionCache $ResourcePermissionCache `
                                            -ResourceAppId $ResourceAppId

                                        if ($null -eq $ResourceAppPermissions) {
                                            Write-Warning "No permissions found for resource app ID: $ResourceAppId"
                                            continue
                                        }

                                        $ReadableRoleType = $null
                                        $RoleDisplayName = $null

                                        $AppRole = $ResourceAppPermissions.appRoles | Where-Object { $_.id -eq $RoleId }
                                        if ($null -ne $AppRole) {
                                            $ReadableRoleType = "Application"
                                            $RoleDisplayName = $AppRole.value
                                            # Application permissions always require admin consent
                                            $RequiresAdminConsent = $true
                                        }
                                        else {
                                            $OauthScope = $ResourceAppPermissions.oauth2PermissionScopes | Where-Object { $_.id -eq $RoleId }
                                            if ($null -ne $OauthScope) {
                                                $ReadableRoleType = "Delegated"
                                                $RoleDisplayName = $OauthScope.value
                                                # Delegated permissions require admin consent if oauth2PermissionScopes.type equals "Admin"
                                                $RequiresAdminConsent = $OauthScope.type -eq "Admin"
                                            }
                                        }

                                        $MappedPermissions += Format-Permission `
                                            -Json $RiskyPermissionsJson `
                                            -AppDisplayName $ResourceDisplayName `
                                            -Id $RoleId `
                                            -RoleType $ReadableRoleType `
                                            -RoleDisplayName $RoleDisplayName `
                                            -IsAdminConsented $IsAdminConsented `
                                            -RequiresAdminConsent $RequiresAdminConsent
                                    }
                                }
                            }
                        } else {
                            Write-Warning "Error for service principal $($Result.id): $($Result.status)"
                        }

                        $RiskyPermissions = @($MappedPermissions | Where-Object { $_.IsRisky -eq $true })

                        # Exclude service principals without risky permissions
                        if ($RiskyPermissions.Count -gt 0) {
                            $ServicePrincipalResults += [PSCustomObject]@{
                                ObjectId                = $ServicePrincipal.Id
                                AppId                   = $ServicePrincipal.AppId
                                DisplayName             = $ServicePrincipal.DisplayName
                                SignInAudience          = $ServicePrincipal.SignInAudience
                                # Credentials from application and service principal objects may get merged in other cmdlets.
                                # Differentiate between the two by setting IsFromApplication=$false
                                KeyCredentials          = Format-Credentials -AccessKeys $ServicePrincipal.KeyCredentials -IsFromApplication $false
                                PasswordCredentials     = Format-Credentials -AccessKeys $ServicePrincipal.PasswordCredentials -IsFromApplication $false
                                FederatedCredentials    = $ServicePrincipal.FederatedIdentityCredentials
                                Permissions             = $MappedPermissions
                                AppOwnerOrganizationId  = $ServicePrincipal.AppOwnerOrganizationId
                            }
                        }
                    }
                }
            }
        } catch {
            Write-Warning "An error occurred in Get-ServicePrincipalsWithRiskyPermissions: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $ServicePrincipalResults
    }
}

function Get-ServicePrincipalsWithRiskyDelegatedPermissionClassifications {
    <#
    .Description
    Returns an array of service principals where each item contains its Object ID, App ID, Display Name,
    Key/Password Credentials, and risky API permissions.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment
    )
    process {
        try {
            $RiskyPermissionsJson = Get-RiskyPermissionsJson
            $Resources = $RiskyPermissionsJson.resources.PSObject.Properties


            $RiskyDelegatedPermissionClassificationResults = @()
            foreach ($Resource in $Resources) {
                $ResourceId = $Resource.Name
                $ResourceName = $Resource.Value

                $ServicePrincipal = (
                    Invoke-GraphDirectly `
                        -Commandlet "Get-MgServicePrincipal" `
                        -M365Environment $M365Environment `
                        -QueryParams @{
                            '$filter' = "appId eq '$ResourceId'"
                        }
                    ).Value

                $ServicePrincipalId = $ServicePrincipal.id

                $RiskyDelegatedPermissions = $RiskyPermissionsJson.permissions.$ResourceName.Delegated.PSObject.Properties

                $PermClassifications = (Invoke-GraphDirectly -commandlet "Get-MgBetaServicePrincipalDelagatedPermissionClassifications" -M365Environment $M365Environment -ID $ServicePrincipalId).Value

                $RiskyPermClassifications = @()
                foreach ($PermClassification in $PermClassifications) {
                    if ($PermClassification.Classification -eq "low" -and $RiskyDelegatedPermissions.Name -contains $PermClassification.PermissionId) {
                        $RiskyPermClassifications += [PSCustomObject]@{
                            id                = $PermClassification.id
                            permissionId      = $PermClassification.permissionId
                            permissionName    = $PermClassification.permissionName
                            classification    = $PermClassification.classification
                        }
                    }
                }

                if ($RiskyPermClassifications.Count -gt 0) {
                    $RiskyDelegatedPermissionClassificationResults += [PSCustomObject]@{
                        ObjectId                        = $ServicePrincipalId
                        AppId                           = $ResourceId
                        DisplayName                     = $ServicePrincipal.DisplayName
                        RiskyPermClassifications        = $RiskyPermClassifications.permissionName
                    }
                }
            }
            return $RiskyDelegatedPermissionClassificationResults
        } catch {
            Write-Warning "An error occurred in Get-ServicePrincipalsWithRiskyDelegatedPermissionClassifications: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
    }
}

function Format-RiskyApplications {
    <#
    .Description
    Returns an aggregated JSON dataset of application objects, combining data from both applications and
    service principal objects. Key/Password/Federated credentials are combined into a single array, and
    admin consent is reflected in each object's list of associated risky permissions.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $RiskyApps,

        [ValidateNotNullOrEmpty()]
        [Object[]]
        $RiskySPs
    )
    process {
        try {
            $Applications = @()
            foreach ($App in $RiskyApps) {
                $MatchedServicePrincipal = $RiskySPs | Where-Object { $_.AppId -eq $App.AppId }

                # Merge objects if an application and service principal exist with the same AppId
                $MergedObject = @{}
                if ($MatchedServicePrincipal) {
                    # Determine if each risky permission was admin consented or not
                    foreach ($Permission in $App.Permissions) {
                        $ServicePrincipalRoleIds = $MatchedServicePrincipal.Permissions | Select-Object -ExpandProperty RoleId
                        if ($ServicePrincipalRoleIds -contains $Permission.RoleId) {
                            $Permission.IsAdminConsented = $true
                        }
                    }

                    $ObjectIds = [PSCustomObject]@{
                        Application      = $App.ObjectId
                        ServicePrincipal = $MatchedServicePrincipal.ObjectId
                    }

                    $MergedKeyCredentials = Merge-Credentials `
                        -ApplicationAccessKeys $App.KeyCredentials `
                        -ServicePrincipalAccessKeys $MatchedServicePrincipal.KeyCredentials

                    $MergedPasswordCredentials = Merge-Credentials `
                        -ApplicationAccessKeys $App.PasswordCredentials `
                        -ServicePrincipalAccessKeys $MatchedServicePrincipal.PasswordCredentials

                    $MergedFederatedCredentials = Merge-Credentials `
                        -ApplicationAccessKeys $App.FederatedCredentials `
                        -ServicePrincipalAccessKeys $MatchedServicePrincipal.FederatedCredentials

                    $MergedObject = [PSCustomObject]@{
                        ObjectId                 = $ObjectIds
                        AppId                    = $App.AppId
                        DisplayName              = $App.DisplayName
                        IsMultiTenantEnabled     = $App.IsMultiTenantEnabled
                        KeyCredentials           = $MergedKeyCredentials
                        PasswordCredentials      = $MergedPasswordCredentials
                        FederatedCredentials     = $MergedFederatedCredentials
                        Permissions              = $App.Permissions
                    }
                }
                else {
                    $MergedObject = $App
                }

                # Calculate severity score after admin consent for permissions has been determined
                $SeverityInfo = Set-SeverityScore -Object $MergedObject -ObjectType "Application"

                # Add severity info to the merged object
                $MergedObject | Add-Member -MemberType NoteProperty -Name "SeverityScore" -Value $SeverityInfo.TotalScore
                $MergedObject | Add-Member -MemberType NoteProperty -Name "MaxScore" -Value $SeverityInfo.MaxScore
                $MergedObject | Add-Member -MemberType NoteProperty -Name "ScorePercentage" -Value $SeverityInfo.ScorePercentage
                $MergedObject | Add-Member -MemberType NoteProperty -Name "SeverityLevel" -Value $SeverityInfo.SeverityLevel
                $MergedObject | Add-Member -MemberType NoteProperty -Name "ScoreBreakdown" -Value $SeverityInfo.ScoreBreakdown

                $Applications += $MergedObject
            }
        }
        catch {
            Write-Warning "An error occurred in Format-RiskyApplications: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }
        return $Applications
    }
}

function Format-RiskyThirdPartyServicePrincipals {
    <#
    .Description
    Returns a JSON dataset of service principal objects owned by external organizations.
    .Functionality
    #Internal
    ##>
    param (
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $RiskySPs,

        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment,

        # Raw hashtable containing privileged service principals which is keyed by ServicePrincipalId (object id)
        [hashtable]
        $PrivilegedServicePrincipals = @{}
    )
    process {
        try {
            $ServicePrincipals = @()
            $OrgInfo = (Invoke-GraphDirectly -Commandlet "Get-MgBetaOrganization" -M365Environment $M365Environment).Value

            foreach ($ServicePrincipal in $RiskySPs) {
                if ($null -eq $ServicePrincipal) {
                    continue
                }

                # A null value indicates the owner organization is unknown (e.g., agent service principal)
                # and should not be treated as a third-party service principal.
                if ($null -eq $ServicePrincipal.AppOwnerOrganizationId) {
                    Write-Warning "Service principal $($ServicePrincipal.DisplayName) with AppId $($ServicePrincipal.AppId) does not have an AppOwnerOrganizationId. Skipping."
                    continue
                }

                # If the service principal's owner id is not the same as this tenant then it is a 3rd party principal
                if ($ServicePrincipal.AppOwnerOrganizationId -ne $OrgInfo.Id) {
                    $PrivilegedRoles = @()
                    if ($PrivilegedServicePrincipals.ContainsKey($ServicePrincipal.ObjectId)) {
                        $PrivilegedRoles = $PrivilegedServicePrincipals[$ServicePrincipal.ObjectId].roles
                    }

                    # Calculate severity score after admin consent for permissions has been determined
                    $SeverityInfo = Set-SeverityScore `
                        -Object $ServicePrincipal `
                        -ObjectType "ServicePrincipal" `
                        -IsThirdParty `
                        -PrivilegedRoles $PrivilegedRoles

                    # Add severity info to the merged object
                    $ServicePrincipal | Add-Member -MemberType NoteProperty -Name "SeverityScore" -Value $SeverityInfo.TotalScore
                    $ServicePrincipal | Add-Member -MemberType NoteProperty -Name "MaxScore" -Value $SeverityInfo.MaxScore
                    $ServicePrincipal | Add-Member -MemberType NoteProperty -Name "ScorePercentage" -Value $SeverityInfo.ScorePercentage
                    $ServicePrincipal | Add-Member -MemberType NoteProperty -Name "SeverityLevel" -Value $SeverityInfo.SeverityLevel
                    $ServicePrincipal | Add-Member -MemberType NoteProperty -Name "ScoreBreakdown" -Value $SeverityInfo.ScoreBreakdown
                    $ServicePrincipal | Add-Member -MemberType NoteProperty -Name "PrivilegedRoles" -Value $PrivilegedRoles

                    $ServicePrincipals += $ServicePrincipal
                }
            }
        }
        catch {
            Write-Warning "An error occurred in Format-RiskyThirdPartyServicePrincipals: $($_.Exception.Message)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
            throw $_
        }

        return $ServicePrincipals
    }
}

function Get-SeverityWeights {
    <#
    .Description
    Returns the weight factors used in severity score calculation.

    Maximum score is 100 for both applications and service principals.
    The score is composed of the following factors:

    Factor                        App     SP      Notes
    ─────────────────────────────────────────────────────────────────────────────
    Admin consented perms         50      50      Weighted by RiskLevel per permission
    Non-admin consented perms     10      10      Weighted by RiskLevel per permission
    Multi-tenant                  15      -       Applications only
    Third-party SP                -       10      Service principals only
    Privileged roles              -       15      Service principals only
    Password credentials          8       8       + points for long-lived (>180 days)
    Key credentials               4       4       + points for long-lived (>365 days)
    Federated credentials         3       3       No lifetime check
    ─────────────────────────────────────────────────────────────────────────────
    Total                         100     100

    .Functionality
    #Internal
    #>
    return [PSCustomObject]@{
        RiskLevelWeights = @{
            Critical = 25
            High = 15
            Medium = 5
            Low = 2
            Description = "Risk level weights are assigned based on the level of access granted by each permission."
        }

        AdminConsentedRiskyPermissions = @{
            MaxPoints = 50
            Description = "Admin consented permissions pose a higher risk as they have been granted elevated privileges."
        }

        NonAdminConsentedRiskyPermissions = @{
            MaxPoints = 10
            Description = "Non-admin consented permissions pose less of a risk since they have not been granted elevated privileges. However, they can still be granted admin consent in the future and should be monitored."
        }

        # Context factors (25 points max)
        MultiTenant = @{
            Points = 15
            Description = "Multi-tenant applications can be used across multiple organizations, increasing their attack surface."
        }

        ThirdPartyServicePrincipal = @{
            Points = 10
            Description = "Third-party service principals are owned by external organizations and do not fall under the same security policies as internal service principals."
        }

        PrivilegedRoles = @{
            PointsPerRole = 8
            MaxPoints = 15
            Description = "Service principals with privileged roles (e.g., Global Administrator) have elevated permissions and pose a higher risk."
        }

        PasswordCredentials = @{
            PointsPerCredential = 2
            PointsPerLongLivedCredential = 3
            MaxPoints = 8
            ThresholdInDays = 180 # Credentials valid for more than 6 months are considered long-lived
            Description = "Credentials can be used to authenticate as the application/service principal."
        }

        KeyCredentials = @{
            PointsPerCredential = 1
            PointsPerLongLivedCredential = 2
            MaxPoints = 4
            ThresholdInDays = 365 # Key credentials valid for more than 1 year are considered long-lived
            Description = "Key, or certificate credentials, can be used to authenticate as the application/service principal, but are generally more secure than password credentials."
        }

        FederatedCredentials = @{
            PointsPerCredential = 1
            MaxPoints = 3
            Description = "Federated credentials allow an application/service principal to authenticate using an external identity provider."
        }

        Thresholds = @{
            Critical = 70
            High = 40
            Medium = 20
            Description = "Severity thresholds for categorizing applications/service principals based on their calculated severity score."
        }

        MaxScore = @{
            Application = 100
            ServicePrincipal = 100
            Description = "Maximum achievable score varies by object type"
        }
    }
}

function Set-CredentialScore {
    <#
    .Description
    Calculates the severity score for credentials; handles password, key, and federated credentials.
    .Functionality
    #Internal
    #>
    param (
        [PSCredential[]]
        $Credentials,

        [ValidateNotNullOrEmpty()]
        [Object]
        $WeightConfig,

        [switch]
        $CheckLifetime
    )

    $CredentialPoints = 0
    $CredentialCount = 0
    $LongLivedCredentialCount = 0

    if ($null -eq $Credentials -or @($Credentials).Count -eq 0) {
        return @{
            CredentialCount = $CredentialCount
            TotalPoints = $CredentialPoints
        }
    }

    foreach ($Credential in $Credentials) {
        $CredentialCount++

        # Base points for credential existence
        $CredentialPoints += $WeightConfig.PointsPerCredential

        # Add additional points for long-lived credentials (excludes federated)
        if ($CheckLifetime -and $null -ne $Credential.StartDateTime -and $null -ne $Credential.EndDateTime) {
            $Duration = (New-TimeSpan -Start $Credential.StartDateTime -End $Credential.EndDateTime).Days

            if ($Duration -gt $WeightConfig.ThresholdInDays) {
                $CredentialPoints += $WeightConfig.PointsPerLongLivedCredential
                $LongLivedCredentialCount++
            }
        }
    }

    $CredentialPoints = [Math]::Min($CredentialPoints, $WeightConfig.MaxPoints)

    return @{
        CredentialCount = $CredentialCount
        LongLivedCredentialCount = $LongLivedCredentialCount
        TotalPoints = $CredentialPoints
    }
}

function Set-SeverityScore {
    <#
    .Description
    Calculates a severity score for each risky application/service principal based on multiple risk factors:
    - Number of risky permissions
    - Number of admin consented risky permissions
    - Multi-tenant enabled/disabled
    - Third-party service principal (owned externally)
    - Long-lived credentials exceeding max duration
    
    The total severity score is normalized to 100 to factor in different weight distributions for each of the above risk factors.
    .Functionality
    #Internal
    #>
    param (
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $Object,

        [ValidateNotNullOrEmpty()]
        [ValidateSet("Application","ServicePrincipal")]
        [string]
        $ObjectType,

        [switch]
        $IsThirdPartyServicePrincipal,

        [string[]]
        $PrivilegedRoles = @()
    )
    try {
        $Weights = Get-SeverityWeights

        $Score = 0
        $ScoreBreakdown = @{}

        # 1. Determine admin consented risky permission weight factor
        $AdminConsentedRiskyPermissions = @($Object.Permissions | Where-Object {
            $_.IsRisky -eq $true -and $_.IsAdminConsented -eq $true
        })
        $AdminConsentedRawPoints = ($AdminConsentedRiskyPermissions | ForEach-Object {
            $Weights.RiskLevelWeights[$_.RiskLevel]
        } | Measure-Object -Sum).Sum
        $AdminConsentedPoints = [Math]::Min(
            $AdminConsentedRawPoints,
            $Weights.AdminConsentedRiskyPermissions.MaxPoints
        )
        $Score += $AdminConsentedPoints
        $ScoreBreakdown.AdminConsentedRiskyPermissions = [PSCustomObject]@{
            PermissionCount = $AdminConsentedRiskyPermissions.Count
            TotalPoints = $AdminConsentedPoints
        }

        # 2. Determine non-admin consented risky permission weight factor
        $NonAdminConsentedRiskyPermissions = @($Object.Permissions | Where-Object {
            $_.IsRisky -eq $true -and $_.IsAdminConsented -eq $false
        })
        $NonAdminConsentedRawPoints = ($NonAdminConsentedRiskyPermissions | ForEach-Object {
            $Weights.RiskLevelWeights[$_.RiskLevel]
        } | Measure-Object -Sum).Sum
        $NonAdminConsentedPoints = [Math]::Min(
            $NonAdminConsentedRawPoints,
            $Weights.NonAdminConsentedRiskyPermissions.MaxPoints
        )
        $Score += $NonAdminConsentedPoints
        $ScoreBreakdown.NonAdminConsentedRiskyPermissions = [PSCustomObject]@{
            PermissionCount = $NonAdminConsentedRiskyPermissions.Count
            TotalPoints = $NonAdminConsentedPoints
        }

        # 3. Determine privileged roles weight factor (used only for service principals)
        $PrivilegedRolesPoints = 0
        if ($PrivilegedRoles.Count -gt 0) {
            $PrivilegedRolesPoints = [Math]::Min(
                $PrivilegedRoles.Count * $Weights.PrivilegedRoles.PointsPerRole,
                $Weights.PrivilegedRoles.MaxPoints
            )
            $Score += $PrivilegedRolesPoints

            $ScoreBreakdown.PrivilegedRoles = [PSCustomObject]@{
                RoleCount = $PrivilegedRoles.Count
                TotalPoints = $PrivilegedRolesPoints
                Roles = $PrivilegedRoles
            }
        }

        # 4. Determine multi-tenant weight factor (used only for applications)
        $MultiTenantPoints = 0
        if ($Object.IsMultiTenantEnabled -eq $true) {
            $MultiTenantPoints = $Weights.MultiTenant.Points
            $Score += $MultiTenantPoints

            $ScoreBreakdown.MultiTenant = [PSCustomObject]@{
                IsMultiTenantEnabled = $Object.IsMultiTenantEnabled
                TotalPoints = $MultiTenantPoints
            }
        }

        # 5. Determine third-party service principal weight factor (used only for service principals)
        $ThirdPartyServicePrincipalPoints = 0
        if ($IsThirdPartyServicePrincipal -eq $true) {
            $ThirdPartyServicePrincipalPoints = $Weights.ThirdPartyServicePrincipal.Points
            $Score += $ThirdPartyServicePrincipalPoints

            $ScoreBreakdown.ThirdPartyServicePrincipal = [PSCustomObject]@{
                IsThirdPartyServicePrincipal = $IsThirdPartyServicePrincipal
                TotalPoints = $ThirdPartyServicePrincipalPoints
            }
        }

        # 6. Calculate password credential weight factor
        $PasswordCredentialScore = Set-CredentialScore `
            -Credentials $Object.PasswordCredentials `
            -WeightConfig $Weights.PasswordCredentials `
            -CheckLifetime
        
        $Score += $PasswordCredentialScore.TotalPoints
        $ScoreBreakdown.PasswordCredentials = $PasswordCredentialScore

        # 7. Calculate key credential weight factor
        $KeyCredentialScore = Set-CredentialScore `
            -Credentials $Object.KeyCredentials `
            -WeightConfig $Weights.KeyCredentials `
            -CheckLifetime
        
        $Score += $KeyCredentialScore.TotalPoints
        $ScoreBreakdown.KeyCredentials = $KeyCredentialScore

        # 8. Calculate federated credential weight factor
        $FederatedCredentialScore = Set-CredentialScore `
            -Credentials $Object.FederatedCredentials `
            -WeightConfig $Weights.FederatedCredentials `
        
        $Score += $FederatedCredentialScore.TotalPoints
        $ScoreBreakdown.FederatedCredentials = $FederatedCredentialScore

        # Determine severity level
        $SeverityLevel = switch ($Score) {
            { $_ -ge $Weights.Thresholds.Critical } { "Critical"; break }
            { $_ -ge $Weights.Thresholds.High } { "High"; break }
            { $_ -ge $Weights.Thresholds.Medium } { "Medium"; break }
            default { "Low" }
        }

        return [PSCustomObject]@{
            TotalScore = $Score
            MaxScore = $Weights.MaxScore.$ObjectType
            ScorePercentage = [Math]::Round(($Score / $Weights.MaxScore.$ObjectType) * 100, 1)
            SeverityLevel = $SeverityLevel
            ScoreBreakdown = $ScoreBreakdown
        }
    }
    catch {
        Write-Warning "An error occurred in Set-SeverityScore: $($_.Exception.Message)"
        Write-Warning "Stack trace: $($_.ScriptStackTrace)"
        throw $_
    }
}

Export-ModuleMember -Function @(
    "Get-RiskyPermissionsJson",
    "Format-Credentials",
    "Get-ApplicationsWithRiskyPermissions",
    "Get-ServicePrincipalsWithRiskyPermissions",
    "Format-RiskyApplications",
    "Format-RiskyThirdPartyServicePrincipals",
    "Get-ServicePrincipalsWithRiskyDelegatedPermissionClassifications"
)
