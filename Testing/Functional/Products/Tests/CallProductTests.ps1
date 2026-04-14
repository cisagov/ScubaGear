<#
    .SYNOPSIS
    The purpose of this script is to enable a GitHub Action workflow to run the functional tests for one product.
    .EXAMPLE
    To run this script, call it from the root of the repo, like so: ./Testing/Functional/Products/Tests/CallProductTests.ps1 <params> <thumbprint>
#>

param(
    # The hashtable with the params.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [hashtable]$params,
    # The thumbprint of the cert used to access the product.
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$thumbprint
)

$testScriptDir = 'Testing/Functional/Products'

# Add thumbprint to hashtable
$params["Thumbprint"] = $thumbprint

# Create an array of test containers
$testContainers = @()
$testContainers += New-PesterContainer -Path $testScriptDir -Data $params

# Invoke Pester for each test container and capture structured counts.
$pesterResult = Invoke-Pester -Container $testContainers -Output Detailed -PassThru

$passedCount = [int]$pesterResult.PassedCount
$failedCount = [int]$pesterResult.FailedCount
$skippedCount = [int]$pesterResult.SkippedCount
$totalCount = [int]$pesterResult.TotalCount

Write-Host "Tests summary: $passedCount/$totalCount passing, $failedCount failed, $skippedCount skipped"

if ($env:GITHUB_OUTPUT) {
    "passed=$passedCount" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
    "failed=$failedCount" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
    "skipped=$skippedCount" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
    "total=$totalCount" | Out-File -FilePath $env:GITHUB_OUTPUT -Encoding utf8 -Append
}

if ($failedCount -gt 0) {
    exit 1
}
