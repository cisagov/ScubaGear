<#
    .SYNOPSIS
        Test written Rego Unit tests individually and as a whole

    .DESCRIPTION
        This script executes the files with the format *ControlGroupName*Config_##_test.rego
        that are found within each products folder in the Testing\Unit\Rego directory. You can run
        this script focusing only on one product or multiple such as aad, defender, exo, powerplatform, sharepoint, and teams.

    .EXAMPLE
        .\RunUnitTests.ps1
        Runs every unit test of every product, no flags necessary

    .EXAMPLE
        .\RunUnitTests.ps1 -p teams,sharepoint
        Runs all tests for the specified products. Products must be specified with the -p parameter.
        Valid product names are: aad, defender, exo, powerplatform, sharepoint, and teams.

    .EXAMPLE
        .\RunUnitTests.ps1 -p aad -c 1
        Will run the AADConfig_01_test.rego. When specifying a control group, only one product is able to be used
        at a time.

    .EXAMPLE
        .\RunUnitTests.ps1 -p -teams -c 3 -t test_AllowPublicUsers_Correct
        Will run the specific test inside the TeamsConfig_06_test.rego.
        Only one parameter is allowed for the -t option just as there is only one parameter allowed for the -c option.

#>

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet('AAD','Defender','EXO','PowerPlatform','Sharepoint','Teams')]
    [string[]]$p = "",
    [Parameter()]
    [string[]]$c = "",
    [Parameter()]
    [string[]]$t = "",
    [Parameter()]
    [switch]$v
)

$ScriptName = $MyInvocation.MyCommand
$FilePath = ".\Unit\Rego"
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
            Write-Output ".\$ScriptName [-p] <product> [-c] <control group numbers> [-t] <test names>`n"
        }
        BaselineItemFlagMissing {
            Write-Output "ERROR: Missing value(s) to run opa for specific control group item(s)"
            Write-Output ".\$ScriptName [-p] <product> [-c] <control group numbers>`n"
        }
        BaselineItemNumber {
            Write-Output "ERROR: Unrecognized number '$c'"
            Write-Output "Must be an integer (1, 2, 3, ...) or control group syntax (01, 02, 03..09, 10, ...)`n"
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
    foreach($ControlGroup in $c) {
        $Result = Get-ControlGroup $ControlGroup
        if($Result[0]){
            $ControlGroup = $Result[1]
            $Filename = Get-ChildItem $(Join-Path -Path $FilePath -ChildPath $Product) |
            Where-Object {$_.Name -like "*$ControlGroup*" }

            if ($null -eq $Filename){
                Write-Warning "`nNOT FOUND: Control Group $c does not exist in the $Product directory"
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
$cEmpty = $c[0] -eq ""
$tEmpty = $t[0] -eq ""
$Flag = ""

if ($v.IsPresent) {
    $Flag = "-v"
}
if($pEmpty -and $cEmpty -and $tEmpty) {
    $p = @('AAD','Defender','EXO','PowerPlatform','Sharepoint','Teams')
    Invoke-Product -Flag $Flag
}
elseif((-not $pEmpty) -and (-not $cEmpty) -and (-not $tEmpty)) {
    if (($p.Count -gt 1) -or ($c.Count -gt 1)) {
        Write-Output "**WARNING** can only take 1 argument for each: product & Control Group item`n...Running test for $($p[0]) and $($c[0]) only"
    }

    Invoke-TestName -Flag $Flag -Product $p[0] -ControlGroup $c[0]
}
elseif((-not $pEmpty) -and (-not $cEmpty) -and $tEmpty) {
    if ($p.Count -gt 1) {
        Write-Output "**WARNING** can only take 1 argument for product`n...Running test for $($p[0]) only"
    }
    Invoke-ControlGroupItem -Flag $Flag -Product $p[0]
}
elseif((-not $pEmpty) -and $cEmpty -and $tEmpty) {
    Invoke-Product -Flag $Flag
}
elseif($pEmpty -or $cEmpty -and (-not $tEmpty)) {
    Get-ErrorMsg TestNameFlagsMissing
}
elseif($pEmpty -and (-not $cEmpty) -and $tEmpty) {
    Get-ErrorMsg ControlGroupItemFlagMissing
}