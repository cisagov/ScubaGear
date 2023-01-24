# Requires Pester
# Requires a ProviderSettingsExport.json and TestResults.json in this Directory

# Connects to the Tenant
Invoke-Pester -Output Detailed .\Connection\Connection.Tests.ps1


$ProviderTests = Get-ChildItem (".\Providers") -Recurse | Where-Object { $_.Name -like 'Export*.ps1' }
if (!$ProviderTests)
{
    throw "Provider tests were not found, aborting this run"
}

# Runs individual provider tests
foreach ($ProviderTest in $ProviderTests.Name) {
    Invoke-Pester -Output Detailed ".\$($ProviderTest)"
}

Invoke-Pester -Output Detailed .\RunRego\Run-Rego.Tests.ps1
Invoke-Pester -Output Detailed .\CreateReport\New-Report.Tests.ps1
Import-Module ../../../PowerShell/ScubaGear/Modules/Orchestrator.psm1
Invoke-Pester -Output Detailed .\Orchestrator\Orchestrator.Tests.ps1
