# Helper functions for functional test
function FromInnerHtml{
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

function Set-NestedMemberValue
{
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

function UpdateDirectorySettingByName{
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

  $Ids = Get-MgDirectorySetting | Where-Object { $_.DisplayName -eq $DisplayName } | Select-Object -Property Id

  foreach($Id in $Ids){
      if (-not ([string]::IsNullOrEmpty($Id.Id))){
          Update-MgDirectorySetting -DirectorySettingId $($Id.Id) @Updates
          break
      }
  }
}