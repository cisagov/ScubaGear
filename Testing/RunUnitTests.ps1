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
    [Parameter(Mandatory=$false)]
    [ValidateSet('AAD','Defender','EXO','PowerPlatform','Sharepoint','Teams')]
    [Alias('p')]
    [string[]]$Products = '*',
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Alias('c')]
    [string[]]$ControlGroups = '*',
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Alias('t')]
    [string[]]$Tests = "*",
    [Parameter(Mandatory=$false)]
    [Alias('v')]
    [switch]$Ver,
    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]
    $ScubaParentDirectory = $env:USERPROFILE,
    [Parameter(Mandatory=$false)]
    [switch]
    $RunAsInstalled
)

$ScubaHiddenHome = Join-Path -Path $ScubaParentDirectory -ChildPath '.scubagear'
$ScubaTools = Join-Path -Path $ScubaHiddenHome -ChildPath 'Tools'
$OPAExe = Join-Path -Path $ScubaTools -ChildPath 'opa_windows_amd64.exe'
$ScriptName = $MyInvocation.MyCommand
$RootPath = Join-Path -Path $PSScriptRoot -ChildPath '../PowerShell/ScubaGear'

if ($RunAsInstalled){
    if ($null -ne (Get-Module -Name ScubaGear)){
        $RootPath = Split-Path (Get-Module -Name ScubaGear).Path -Parent
    }
    else {
        Write-Error "ScubaGear is not installed.  You cannot use RunAsInstalled switch." -ErrorAction 'Stop'
    }
}

$RegoUnitTestPath = Join-Path -Path $RootPath -ChildPath "Testing\Unit\Rego"
$UtilFilename = (Get-ChildItem $RegoUnitTestPath | Where-Object {$_.Name -like "TestAssertions*" }).FullName
$RegoPolicyPath = Join-Path -Path $RootPath -ChildPath "Rego"

function Get-ErrorMsg {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ErrorCode
    )

    $FontColor = $host.ui.RawUI.ForegroundColor
    $BackgroundColor = $host.ui.RawUI.BackgroundColor
    $host.ui.RawUI.ForegroundColor = "Red"
    $host.ui.RawUI.BackgroundColor = "Black"
    switch ($ErrorCode) {
        TestNameFlagMissingInfo {
            Write-Output "ERROR: Missing value(s) to run opa for specific test case(s)"
            Write-Output ".\$ScriptName [-p] <product> [-c] <control group number> [-t] <test names>`n"
        }
        ControlGroupFlagMissingInfo {
            Write-Output "ERROR: Missing value(s) to run opa for specific Control Group(s)"
            Write-Output ".\$ScriptName [-p] <product> [-c] <control group numbers>`n"
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
        ControlGroupItemNumber {
            Write-Output "Error: Unrecognized control group"
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
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Flag,

        [Parameter(Mandatory=$true)]
        [ValidateSet('AAD','Defender','EXO','PowerPlatform','Sharepoint','Teams')]
        [string[]]$Products
    )

    foreach($Product in $Products) {
        Write-Output "`n==== Testing $Product ===="
        $ConfigFilename = (Get-ChildItem $(Join-Path -Path $RegoUnitTestPath -ChildPath $Product) |
            Where-Object {$_.Name -like "*BaseConfig*" }).FullName
        $Directory = Join-Path -Path $RegoUnitTestPath -ChildPath $Product
        & $OPAExe test $RegoPolicyPath $Directory .\$ConfigFilename .\$UtilFilename $Flag
    }
    Write-Output ""
}

$pEmpty = $Products[0] -eq "*"
$cEmpty = $ControlGroups[0] -eq "*"
$tEmpty = $Tests[0] -eq "*"
$Flag = ""

if ($v.IsPresent) {
    $Flag = "-v"
}
if($pEmpty) {
    Invoke-Product -Flag $Flag -Products @('AAD','Defender','EXO','PowerPlatform','Sharepoint','Teams')
}
elseif((-not $pEmpty) -and (-not $cEmpty) -and (-not $tEmpty)) {
    if (($Products.Count -gt 1) -or ($ControlGroups.Count -gt 1)) {
        Write-Output "**WARNING** can only take 1 argument for each: Products & Control Groups item`n...Running test for $($Products[0]) and $($ControlGroups[0]) only"
    }

    Invoke-TestName -Flag $Flag -Product $Products[0] -ControlGroup $ControlGroups[0]
}
elseif((-not $pEmpty) -and (-not $cEmpty) -and $tEmpty) {
    if ($Products.Count -gt 1) {
        Write-Output "**WARNING** can only take 1 argument for Products`n...Running test for $($Products[0]) only"
    }
    Invoke-ControlGroupItem -Flag $Flag -Product $Products[0] -ControlGroup $ControlGroups
}
elseif((-not $pEmpty) -and $cEmpty -and $tEmpty) {
    Invoke-Product -Flag $Flag -Product $Products
}
elseif($pEmpty -or $cEmpty -and (-not $tEmpty)) {
    Get-ErrorMsg TestNameFlagMissingInfo
}
elseif($pEmpty -and (-not $cEmpty) -and $tEmpty) {
    Get-ErrorMsg ControlGroupFlagMissingInfo
}