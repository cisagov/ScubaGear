<#
.SYNOPSIS
Copies files to appropriate directories and cleans up DLP-renamed duplicates.

.DESCRIPTION
This script copies files from a source directory to their target locations and removes
DLP-created duplicate files that have _<random>.txt appended to their names.

.PARAMETER SourceDirectory
The directory containing the files to copy

.PARAMETER TargetDirectory
The root directory where files should be copied (will maintain relative structure)

.PARAMETER FileMapping
Optional hashtable mapping source files to specific target paths

.PARAMETER DryRun
Show what would be done without actually performing the operations

.PARAMETER RemoveDLPFiles
Remove files with DLP naming pattern (_<random>.txt)

.EXAMPLE
.\Copy-AndReplaceDLPFiles.ps1 -SourceDirectory "C:\Backup\Files" -TargetDirectory "C:\Project" -RemoveDLPFiles

.EXAMPLE
.\Copy-AndReplaceDLPFiles.ps1 -SourceDirectory "C:\Backup" -TargetDirectory "C:\Project" -DryRun
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceDirectory,
    
    [Parameter(Mandatory = $true)]
    [string]$TargetDirectory,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$FileMapping = @{},
    
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory = $false)]
    [switch]$RemoveDLPFiles = $true
)

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "Green" = [System.ConsoleColor]::Green
        "Yellow" = [System.ConsoleColor]::Yellow
        "Red" = [System.ConsoleColor]::Red
        "Cyan" = [System.ConsoleColor]::Cyan
        "Magenta" = [System.ConsoleColor]::Magenta
        "White" = [System.ConsoleColor]::White
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

function Test-DLPPattern {
    param([string]$FileName)
    
    # Pattern for DLP files: originalname_<random>.txt
    # Matches files ending with underscore followed by random characters and .txt
    return $FileName -match '_[a-zA-Z0-9]+\.txt$'
}

function Get-OriginalFileName {
    param([string]$DLPFileName)
    
    # Remove the _<random>.txt suffix to get original name
    if (Test-DLPPattern -FileName $DLPFileName) {
        return $DLPFileName -replace '_[a-zA-Z0-9]+\.txt$', ''
    }
    return $DLPFileName
}

function Find-DLPFiles {
    param(
        [string]$Directory,
        [string]$OriginalFileName
    )
    
    $dlpFiles = @()
    $searchPattern = (Get-OriginalFileName -DLPFileName $OriginalFileName) + "_*.txt"
    
    try {
        $dlpFiles = Get-ChildItem -Path $Directory -Filter $searchPattern -File -ErrorAction SilentlyContinue
        $dlpFiles = $dlpFiles | Where-Object { Test-DLPPattern -FileName $_.Name }
    }
    catch {
        Write-ColorOutput "Warning: Could not search for DLP files in $Directory - $($_.Exception.Message)" "Yellow"
    }
    
    return $dlpFiles
}

function Copy-FileWithStructure {
    param(
        [string]$SourceFile,
        [string]$TargetFile,
        [switch]$DryRun
    )
    
    try {
        # Create target directory if it doesn't exist
        $targetDir = Split-Path -Path $TargetFile -Parent
        if (-not (Test-Path $targetDir)) {
            if ($DryRun) {
                Write-ColorOutput "[DRY RUN] Would create directory: $targetDir" "Cyan"
            } else {
                New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                Write-ColorOutput "Created directory: $targetDir" "Green"
            }
        }
        
        # Copy the file
        if ($DryRun) {
            Write-ColorOutput "[DRY RUN] Would copy: $SourceFile -> $TargetFile" "Cyan"
        } else {
            Copy-Item -Path $SourceFile -Destination $TargetFile -Force
            Write-ColorOutput "Copied: $SourceFile -> $TargetFile" "Green"
        }
        return $true
    }
    catch {
        Write-ColorOutput "Error copying $SourceFile to $TargetFile - $($_.Exception.Message)" "Red"
        return $false
    }
}

function Remove-DLPFile {
    param(
        [string]$FilePath,
        [switch]$DryRun
    )
    
    try {
        if ($DryRun) {
            Write-ColorOutput "[DRY RUN] Would remove DLP file: $FilePath" "Cyan"
        } else {
            Remove-Item -Path $FilePath -Force
            Write-ColorOutput "Removed DLP file: $FilePath" "Yellow"
        }
        return $true
    }
    catch {
        Write-ColorOutput "Error removing DLP file $FilePath - $($_.Exception.Message)" "Red"
        return $false
    }
}

# Main script execution
try {
    Write-ColorOutput "=== File Copy and DLP Cleanup Script ===" "Magenta"
    Write-ColorOutput "Source Directory: $SourceDirectory" "White"
    Write-ColorOutput "Target Directory: $TargetDirectory" "White"
    
    if ($DryRun) {
        Write-ColorOutput "DRY RUN MODE - No changes will be made" "Yellow"
    }
    
    # Validate directories
    if (-not (Test-Path $SourceDirectory)) {
        throw "Source directory does not exist: $SourceDirectory"
    }
    
    if (-not (Test-Path $TargetDirectory)) {
        Write-ColorOutput "Target directory does not exist, will be created: $TargetDirectory" "Yellow"
    }
    
    # Get all files from source directory
    Write-ColorOutput "`nScanning source directory for files..." "Cyan"
    $sourceFiles = Get-ChildItem -Path $SourceDirectory -File -Recurse
    
    if ($sourceFiles.Count -eq 0) {
        Write-ColorOutput "No files found in source directory." "Yellow"
        return
    }
    
    Write-ColorOutput "Found $($sourceFiles.Count) files to process" "Green"
    
    $copiedCount = 0
    $dlpRemovedCount = 0
    $errorCount = 0
    
    foreach ($sourceFile in $sourceFiles) {
        Write-ColorOutput "`nProcessing: $($sourceFile.Name)" "White"
        
        # Determine target path
        $relativePath = $sourceFile.FullName.Substring($SourceDirectory.Length).TrimStart('\', '/')
        $targetPath = ""
        
        # Check if there's a specific mapping for this file
        if ($FileMapping.ContainsKey($sourceFile.Name)) {
            $targetPath = $FileMapping[$sourceFile.Name]
            if (-not [System.IO.Path]::IsPathRooted($targetPath)) {
                $targetPath = Join-Path $TargetDirectory $targetPath
            }
        } else {
            $targetPath = Join-Path $TargetDirectory $relativePath
        }
        
        # Copy the file
        $copySuccess = Copy-FileWithStructure -SourceFile $sourceFile.FullName -TargetFile $targetPath -DryRun:$DryRun
        if ($copySuccess) {
            $copiedCount++
        } else {
            $errorCount++
        }
        
        # Find and remove DLP files if enabled
        if ($RemoveDLPFiles) {
            $targetDir = Split-Path -Path $targetPath -Parent
            if (Test-Path $targetDir) {
                $dlpFiles = Find-DLPFiles -Directory $targetDir -OriginalFileName $sourceFile.Name
                
                foreach ($dlpFile in $dlpFiles) {
                    if ($VerbosePreference) {
                        Write-ColorOutput "Found DLP file: $($dlpFile.FullName)" "Yellow"
                    }
                    
                    $removeSuccess = Remove-DLPFile -FilePath $dlpFile.FullName -DryRun:$DryRun
                    if ($removeSuccess) {
                        $dlpRemovedCount++
                    } else {
                        $errorCount++
                    }
                }
            }
        }
    }
    
    # Summary
    Write-ColorOutput "`n=== SUMMARY ===" "Magenta"
    Write-ColorOutput "Files copied: $copiedCount" "Green"
    if ($RemoveDLPFiles) {
        Write-ColorOutput "DLP files removed: $dlpRemovedCount" "Yellow"
    }
    if ($errorCount -gt 0) {
        Write-ColorOutput "Errors encountered: $errorCount" "Red"
    }
    
    if ($DryRun) {
        Write-ColorOutput "`nThis was a dry run. Use -DryRun:`$false to perform actual operations." "Cyan"
    } else {
        Write-ColorOutput "`nOperation completed successfully!" "Green"
    }
}
catch {
    Write-ColorOutput "Script error: $($_.Exception.Message)" "Red"
    exit 1
}

<#
USAGE EXAMPLES:

# Basic usage - copy files and remove DLP duplicates
.\Copy-AndReplaceDLPFiles.ps1 -SourceDirectory "E:\BACKUP\ScubaGearDLPFix" -TargetDirectory "C:\Project"

# Dry run to see what would happen
.\Copy-AndReplaceDLPFiles.ps1 -SourceDirectory "E:\BACKUP\ScubaGearDLPFix" -TargetDirectory "E:\Development\Github\cisagov\ScubaGear-1437-yaml-validation" -DryRun

# With specific file mappings
$mapping = @{
    "config.json" = "PowerShell\ScubaGear\Modules\ScubaConfigApp\config.json"
    "helper.psm1" = "PowerShell\ScubaGear\Modules\ScubaConfigApp\ScubaConfigAppHelpers\helper.psm1"
}
.\Copy-AndReplaceDLPFiles.ps1 -SourceDirectory "C:\Backup" -TargetDirectory "C:\Project" -FileMapping $mapping

# Copy only, don't remove DLP files
.\Copy-AndReplaceDLPFiles.ps1 -SourceDirectory "C:\Backup" -TargetDirectory "C:\Project" -RemoveDLPFiles:$false

# Verbose output
.\Copy-AndReplaceDLPFiles.ps1 -SourceDirectory "C:\Backup" -TargetDirectory "C:\Project" -Verbose
#>