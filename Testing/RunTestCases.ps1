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
    [switch]$help,
    [Parameter()]
    [switch]$v
)

$Tens = @('01','02','03','04','05','06','07','08','09')
$ScriptName = $MyInvocation.MyCommand

function Show-Menu {
    Write-Output ""
    Write-Output "`t==================================== Flags ===================================="
    Write-Output "`t-h, -help`tshows help menu"
    Write-Output ""
    Write-Output "`t-p`t`tproduct name, can take a comma-separated list of product names"
    Write-Output ""
    Write-Output "`t-b`t`tbaseline item number, can take a comma-separated list of item numbers"
    Write-Output ""
    Write-Output "`t-t`t`ttest name, can take a comma-separated list of test names"
    Write-Output ""
    Write-Output "`t-v`t`tverbose, verbose opa output"
    Write-Output ""
    Write-Output "`t==================================== Usage ===================================="
    Write-Output "`tRuning all tests is default, no flags are necessary"
    Write-Output "`t.\$ScriptName"
    Write-Output ""
    Write-Output "`tTo run all test cases for specified products, must indicate products with -p"
    Write-Output "`t.\$ScriptName [-p] <products>"
    Write-Output ""
    Write-Output "`tTo run all test cases in baseline item numbers, must indicate product with -p"
    Write-Output "`tand baseline item numbers with -b"
    Write-Output "`t.\$ScriptName [-p] <product> [-b] <baseline numbers>"
    Write-Output ""
    Write-Output "`tTo run test case for specified baseline item number must indicate product with -p,"
    Write-Output "`tbaseline item numberwith -b, and test cases with -t"
    Write-Output "`t.\$ScriptName [-p] <product> [-b] <baseline number> [-t] <test names>"
    Write-Output ""
    Write-Output "`tVerbose flag can be added to any test at beginning or end of command line"
    Write-Output "`t.\$ScriptName [-v]"
    Write-Output ""
    Write-Output "`t==================================== Examples ===================================="
    Write-Output "`t.\$ScriptName -p AAD, Defender, OneDrive"
    Write-Output ""
    Write-Output "`t.\$ScriptName -p AAD -b 01, 2, 10"
    Write-Output ""
    Write-Output "`t.\$ScriptName -p AAD -b 01 -t test_IncludeApplications_Incorrect, test_Conditions_Correct"
    Write-Output ""
    Write-Output "`t.\$ScriptName -p AAD -v"
    Write-Output ""
    Write-Output "`t.\$ScriptName -v -p AAD -b 01 -t test_IncludeApplications_Incorrect"
    Write-Output ""
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
            Write-Output ".\$ScriptName [-p] <product> [-b] <baseline numbers> [-t] <test names>"
        }
        BaselineItemFlagMissing {
            Write-Output "ERROR: Missing value(s) to run opa for specific baseline item(s)"
            Write-Output ".\$ScriptName [-p] <product> [-b] <baseline numbers>"
        }
        BaselineItemNumber {
            Write-Output "ERROR: Unrecognized number '$b'"
            Write-Output "Must be an integer (1, 2, 3, ...) or baseline syntax (01, 02, 03..09, 10, ...)"
        }
        FileIOError {
            $Filename = $Flag[1]
            Write-Output "ERROR: '$Filename' not found"
        }
        Default {
            Write-Output "ERROR: Unknown"
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
        [string]$Flag,
        [Parameter()]
        [string[]]$Products
    )

    foreach($Product in $Products) {
        Write-Output "...Testing $Product"
        ..\opa_windows_amd64.exe test ..\Rego\ .\$Product $Flag
        Write-Output ""
    }
}

function Get-Baseline {
    [CmdletBinding()]
    param (
        [string] $Baseline
    )
    if(($Baseline -match "^\d+$") -or ($Baseline -in $Tens)) {
        return $true
    }
    return $false
}

function Invoke-BaselineItem {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Flag
    )
    $Product = $p[0]
    foreach($Baseline in $b) {
        if(Get-Baseline $Baseline){
            if ([int]$Baseline -lt 10) {
                $Baseline = $Tens[[int]$Baseline-1]
            }
            $FileName = $Product+"\"+$Product+"Config2_"+$Baseline+"_test.rego"
            if(Test-Path -Path $FileName -PathType Leaf) {
                Write-Output "...Testing $Baseline"
                ..\opa_windows_amd64.exe test ..\Rego\ .\$FileName $Flag
                Write-Output ""
            }
            else {
                Get-ErrorMsg FileIOError, $FileName
            }
        }
        else {
            Get-ErrorMsg BaselineItemNumber
        }
    }
}

function Invoke-TestName {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Flag
    )

    $Product = $p[0]
    $Baseline = $b[0]
    if(Get-Baseline $Baseline){
        if ([int]$Baseline -lt 10) {
            $Baseline = $Tens[[int]$Baseline-1]
        }
        $FileName = $Product+"\"+$Product+"Config2_"+$Baseline+"_test.rego"
        if(Test-Path -Path $FileName -PathType Leaf) {
            foreach($Test in $t) {
                Write-Output "...Testing $Test"
                ..\opa_windows_amd64.exe test ..\Rego\ .\$FileName -r $Test $Flag
                Write-Output ""
            }
        }
        else {
            Get-ErrorMsg FileIOError, $FileName
        }
    }
    else {
        Get-ErrorMsg BaselineItemNumber
    }
}

$pEmpty = $p[0] -eq ""
$bEmpty = $b[0] -eq ""
$tEmpty = $t[0] -eq ""
$Flag = ""

if (($h.IsPresent) -or ($help.IsPresent)) {
    Show-Menu
}
if ($v.IsPresent) {
    $Flag = "-v"
}
if($pEmpty -and $bEmpty -and $tEmpty) {
    Invoke-Product $Flag @('AAD','Defender','EXO','OneDrive','PowerPlatform','Sharepoint','Teams')
}
elseif((-not $pEmpty) -and (-not $bEmpty) -and (-not $tEmpty)) {
    if (($p.Count -gt 1) -or ($b.Count -gt 1)) {
        $FirstArgP = $p[0]
        $FirstArgB = $b[0]
        Write-Output "**WARNING** can only take 1 argument for each: product & baseline item"
        Write-Output "...Running test for $FirstArgP and $FirstArgB only"
    }
    Invoke-TestName $Flag
}
elseif((-not $pEmpty) -and (-not $bEmpty) -and $tEmpty) {
    if ($p.Count -gt 1) {
        $FirstArgP = $p[0]
        Write-Output "**WARNING** can only take 1 argument for product"
        Write-Output "...Running test for $FirstArgP only"
    }
    Invoke-BaselineItem $Flag
}
elseif((-not $pEmpty) -and $bEmpty -and $tEmpty) {
    Invoke-Product $Flag $p
}
elseif($pEmpty -or $bEmpty -and (-not $tEmpty)) {
    Get-ErrorMsg TestNameFlagsMissing
}
elseif($pEmpty -and (-not $bEmpty) -and $tEmpty) {
    Get-ErrorMsg BaselineItemFlagMissing
}