$UtilityModulePath = Join-Path -Path $PSScriptRoot -ChildPath "../../../PowerShell/ScubaGear/Modules/Utility/Utility.psm1" -Resolve
Import-Module $UtilityModulePath -Function Get-Utf8NoBom, Set-Utf8NoBom

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
    $First = $First -Replace '<br>', '<br/>'
    $First = $First -Replace '&amp;', '&'
    Write-Debug " First: $First"
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
  if (-not (Test-Path -Path "$OutputFolder/ModifiedProviderSettingsExport.json" -PathType Leaf)){
      Copy-Item -Path "$OutputFolder/ProviderSettingsExport.json" -Destination "$OutputFolder/ModifiedProviderSettingsExport.json"
  }

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

function UpdateCachedConditionalAccessPolicyByName {
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
  $Index = $ConditionalAccessPolicies.indexof($($ConditionalAccessPolicies.Where{ $_.DisplayName -eq $DisplayName }))

  if (-1 -ne $Index) {
    $Updates.Keys | ForEach-Object {
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

function SetAndCheckTenantSetting {
<#
    .SYNOPSIS
      Function executes one script block until the second block registers it as successful or timeout occurs.
    .PARAMETER SetBlock
      Script block used to set the tenant setting value
    .PARAMETER CheckBlock
      A hashtable of key/value pairs used as a splat for the Update-MgBetaDirectorySetting commandlet.
    .PARAMETER Retries
      Number of times to retry the set block before failing (0 - 10)
    .PARAMETER WaitInterval
      Number of seconds to wait before each check, except the first which always checks immediately (0 - 3600)
    .PARAMETER WaitOnFirstCheck
      Delay first check by WaitInterval if true, otherwise check immediately (Default: True)
    .NOTES
      If the check block does not return true after the last retry, function will throw an error.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $SetBlock,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $CheckBlock,
    [Parameter(Mandatory = $false)]
    [ValidateRange(0,10)]
    [int]
    $Retries = 3,
    [Parameter(Mandatory = $false)]
    [ValidateRange(0,3600)]
    [int]
    $WaitInterval = 10,
    [Parameter(Mandatory = $false)]
    [switch]
    $WaitOnFirstCheck = $False
)
    $SetAttempts = 0

    try {
        $SetFunc = [ScriptBlock]::Create($SetBlock)
        $CheckFunc = [ScriptBlock]::Create($CheckBlock)
        do {
            Write-Debug("Running set block: $($SetFunc.Ast.EndBlock)...")
            Invoke-Command -ScriptBlock $SetFunc

            # Sleep if not first check or option to always wait is set
            if($SetAttempts -ne 0 -or $WaitOnFirstCheck) {
                Write-Debug("Sleeping for $WaitInterval seconds...")
                Start-Sleep $WaitInterval
            }
            Write-Debug("Running check block: $($CheckFunc.Ast.EndBlock)...")
            $CheckSucceeded = Invoke-Command -ScriptBlock $CheckFunc
            Write-Verbose("(Attempt $SetAttempts) Check block result = $CheckSucceeded")
            ++$SetAttempts
        } while(-not $CheckSucceeded -and $SetAttempts -lt $Retries)

        if(-not $CheckSucceeded) {
            throw "Unable to set value after $SetAttempts attempts."
        }
    } catch {
        throw "Error executing script block: $_.StackTrace"
    }
}