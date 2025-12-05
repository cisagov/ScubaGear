Describe "ScubaConfig JSON Schema Validation Tests" {
    BeforeAll {
        # Read the schema file for testing
        $SchemaPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfig\ScubaConfigSchema.json"
        $SchemaContent = Get-Content -Path $SchemaPath -Raw | ConvertFrom-Json
    }

    Context "Schema Structure Validation" {
        It "Should have valid JSON schema structure" {
            $SchemaContent | Should -Not -BeNullOrEmpty
            $SchemaContent.'$schema' | Should -Be "http://json-schema.org/draft-07/schema#"
            $SchemaContent.title | Should -Be "ScubaGear Configuration Schema"
            $SchemaContent.type | Should -Be "object"
        }

        It "Should define required root-level properties" {
            $SchemaContent.properties | Should -Not -BeNullOrEmpty
            $SchemaContent.properties.ProductNames | Should -Not -BeNullOrEmpty
            $SchemaContent.properties.M365Environment | Should -Not -BeNullOrEmpty
        }

        It "Should have proper ProductNames definition" {
            $ProductNames = $SchemaContent.properties.ProductNames

            $ProductNames.type | Should -Be "array"
            $ProductNames.items.type | Should -Be "string"
            $ProductNames.items.enum | Should -Contain "aad"
            $ProductNames.items.enum | Should -Contain "defender"
            $ProductNames.items.enum | Should -Contain "exo"
            $ProductNames.items.enum | Should -Contain "powerplatform"
            $ProductNames.items.enum | Should -Contain "sharepoint"
            $ProductNames.items.enum | Should -Contain "teams"
            $ProductNames.items.enum | Should -Contain "*"
            $ProductNames.minItems | Should -Be 1
            $ProductNames.uniqueItems | Should -Be $true
        }

        It "Should have proper M365Environment definition" {
            $M365Environment = $SchemaContent.properties.M365Environment

            $M365Environment.type | Should -Be "string"
            $M365Environment.enum | Should -Contain "commercial"
            $M365Environment.enum | Should -Contain "gcc"
            $M365Environment.enum | Should -Contain "gcchigh"
            $M365Environment.enum | Should -Contain "dod"
            $M365Environment.default | Should -Be "commercial"
        }

        It "Should have boolean properties correctly defined" {
            $BooleanProperties = @("LogIn", "DisconnectOnExit", "SkipDoH")

            foreach ($prop in $BooleanProperties) {
                $SchemaContent.properties.$prop | Should -Not -BeNullOrEmpty
                $SchemaContent.properties.$prop.type | Should -Be "boolean"
            }
        }

        It "Should have string properties with patterns where appropriate" {
            $StringPropsWithPatterns = @("OutFolderName", "OutProviderFileName", "OutRegoFileName", "OutReportName")

            foreach ($prop in $StringPropsWithPatterns) {
                if ($SchemaContent.properties.$prop) {
                    $SchemaContent.properties.$prop.type | Should -Be "string"
                    if ($SchemaContent.properties.$prop.pattern) {
                        $SchemaContent.properties.$prop.pattern | Should -Not -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Context "Policy Configuration Schema" {
        It "Should have OmitPolicy definition with oneOf structure" {
            $OmitPolicy = $SchemaContent.properties.OmitPolicy

            $OmitPolicy | Should -Not -BeNullOrEmpty
            $OmitPolicy.type | Should -Be "object"
            $OmitPolicy.patternProperties | Should -Not -BeNullOrEmpty

            $PatternKey = $OmitPolicy.patternProperties.PSObject.Properties.Name[0]
            $PatternDef = $OmitPolicy.patternProperties.$PatternKey

            $PatternDef.oneOf | Should -Not -BeNullOrEmpty
            $PatternDef.oneOf.Count | Should -Be 2

            # First option: string
            $PatternDef.oneOf[0].type | Should -Be "string"

            # Second option: object with Rationale
            $PatternDef.oneOf[1].type | Should -Be "object"
            $PatternDef.oneOf[1].properties.Rationale | Should -Not -BeNullOrEmpty
            $PatternDef.oneOf[1].properties.Rationale.type | Should -Be "string"
            $PatternDef.oneOf[1].required | Should -Contain "Rationale"
        }

        It "Should have AnnotatePolicy definition with oneOf structure" {
            $AnnotatePolicy = $SchemaContent.properties.AnnotatePolicy

            $AnnotatePolicy | Should -Not -BeNullOrEmpty
            $AnnotatePolicy.type | Should -Be "object"
            $AnnotatePolicy.patternProperties | Should -Not -BeNullOrEmpty

            $PatternKey = $AnnotatePolicy.patternProperties.PSObject.Properties.Name[0]
            $PatternDef = $AnnotatePolicy.patternProperties.$PatternKey

            $PatternDef.oneOf | Should -Not -BeNullOrEmpty
            $PatternDef.oneOf.Count | Should -Be 2

            # First option: string
            $PatternDef.oneOf[0].type | Should -Be "string"

            # Second option: object with Comment
            $PatternDef.oneOf[1].type | Should -Be "object"
            $PatternDef.oneOf[1].properties.Comment | Should -Not -BeNullOrEmpty
            $PatternDef.oneOf[1].properties.Comment.type | Should -Be "string"
            $PatternDef.oneOf[1].required | Should -Contain "Comment"
        }

        It "Should have strict policy ID pattern validation" {
            $OmitPolicy = $SchemaContent.properties.OmitPolicy
            $AnnotatePolicy = $SchemaContent.properties.AnnotatePolicy

            # Both should have additionalProperties set to false for strict validation
            $OmitPolicy.additionalProperties | Should -Be $false
            $AnnotatePolicy.additionalProperties | Should -Be $false
        }
    }

    Context "Product Configuration Schema" {
        It "Should have product definitions for all supported products" {
            $SupportedProducts = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")

            foreach ($product in $SupportedProducts) {
                $SchemaContent.properties.$product | Should -Not -BeNullOrEmpty -Because "Product $product should be defined in schema"
            }
        }

        It "Should have exclusions definitions where applicable" {
            # AAD should have CapExclusions and RoleExclusions
            if ($SchemaContent.properties.aad -and $SchemaContent.properties.aad.properties) {
                $SchemaContent.properties.aad.properties.CapExclusions | Should -Not -BeNullOrEmpty
                $SchemaContent.properties.aad.properties.RoleExclusions | Should -Not -BeNullOrEmpty
            }

            # Defender should have SensitiveAccounts
            if ($SchemaContent.properties.defender -and $SchemaContent.properties.defender.properties) {
                $SchemaContent.properties.defender.properties.SensitiveAccounts | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Pattern Definitions" {
        It "Should have pattern definitions with friendly names" {
            if ($SchemaContent.definitions -and $SchemaContent.definitions.patterns) {
                $Patterns = $SchemaContent.definitions.patterns

                $Patterns | Should -Not -BeNullOrEmpty

                # Check for common patterns
                if ($Patterns.guid) {
                    $Patterns.guid.pattern | Should -Not -BeNullOrEmpty
                    $Patterns.guid.friendlyName | Should -Not -BeNullOrEmpty
                }

                if ($Patterns.upn) {
                    $Patterns.upn.pattern | Should -Not -BeNullOrEmpty
                    $Patterns.upn.friendlyName | Should -Not -BeNullOrEmpty
                }

                if ($Patterns.policyId) {
                    $Patterns.policyId.pattern | Should -Not -BeNullOrEmpty
                    $Patterns.policyId.friendlyName | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    Context "Schema Completeness" {
        It "Should support additionalProperties at root level" {
            # Root level should allow additional properties for custom configurations
            $SchemaContent.additionalProperties | Should -Be $true
        }

        It "Should have array validation for DNS resolvers" {
            if ($SchemaContent.properties.PreferredDnsResolvers) {
                $DnsResolvers = $SchemaContent.properties.PreferredDnsResolvers

                $DnsResolvers.type | Should -Be "array"
                $DnsResolvers.items | Should -Not -BeNullOrEmpty
                $DnsResolvers.items.type | Should -Be "string"
            }
        }

        It "Should have proper GUID validation in exclusions" {
            if ($SchemaContent.properties.aad -and
                $SchemaContent.properties.aad.properties -and
                $SchemaContent.properties.aad.properties.CapExclusions) {

                $CapExclusions = $SchemaContent.properties.aad.properties.CapExclusions

                if ($CapExclusions.properties.Users) {
                    $CapExclusions.properties.Users.type | Should -Be "array"
                    $CapExclusions.properties.Users.items | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}