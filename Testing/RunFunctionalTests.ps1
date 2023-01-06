<#
    .SYNOPSIS
        Test SCuBA tool against various outputs for functional testing.

    .DESCRIPTION
        This script executes prexisting provider exports against the Rego code and compares output against saved runs for
        regression testing.

    .NOTES
        To run the test on the Rego test results, the user MUST have a folder called BasicRegressionTests saved somewhere in
        their home directory (e.g., Downloads, Documents, Desktop). The BasicRegressionTests folder holds sub folders for each
        provider that is being regression tested based on the product name designation used in ScubaGear.  These include aad,
        defender, exo, onedrive, powerplatform, sharepoint, and teams. Each subfolder contains a pair of files: the provider JSON
        and test results JSON. These files MUST be generated using the main branch and are used as master copy references to
        compare against output generated by new runs of ScubaGear by the functional testing tool.  Each file pair must be renamed
        using the following naming convention:
            - SettingsExport.json renamed to <Provider>ProviderExport-<tennant>-<mmddyyyy>
            - TestResults.json renamed to <Provider>TestResults-<tennant>-<mmddyyyy>

        EXAMPLE
            - AADProviderExport-contoso-01052023
            - AADTestResults-contoso-01052023

    .OUTPUTS
        Text output that indicates how many tests were consistent or different from the saved test results.

    .EXAMPLE
        .\RunFunctionalTests.ps1
        Running against all Rego regression tests is default, no flags necessary.

    .EXAMPLE
        .\RunFunctionalTests.ps1 -p teams,exo,defender,aad
        Runs all test cases for specified products. Products must be specified with -p parameter.
        Valid product names are: aad, defender, exo, onedrive, powerplatform, sharepoint, teams, and '*'.
        Runs all products on default.

    .EXAMPLE
        .\RunFunctionalTests.ps1 -t Rego -p *
        To run a specific type of test, must indicate test with -t. Possible types are: Rego, Full
        Runs Rego regression test on default.

    .EXAMPLE
        .\RunFunctionalTests.ps1 -a Simple
        To run a predefined set of tests, must indicate type with -a. Possible types are: Simple, Minimum, Extreme
        CAUTION when using Extreme, there are 1957 test cases. Can be used when running against tenant or Rego regression test

    .EXAMPLE
        .\RunFunctionalTests.ps1 -o .\Functional\Reports
        Enter the file path for the SCuBA working directory. This is where the ProviderExport, TestResults, and Report will be generated by the tool.
        The default path is .\Functional\Reports.

    .EXAMPLE
        .\RunFunctionalTests.ps1 -s .\Functional\Archive
        Enter the file path for where the test results from the Rego regression test will be saved. The default path is .\Functional\Archive.

    .EXAMPLE
        .\RunFunctionalTests.ps1 -i .\BasicRegressionTests
        Enter the directory path where the saved provider exports & test results are for the rego test. The default path is .\Functional\BasicRegressionTests

    .EXAMPLE
        .\RunFunctionalTests.ps1 -v
        Outputs the verbose results for the test.

    .EXAMPLE
        .\RunFunctionalTests.ps1 -q $false
        Choose to supress the reports from open immediately after generation.
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'VerboseOutput',
    Justification = 'variable is used in another scope')]

[CmdletBinding()]
param (
    <#
        .PARAMETER Products
            Takes a comma seperated list of product names to run the script
            against: 'teams', 'exo', 'defender', 'aad', 'powerplatform', 'sharepoint', 'onedrive', '*'. Runs all on default.
        #>
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('teams', 'exo', 'defender', 'aad', 'powerplatform', 'sharepoint', 'onedrive', '*', IgnoreCase = $false)]
    [Alias('p')]
    [string[]]$Products = '*',

    <#
        .PARAMETER TestType
            Takes the user's selection of test type: Rego, Full. Runs Rego on default.
        #>
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Rego', 'Full')]
    [Alias('t')]
    [string]$TestType = 'Rego',

    <#
        .PARAMETER Auto
            Takes the user's selection of auto test type: Simple, Minimum, Extreme.
        #>
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Simple', 'Minimum', 'Extreme')]
    [Alias('a')]
    [string]$Auto = '',

    <#
        .PARAMETER Out
            Takes the user's selection of SCuBA's working directory.
        #>
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Alias('o')]
    [string]$Out = '.\Functional\Reports',

    <#
        .PARAMETER Save
            Takes the user's selection of where test results from regression test is to be saved.
        #>
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Alias('s')]
    [string]$Save = '.\Functional\Archive',

    <#
        .PARAMETER RegressionTests
            Takes the directory path to the Regression Tests.
        #>
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Alias('i')]
    [string]$RegressionTests = (Join-Path -Path $Home -ChildPath 'BasicRegressionTests'),

    <#
        .PARAMETER VerboseOutput
            Prints the verbose output.
        #>
    [Parameter(Mandatory = $false)]
    [Alias('v')]
    [switch]$VerboseOutput,

    <#
        .PARAMETER Quiet
            Runs SCuBA in silent mode so the reports do not open immediately after generation.
        #>
    [Parameter(Mandatory = $false)]
    [Alias('q')]
    [switch]$Quiet
)

function Compare-Results {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Filename
    )

    $ResultRegression = $Filename -replace 'ProviderExport', 'TestResults'
    $RegressionJson = Get-Content $ResultRegression | ConvertFrom-Json
    $TestResultFile = Get-ChildItem $Out -Filter *.json | Where-Object { $_.Name -match 'TestResults' } | Select-Object Fullname
    $ResultNew = Get-SavedFilename $ResultRegression
    Copy-Item -Path $TestResultFile.Fullname -Destination $ResultNew

    if (Confirm-FileExists $ResultNew) {
        $NewJson = Get-Content $ResultNew | ConvertFrom-Json

        if (($RegressionJson | ConvertTo-Json -Compress) -eq ($NewJson | ConvertTo-Json -Compress)) {
            return "`n`t$(Split-Path -Path $ResultRegression -Leaf -Resolve) : CONSISTENT"
        }
        else {
            try {
                code --diff $ResultRegression $ResultNew
            }
            catch {
                Compare-Object (($RegressionJson | ConvertTo-Json) -split '\r?\n') (($NewJson | ConvertTo-Json) -split '\r?\n')
                Write-Output "`n==== $(Split-Path -Path $ResultRegression -Leaf -Resolve) vs $(Split-Path -Path $ResultNew -Leaf -Resolve) ====`n" | Out-Host
            }
        }

        return "`n`t$(Split-Path -Path $ResultRegression -Leaf -Resolve) : DIFFERENT"
    }
}

function Confirm-FileExists {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Filename
    )

    if (Test-Path -Path $Filename -PathType Leaf) {
        return $true
    }
    else {
        Write-Warning "$Filename not found`nSkipping......`n" | Out-Host
    }
    return $false
}

function Get-SavedFilename {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Filepath
    )

    $Filename = Split-Path -Path $Filepath -Leaf -Resolve
    $Date = Get-Date -Format 'MMddyyyy'
    $NewFilename = $Filename -replace '[0-9]+\.json', ($Date + '.json')

    return Join-Path -Path (Get-Item $Save) -ChildPath $NewFilename
}

function Get-ProviderExportFiles {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    try {
        $TestFiles = (Get-ChildItem  $FilePath -ErrorAction Stop | Where-Object { $_.Name -match 'ProviderExport' } | Select-Object FullName).FullName
        return $true, $TestFiles
    }
    catch {
        Write-Warning "$Product is missing, no files for Rego test found`nSkipping......`n" | Out-Host
    }

    return $false
}

function Write-RegoOutput {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('aad', 'defender', 'exo', 'onedrive', 'powerplatform', 'sharepoint', 'teams', '*', IgnoreCase = $false)]
        [string[]]$Products,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$RegoResults
    )

    if ($VerboseOutput.IsPresent) {
        Write-Output "`n`t=== Testing @($($Products -join ",")) ===$($RegoResults[2])"
    }
    elseif ($Result[3] -ne "") {
        Write-Output "`n`t=== Testing @($($Products -join ",")) ===$($RegoResults[3])"
    }
}

function Read-AutoFile {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Filename
    )

    $Result = @(0, 0)
    $LogIn = $true
    if ($TestType -eq 'Full') {
        if ($Quiet.IsPresent -eq $false) {
            $Quiet = Confirm-UserSelection 'Do you want reports to open immediately after generation [y/n]'
        }
    }

    if (Confirm-FileExists $Filename) {
        foreach ($Products in Get-Content $Filename) {
            if ($TestType -eq 'Full') {
                Invoke-Full $Products -LogIn $LogIn -Silent $Quiet
                $LogIn = $false
            }
            elseif ($TestType -eq 'Rego') {
                $Result = Invoke-Rego -Products $Products -PassCount $Result[0] -TotalCount $Result[1]
            }
        }
        if (($TestType -eq 'Rego') -and ($Result[1] -gt 0)) {
            Write-RegoOutput $Products $Result
            Write-Output "`n`tCONSISTENT $($Result[0])/$($Result[1])`n"
        }
    }
}

function Invoke-Rego {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('aad', 'defender', 'exo', 'onedrive', 'powerplatform', 'sharepoint', 'teams', '*', IgnoreCase = $false)]
        [string[]]$Products,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]$PassCount,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]$TotalCount
    )

    $ExportFilename = Join-Path -Path $Out -ChildPath 'ProviderSettingsExport.json'
    $VerboseOutput = ' '
    $FailString = ' '

    foreach ($Product in $Products) {
        $FilePath = Join-Path -Path $RegressionTests -ChildPath $Product
        $FilesFound = Get-ProviderExportFiles $FilePath

        if ($FilesFound[0]) {
            $TotalCount += $FilesFound[1].Length

            foreach ($File in $FilesFound[1]) {

                if (Confirm-FileExists $File) {
                    Copy-Item -Path $File -Destination $ExportFilename

                    if (Confirm-FileExists $ExportFilename) {
                        try {
                            .\Functional\RegoCachedProviderTesting.ps1 -ProductNames $Product -ExportProvider $false -OutPath $Out
                        }
                        catch {
                            Set-Location $PSScriptRoot
                            Write-Error "Unknown problem running '.\Functional\RegoCachedProviderTesting.ps1', please report."
                            exit
                        }
                        Set-Location $PSScriptRoot
                        $ResultString = Compare-Results $File

                        if ($ResultString.Contains('CONSISTENT')) {
                            $PassCount += 1
                        }
                        else {
                            $FailString += $ResultString
                        }

                        $VerboseOutput += $ResultString
                        Remove-Item $ExportFilename
                    }
                }
            }
        }
    }

    return $PassCount, $TotalCount, $VerboseOutput, $FailString
}

function Invoke-Full {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('aad', 'defender', 'exo', 'onedrive', 'powerplatform', 'sharepoint', 'teams', '*', IgnoreCase = $false)]
        [string[]]$Products,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $LogIn = $false,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $Quiet = $True
    )
    try {
        .\Functional\RegoCachedProviderTesting.ps1 -ProductNames $Products -OutPath $Out -LogIn $LogIn -Quiet $Quiet
    }
    catch {
        Set-Location $PSScriptRoot
        Write-Error "Unknown problem running '.\Functional\RegoCachedProviderTesting.ps1', please report."
        exit
    }
    Set-Location $PSScriptRoot

}

function Invoke-Auto {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Simple', 'Minimum', 'Extreme')]
        [string]$Auto
    )

    $Filename = ''

    switch ($Auto) {
        'Extreme' {
            Write-Warning "File has 1957 tests!`n" | Out-Host
            if ((Confirm-UserSelection "Do you wish to continue [y/n]?") -eq $false) {
                Write-Output "Canceling....."
                exit
            }
            Write-Output "Continuing.....`nEnter Ctrl+C to cancel`n"

            $Filename = "Functional\Auto\ExtremeTest.txt"
        }
        'Minimum' {
            $Filename = "Functional\Auto\MinimumTest.txt"
        }
        'Simple' {
            $Filename = "Functional\Auto\SimpleTest.txt"
        }
        Default {
            Write-Error "Uknown auto test '$Auto'"
        }
    }

    Read-AutoFile $Filename
}

function Confirm-Continue {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Prompt
    )

    $Choice = Read-Host -Prompt $Prompt

    if (($Choice -ne 'y') -or ($Choice -ne 'yes')) {
        return $true
    }

    return $false
}

function New-Folders {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Folder
    )

    if ((Test-Path $Folder) -eq $false) {
        New-Item $Folder -ItemType Directory
    }
}

function Get-AbsolutePath {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    $NewFilePath = (Get-ChildItem -Recurse -Filter $(Split-Path -Path $FilePath -Leaf) -Directory -ErrorAction SilentlyContinue -Path $(Split-Path -Path $FilePath)).FullName

    if ($null -eq $NewFilePath) {
        Write-Error "$FilePath NOT FOUND" | Out-Host
        exit
    }
    return $NewFilePath
}

New-Folders $Out
$Out = Get-AbsolutePath $Out

if ($Products[0] -eq '*') {
    [string[]] $Products = ((Get-ChildItem -Path 'Unit\Rego' -Recurse -Directory -Force -ErrorAction SilentlyContinue |
    Select-Object Name).Name).toLower()
}

if ($Auto -ne '') {
    if ($TestType -eq 'Full') {
        Write-Output "COMING SOON: Disabled until defender bug is fixed"
        exit
    }
    Invoke-Auto $Auto
}

elseif ($TestType -eq 'Rego') {
    New-Folders $Save
    $Save = Get-AbsolutePath $Save
    $RegressionTests = Get-AbsolutePath $RegressionTests
    $Result = Invoke-Rego -Products $Products -PassCount 0 -TotalCount 0

    if ($Result[1] -gt 0) {
        Write-RegoOutput $Products $Result
        Write-Output "`n`tCONSISTENT $($Result[0])/$($Result[1])`n"
    }
}

else {
    Write-Output "COMING SOON: Disabled until defender bug is fixed"
    exit
    Invoke-Full -Products Products -LogIn $true -Silent $Quiet
}