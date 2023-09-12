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

    Write-Host "Input: $InputObject"

    foreach($m in $MemberPath){
        Write-Host "Processing $m"
        $IndexedMember = $m.Split([regex]::escape('[]'))

        Write-Host "Member: $m Count: $($IndexedMember.Count)"
        if ($IndexedMember -eq 1){
            Write-Host "Regular path"
            $InputObject = $InputObject.$m
        }
        elseif ($IndexedMember -gt 1){
            Write-Host "Indexed members: $($IndexedMember[0]) $($IndexedMember[1]) $($IndexedMember[2]) $($IndexedMember[3])"
            $InputObject = $InputObject.$($IndexedMember[0])
            $InputObject.GetType()
            $InputObject = $InputObject[[int]($IndexedMember[1])]
        }
        else {
            Write-Host "BAD..."
        }

        Write-Host "Resolve: $($InputObject)"
    }

    $InputObject.$leaf = $Value
  }
}
