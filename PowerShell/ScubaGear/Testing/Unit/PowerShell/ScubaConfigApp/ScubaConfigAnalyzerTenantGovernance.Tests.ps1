Describe -Tag 'Analyzer' -Name 'ScubaConfigAnalyzer tenant governance configuration' {
    BeforeAll {
        $scubaGearRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $configAppRoot = Join-Path $scubaGearRoot 'Modules\ScubaConfigApp'
        $helperPath = Join-Path $configAppRoot 'ScubaConfigAnalyzerHelpers\ScubaConfigAnalyzerTenantGovernanceHelper.psm1'
        $controlPath = Join-Path $configAppRoot 'ScubaConfigAnalyzer_Control_en-US.json'
        $xamlPath = Join-Path $configAppRoot 'ScubaConfigAppResources\ScubaConfigAnalyzerUI.xaml'
        $policyStubPath = Join-Path $scubaGearRoot 'Testing\Unit\PowerShell\CreateReport\CreateReportStubs\ProviderSettingsExport.json'

        Import-Module $helperPath -Force
        $control = Get-Content $controlPath -Raw | ConvertFrom-Json
        # $script: scope so the It blocks (separate scriptblocks) can read these without tripping PSUseDeclaredVarsMoreThanAssignments.
        [xml]$script:xaml = Get-Content $xamlPath -Raw
        $policies = @(Get-Content $policyStubPath -Raw | ConvertFrom-Json | Select-Object -ExpandProperty conditional_access_policies)
        $script:document = ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies $policies -TenantId 'test-tenant' `
            -SchemaUrl $control.tenantGovernanceSchemaURL | ConvertFrom-Json
    }

    It 'is disabled by default and declares the UTCM schema URL' {
        $control.GenerateTenantGovernanceConfig | Should -BeFalse
        $control.tenantGovernanceSchemaURL | Should -Be 'https://www.schemastore.org/utcm-monitor.json'
    }

    It 'provides the feature-gated tab and its copy and export controls' {
        foreach ($name in @('TenantGovernanceTab', 'TenantGovernanceJson_TextBox', 'CopyTenantGovernance_Button', 'ExportTenantGovernance_Button')) {
            $xaml.SelectSingleNode("//*[@*[local-name()='Name']='$name']") | Should -Not -BeNullOrEmpty
        }
        $xaml.SelectSingleNode("//*[@*[local-name()='Name']='TenantGovernanceTab']").Visibility | Should -Be 'Collapsed'
    }

    It 'emits a flat baseline object with parameters as an array' {
        $document.PSObject.Properties.Name | Should -Not -Contain 'baseline'
        $document.PSObject.Properties.Name | Should -Contain 'resources'
        (Get-Content $policyStubPath -Raw | ConvertFrom-Json) | Out-Null
        $rawParameters = (ConvertTo-ScATenantGovernanceJson -ConditionalAccessPolicies $policies -TenantId 'test-tenant' | ConvertFrom-Json).parameters
        ,$rawParameters | Should -BeOfType [System.Object[]]
    }

    It 'creates one Entra Conditional Access resource per collected policy' {
        @($document.resources).Count | Should -Be $policies.Count
        @($document.resources | Where-Object { $_.resourceType -ne 'microsoft.entra.conditionalaccesspolicy' }).Count | Should -Be 0
        @($document.resources | Where-Object { [string]::IsNullOrWhiteSpace($_.properties.DisplayName) }).Count | Should -Be 0
    }

    It 'preserves UTCM collection fields as arrays when a source policy has one value' {
        $singleValuePolicy = $document.resources | Where-Object { $_.properties.IncludeApplications.Count -eq 1 } | Select-Object -First 1
        $singleValuePolicy | Should -Not -BeNullOrEmpty
        ($singleValuePolicy.properties.IncludeApplications -is [array]) | Should -BeTrue
    }
}
