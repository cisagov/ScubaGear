$UtilityModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Utility/Utility.psm1" -Resolve
Import-Module $UtilityModulePath -Function Get-Utf8NoBom, Set-Utf8NoBom, Invoke-GraphDirectly

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

function Get-NestedProviderValue {
  <#
    .SYNOPSIS
      Reads a value from a provider settings export object using dot/bracket notation.
      Companion to Set-NestedMemberValue — traverses all path segments (including the
      final one) and returns the value at that location.
    .PARAMETER InputObject
      The root PSObject from a parsed ProviderSettingsExport.json.
    .PARAMETER MemberPath
      A dot-delimited path string, supporting array index syntax,
      e.g. "legacy_exchange_service_principal[0].HasKeyCredentials"
  #>
  param(
    [Parameter(Mandatory = $true)]
    [object]$InputObject,

    [Parameter(Mandatory = $true)]
    [string]$MemberPath,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Delimiter = '.'
  )

  process {
    $PathParts = $MemberPath.Split([string[]]@($Delimiter), [System.StringSplitOptions]::None)

    foreach ($m in $PathParts) {
      $IndexedMember = $m.Split([regex]::escape('[]'))

      if ($IndexedMember.Count -eq 1) {
        $InputObject = $InputObject.$m
      }
      elseif ($IndexedMember.Count -gt 1) {
        $InputObject = $InputObject.$($IndexedMember[0])
        $InputObject = $InputObject[[int]($IndexedMember[1])]
      }
      else {
        Write-Error "Failed to Get-NestedProviderValue for path: $MemberPath"
        return $null
      }
    }

    return $InputObject
  }
}

function Add-LegacyExchangeSPKeyCredential {
  <#
    .SYNOPSIS
      Adds a self-signed test key credential to the Office 365 Exchange Online first-party
      service principal (appId 00000002-0000-0ff1-ce00-000000000000) to simulate the
      unmitigated legacy hybrid Exchange configuration. Saves enough state to allow
      Remove-LegacyExchangeSPKeyCredential to clean up only the test-added credential.
    .NOTES
      Stores the generated certificate in $script:LegacyExchangeTestKeyCert.
  #>
  $LegacyExchangeAppId = "00000002-0000-0ff1-ce00-000000000000"

  $SP = (Invoke-GraphDirectly `
    -Commandlet "Get-MgBetaServicePrincipal" `
    -M365Environment $M365Environment `
    -QueryParams @{ '$filter' = "appId eq '$LegacyExchangeAppId'" }
  ).Value

  if ($null -eq $SP) {
    throw "Could not find service principal for appId $LegacyExchangeAppId"
  }

  # Generate a self-signed cert entirely in memory — no disk I/O
  $CertRequest = [System.Security.Cryptography.X509Certificates.CertificateRequest]::new(
    "CN=ScubaGearFunctionalTest",
    [System.Security.Cryptography.RSA]::Create(2048),
    [System.Security.Cryptography.HashAlgorithmName]::SHA256,
    [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
  )

  $Now = [System.DateTimeOffset]::UtcNow
  $Cert = $CertRequest.CreateSelfSigned($Now, $Now.AddDays(1))
  
  Invoke-GraphDirectly `
    -Commandlet "Update-MgServicePrincipal" `
    -M365Environment $M365Environment `
    -Id $SP.Id `
    -Body @{
      keyCredentials = @(
        @{
          type        = "AsymmetricX509Cert"
          usage       = "Verify"
          key         = [System.Convert]::ToBase64String($Cert.RawData)
          displayName = "TestExchangeHybridKeyCredential"
        }
      )
    }

  $script:TestState.LegacyExchangeKeyCredentialAdded = $true
  Write-Debug "Add-LegacyExchangeSPKeyCredential: added cert thumbprint $($Cert.Thumbprint) to SP $($SP.Id)"
}

function Remove-LegacyExchangeSPKeyCredential {
  <#
    .SYNOPSIS
      Removes only the test key credential that was added by
      Add-LegacyExchangeSPKeyCredential. Pre-existing credentials on the service
      principal are left untouched.
  #>
  $LegacyExchangeAppId = "00000002-0000-0ff1-ce00-000000000000"

  if (-not $script:TestState.LegacyExchangeKeyCredentialAdded) {
    Write-Warning "Remove-LegacyExchangeSPKeyCredential: no test key credential to remove."
    return
  }

  $SP = (Invoke-GraphDirectly `
    -Commandlet "Get-MgBetaServicePrincipal" `
    -M365Environment $M365Environment `
    -QueryParams @{ '$filter' = "appId eq '$LegacyExchangeAppId'" }
  ).Value

  if ($null -eq $SP) {
    throw "Could not find service principal for appId $LegacyExchangeAppId"
  }

  Invoke-GraphDirectly `
    -Commandlet "Update-MgServicePrincipal" `
    -M365Environment $M365Environment `
    -Id $SP.Id `
    -Body @{ keyCredentials = @() }

  $script:TestState.LegacyExchangeKeyCredentialAdded = $false
  Write-Debug "Remove-LegacyExchangeSPKeyCredential: removed test key credential from SP $($SP.Id)"
}

function New-DedicatedExchangeHybridApp {
  <#
    .SYNOPSIS
      Creates a test app registration and service principal that mimics the output of
      ConfigureExchangeHybridApplication.ps1 — an app with the full_access_as_app role
      assigned on the Office 365 Exchange Online service principal.
    .NOTES
      Stores the created object IDs in $script:TestState.DedicatedHybridTestAppId and
      $script:TestState.DedicatedHybridTestSPId for use by the cleanup functions.
  #>

  $ExchangeOnlineAppId   = "00000002-0000-0ff1-ce00-000000000000"
  $FullAccessAsAppRoleId = "dc890d15-9560-4a4c-9b7f-a736ec74ec40"
  $DisplayName           = "ScubaGearFunctionalTest-ExchangeHybrid"

  $App = (Invoke-GraphDirectly `
    -Commandlet "New-MgApplication" `
    -M365Environment $M365Environment `
    -Body @{ DisplayName = $DisplayName }
  )

  $SP = (Invoke-GraphDirectly `
    -Commandlet "New-MgServicePrincipal" `
    -M365Environment $M365Environment `
    -Body @{ AppId = $App.AppId }
  )

  $ExchangeOnlineSP = (Invoke-GraphDirectly `
    -Commandlet "Get-MgServicePrincipal" `
    -M365Environment $M365Environment `
    -QueryParams @{ '$filter' = "appId eq '$ExchangeOnlineAppId'" }
  ).Value

  if ($null -eq $ExchangeOnlineSP) {
    throw "Could not find Exchange Online service principal (appId $ExchangeOnlineAppId)"
  }

  Invoke-GraphDirectly `
    -Commandlet "New-MgServicePrincipalAppRoleAssignment" `
    -M365Environment $M365Environment `
    -Id $ExchangeOnlineSP.Id `
    -Body @{
      PrincipalId = $SP.Id
      ResourceId  = $ExchangeOnlineSP.Id
      AppRoleId   = $FullAccessAsAppRoleId
    }

  $script:TestState.DedicatedHybridTestAppId = $App.Id
  $script:TestState.DedicatedHybridTestSPId  = $SP.Id
  Write-Debug "New-DedicatedExchangeHybridApp: created AppId=$($App.Id) SPId=$($SP.Id)"
}

function Remove-DedicatedExchangeHybridApp {
  <#
    .SYNOPSIS
      Removes both the app registration and the service principal created by
      New-DedicatedExchangeHybridApp.
  #>
  if ($null -ne $script:TestState.DedicatedHybridTestSPId) {
    Invoke-GraphDirectly `
      -Commandlet "Remove-MgBetaServicePrincipal" `
      -M365Environment $M365Environment `
      -Id $script:TestState.DedicatedHybridTestSPId
    $script:TestState.DedicatedHybridTestSPId = $null
  }

  if ($null -ne $script:TestState.DedicatedHybridTestAppId) {
    Invoke-GraphDirectly `
      -Commandlet "Remove-MgBetaApplication" `
      -M365Environment $M365Environment `
      -Id $script:TestState.DedicatedHybridTestAppId
    $script:TestState.DedicatedHybridTestAppId = $null
  }
  Write-Debug "Remove-DedicatedExchangeHybridApp: removed test app registration and SP"
}

function Remove-DedicatedExchangeHybridAppRegOnly {
  <#
    .SYNOPSIS
      Removes only the app registration created by New-DedicatedExchangeHybridApp,
      leaving the service principal orphaned. Simulates the scenario where the backing
      app registration for an Exchange hybrid SP has been deleted.
  #>
  if ($null -ne $script:TestState.DedicatedHybridTestAppId) {
    Invoke-GraphDirectly `
      -Commandlet "Remove-MgBetaApplication" `
      -M365Environment $M365Environment `
      -Id $script:TestState.DedicatedHybridTestAppId
    $script:TestState.DedicatedHybridTestAppId = $null
  }
  Write-Debug "Remove-DedicatedExchangeHybridAppRegOnly: removed app registration, SP remains orphaned"
}
