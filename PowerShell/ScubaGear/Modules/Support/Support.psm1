function Copy-ScubaBaselineDocument {
    <#
    .SYNOPSIS
    Copy security baselines documents to a user specified location.
    .Description
    This function makes copies of the security baseline documents included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the baselines. Defaults to <user home>\ScubaGear\baselines
    .Example
    Copy-ScubaBaselineDocument
    .Functionality
    Public
    .NOTES
    SuppressMessage for PSReviewUnusedParameter due to linter bug. Open issue to remove if/when fixed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $Destination = (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear"),
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    if (-not (Test-Path -Path $Destination -PathType Container)){
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }

    @("teams", "exo", "defender", "aad", "powerbi", "powerplatform", "sharepoint") | ForEach-Object {
        $SourceFileName = Join-Path -Path $PSScriptRoot -ChildPath "..\..\baselines\$_.md"
        $TargetFileName = Join-Path -Path $Destination -ChildPath "$_.md"
        Copy-Item -Path $SourceFileName -Destination $Destination -Force:$Force -ErrorAction Stop  2> $null
        Set-ItemProperty -Path $TargetFileName -Name IsReadOnly -Value $true
    }
}

function Initialize-SCuBA {
    <#
    .SYNOPSIS
        This script installs the required Powershell modules used by the
        assessment tool
    .DESCRIPTION
        Installs the modules required to support SCuBAGear.  If the Force
        switch is set then any existing module will be re-installed even if
        already at latest version. If the SkipUpdate switch is set then any
        existing module will not be updated to th latest version.
    .EXAMPLE
        Initialize-SCuBA
    .NOTES
        Executing the script with no switches set will install the latest
        version of a module if not already installed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = 'Installs a given module and overrides warning messages about module installation conflicts. If a module with the same name already exists on the computer, Force allows for multiple versions to be installed. If there is an existing module with the same name and version, Force overwrites that version')]
        [switch]
        $Force,

        [Parameter(HelpMessage = 'If specified then modules will not be updated to latest version')]
        [switch]
        $SkipUpdate,

        [Parameter(HelpMessage = 'Do not automatically trust the PSGallery repository for module installation')]
        [switch]
        $DoNotAutoTrustRepository,

        [Parameter(HelpMessage = 'Do not download OPA')]
        [switch]
        $NoOPA,

        [Parameter(Mandatory = $false, HelpMessage = 'The version of OPA Rego to be downloaded, must be in "x.x.x" format')]
        [Alias('version')]
        [string]
        $ExpectedVersion = '0.59.0',

        [Parameter(Mandatory = $false, HelpMessage = 'The operating system the program is running on')]
        [ValidateSet('Windows','MacOS','Linux')]
        [Alias('os')]
        [string]
        $OperatingSystem  = "Windows",

        [Parameter(Mandatory = $false, HelpMessage = 'The file name that the opa executable is to be saved as')]
        [Alias('name')]
        [string]
        $OPAExe = "",

        [Parameter(Mandatory=$false, HelpMessage = 'Directory to contain ScubaGear artifacts. Defaults to <home>.')]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $ScubaParentDirectory = $env:USERPROFILE
    )

    # Set preferences for writing messages
    $PreferenceStack = New-Object -TypeName System.Collections.Stack
    $PreferenceStack.Push($DebugPreference)
    $PreferenceStack.Push($InformationPreference)
    $DebugPreference = "Continue"
    $InformationPreference = "Continue"

    if (-not $DoNotAutoTrustRepository) {
        $Policy = Get-PSRepository -Name "PSGallery" | Select-Object -Property -InstallationPolicy

        if ($($Policy.InstallationPolicy) -ne "Trusted") {
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
            Write-Information -MessageData "Setting PSGallery repository to trusted."
        }
    }

    # Start a stopwatch to time module installation elapsed time
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $RequiredModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "PowerShell\ScubaGear\RequiredVersions.ps1"
    if (Test-Path -Path $RequiredModulesPath) {
        . $RequiredModulesPath
    }

    if ($ModuleList) {
        # Add PowerShellGet to beginning of ModuleList for installing required modules.
        $ModuleList = ,@{
            ModuleName = 'PowerShellGet'
            ModuleVersion = [version] '2.1.0'
            MaximumVersion = [version] '2.99.99999'
        } + $ModuleList
    }
    else {
        throw "Required modules list is required."
    }

    foreach ($Module in $ModuleList) {

        $ModuleName = $Module.ModuleName

        if (Get-Module -ListAvailable -Name $ModuleName) {
            $HighestInstalledVersion = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object Version -First 1).Version
            $LatestVersion = [Version](Find-Module -Name $ModuleName -MinimumVersion $Module.ModuleVersion -MaximumVersion $Module.MaximumVersion).Version

            if ($HighestInstalledVersion -ge $LatestVersion) {
                Write-Debug "${ModuleName}: ${HighestInstalledVersion} already has latest installed."

                if ($Force -eq $true) {
                    Install-Module -Name $ModuleName `
                        -Force `
                        -AllowClobber `
                        -Scope CurrentUser `
                        -MaximumVersion $Module.MaximumVersion
                    Write-Information -MessageData "Re-installing module to latest acceptable version: ${ModuleName}."
                }
            }
            else {
                if ($SkipUpdate -eq $true) {
                    Write-Debug "Skipping update for ${ModuleName}: ${HighestInstalledVersion} to newer version ${LatestVersion}."
                }
                else {
                    Install-Module -Name $ModuleName `
                        -Force `
                        -AllowClobber `
                        -Scope CurrentUser `
                        -MaximumVersion $Module.MaximumVersion
                    $MaxInstalledVersion = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object Version -First 1).Version
                    Write-Information -MessageData "${ModuleName}: ${HighestInstalledVersion} updated to version ${MaxInstalledVersion}."
                }
            }
        }
        else {
            Install-Module -Name $ModuleName `
                -AllowClobber `
                -Scope CurrentUser `
                -MaximumVersion $Module.MaximumVersion
                $MaxInstalledVersion = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object Version -First 1).Version
            Write-Information -MessageData "Installed the latest acceptable version of ${ModuleName}: ${MaxInstalledVersion}."
        }
    }

    if ($NoOPA -eq $true) {
        Write-Debug "Skipping Download for OPA.`n"
    }
    else {
        try {
            Install-OPA -OPAExe $OPAExe -ExpectedVersion $ExpectedVersion -OperatingSystem $OperatingSystem -ScubaParentDirectory $ScubaParentDirectory
        }
        catch {
            $Error[0] | Format-List -Property * -Force | Out-Host
        }
    }

    # Stop the clock and report total elapsed time
    $Stopwatch.stop()

    Write-Debug "ScubaGear setup time elapsed: $([math]::Round($stopwatch.Elapsed.TotalSeconds,0)) seconds."

    $InformationPreference = $PreferenceStack.Pop()
    $DebugPreference = $PreferenceStack.Pop()
}

function Install-OPA {
    <#
    .SYNOPSIS
        This script installs the required OPA executable used by the
        assessment tool
    .DESCRIPTION
        Installs the OPA executable required to support SCuBAGear.
    .EXAMPLE
        Install-OPA
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = 'The version of OPA Rego to be downloaded, must be in "x.x.x" format')]
        [Alias('version')]
        [string]
        $ExpectedVersion = '0.59.0',

        [Parameter(Mandatory = $false, HelpMessage = 'The file name that the opa executable is to be saved as')]
        [Alias('name')]
        [string]
        $OPAExe = "",

        [Parameter(Mandatory = $false, HelpMessage = 'The operating system the program is running on')]
        [ValidateSet('Windows','MacOS','Linux')]
        [Alias('os')]
        [string]
        $OperatingSystem  = "Windows",

        [Parameter(Mandatory=$false, HelpMessage = 'Directory to contain ScubaGear artifacts. Defaults to <home>.')]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $ScubaParentDirectory = $env:USERPROFILE
    )

    # Constants
    $ACCEPTABLEVERSIONS = '0.42.1','0.42.2','0.43.1','0.44.0','0.45.0','0.46.3','0.47.4','0.48.0','0.49.2','0.50.2',
    '0.51.0','0.52.0','0.53.1','0.54.0','0.55.0','0.56.0','0.57.1','0.58.0','0.59.0'
    $FILENAME = @{ Windows = "opa_windows_amd64.exe"; MacOS = "opa_darwin_amd64"; Linux = "opa_linux_amd64_static"}

    # Set prefernces for writing messages
    $PreferenceStack = New-Object -TypeName System.Collections.Stack
    $PreferenceStack.Push($DebugPreference)
    $PreferenceStack.Push($InformationPreference)
    $PreferenceStack.Push($ErrorActionPreference)
    $DebugPreference = "Continue"
    $InformationPreference = "Continue"
    $ErrorActionPreference = "Stop"

    $ScubaHiddenHome = Join-Path -Path $ScubaParentDirectory -ChildPath '.scubagear'
    $ScubaTools = Join-Path -Path $ScubaHiddenHome -ChildPath 'Tools'
    if((Test-Path -Path $ScubaTools) -eq $false) {
        New-Item -ItemType Directory -Force -Path $ScubaTools
        Write-Output "" | Out-Host
    }

    if(-not $ACCEPTABLEVERSIONS.Contains($ExpectedVersion)) {
        $AcceptableVersionsString = $ACCETABLEVERSIONS -join "`r`n" | Out-String
        throw "Version parameter entered, ${ExpectedVersion}, is not in the list of acceptable versions. Acceptable versions are:`r`n${AcceptableVersionsString}"
    }

    $Filename = $FILENAME.$OperatingSystem
    if($OPAExe -eq "") {
        $OPAExe = $Filename
    }

    if(Test-Path -Path ( Join-Path $ScubaTools $OPAExe) -PathType Leaf) {
        $Result = Confirm-OPAHash -out $OPAExe -version $ExpectedVersion -name $Filename

        if($Result[0]) {
            Write-Debug "${OPAExe}: ${ExpectedVersion} already has latest installed."
        }
        else {
            if($OPAExe -eq $Filename) {
                Write-Information "SHA256 verification failed, downloading new executable" | Out-Host
                InstallOPA -out $OPAExe -version $ExpectedVersion -name $Filename
            }
            else {
                Write-Warning "SHA256 verification failed, please confirm file name is correct & remove old file before running script" | Out-Host
            }
        }
    }
    else {
        InstallOPA -out $OPAExe -version $ExpectedVersion -name $Filename
    }

    $ErrorActionPreference = $PreferenceStack.Pop()
    $InformationPreference = $PreferenceStack.Pop()
    $DebugPreference = $PreferenceStack.Pop()
}

function Get-OPAFile {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('out')]
        [string]$OPAExe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('name')]
        [string]$Filename
    )
    <#
    .FUNCTIONALITY Internal
    #>
    $InstallUrl = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/$($Filename)"
    $OutFile = ( Join-Path $ScubaTools $OPAExe ) #(Join-Path (Get-Location).Path $OPAExe)

    try {
        $Display = "Downloading OPA executable"
        Start-BitsTransfer -Source $InstallUrl -Destination $OutFile -DisplayName $Display -MaxDownloadTime 300
        Write-Information -MessageData "Installed the specified OPA version (${ExpectedVersion}) to ${OutFile}" | Out-Host
    }
    catch {
        $Error[0] | Format-List -Property * -Force | Out-Host
        throw "Unable to download OPA executable. To try manually downloading, see details in README under 'Download the required OPA executable'" | Out-Host
    }
}

function Get-ExeHash {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('name')]
        [string]$Filename,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion
    )
    <#
    .FUNCTIONALITY Internal
    #>
    $InstallUrl = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/$($Filename).sha256"
    $OutFile = (Join-Path (Get-Location).Path $InstallUrl.SubString($InstallUrl.LastIndexOf('/')))

    try {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($InstallUrl, $OutFile)
    }
    catch {
        $Error[0] | Format-List -Property * -Force | Out-Host
        Write-Error "Unable to download OPA SHA256 hash for verification" | Out-Host
    }
    finally {
        $WebClient.Dispose()
    }

    $Hash = ($(Get-Content $OutFile -raw) -split " ")[0]
    Remove-Item $OutFile

    return $Hash
}

function Confirm-OPAHash {
    <#
    .FUNCTIONALITY Internal
    #>
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('out')]
        [string]$OPAExe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('name')]
        [string]
        $Filename
    )

    if ((Get-FileHash ( Join-Path $ScubaTools $OPAExe ) -Algorithm SHA256 ).Hash -ne $(Get-ExeHash -name $Filename -version $ExpectedVersion)) {
        return $false, "SHA256 verification failed, retry download or install manually. See README under 'Download the required OPA executable' for instructions."
    }

    return $true, "Downloaded OPA version ($ExpectedVersion) SHA256 verified successfully`n"
}

function InstallOPA {
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('out')]
        [string]$OPAExe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('version')]
        [string]$ExpectedVersion,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('name')]
        [string]
        $Filename
    )
    <#
    .FUNCTIONALITY Internal
    #>
    Get-OPAFile -out $OPAExe -version $ExpectedVersion -name $Filename
    $Result = Confirm-OPAHash -out $OPAExe -version $ExpectedVersion -name $Filename
    $Result[1] | Out-Host
}

function Debug-SCuBA {
    <#
        .SYNOPSIS
            Gather diagnostic information from previous run(s) into a single
            archive bundle for error reporting and troubleshooting.
        .DESCRIPTION
            Assists development teams in diagnosing issues with the ScubaGear
            assessment tool by generating and bundling up information related
            to one or more previous assessment runs.
        .EXAMPLE
            Debug-SCuBA
        .NOTES
            Executing the script with no switches will cause it to create an archive
            of the latest SCuBAGear run report and result files in the current working
            directory.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, HelpMessage = 'Directory to contain debug report')]
        [string]
        $ReportPath = "$($($(Get-Item $PSScriptRoot).Parent).FullName)\Reports",

        [Parameter(Mandatory=$false, HelpMessage = 'Include ScubaGear report on tenant configuration?')]
        [switch]
        $IncludeReports  = $false,

        [Parameter(Mandatory=$false, HelpMessage = 'Include all available ScubaGear report on tenant configuration?')]
        [switch]
        $AllReports = $false
    )

    $PreferenceStack = New-Object -TypeName System.Collections.Stack
    $PreferenceStack.Push($DebugPreference)
    $DebugPreference = 'Continue'

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

    $DebugPreference = $PreferenceStack.Pop()
}

function Copy-ScubaSampleReport {
    <#
    .SYNOPSIS
    Copy sample reports to user defined location.
    .Description
    This function makes copies of the sample reports included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the samples. Defaults to <user home>\ScubaGear\samples\reports
    .Example
    Copy-ScubaSampleReport
    .Functionality
    Public
    .NOTES
    SuppressMessage for PSReviewUnusedParameter due to linter bug. Open issue to remove if/when fixed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $DestinationDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/samples/reports"),
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    $SourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Sample-Reports\"
    Copy-ScubaModuleFile -SourceDirectory $SourceDirectory -DestinationDirectory $DestinationDirectory -Force:$Force
}

function Copy-ScubaSampleConfigFile {
    <#
    .SYNOPSIS
    Copy sample configuration files to user defined location.
    .Description
    This function makes copies of the sample configuration files included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the samples. Defaults to <user home>\ScubaGear\samples\config-files
    .Example
    Copy-ScubaSampleConfigFile
    .Functionality
    Public
    .NOTES
    SuppressMessage for PSReviewUnusedParameter due to linter bug. Open issue to remove if/when fixed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $DestinationDirectory = (Join-Path -Path $env:USERPROFILE -ChildPath "ScubaGear/samples/config-files"),
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    $SourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Sample-Config-Files\"
    Copy-ScubaModuleFile -SourceDirectory $SourceDirectory -DestinationDirectory $DestinationDirectory -Force:$Force
}

function Copy-ScubaModuleFile {
    <#
    .SYNOPSIS
    Copy Scuba module files (read-only) to user defined location.
    .Description
    This function makes copies of files included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the files.
    .Example
    Copy-ScubaModuleFile =Destination SomeWhere
    .Functionality
    Private
    .NOTES
    SuppressMessage for PSReviewUnusedParameter due to linter bug. Open issue to remove if/when fixed.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $SourceDirectory,
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path -Path $_ -IsValid})]
        [string]
        $DestinationDirectory,
        [Parameter(Mandatory = $false)]
        [switch]
        $Force
    )

    if (-not (Test-Path -Path $DestinationDirectory -PathType Container)){
        New-Item -ItemType Directory -Path $DestinationDirectory | Out-Null
    }

    try {
        Get-ChildItem -Path $SourceDirectory | Copy-Item -Destination $DestinationDirectory -Recurse -Container -Force:$Force -ErrorAction Stop 2> $null
        Get-ChildItem -Path $DestinationDirectory -File -Recurse | ForEach-Object {$_.IsReadOnly = $true}
    }
    catch {
        throw "Scuba copy module files failed."
    }
}

Export-ModuleMember -Function @(
    'Copy-ScubaBaselineDocument',
    'Install-OPA',
    'Initialize-SCuBA',
    'Debug-SCuBA',
    'Copy-ScubaSampleReport',
    'Copy-ScubaSampleConfigFile'
)
