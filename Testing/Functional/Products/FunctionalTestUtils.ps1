# Helper functions for functional test
function FromInnerHtml{
    <#
    .SYNOPSIS
      Private helper function to convert Inner HTML values format to match expected values format
  #>
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InnerHtml
    )
    process{
        #$NewLine = [System.Environment]::NewLine
        $OutString = $InnerHtml -Replace '<br>', '<br/>'
        $OutString = $OutString -Replace "<a href=""", "<a href='"
        $OutString = $OutString -Replace """>", "'>"
        $OutString
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

  $ProviderExport = Get-Content -Raw "$OutputFolder/ModifiedProviderSettingsExport.json" | ConvertFrom-Json
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
  Set-Content -Path "$OutputFolder/ModifiedProviderSettingsExport.json" -Value $Json
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