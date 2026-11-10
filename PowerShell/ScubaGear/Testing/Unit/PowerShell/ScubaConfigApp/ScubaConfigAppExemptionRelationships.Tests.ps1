Describe -Tag 'Helpers' -Name 'ScubaConfigApp policy exemption relationships (parent / dependent policies)' {
    BeforeAll {
        $scubaGearRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
        $script:appRoot = Join-Path $scubaGearRoot 'Modules\ScubaConfigApp'
        $helpersPath = Join-Path $appRoot 'ScubaConfigAppHelpers'
        $script:configSchemaPath = Join-Path $scubaGearRoot 'schemas\ScubaConfigSchema.json'
        $script:controlPath = Join-Path $appRoot 'ScubaConfigApp_Control_en-US.json'
        $script:control = Get-Content $controlPath -Raw | ConvertFrom-Json
        $script:relationship = (Get-Content $configSchemaPath -Raw | ConvertFrom-Json).schemaMetadata.policyExclusionRelationships.'MS.AAD.2.1v2'

        Import-Module (Join-Path $helpersPath 'ScubaConfigAppDebugHelper.psm1') -Force
        Import-Module (Join-Path $helpersPath 'ScubaConfigAppDynamicCardHelper.psm1') -Force
        Import-Module (Join-Path $helpersPath 'ScubaConfigAppCommonUIHelper.psm1') -Force
    }

    AfterAll {
        foreach ($name in 'ScubaConfigAppCommonUIHelper', 'ScubaConfigAppDynamicCardHelper', 'ScubaConfigAppDebugHelper') {
            Remove-Module $name -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Control file configuration' {
        It 'points ConfigSchemaPath at the config schema that holds the relationship metadata' {
            $resolved = Join-Path $appRoot $control.ConfigSchemaPath
            Test-Path $resolved | Should -BeTrue
            (Resolve-Path $resolved).Path | Should -Be (Resolve-Path $configSchemaPath).Path
        }

        It 'enables the relationship note only on the Exclusions card' {
            $exclusions = $control.baselineControls | Where-Object controlType -EQ 'Exclusions'
            $exclusions.showExemptionRelationshipNote | Should -BeTrue
            foreach ($other in $control.baselineControls | Where-Object controlType -NE 'Exclusions') {
                $other.PSObject.Properties['showExemptionRelationshipNote'] | Should -BeNullOrEmpty
            }
        }

        It 'stores the localizable note and warning text in the control file, not in code' {
            foreach ($key in 'PolicyExemptionParentNote', 'PolicyExemptionDependentNote', 'PolicyExemptionOmittedWarning', 'PolicyExemptionWarningsPrefix') {
                $control.localeInfoMessages.$key | Should -Not -BeNullOrEmpty
            }
            @($control.policyExemptionRelationships.exemptionFields) | Should -Contain 'Users'
            @($control.policyExemptionRelationships.exemptionFields) | Should -Contain 'Groups'
            @($control.policyExemptionRelationships.exemptionFields) | Should -Contain 'GuestUserTypes'
        }

        It 'does not hardcode the related policy ids in the helper code' {
            foreach ($file in 'ScubaConfigAppDynamicCardHelper.psm1', 'ScubaConfigAppCommonUIHelper.psm1') {
                (Get-Content (Join-Path $helpersPath $file) -Raw) | Should -Not -Match 'MS\.AAD\.2\.[12]v2'
            }
        }
    }

    Context 'Import-PolicyExclusionRelationship and Get-PolicyExclusionRelationshipNote' {
        BeforeEach {
            InModuleScope ScubaConfigAppDynamicCardHelper -Parameters @{ control = $control } {
                param($control)
                $script:syncHash = [hashtable]::Synchronized(@{ UIConfigs = $control })
            }
        }

        It 'loads the parent and dependents from the config schema' {
            InModuleScope ScubaConfigAppDynamicCardHelper -Parameters @{ path = $configSchemaPath; relationship = $relationship } {
                param($path, $relationship)
                Import-PolicyExclusionRelationship -ConfigSchemaPath $path
                $loaded = $script:syncHash.PolicyExclusionRelationships['MS.AAD.2.1v2']
                @($loaded.Dependents) | Should -Be @($relationship.dependents)
                $loaded.Note | Should -Be $relationship.note
                $script:syncHash.PolicyExclusionRelationships.ContainsKey('_comment') | Should -BeFalse
            }
        }

        It 'leaves the table empty when the schema is missing' {
            InModuleScope ScubaConfigAppDynamicCardHelper {
                Import-PolicyExclusionRelationship -ConfigSchemaPath 'C:\does\not\exist\ScubaConfigSchema.json'
                $script:syncHash.PolicyExclusionRelationships.Count | Should -Be 0
                Get-PolicyExclusionRelationshipNote -PolicyId 'MS.AAD.2.1v2' | Should -BeNullOrEmpty
            }
        }

        It 'shows the schema note on the parent policy card' {
            InModuleScope ScubaConfigAppDynamicCardHelper -Parameters @{ path = $configSchemaPath; relationship = $relationship } {
                param($path, $relationship)
                Import-PolicyExclusionRelationship -ConfigSchemaPath $path
                $note = Get-PolicyExclusionRelationshipNote -PolicyId 'MS.AAD.2.1v2'
                $note | Should -Be ($script:syncHash.UIConfigs.localeInfoMessages.PolicyExemptionParentNote -f $relationship.note)
                $note | Should -Match ([regex]::Escape($relationship.note))
            }
        }

        It 'shows that a dependent policy reads the parent policy exemptions' {
            InModuleScope ScubaConfigAppDynamicCardHelper -Parameters @{ path = $configSchemaPath; relationship = $relationship } {
                param($path, $relationship)
                Import-PolicyExclusionRelationship -ConfigSchemaPath $path
                $dependent = @($relationship.dependents)[0]
                $note = Get-PolicyExclusionRelationshipNote -PolicyId $dependent
                $note | Should -Match "^Note: $([regex]::Escape($dependent)) reads the exemptions configured for MS\.AAD\.2\.1v2"
                $note | Should -Not -Match ([regex]::Escape($relationship.note))
            }
        }

        It 'returns nothing for an unrelated policy' {
            InModuleScope ScubaConfigAppDynamicCardHelper -Parameters @{ path = $configSchemaPath } {
                param($path)
                Import-PolicyExclusionRelationship -ConfigSchemaPath $path
                Get-PolicyExclusionRelationshipNote -PolicyId 'MS.AAD.3.1v1' | Should -BeNullOrEmpty
            }
        }

        It 'follows custom relationship metadata instead of fixed policy ids' {
            InModuleScope ScubaConfigAppDynamicCardHelper {
                $script:syncHash.PolicyExclusionRelationships = @{ 'MS.TEST.1.1v1' = @{ Dependents = @('MS.TEST.1.2v1'); Note = 'Custom note.' } }
                Get-PolicyExclusionRelationshipNote -PolicyId 'MS.TEST.1.1v1' | Should -Be 'Note: Custom note.'
                Get-PolicyExclusionRelationshipNote -PolicyId 'MS.TEST.1.2v1' | Should -Match 'MS\.TEST\.1\.2v1 reads the exemptions configured for MS\.TEST\.1\.1v1'
            }
        }
    }

    Context 'Get-PolicyExemptionDependencyWarning' {
        BeforeEach {
            InModuleScope ScubaConfigAppCommonUIHelper -Parameters @{ control = $control; relationship = $relationship } {
                param($control, $relationship)
                $script:syncHash = [hashtable]::Synchronized(@{
                    UIConfigs = $control
                    PolicyExclusionRelationships = @{ 'MS.AAD.2.1v2' = @{ Dependents = @('MS.AAD.2.2v2'); Note = $relationship.note } }
                    ExclusionData = [ordered]@{}
                    OmissionData  = [ordered]@{}
                })
            }
        }

        It 'warns when the parent has <Field> exemptions and the dependent is omitted' -ForEach @(
            @{ Field = 'Users';          Values = @('11111111-1111-1111-1111-111111111111') }
            @{ Field = 'Groups';         Values = @('22222222-2222-2222-2222-222222222222') }
            @{ Field = 'GuestUserTypes'; Values = @('b2bCollaborationGuest') }
        ) {
            InModuleScope ScubaConfigAppCommonUIHelper -Parameters @{ Field = $Field; Values = $Values; relationship = $relationship } {
                param($Field, $Values, $relationship)
                $script:syncHash.ExclusionData['Aad'] = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ CapExclusions = [ordered]@{ $Field = $Values } } }
                $script:syncHash.OmissionData['Aad'] = [ordered]@{ OmitPolicy = [ordered]@{ 'MS.AAD.2.2v2' = [ordered]@{ Rationale = 'not needed' } } }
                $warnings = @(Get-PolicyExemptionDependencyWarning)
                $warnings.Count | Should -Be 1
                $warnings[0] | Should -Match 'MS\.AAD\.2\.1v2 has exemptions configured but MS\.AAD\.2\.2v2 is listed in Omit Policies'
                $warnings[0] | Should -Match ([regex]::Escape($relationship.note))
            }
        }

        It 'does not warn when the dependent policy is not omitted' {
            InModuleScope ScubaConfigAppCommonUIHelper {
                $script:syncHash.ExclusionData['Aad'] = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ CapExclusions = [ordered]@{ Users = @('u1') } } }
                $script:syncHash.OmissionData['Aad'] = [ordered]@{ OmitPolicy = [ordered]@{ 'MS.AAD.3.1v1' = [ordered]@{ Rationale = 'other' } } }
                @(Get-PolicyExemptionDependencyWarning).Count | Should -Be 0
            }
        }

        It 'does not warn when nothing is omitted' {
            InModuleScope ScubaConfigAppCommonUIHelper {
                $script:syncHash.ExclusionData['Aad'] = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ CapExclusions = [ordered]@{ Users = @('u1') } } }
                @(Get-PolicyExemptionDependencyWarning).Count | Should -Be 0
            }
        }

        It 'does not warn when the parent has no exemptions' {
            InModuleScope ScubaConfigAppCommonUIHelper {
                $script:syncHash.OmissionData['Aad'] = [ordered]@{ OmitPolicy = [ordered]@{ 'MS.AAD.2.2v2' = [ordered]@{ Rationale = 'not needed' } } }
                @(Get-PolicyExemptionDependencyWarning).Count | Should -Be 0
                $script:syncHash.ExclusionData['Aad'] = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ CapExclusions = [ordered]@{ Users = @() } } }
                @(Get-PolicyExemptionDependencyWarning).Count | Should -Be 0
            }
        }

        It 'ignores exclusion fields that are not exemptions of principals' {
            InModuleScope ScubaConfigAppCommonUIHelper {
                $script:syncHash.ExclusionData['Aad'] = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ CapExclusions = [ordered]@{ Applications = @('app1') } } }
                $script:syncHash.OmissionData['Aad'] = [ordered]@{ OmitPolicy = [ordered]@{ 'MS.AAD.2.2v2' = [ordered]@{ Rationale = 'not needed' } } }
                @(Get-PolicyExemptionDependencyWarning).Count | Should -Be 0
            }
        }

        It 'does not warn when only the parent policy is omitted' {
            InModuleScope ScubaConfigAppCommonUIHelper {
                $script:syncHash.ExclusionData['Aad'] = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ CapExclusions = [ordered]@{ Users = @('u1') } } }
                $script:syncHash.OmissionData['Aad'] = [ordered]@{ OmitPolicy = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ Rationale = 'not needed' } } }
                @(Get-PolicyExemptionDependencyWarning).Count | Should -Be 0
            }
        }

        It 'returns nothing when no relationships are loaded' {
            InModuleScope ScubaConfigAppCommonUIHelper {
                $script:syncHash.PolicyExclusionRelationships = @{}
                $script:syncHash.ExclusionData['Aad'] = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ CapExclusions = [ordered]@{ Users = @('u1') } } }
                $script:syncHash.OmissionData['Aad'] = [ordered]@{ OmitPolicy = [ordered]@{ 'MS.AAD.2.2v2' = [ordered]@{ Rationale = 'not needed' } } }
                @(Get-PolicyExemptionDependencyWarning).Count | Should -Be 0
            }
        }

        It 'is reported by Invoke-RequiredFieldValidation as a non-blocking warning' {
            Mock -ModuleName ScubaConfigAppCommonUIHelper Write-DebugOutput {}
            InModuleScope ScubaConfigAppCommonUIHelper {
                $script:syncHash.UIConfigs = [pscustomobject]@{
                    requiredFields = [pscustomobject]@{}
                    MinimumProductsRequired = 1
                    localeInfoMessages = $script:syncHash.UIConfigs.localeInfoMessages
                    policyExemptionRelationships = $script:syncHash.UIConfigs.policyExemptionRelationships
                    localeErrorMessages = [pscustomobject]@{ ProductSelection = 'Select {0}' }
                }
                $script:syncHash.GeneralSettingsData = @{ ProductNames = @('aad') }
                $script:syncHash.ExclusionData['Aad'] = [ordered]@{ 'MS.AAD.2.1v2' = [ordered]@{ CapExclusions = [ordered]@{ Users = @('u1') } } }
                $script:syncHash.OmissionData['Aad'] = [ordered]@{ OmitPolicy = [ordered]@{ 'MS.AAD.2.2v2' = [ordered]@{ Rationale = 'not needed' } } }
                $result = Invoke-RequiredFieldValidation
                $result.IsValid | Should -BeTrue
                $result.Errors.Count | Should -Be 0
                @($result.Warnings).Count | Should -Be 1
                $result.Warnings[0] | Should -Match 'MS\.AAD\.2\.2v2 is listed in Omit Policies'

                $script:syncHash.OmissionData['Aad'] = [ordered]@{ OmitPolicy = [ordered]@{} }
                @((Invoke-RequiredFieldValidation).Warnings).Count | Should -Be 0
            }
        }
    }
}
