using module '..\ScubaConfig\ScubaConfig.psm1'

function Copy-SCuBABaselineDocument {
    <#
    .SYNOPSIS
    Copy security baselines documents to a user specified location.
    .Description
    This function makes copies of the security baseline documents included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the baselines. Defaults to <user home>\ScubaGear\baselines
    .Example
    Copy-SCuBABaselineDocument
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
        This function installs the required Powershell modules used by the
        assessment tool.
    .DESCRIPTION
        Installs the modules required to support SCuBAGear.  If the Force
        switch is set then any existing module will be re-installed even if
        already at latest version. If the SkipUpdate switch is set then any
        existing module will not be updated to th latest version.
    .PARAMETER $Force
        Installs a given module and overrides warning messages about module installation conflicts. If a module with the same name already exists on the computer, Force allows for multiple versions to be installed. If there is an existing module with the same name and version, Force overwrites that version.
    .PARAMETER $SkipUpdate
        If specified then modules will not be updated to latest version.
    .PARAMETER $DoNotAutoTrustRepository
        Do not automatically trust the PSGallery repository for module installation.
    .PARAMETER $NoOPA
        Do not download OPA
    .PARAMETER $ExpectedVersion
        The version of OPA Rego to be downloaded, must be in "x.x.x" format.
    .PARAMETER $OperatingSystem
        The operating system the program is running on.
    .PARAMETER $OPAExe
        The file name that the opa executable is to be saved as.
    .PARAMETER $ScubaParentDirectory
        Directory to contain ScubaGear artifacts. Defaults to <home>.
    .PARAMETER $Scope
        Specifies the Install-Module scope of the dependent PowerShell modules. Acceptable values are AllUsers and CurrentUser. Defaults to CurrentUser.
    .EXAMPLE
        Initialize-SCuBA
    .EXAMPLE
        Initalize-SCuBA -Scope AllUsers
        Install all dependent PowerShell modules in a location that's accessible to all users of the computer.
    .NOTES
        Executing the script with no switches set will install the latest
        version of a module if not already installed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]
        $Force,
        [Parameter(Mandatory = $false)]
        [switch]
        $SkipUpdate,
        [Parameter(Mandatory = $false)]
        [switch]
        $DoNotAutoTrustRepository,
        [Parameter(Mandatory = $false)]
        [switch]
        $NoOPA,
        [Parameter(Mandatory = $false)]
        [Alias('version')]
        [string]
        $ExpectedVersion = [ScubaConfig]::ScubaDefault('DefaultOPAVersion'),
        [Parameter(Mandatory = $false)]
        [ValidateSet('Windows','MacOS','Linux')]
        [Alias('os')]
        [string]
        $OperatingSystem  = "Windows",
        [Parameter(Mandatory = $false)]
        [Alias('name')]
        [string]
        $OPAExe = "",
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $ScubaParentDirectory = $env:USERPROFILE,
        [Parameter(Mandatory=$false)]
        [ValidateSet('CurrentUser','AllUsers')]
        [string]
        $Scope = 'CurrentUser'
    )

    Write-Information -MessageData "Initializing ScubaGear..."
    # Set preferences for writing messages
    $PreferenceStack = New-Object -TypeName System.Collections.Stack
    $PreferenceStack.Push($DebugPreference)
    $PreferenceStack.Push($InformationPreference)
    $DebugPreference = "Continue"
    $InformationPreference = "Continue"

    if ($DoNotAutoTrustRepository) {
        $RepositoryDetails = Get-PSRepository -Name "PSGallery"
        Write-Output "PSGallery is $($RepositoryDetails.Trusted)."
    }
    else {
        $Policy = Get-PSRepository -Name "PSGallery" | Select-Object -Property -InstallationPolicy
        if ($($Policy.InstallationPolicy) -ne "Trusted") {
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
            Write-Output "PSGallery is trusted."
        }
    }

    # Start a stopwatch to time module installation elapsed time
    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Since this method is called from the Support module, script root
    # points to the Support module location
    # Use script root rather than Get-Module as this may be called by
    # a script that only imports the function and not the whole module
    $SupportPath = $PSScriptRoot

    # Scuba module structure means module home is grandparent of support
    $ScubaModuleDir = Split-Path -Path $(Split-Path -Path $SupportPath -Parent) -Parent

    # Removing the import below causes issues with testing, let it be.
    # Import module magic may be helping by:
    #   * restricting the import so only that only function is exported
    #   * imported function takes precedence over imported modules w/ function
    Import-Module $SupportPath -Function Initialize-Scuba

    try {
        ($RequiredModulesPath = Join-Path -Path $ScubaModuleDir -ChildPath 'RequiredVersions.ps1') *> $null
        . $RequiredModulesPath
    }
    catch {
        throw "Unable to find RequiredVersions.ps1 in expected directory:`n`t$ScubaModuleDir"
    }

    if ($ModuleList) {
        # Note: PS-Get is intentionally not listed with the other modules in RequiredVersions.ps1.
        # It is added here to ensure it is the first module to be installed, which is required to
        # ensure "that the other packages can be properly evaluated and installed."
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
                        -Scope "$($Scope)" `
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
                        -Scope "$($Scope)" `
                        -MaximumVersion $Module.MaximumVersion
                    $MaxInstalledVersion = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object Version -First 1).Version
                    Write-Information -MessageData "${ModuleName}: ${HighestInstalledVersion} updated to version ${MaxInstalledVersion}."
                }
            }
        }
        else {
            Install-Module -Name $ModuleName `
                -AllowClobber `
                -Scope "$($Scope)" `
                -MaximumVersion $Module.MaximumVersion
                $MaxInstalledVersion = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object Version -First 1).Version
            Write-Information -MessageData "Installed the latest acceptable version of ${ModuleName}: ${MaxInstalledVersion}."
        }
    }

    if ($NoOPA -eq $true) {
        Write-Information -MessageData "Skipping Download for OPA.`n"
    }
    else {
        try {
            Install-OPAforSCuBA -OPAExe $OPAExe -ExpectedVersion $ExpectedVersion -OperatingSystem $OperatingSystem -ScubaParentDirectory $ScubaParentDirectory
        }
        catch {
            $Error[0] | Format-List -Property * -Force | Out-Host
        }
    }

    # Stop the clock and report total elapsed time
    $Stopwatch.stop()
    Write-Output "ScubaGear setup time elapsed (in seconds): $([math]::Round($stopwatch.Elapsed.TotalSeconds,0))"

    $InformationPreference = $PreferenceStack.Pop()
    $DebugPreference = $PreferenceStack.Pop()
}

function Install-OPAforSCuBA {
    <#
    .SYNOPSIS
        This script installs the required OPA executable used by the
        assessment tool
    .DESCRIPTION
        Installs the OPA executable required to support SCuBAGear.
    .PARAMETER $ExpectedVersion
        The version of OPA Rego to be downloaded, must be in "x.x.x" format.
    .PARAMETER $OPAExe
        The file name that the opa executable is to be saved as.
    .PARAMETER $OperatingSystem
        The operating system the program is running on.  Valid values are 'Windows', 'MacOS', and 'Linux'.
    .PARAMETER $ScubaParentDirectory
        Directory to contain ScubaGear artifacts. Defaults to <home>.
    .EXAMPLE
        Install-OPAforSCuBA
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [Alias('version')]
        [string]
        $ExpectedVersion = [ScubaConfig]::ScubaDefault('DefaultOPAVersion'),
        [Parameter(Mandatory = $false)]
        [Alias('name')]
        [string]
        $OPAExe = "",
        [Parameter(Mandatory = $false)]
        [ValidateSet('Windows','MacOS','Linux')]
        [Alias('os')]
        [string]
        $OperatingSystem  = "Windows",
        [Parameter(Mandatory=$false)]
        [ValidateScript({Test-Path -Path $_ -PathType Container})]
        [string]
        $ScubaParentDirectory = $env:USERPROFILE
    )

    # Constants
    $ACCEPTABLEVERSIONS = '0.69.0', '0.70.0', '1.0.1', '1.1.0', '1.2.0',
    '1.3.0', '1.4.2', '1.5.0', '1.6.0',
    '1.7.1', [ScubaConfig]::ScubaDefault('DefaultOPAVersion') # End Versions
    $FILENAME = @{ Windows = "opa_windows_amd64.exe"; MacOS = "opa_darwin_amd64"; Linux = "opa_linux_amd64_static"}

    # Set preferences for writing messages
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
        New-Item -ItemType Directory -Force -Path $ScubaTools | Out-Null
        Write-Information "" | Out-Host
    }
    if(-not $ACCEPTABLEVERSIONS.Contains($ExpectedVersion)) {
        $AcceptableVersionsString = $ACCEPTABLEVERSIONS -join "`r`n" | Out-String
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
                Write-Information -MessageData "SHA256 verification failed, downloading new executable" | Out-Host
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
    <#
        .SYNOPSIS Internal
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
        [string]$Filename
    )

    $InstallUrl = "https://openpolicyagent.org/downloads/v$($ExpectedVersion)/$($Filename)"
    $OutFile = ( Join-Path $ScubaTools $OPAExe ) #(Join-Path (Get-Location).Path $OPAExe)

    try {
        $Display = "Downloading OPA executable"
        Start-BitsTransfer -Source $InstallUrl -Destination $OutFile -DisplayName $Display -MaxDownloadTime 300
        Write-Information -MessageData "Installed the specified OPA version (${ExpectedVersion}) to ${OutFile}" | Out-Host
    }
    catch {
        $Error[0] | Format-List -Property * -Force | Out-Host
        throw "Unable to download OPA executable. To try manually downloading, see details found under the section titled 'OPA Installation' within the 'Dependencies' markdown linked in the README" | Out-Host
    }
}

function Get-ExeHash {
    <#
        .SYNOPSIS Internal
    #>
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
        .SYNOPSIS Internal
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
    <#
        .SYNOPSIS Internal
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

    Get-OPAFile -out $OPAExe -version $ExpectedVersion -name $Filename
    Confirm-OPAHash -out $OPAExe -version $ExpectedVersion -name $Filename
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

function Copy-SCuBASampleReport {
    <#
    .SYNOPSIS
    Copy sample reports to user defined location.
    .Description
    This function makes copies of the sample reports included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the samples. Defaults to <user home>\ScubaGear\samples\reports
    .Example
    Copy-SCuBASampleReport
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

function Copy-SCuBASampleConfigFile {
    <#
    .SYNOPSIS
    Copy sample configuration files to user defined location.
    .Description
    This function makes copies of the sample configuration files included with the installed ScubaGear module.
    .Parameter Destination
    Where to copy the samples. Defaults to <user home>\ScubaGear\samples\config-files
    .Example
    Copy-SCuBASampleConfigFile
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

function New-SCuBAConfig {
    <#
    .SYNOPSIS
    Generate a config file for the ScubaGear tool
    .Description
    Using provided user input generate a config file to run ScubaGear tailored to the end user
    .Parameter ProductNames
    A list of one or more M365 shortened product names that the tool will assess when it is executed. Acceptable product name values are listed below.
    To assess Azure Active Directory you would enter the value aad.
    To assess Exchange Online you would enter exo and so forth.
    - Azure Active Directory: aad
    - Defender for Office 365: defender
    - Exchange Online: exo
    - MS Power Platform: powerplatform
    - SharePoint Online: sharepoint
    - MS Teams: teams.
    Use '*' to run all baselines.
    .Parameter M365Environment
    This parameter is used to authenticate to the different commercial/government environments.
    Valid values include "commercial", "gcc", "gcchigh", or "dod".
    - For M365 tenants with E3/E5 licenses enter the value **"commercial"**.
    - For M365 Government Commercial Cloud tenants with G3/G5 licenses enter the value **"gcc"**.
    - For M365 Government Commercial Cloud High tenants enter the value **"gcchigh"**.
    - For M365 Department of Defense tenants enter the value **"dod"**.
    Default value is 'commercial'.
    .Parameter OPAPath
    The folder location of the OPA Rego executable file.
    The OPA Rego executable embedded with this project is located in the project's root folder.
    If you want to execute the tool using a version of OPA Rego located in another folder,
    then customize the variable value with the full path to the alternative OPA Rego exe file.
    .Parameter LogIn
    A `$true` or `$false` variable that if set to `$true`
    will prompt you to provide credentials if you want to establish a connection
    to the specified M365 products in the **$ProductNames** variable.
    For most use cases, leave this variable to be `$true`.
    A connection is established in the current PowerShell terminal session with the first authentication.
    If you want to run another verification in the same PowerShell session simply set
    this variable to be `$false` to bypass the reauthenticating in the same session. Default is $true.
    Note: defender will ask for authentication even if this variable is set to `$false`
    ;;;.Parameter Version
    ;;;Will output the current ScubaGear version to the terminal without running this cmdlet.
    .Parameter AppID
    The application ID of the service principal that's used during certificate based
    authentication. A valid value is the GUID of the application ID (service principal).
    .Parameter CertificateThumbprint
    The thumbprint value specifies the certificate that's used for certificate base authentication.
    The underlying PowerShell modules retrieve the certificate from the user's certificate store.
    As such, a copy of the certificate must be located there.
    .Parameter Organization
    Specify the organization that's used in certificate based authentication.
    Use the tenant's tenantname.onmicrosoft.com domain for the parameter value.
    .Parameter OutPath
    The folder path where both the output JSON and the HTML report will be created.
    The folder will be created if it does not exist. Defaults to current directory.
    .Parameter OutFolderName
    The name of the folder in OutPath where both the output JSON and the HTML report will be created.
    Defaults to "M365BaselineConformance". The client's local timestamp will be appended.
    .Parameter OutProviderFileName
    The name of the Provider output JSON created in the folder created in OutPath.
    Defaults to "ProviderSettingsExport".
    .Parameter OutRegoFileName
    The name of the Rego output JSON and CSV created in the folder created in OutPath.
    Defaults to "TestResults".
    .Parameter OutReportName
    The name of the main html file page created in the folder created in OutPath.
    Defaults to "BaselineReports".
    .Parameter DisconnectOnExit
    Set switch to disconnect all active connections on exit from ScubaGear (default: $false)
    .Parameter ConfigFilePath
    Local file path to a JSON or YAML formatted configuration file.
    Configuration file parameters can be used in place of command-line
    parameters. Additional parameters and variables not available on the
    command line can also be included in the file that will be provided to the
    tool for use in specific tests.
    .Parameter OmitPolicy
    A comma-separated list of policies to exclude from the ScubaGear report, e.g., MS.DEFENDER.1.1v1.
    Note that the rationales will need to be manually added to the resulting config file.
    .Functionality
    Public
    #>
    [CmdletBinding(DefaultParameterSetName='Report')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    param (

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description = "YAML configuration file with default description", #(Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("teams", "exo", "defender", "aad", "powerplatform", "sharepoint", '*', IgnoreCase = $false)]
        [string[]]
        $ProductNames = @("aad", "defender", "exo", "sharepoint", "teams"),

        [Parameter(Mandatory = $false)]
        [ValidateSet("commercial", "gcc", "gcchigh", "dod", IgnoreCase = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $M365Environment = "commercial",

        [Parameter(Mandatory = $false)]
        [ValidateScript({Test-Path -PathType Container $_})]
        [string]
        $OPAPath = ".", #(Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $LogIn = $true,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet($true, $false)]
        [boolean]
        $DisconnectOnExit = $false,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutPath = '.',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppID,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateThumbprint,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Organization,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutFolderName = "M365BaselineConformance",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutProviderFileName = "ProviderSettingsExport",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutRegoFileName = "TestResults",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $OutReportName = "BaselineReports",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConfigLocation = "./",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $OmitPolicy = @()
    )

    $Config = New-Object ([System.Collections.specialized.OrderedDictionary])

    ($MyInvocation.MyCommand.Parameters ).Keys | ForEach-Object{
        $Val = (Get-Variable -Name $_ -EA SilentlyContinue).Value
        if( $Val.length -gt 0 ) {
            #$config[$_] = $val
            $Config.add($_, $Val)
        }
    }

    if ($config.Contains("OmitPolicy")) {
        # We don't want to immediately save this parameter to the config, as it's not in the right
        # format yet.
        $config.Remove("OmitPolicy")
    }

    $CapExclusionNamespace = @(
        "MS.AAD.1.1v1",
        "MS.AAD.2.1v1",
        "MS.AAD.2.3v1",
        "MS.AAD.3.1v1",
        "MS.AAD.3.2v1",
        "MS.AAD.3.6v1",
        "MS.AAD.3.7v1",
        "MS.AAD.3.8v1",
        "MS.AAD.3.9v1"
        )
    $RoleExclusionNamespace = "MS.AAD.7.4v1"

    $CommonSensitiveAccountFilterNamespace = @(
        "MS.DEFENDER.1.4v1",
        "MS.DEFENDER.1.5v1"
        )

    $UserImpersonationProtectionNamespace = "MS.DEFENDER.2.1v1"

    $AgencyDomainImpersonationProtectionNamespace = "MS.DEFENDER.2.2v1"

    $PartnerDomainImpersonationProtectionNamespace = "MS.DEFENDER.2.3v1"

    $OmissionNamespace = "OmitPolicy"

    # List to track which policies the user specified in $OmitPolicies are properly formatted
    $OmitPolicyValidated = @()

    # Hashmap to structure the ignored policies template
    $config[$OmissionNamespace] = @{}

    foreach ($Policy in $OmitPolicy) {
        if (-not ($Policy -match "^ms\.[a-z]+\.[0-9]+\.[0-9]+v[0-9]+$")) {
            # Note that -match is a case insensitive match
            # Note that the regex does not validate the product name, this will be done
            # later
            $Warning = "The policy, $Policy, in the OmitPolicy parameter, is not a valid "
            $Warning += "policy ID. Expected format 'MS.[PRODUCT].[GROUP].[NUMBER]v[VERSION]', "
            $Warning += "e.g., 'MS.DEFENDER.1.1v1'. Skipping."
            Write-Warning $Warning
            Continue
        }
        $Product = ($Policy -Split "\.")[1]
        # Here's where the product name is validated
        if (-not ($ProductNames -Contains $Product)) {
            $Warning = "The policy, $Policy, in the OmitPolicy parameter, is not encompassed by "
            $Warning += "the products specified in the ProductName parameter. Skipping."
            Write-Warning $Warning
            Continue
        }
        # Ensure the policy ID is properly capitalized (i.e., all caps except for the "v1" portion)
        $PolicyCapitalized = $Policy.Substring(0, $Policy.Length-2).ToUpper() + $Policy.SubString($Policy.Length-2)
        $OmitPolicyValidated += $PolicyCapitalized
        $config[$OmissionNamespace][$PolicyCapitalized] = @{
            "Rationale" = "";
            "Expiration" = "";
        }
    }

    $Warning = "The following policies have been configured for omission: $($OmitPolicyValidated -Join ', '). "
    $Warning += "Note that as the New-Config function does not support providing the rationale for omission via "
    $Warning += "the commandline, you will need to open the resulting config file and manually enter the rationales."
    Write-Warning $Warning

    $AadTemplate = New-Object ([System.Collections.specialized.OrderedDictionary])
    $AadCapExclusions = New-Object ([System.Collections.specialized.OrderedDictionary])
    $AadRoleExclusions = New-Object ([System.Collections.specialized.OrderedDictionary])

    $DefenderTemplate = New-Object ([System.Collections.specialized.OrderedDictionary])
    $DefenderCommonSensitiveAccountFilter = New-Object ([System.Collections.specialized.OrderedDictionary])
    #$defenderUserImpersonationProtection = New-Object ([System.Collections.specialized.OrderedDictionary])
    #$defenderAgencyDomainImpersonationProtection = New-Object ([System.Collections.specialized.OrderedDictionary])
    #$defenderPartnerDomainImpersonationProtection = New-Object ([System.Collections.specialized.OrderedDictionary])



    $AadCapExclusions = @{ CapExclusions = @{} }
    $AadCapExclusions["CapExclusions"].add("Users", @(""))
    $AadCapExclusions["CapExclusions"].add("Groups", @(""))

    $AadRoleExclusions = @{ RoleExclusions = @{} }
    $AadRoleExclusions["RoleExclusions"].add("Users", @(""))
    $AadRoleExclusions["RoleExclusions"].add("Groups", @(""))

    foreach ($Cap in $CapExclusionNamespace){
        $AadTemplate.add($Cap, $AadCapExclusions)
    }

    $AadTemplate.add($RoleExclusionNamespace, $AadRoleExclusions)

    $DefenderCommonSensitiveAccountFilter = @{ SensitiveAccounts = @{} }
    $DefenderCommonSensitiveAccountFilter['SensitiveAccounts'].add("IncludedUsers", @(""))
    $DefenderCommonSensitiveAccountFilter['SensitiveAccounts'].add("IncludedGroups", @(""))
    $DefenderCommonSensitiveAccountFilter['SensitiveAccounts'].add("IncludedDomains", @(""))
    $DefenderCommonSensitiveAccountFilter['SensitiveAccounts'].add("ExcludedUsers", @(""))
    $DefenderCommonSensitiveAccountFilter['SensitiveAccounts'].add("ExcludedGroups", @(""))
    $DefenderCommonSensitiveAccountFilter['SensitiveAccounts'].add("ExcludedDomains", @(""))

    foreach ($Filter in $CommonSensitiveAccountFilterNamespace){
        $DefenderTemplate.add($Filter, $DefenderCommonSensitiveAccountFilter)
    }

    $DefenderTemplate.add($UserImpersonationProtectionNamespace, @{ SensitiveUsers = @("") })
    $DefenderTemplate.add($AgencyDomainImpersonationProtectionNamespace, @{ AgencyDomains = @("") })
    $DefenderTemplate.add($PartnerDomainImpersonationProtectionNamespace, @{ PartnerDomains = @("") })

    $Products = (Get-Variable -Name ProductNames -EA SilentlyContinue).Value
    foreach ($Product in $Products){
        switch ($Product){
            "aad" {
                $config.add("Aad", $AadTemplate)
                }
            "defender" {
                $config.add("Defender", $DefenderTemplate)
                }
        }
    }
    convertto-yaml $Config | set-content "$($ConfigLocation)/SampleConfig.yaml"
}

Export-ModuleMember -Function @(
    'Copy-SCuBABaselineDocument',
    'Install-OPAforSCuBA',
    'Initialize-SCuBA',
    'Debug-SCuBA',
    'Copy-SCuBASampleReport',
    'Copy-SCuBASampleConfigFile',
    'New-SCuBAConfig'
)
