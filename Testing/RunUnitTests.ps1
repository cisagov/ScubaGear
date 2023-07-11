[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('AAD','Defender','EXO','OneDrive','PowerPlatform','Sharepoint','Teams')]
    [string[]]$p = "",
    [Parameter()]
    [string[]]$b = "",
    [Parameter()]
    [string[]]$t = "",
    [Parameter()]
    [switch]$h,
    [Parameter()]
    [switch]$v
)

$ScriptName = $MyInvocation.MyCommand
$FilePath = ".\Unit\Rego"

function Show-Menu {
    Write-Output "`n`t==================================== Flags ===================================="
    Write-Output "`n`t-h`tshows help menu"
    Write-Output "`n`t-p`tproduct name, can take a comma-separated list of product names"
    Write-Output "`n`t-b`tbaseline item number, can take a comma-separated list of item numbers"
    Write-Output "`n`t-t`ttest name, can take a comma-separated list of test names"
    Write-Output "`n`t-v`tverbose, verbose opa output"
    Write-Output "`n`t==================================== Usage ===================================="
    Write-Output "`n`tRuning all tests is default, no flags are necessary"
    Write-Output "`t.\$ScriptName"
    Write-Output "`n`tTo run all test cases for specified products, must indicate products with -p"
    Write-Output "`t.\$ScriptName [-p] <products>"
    Write-Output "`n`tTo run all test cases in baseline item numbers, must indicate product with -p"
    Write-Output "`tand baseline item numbers with -b"
    Write-Output "`t.\$ScriptName [-p] <product> [-b] <baseline numbers>"
    Write-Output "`n`tTo run test case for specified baseline item number must indicate product with -p,"
    Write-Output "`tbaseline item numberwith -b, and test cases with -t"
    Write-Output "`t.\$ScriptName [-p] <product> [-b] <baseline number> [-t] <test names>"
    Write-Output "`n`tVerbose flag can be added to any test at beginning or end of command line"
    Write-Output "`t.\$ScriptName [-v]"
    Write-Output "`n`t==================================== Examples ===================================="
    Write-Output "`n`t.\$ScriptName -p AAD, Defender, OneDrive"
    Write-Output "`n`t.\$ScriptName -p AAD -b 01, 2, 10"
    Write-Output "`n`t.\$ScriptName -p AAD -b 01 -t test_IncludeApplications_Incorrect, test_Conditions_Correct"
    Write-Output "`n`t.\$ScriptName -p AAD -v"
    Write-Output "`n`t.\$ScriptName -v -p AAD -b 01 -t test_IncludeApplications_Incorrect`n"
    exit
}

function Get-ErrorMsg {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$Flag
    )

    $FontColor = $host.ui.RawUI.ForegroundColor
    $BackgroundColor = $host.ui.RawUI.BackgroundColor
    $host.ui.RawUI.ForegroundColor = "Red"
    $host.ui.RawUI.BackgroundColor = "Black"
    switch ($Flag[0]) {
        TestNameFlagsMissing {
            Write-Output "ERROR: Missing value(s) to run opa for specific test case(s)"
            Write-Output ".\$ScriptName [-p] <product> [-b] <baseline numbers> [-t] <test names>`n"
        }
        BaselineItemFlagMissing {
            Write-Output "ERROR: Missing value(s) to run opa for specific baseline item(s)"
            Write-Output ".\$ScriptName [-p] <product> [-b] <baseline numbers>`n"
        }
        BaselineItemNumber {
            Write-Output "ERROR: Unrecognized number '$b'"
            Write-Output "Must be an integer (1, 2, 3, ...) or baseline syntax (01, 02, 03..09, 10, ...)`n"
        }
        FileIOError {
            Write-Output "ERROR: '$($Flag[1])' not found`n"
        }
        Default {
            Write-Output "ERROR: Unknown`n"
        }
    }
    $host.ui.RawUI.ForegroundColor = $FontColor
    $host.ui.RawUI.BackgroundColor = $BackgroundColor
    exit
}

function Invoke-Product {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Flag
    )

    foreach($Product in $p) {
        Write-Output "`n==== Testing $Product ===="
        $Directory = Join-Path -Path $FilePath -ChildPath $Product
        ..\opa_windows_amd64.exe test ..\Rego\ $Directory $Flag
    }
    Write-Output ""
}

function Get-ControlGroup {
    [CmdletBinding()]
    param (
        [string] $ControlGroup
    )

    $Tens = @('01','02','03','04','05','06','07','08','09')
    if(($ControlGroup -match "^\d+$") -or ($ControlGroup -in $Tens)) {
        if ([int]$ControlGroup -lt 10) {
            $ControlGroup = $Tens[[int]$ControlGroup-1]
        }
        return $true, $ControlGroup
    }
    return $false
}

function Invoke-ControlGroupItem {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Flag,
        [Parameter()]
        [string]$Product
    )

    Write-Output "`n==== Testing $Product ===="
    foreach($ControlGroup in $b) {
        $Result = Get-ControlGroup $ControlGroup
        if($Result[0]){
            $ControlGroup = $Result[1]
            $Filename = Get-ChildItem $(Join-Path -Path $FilePath -ChildPath $Product) |
            Where-Object {$_.Name -like "*$ControlGroup*" }

            if ($Filename -eq $null){
                Write-Warning "`nNOT FOUND: Control Group $b does not exist in the $Product directory"
            }

            elseif(Test-Path -Path $Filename.Fullname -PathType Leaf) {
                Write-Output "`nTesting Control Group $ControlGroup"
                ..\opa_windows_amd64.exe test ..\Rego\ .\$($Filename.Fullname) $Flag
            }
            else {
                Get-ErrorMsg FileIOError, $Filename
            }
        }
        else {
            Get-ErrorMsg ControlGroupItemNumber
        }
    }
    Write-Output ""
}

function Invoke-TestName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Flag,
        [Parameter()]
        [string]$Product,
        [Parameter()]
        [string]$ControlGroup
    )

    $Result = Get-ControlGroup $ControlGroup
    if($Result[0]){
        $ControlGroup = $Result[1]
        $Filename = Get-ChildItem $(Join-Path -Path $FilePath -ChildPath $Product) |
        Where-Object {$_.Name -like "*$ControlGroup*" }

        if(Test-Path -Path $Filename.Fullname -PathType Leaf) {
            Write-Output "`n==== Testing $Product Control Group $ControlGroup ===="

            foreach($Test in $t) {
                $Match = Select-String -Path $Filename.Fullname -Pattern $Test -Quiet

                if ($Match){
                    Write-Output "`nTesting $Test"
                    ..\opa_windows_amd64.exe test ..\Rego\ .\$($Filename.Fullname) -r $Test $Flag
                }
                else{
                    Write-Warning "`nNOT FOUND: $Test in $Filename"
                }
                
            }
        }
        else {
            Get-ErrorMsg FileIOError, $Filename
        }
    }
    else {
        Get-ErrorMsg ControlGroupItemNumber
    }
    Write-Output ""
}

$pEmpty = $p[0] -eq ""
$bEmpty = $b[0] -eq ""
$tEmpty = $t[0] -eq ""
$Flag = ""

if ($h.IsPresent) {
    Show-Menu
}
if ($v.IsPresent) {
    $Flag = "-v"
}
if($pEmpty -and $bEmpty -and $tEmpty) {
    $p = @('AAD','Defender','EXO','OneDrive','PowerPlatform','Sharepoint','Teams')
    Invoke-Product -Flag $Flag
}
elseif((-not $pEmpty) -and (-not $bEmpty) -and (-not $tEmpty)) {
    if (($p.Count -gt 1) -or ($b.Count -gt 1)) {
        Write-Output "**WARNING** can only take 1 argument for each: product & Control Group item`n...Running test for $($p[0]) and $($b[0]) only"
    }

    Invoke-TestName -Flag $Flag -Product $p[0] -ControlGroup $b[0]
}
elseif((-not $pEmpty) -and (-not $bEmpty) -and $tEmpty) {
    if ($p.Count -gt 1) {
        Write-Output "**WARNING** can only take 1 argument for product`n...Running test for $($p[0]) only"
    }
    Invoke-ControlGroupItem -Flag $Flag -Product $p[0]
}
elseif((-not $pEmpty) -and $bEmpty -and $tEmpty) {
    Invoke-Product -Flag $Flag
}
elseif($pEmpty -or $bEmpty -and (-not $tEmpty)) {
    Get-ErrorMsg TestNameFlagsMissing
}
elseif($pEmpty -and (-not $bEmpty) -and $tEmpty) {
    Get-ErrorMsg ControlGroupItemFlagMissing
}