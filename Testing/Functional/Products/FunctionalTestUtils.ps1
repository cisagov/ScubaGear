$UtilityModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Utility/Utility.psm1" -Resolve
Import-Module $UtilityModulePath -Function Get-Utf8NoBom, Set-Utf8NoBom

# -----------------------------------------------------------------------
# Power Platform REST wrappers for functional test preconditions
# These replace the removed Microsoft.PowerApps.Administration.PowerShell
# cmdlets. $script:PPBaseUrl and $script:PPAccessToken must be set by
# Products.Tests.ps1 BeforeAll before these functions are called.
# -----------------------------------------------------------------------
function Get-TenantSettings {
    $Response = Invoke-RestMethod -Uri "$script:PPBaseUrl/providers/Microsoft.BusinessAppPlatform/listTenantSettings?api-version=2023-06-01" `
        -Method POST -Headers @{ Authorization = "Bearer $script:PPAccessToken" } -ContentType "application/json"
    return $Response
}

function Set-TenantSettings {
    param([Parameter(Position=0)][object]$Settings, [hashtable]$RequestBody)
    if ($RequestBody) { $Body = $RequestBody | ConvertTo-Json -Depth 10 }
    else              { $Body = $Settings    | ConvertTo-Json -Depth 10 }
    Invoke-RestMethod -Uri "$script:PPBaseUrl/providers/Microsoft.BusinessAppPlatform/scopes/admin/updateTenantSettings?api-version=2023-06-01" `
        -Method POST -Headers @{ Authorization = "Bearer $script:PPAccessToken" } -Body $Body -ContentType "application/json" | Out-Null
}

function Get-AdminPowerAppEnvironment {
    param([switch]$Default)
    $Response = Invoke-RestMethod -Uri "$script:PPBaseUrl/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments?api-version=2023-06-01" `
        -Method GET -Headers @{ Authorization = "Bearer $script:PPAccessToken" }
    if ($Default) {
        return $Response.value | Where-Object { $_.properties.isDefault -eq $true } | Select-Object -First 1 |
               Select-Object @{ Name="EnvironmentName"; Expression={ $_.name } }
    }
    return $Response.value
}

function Get-DlpPolicy {
    $Response = Invoke-RestMethod -Uri "$script:PPBaseUrl/providers/Microsoft.BusinessAppPlatform/scopes/admin/apiPolicies?api-version=2018-11-01" `
        -Method GET -Headers @{ Authorization = "Bearer $script:PPAccessToken" }
    return $Response
}

function Remove-DlpPolicy {
    param([Parameter(ValueFromPipelineByPropertyName=$true)][string]$PolicyName)
    process {
        Invoke-RestMethod -Uri "$script:PPBaseUrl/providers/Microsoft.BusinessAppPlatform/scopes/admin/apiPolicies/$($PolicyName)?api-version=2018-11-01" `
            -Method DELETE -Headers @{ Authorization = "Bearer $script:PPAccessToken" } | Out-Null
    }
}

function New-AdminDlpPolicy {
    param([string]$DisplayName, [string]$EnvironmentName)
    $EnvId = "/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments/$EnvironmentName"
    $Body = @{
        displayName     = $DisplayName
        environmentType = "OnlyEnvironments"
        environments    = @(
            @{ id = $EnvId; name = $EnvironmentName; type = "Microsoft.BusinessAppPlatform/scopes/environments" }
        )
        connectorGroups = @(
            @{ classification = "Confidential"; connectors = @() }
            @{ classification = "General";      connectors = @() }
            @{ classification = "Blocked";      connectors = @() }
        )
        defaultConnectorsClassification = "General"
    } | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri "$script:PPBaseUrl/providers/Microsoft.BusinessAppPlatform/scopes/admin/apiPolicies?api-version=2018-11-01" `
        -Method POST -Headers @{ Authorization = "Bearer $script:PPAccessToken" } -Body $Body -ContentType "application/json" | Out-Null
}

function Get-PowerAppTenantIsolationPolicy {
    param([string]$TenantId)
    $Response = Invoke-RestMethod -Uri "$script:PPBaseUrl/providers/PowerPlatform.Governance/v1/tenants/$TenantId/tenantIsolationPolicy?api-version=2020-06-01" `
        -Method GET -Headers @{ Authorization = "Bearer $script:PPAccessToken" }
    return $Response
}

function Set-PowerAppTenantIsolationPolicy {
    param([string]$TenantId, [object]$TenantIsolationPolicy)
    $Body = $TenantIsolationPolicy | ConvertTo-Json -Depth 10
    Invoke-RestMethod -Uri "$script:PPBaseUrl/providers/PowerPlatform.Governance/v1/tenants/$TenantId/tenantIsolationPolicy?api-version=2020-06-01" `
        -Method PUT -Headers @{ Authorization = "Bearer $script:PPAccessToken" } -Body $Body -ContentType "application/json" | Out-Null
}

# -----------------------------------------------------------------------
# SharePoint Online REST wrapper for functional test preconditions.
# Replaces the removed Microsoft.Online.SharePoint.PowerShell Set-SPOTenant
# cmdlet. $script:SPOAdminUrl and $script:SPOAccessToken must be set by
# Products.Tests.ps1 BeforeAll before this function is called.
# -----------------------------------------------------------------------
function Set-SPOTenant {
    [CmdletBinding()]
    param(
        [string]$SharingCapability,
        [string]$SharingDomainRestrictionMode,
        [string]$SharingBlockedDomainList,
        [string]$SharingAllowedDomainList,
        [string]$DefaultSharingLinkType,
        [string]$DefaultLinkPermission,
        [int]$RequireAnonymousLinksExpireInDays,
        [string]$FileAnonymousLinkType,
        [string]$FolderAnonymousLinkType,
        [bool]$EmailAttestationRequired,
        [int]$EmailAttestationReAuthDays
    )

    # Integer enum mappings required by the SharePoint OData REST API
    $SharingCapabilityMap = @{
        Disabled = 0; ExternalUserSharingOnly = 1; ExistingExternalUserSharingOnly = 2; ExternalUserAndGuestSharing = 3
    }
    $SharingDomainRestrictionModeMap = @{ None = 0; AllowList = 1; BlockList = 2 }
    $DefaultSharingLinkTypeMap       = @{ None = 0; AnonymousAccess = 1; Internal = 2; Direct = 3 }
    $LinkPermissionMap               = @{ None = 0; View = 1; Edit = 2 }

    $Body = @{ "__metadata" = @{ "type" = "Microsoft.Online.SharePoint.TenantAdministration.Tenant" } }

    foreach ($Param in $PSBoundParameters.Keys) {
        $Value = $PSBoundParameters[$Param]
        $Mapped = switch ($Param) {
            'SharingCapability'            { $SharingCapabilityMap[$Value] }
            'SharingDomainRestrictionMode' { $SharingDomainRestrictionModeMap[$Value] }
            'DefaultSharingLinkType'       { $DefaultSharingLinkTypeMap[$Value] }
            'DefaultLinkPermission'        { $LinkPermissionMap[$Value] }
            'FileAnonymousLinkType'        { $LinkPermissionMap[$Value] }
            'FolderAnonymousLinkType'      { $LinkPermissionMap[$Value] }
            default                        { $Value }
        }
        $Body[$Param] = $Mapped
    }

    $Headers = @{
        Authorization    = "Bearer $script:SPOAccessToken"
        Accept           = "application/json;odata=verbose"
        "Content-Type"   = "application/json;odata=verbose"
        "X-HTTP-Method"  = "MERGE"
        "IF-MATCH"       = "*"
    }

    Invoke-RestMethod -Uri "$script:SPOAdminUrl/_api/SPO.Tenant" -Method POST `
        -Headers $Headers -Body ($Body | ConvertTo-Json -Depth 5) -ErrorAction Stop | Out-Null
}

# Helper functions for functional test
function IsEquivalence{
  <#
  .SYNOPSIS
    Private helper function to compare two string for functional equivalence
#>
  param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $First,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $Second
  )
  process{
    # Normalize input strings to avoid brittle HTML comparisons
    $normalize = {
      param($s)
      ($s -replace '<br>', '<br/>' -replace '&amp;', '&' -replace '<[^>]+>', '').Trim()
    }
    $First = & $normalize $First
    $Second = & $normalize $Second

    Write-Debug "First: $First"
    Write-Debug "Second: $Second"
    0 -eq [String]::Compare(
      $First,
      $Second,
      [System.Globalization.CultureInfo]::InvariantCulture,
      [System.Globalization.CompareOptions]::IgnoreSymbols
    )
  }
}
function Set-NestedMemberValue {
  <#
    .SYNOPSIS
      Private helper function to update provider setting export.
  #>
  param(
    [Parameter(Mandatory = $true)]
    [object]$InputObject,

    [Parameter(Mandatory = $true)]
    [string[]]$MemberPath,

    [Parameter(Mandatory = $true)]
    $Value,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Delimiter = '.'
  )

  begin {
    $MemberPath = $MemberPath.Split([string[]]@($Delimiter))
    $leaf = $MemberPath | Select-Object -Last 1
    $MemberPath = $MemberPath | Select-Object -SkipLast 1
  }

  process {

    foreach($m in $MemberPath){
        $IndexedMember = $m.Split([regex]::escape('[]'))

        if ($IndexedMember -eq 1){
            $InputObject = $InputObject.$m
        }
        elseif ($IndexedMember -gt 1){
            $InputObject = $InputObject.$($IndexedMember[0])
            $InputObject = $InputObject[[int]($IndexedMember[1])]
        }
        else {
            Write-Error "Failed to Set-NestedMemberValue"
        }

    }

    $InputObject.$leaf = $Value
  }
}

function LoadProviderExport() {
  <#
    .SYNOPSIS
      Private helper function to read provider settings export from a file.
  #>
  param(
      [Parameter(Mandatory = $true)]
      [ValidateScript({Test-Path -PathType Container $_})]
      [string]
      $OutputFolder
  )
    # Create new settings file to use for modifications if one does not already exist
    # If modified settings file already exists, use as is.
  if (-not (Test-Path -Path "$OutputFolder/ModifiedProviderSettingsExport.json" -PathType Leaf)){
      Copy-Item -Path "$OutputFolder/ProviderSettingsExport.json" -Destination "$OutputFolder/ModifiedProviderSettingsExport.json"
  }

  # Load the modified settings file as it may contain changes from preconditions
  $Content = Get-Utf8NoBom -FilePath "$OutputFolder/ModifiedProviderSettingsExport.json"

  $ProviderExport = $Content | ConvertFrom-Json
  $ProviderExport
}

function Write-ScubaConfig() {
  <#
    .SYNOPSIS
      Private helper function to write scuba config to a file.
  #>
  param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [hashtable]
      $Config
  )

  $ScubaTestConfigPath = Join-Path -Path "C:\Temp" -ChildPath "ScubaTestConfig.json"
  Set-Content -Path $ScubaTestConfigPath -Value ($Config | ConvertTo-Json ) -Force
}

function PublishProviderExport() {
  <#
    .SYNOPSIS
      Private helper function to write provider settings export to a file.
  #>
  param(
      [Parameter(Mandatory = $true)]
      [ValidateScript({Test-Path -PathType Container $_})]
      [string]
      $OutputFolder,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [object]
      $Export
  )
  $Json = $Export | ConvertTo-Json -Depth 10 | Out-String
  Set-Utf8NoBom -Content $Json -Location "$OutputFolder" -FileName "ModifiedProviderSettingsExport.json"
}

function UpdateProviderExport{
  <#
    .SYNOPSIS
      Update an original provider settings export with new values and save a modified copy.
    .PARAMETER Updates
      A hashtable of key value pairs.  The key can be in dot notation format to reference embedded objects and arrays.
    .PARAMETER OutputFolder
      The directory that contains the original provider setting export and the modified copy.
  #>
  param(
      [Parameter(Mandatory = $true)]
      [ValidateNotNull()]
      [hashtable]
      $Updates,
      [Parameter(Mandatory = $true)]
      [ValidateScript({Test-Path -PathType Container $_})]
      [string]
      $OutputFolder
  )

  $ProviderExport = LoadProviderExport($OutputFolder)

  $Updates.Keys | ForEach-Object{
      try {
          $Update = $Updates.Item($_)
          Set-NestedMemberValue -InputObject $ProviderExport -MemberPath $_  -Value $Update
      }
      catch {
          Write-Error "Exception: UpdateProviderExport failed"
      }
  }

  PublishProviderExport -OutputFolder $OutputFolder -Export $ProviderExport

}

function UpdateDirectorySettingByName{
  <#
    .SYNOPSIS
      Wrapper function for the MS Graph commandlet, Update-MgBetaDirectorySetting, to lookup by name for update.
    .PARAMETER DisplayName
      The DisplayName of the Directory Setting to be updated.
    .PARAMETER Updates
      A hashtable of key/value pairs used as a splat for the Update-MgBetaDirectorySetting commandlet.
    .NOTES
      If more than one directory setting has the same DisplayName then only the first is updated.
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DisplayName', Justification = 'Variable is used in ScriptBlock')]
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $DisplayName,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [hashtable]
      $Updates
  )

  $Ids = Get-MgBetaDirectorySetting | Where-Object { $_.DisplayName -eq $DisplayName } | Select-Object -Property Id

  foreach($Id in $Ids){
      if (-not ([string]::IsNullOrEmpty($Id.Id))){
          Update-MgBetaDirectorySetting -DirectorySettingId $($Id.Id) @Updates
          break
      }
  }
}

function RemoveConditionalAccessPolicyByName{
    <#
    .SYNOPSIS
      Wrapper function for the MS Graph commandlet, Remove-MgBetaIdentityConditionalAccessPolicy, to lookup by name for update.
    .PARAMETER DisplayName
      The DisplayName of the conditional access policy to be removed.
    .NOTES
      If more than one conditional access policy has the same DisplayName then only the first is removed.
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DisplayName', Justification = 'Variable is used in ScriptBlock')]
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $DisplayName
  )

  $Ids = Get-MgBetaIdentityConditionalAccessPolicy | Where-Object {$_.DisplayName -match $DisplayName} | Select-Object -Property Id

  foreach($Id in $Ids){
      if (-not ([string]::IsNullOrEmpty($Id.Id))){
          Remove-MgBetaIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $Id.Id
      }
  }
}

function UpdateConditionalAccessPolicyByName{
    <#
    .SYNOPSIS
      Wrapper function for the MS Graph commandlet, Update-MgBetaIdentityConditionalAccessPolicy, to lookup by name for update.
    .PARAMETER DisplayName
      The DisplayName of the Directory Setting to be updated.
    .PARAMETER Updates
      A hashtable of key/value pairs used as a splat for the Update-MgBetaDirectorySetting commandlet.
    .NOTES
      If more than one conditional access policy has the same DisplayName then only the first is updated.
  #>
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'DisplayName', Justification = 'Variable is used in ScriptBlock')]
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $DisplayName,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [hashtable]
      $Updates
  )

  $Ids = Get-MgBetaIdentityConditionalAccessPolicy | Where-Object {$_.DisplayName -match $DisplayName} | Select-Object -Property Id

  foreach($Id in $Ids){
      if (-not ([string]::IsNullOrEmpty($Id.Id))){
          Update-MgBetaIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $Id.Id @Updates
          break
      }
  }
}

function UpdateCachedConditionalAccessPolicyByName{
      <#
    .SYNOPSIS
      Wrapper function to locate a given conditional access policy by name for update within an provider setting export.
    .PARAMETER DisplayName
      The DisplayName of the Directory Setting to be updated.
    .PARAMETER Updates
      A hashtable of key/value pairs used as a splat for the Update-MgBetaDirectorySetting commandlet.
    .PARAMETER OutputFolder
      The folder containing the original and updated provider settings exports.
    .NOTES
      If more than one conditional access policy has the same DisplayName then only the first is updated.
  #>
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $DisplayName,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [hashtable]
      $Updates,
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $OutputFolder
  )

  $ProviderExport = LoadProviderExport($OutputFolder)

  $ConditionalAccessPolicies = $ProviderExport.conditional_access_policies
  $Index = $ConditionalAccessPolicies.indexof($($ConditionalAccessPolicies.Where{$_.DisplayName -eq $DisplayName}))

  if (-1 -ne $Index){
    $Updates.Keys | ForEach-Object{
      try {
          $Update = $Updates.Item($_)
          $Policy = $ConditionalAccessPolicies[$Index]
          Set-NestedMemberValue -InputObject $Policy -MemberPath $_  -Value $Update
      }
      catch {
          Write-Error "Exception:  UpdateCachedConditionalAccessPolicyByName failed"
      }
    }

    PublishProviderExport -OutputFolder $OutputFolder -Export $ProviderExport
  }
  else {
    throw "Could not find CAP: $DisplayName"
  }
}

function LoadTestResults() {
  <#
    .SYNOPSIS
      Wrapper function to load the test results within the given folder.
    .PARAMETER OutputFolder
      The folder containing the outputs of a ScubaGear run.
  #>
  [CmdletBinding()]
  param (
      [Parameter(Mandatory = $true)]
      [ValidateNotNullOrEmpty()]
      [string]
      $OutputFolder
  )
  $IntermediateTestResults = Get-Content "$OutputFolder/TestResults.json" -Raw | ConvertFrom-Json
  $IntermediateTestResults
}

function Get-ExpectedHeaderNames {
    param(
      [string]
      $TableClass
    )
    switch ($TableClass) {
        "caps_table" { 
          return @("","Name","State","Users","Apps/Actions","Conditions","Block/Grant Access","Session Controls")
        }
        "riskyApps_table" {
          return @("","Display Name","Multi-Tenant Enabled","Key Credentials","Password Credentials","Federated Credentials","Permissions")
        }
        "riskyThirdPartySPs_table" {
          return @("","Display Name","Key Credentials","Password Credentials","Federated Credentials","Permissions")
        }
        default {
          return $null 
        }
    }
}

function Get-ExpectedColumnSize {
    param(
      [string]
      $TableClass
    )
    switch ($TableClass) {
        "caps_table" { return 8 }
        "riskyApps_table" { return 7 }
        "riskyThirdPartySPs_table" { return 6 }
        default { return 0 }
    }
}
