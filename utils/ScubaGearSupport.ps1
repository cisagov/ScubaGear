#Requires -Version 5.1
<#
    .SYNOPSIS
        Gather diagnostic information from previous run(s) into a single
        archive bundle for error reporting and troubleshooting.
    .DESCRIPTION
        Assists development teams in diagnosing issues with the ScubaGear
        assessment tool by generating and bundling up information related
        to one or more previous assessment runs.
    .EXAMPLE
        .\ScubaGearSupport.ps1
    .NOTES
        Executing the script with no switches will cause it to create an archive
        of the latest SCuBAGear run report and result files in the current working
        directory.
#>
[CmdletBinding()]
    param (
        [string]
        $ReportPath = "$($($(Get-Item $PSScriptRoot).Parent).FullName)\Reports",

        [switch]
        $IncludeReports  = $false,

        [switch]
        $AllReports = $false
    )

# Set registry key to inspect
$regPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client'
$regKey = 'AllowBasic'

$Timestamp = Get-Date -Format yyyyMMdd_HHmmss

Write-Debug "Script started from $PSScriptRoot"
Write-Debug "Report Path is $ReportPath"
Write-Debug "Timestamp set as $Timestamp"

## Create bundle directory timestamped inside current directory
try {
    $DiagnosticPath = New-Item -ItemType Directory "ScubaGear_diag_$Timestamp"
    Write-Debug "Created new directory $($DiagnosticPath.FullName)"

    $EnvFile= New-Item -Path $(Join-Path -Path $DiagnosticPath -ChildPath EnvInfo_$Timestamp) -ItemType File
    Write-Debug "Created new environment info file at $($EnvFile.FullName)"
}
catch {
    Write-Error "ERRROR: Could not create diagnostics directory and/or files."
}

## Get environment information
"System Environment information from $Timestamp`n" >> $EnvFile

"PowerShell Information" >> $EnvFile
"----------------------" >> $EnvFile
$PSVersionTable >> $EnvFile
"`n" >> $EnvFile

"WinRM Client Setting" >> $EnvFile
"--------------------" >> $EnvFile
if (Test-Path -LiteralPath $regPath){
    try {
        $allowBasic = Get-ItemPropertyValue -Path $regPath -Name $regKey
    }
    catch [System.Management.Automation.PSArgumentException]{
        "Key, $regKey, was not found`n" >> $EnvFile
    }
    catch{
        "Unexpected error occured attempting to get registry key, $regKey.`n" >> $EnvFile
    }

    "AllowBasic = $allowBasic`n" >> $EnvFile
}
else {
    "Registry path not found: $regPath" >> $EnvFile
}

"Installed PowerShell Modules Available" >> $EnvFile
"--------------------------------------" >> $EnvFile
Get-Module -ListAvailable >> $EnvFile

"Imported PowerShell Modules" >> $EnvFile
"---------------------------" >> $EnvFile
Get-Module >> $EnvFile

if($IncludeReports) {
    # Generate list of ScubaGear Report folder(s) to include in diagnostics
    $ReportList = @()
    if($AllReports) {
        $ReportList = Get-ChildItem -Directory -Path $ReportPath -Filter "M365BaselineConformance*"
    }
    else {
        $ReportList = Get-ChildItem -Directory -Path $ReportPath -Filter "M365BaselineConformance*" |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
    }

    Write-Debug "Reports to Include: $ReportList"

    if($ReportList.Count -eq 0) {
        Write-Warning "No ScubaGear report folders found at $ReportPath."
    }

    # Copy each report folder to diagnostics folder
    foreach ($ReportFolder in $ReportList) {
        Write-Debug "Copying $($ReportFolder.FullName) to diagnostic bundle"
        Copy-Item -Path $ReportFolder.FullName -Destination $DiagnosticPath -Recurse
    }
}

# Create archive bundle of report and results directory
$ZipFile = "$($DiagnosticPath.FullName).zip"

if(Test-Path -Path $ZipFile) {
    Write-Error "ERROR: Diagnostic archive bundle $ZipFile already exists"
}
else {
    Compress-Archive -Path $DiagnosticPath.FullName -DestinationPath $ZipFile
}