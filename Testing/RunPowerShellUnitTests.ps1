# Requires Pester
# Runs all tests in the PowerShell Unit tests directory
Invoke-Pester -Path "$PSScriptRoot\..\PowerShell\ScubaGear\Testing\Unit\PowerShell" -Output Detailed
