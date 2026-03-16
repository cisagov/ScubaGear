<#
.SYNOPSIS
    Generates the ScubaBaseline.json asset package from baseline markdown files.

.DESCRIPTION
    This script is designed to be run as part of the GitHub Actions workflow to automatically
    generate the machine-readable ScubaBaseline.json from the authoritative markdown baseline files.
    
    The script:
    - Parses all baseline markdown files in PowerShell/ScubaGear/baselines/
    - Extracts policy details, exclusion mappings, and metadata
    - Generates a versioned JSON output file
    - Places the file in the PowerShell/ScubaGear/schema/ directory for inclusion in the module package
    
    This ensures the machine-readable SCBs are always in sync with the markdown source of truth.

.PARAMETER OutputPath
    The path where the ScubaBaseline.json file will be created.
    Defaults to 'PowerShell/ScubaGear/schema/ScubaBaseline.json' (relative to repository root).

.PARAMETER BaselineDirectory
    The directory containing the baseline markdown files.
    Defaults to 'PowerShell/ScubaGear/baselines' (relative to repository root).

.PARAMETER Validate
    If specified, validates the generated JSON against the schema and outputs validation results.

.EXAMPLE
    .\Generate-ScubaBaseline.ps1
    Generates the baseline JSON using default paths.

.EXAMPLE
    .\Generate-ScubaBaseline.ps1 -OutputPath "output/ScubaBaseline.json" -Validate
    Generates the baseline JSON to a custom location and validates it.

.NOTES
    This script is called by the GitHub Action workflow 'generate_baseline_json.yaml'
    when baseline markdown files are modified in a pull request.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "PowerShell/ScubaGear/schema/ScubaBaseline.json",

    [Parameter(Mandatory=$false)]
    [string]$BaselineDirectory = "PowerShell/ScubaGear/baselines",

    [Parameter(Mandatory=$false)]
    [switch]$Validate
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Get the repository root (2 levels up from utils/workflow)
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Write-Host "Repository root: $RepoRoot"

# Resolve absolute paths
$BaselineDirectoryPath = Join-Path $RepoRoot $BaselineDirectory
$OutputFilePath = Join-Path $RepoRoot $OutputPath

Write-Host "Baseline directory: $BaselineDirectoryPath"
Write-Host "Output file: $OutputFilePath"

# Verify baseline directory exists
if (-not (Test-Path $BaselineDirectoryPath)) {
    throw "Baseline directory not found: $BaselineDirectoryPath"
}

# Import the baseline schema helper module
$ModulePath = Join-Path $RepoRoot "PowerShell\ScubaGear\Modules\Support\ScubaBaselineSchemaHelper.psm1"
if (-not (Test-Path $ModulePath)) {
    throw "Baseline schema helper module not found: $ModulePath"
}

Write-Host "Importing module: $ModulePath"
Import-Module $ModulePath -Force -Verbose:$false

# Generate the baseline JSON
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Generating ScubaBaseline.json from markdown files" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

try {
    # Create output directory if it doesn't exist
    $OutputDir = Split-Path -Parent $OutputFilePath
    if (-not (Test-Path $OutputDir)) {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        Write-Host "Created output directory: $OutputDir"
    }

    # Use the module function to generate the baseline
    $result = Update-ScubaConfigBaselineWithMarkdown `
        -BaselineFilePath $OutputFilePath `
        -BaselineDirectory $BaselineDirectoryPath

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "✓ Successfully generated ScubaBaseline.json" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Output file: $OutputFilePath" -ForegroundColor Green
    
    # Get file size
    $FileInfo = Get-Item $OutputFilePath
    $FileSizeKB = [math]::Round($FileInfo.Length / 1KB, 2)
    Write-Host "File size: $FileSizeKB KB" -ForegroundColor Green
    
    # Count products and policies
    $JsonContent = Get-Content $OutputFilePath -Raw | ConvertFrom-Json
    $ProductCount = $JsonContent.baselines.PSObject.Properties.Count
    $TotalPolicies = 0
    foreach ($product in $JsonContent.baselines.PSObject.Properties) {
        $TotalPolicies += $product.Value.Count
    }
    
    Write-Host "Products: $ProductCount" -ForegroundColor Green
    Write-Host "Total Policies: $TotalPolicies" -ForegroundColor Green
    Write-Host "Version: $($JsonContent.Version)" -ForegroundColor Green

    # Validate if requested
    if ($Validate) {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "Validating generated JSON" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        
        # Basic validation checks
        $ValidationErrors = @()
        
        # Check required top-level properties
        $RequiredProps = @('Version', 'DebugMode', 'baselines')
        foreach ($prop in $RequiredProps) {
            if (-not $JsonContent.PSObject.Properties.Name.Contains($prop)) {
                $ValidationErrors += "Missing required property: $prop"
            }
        }
        
        # Validate each policy has required fields
        $RequiredPolicyFields = @('id', 'name', 'policySection', 'sectionDescription', 'exclusionField', 'omissionField', 'annotationField')
        foreach ($product in $JsonContent.baselines.PSObject.Properties) {
            $productName = $product.Name
            foreach ($policy in $product.Value) {
                foreach ($field in $RequiredPolicyFields) {
                    if (-not $policy.PSObject.Properties.Name.Contains($field)) {
                        $ValidationErrors += "Product '$productName', Policy '$($policy.id)': Missing required field '$field'"
                    }
                }
            }
        }
        
        if ($ValidationErrors.Count -eq 0) {
            Write-Host "✓ Validation passed - No errors found" -ForegroundColor Green
        } else {
            Write-Host "✗ Validation failed with $($ValidationErrors.Count) error(s):" -ForegroundColor Red
            foreach ($error in $ValidationErrors) {
                Write-Host "  - $error" -ForegroundColor Red
            }
            exit 1
        }
    }

    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Generation Complete" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan

} catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "✗ Error generating ScubaBaseline.json" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
