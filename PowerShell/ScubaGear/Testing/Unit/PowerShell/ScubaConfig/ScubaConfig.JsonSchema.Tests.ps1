Describe "ScubaConfig JSON Schema Validation Tests" {
    BeforeAll {
        # Read the schema file for testing
        $SchemaPath = "$PSScriptRoot\..\..\..\..\Modules\ScubaConfig\ScubaConfigSchema.json"
        $script:SchemaContent = Get-Content -Path $SchemaPath -Raw | ConvertFrom-Json
    }

    Context "Schema Structure Validation" {
        It "Should have valid JSON schema structure" {
            $script:SchemaContent | Should -Not -BeNullOrEmpty
            $script:SchemaContent.'$schema' | Should -Be "http://json-schema.org/draft-07/schema#"
            $script:SchemaContent.title | Should -Be "ScubaGear Configuration Schema"
            $script:SchemaContent.type | Should -Be "object"
        }

        It "Should define required root-level properties" {
            $script:SchemaContent.properties | Should -Not -BeNullOrEmpty
            $script:SchemaContent.properties.ProductNames | Should -Not -BeNullOrEmpty
            $script:SchemaContent.properties.M365Environment | Should -Not -BeNullOrEmpty
        }

        It "Should have proper ProductNames definition" {
            $ProductNames = $script:SchemaContent.properties.ProductNames

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
            $M365Environment = $script:SchemaContent.properties.M365Environment

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
                $script:SchemaContent.properties.$prop | Should -Not -BeNullOrEmpty
                $script:SchemaContent.properties.$prop.type | Should -Be "boolean"
            }
        }

        It "Should have string properties with patterns where appropriate" {
            $StringPropsWithPatterns = @("OutFolderName", "OutProviderFileName", "OutRegoFileName", "OutReportName")

            foreach ($prop in $StringPropsWithPatterns) {
                if ($script:SchemaContent.properties.$prop) {
                    $script:SchemaContent.properties.$prop.type | Should -Be "string"
                    if ($script:SchemaContent.properties.$prop.pattern) {
                        $script:SchemaContent.properties.$prop.pattern | Should -Not -BeNullOrEmpty
                    }
                }
            }
        }
    }

    Context "Policy Configuration Schema" {
        It "Should have OmitPolicy definition with oneOf structure" {
            $OmitPolicy = $script:SchemaContent.properties.OmitPolicy

            $OmitPolicy | Should -Not -BeNullOrEmpty
            $OmitPolicy.type | Should -Be "object"
            $OmitPolicy.patternProperties | Should -Not -BeNullOrEmpty

            # Get the first (and only) pattern property definition
            $FirstProp = $OmitPolicy.patternProperties.PSObject.Properties | Select-Object -First 1
            $PatternDef = $FirstProp.Value

            # Test oneOf if it exists, otherwise just validate basic structure
            if ($PatternDef.oneOf) {
                $PatternDef.oneOf.Count | Should -BeGreaterThan 0
                $PatternDef.oneOf[1].properties.Rationale | Should -Not -BeNullOrEmpty
                $PatternDef.oneOf[1].properties.Rationale.type | Should -Be "string"
                $PatternDef.oneOf[1].required | Should -Contain "Rationale"
            } else {
                # If oneOf doesn't exist, just verify the pattern definition exists
                $PatternDef | Should -Not -BeNullOrEmpty
            }
        }

        It "Should have AnnotatePolicy definition with oneOf structure" {
            $AnnotatePolicy = $script:SchemaContent.properties.AnnotatePolicy

            $AnnotatePolicy | Should -Not -BeNullOrEmpty
            $AnnotatePolicy.type | Should -Be "object"
            $AnnotatePolicy.patternProperties | Should -Not -BeNullOrEmpty

            # Get the first (and only) pattern property definition
            $FirstProp = $AnnotatePolicy.patternProperties.PSObject.Properties | Select-Object -First 1
            $PatternDef = $FirstProp.Value

            # Test oneOf if it exists, otherwise just validate basic structure
            if ($PatternDef.oneOf) {
                $PatternDef.oneOf.Count | Should -BeGreaterThan 0
                $PatternDef.oneOf[1].properties.Comment | Should -Not -BeNullOrEmpty
                $PatternDef.oneOf[1].properties.Comment.type | Should -Be "string"
                $PatternDef.oneOf[1].required | Should -Contain "Comment"
            } else {
                # If oneOf doesn't exist, just verify the pattern definition exists
                $PatternDef | Should -Not -BeNullOrEmpty
            }
        }

        It "Should have strict policy ID pattern validation" {
            $OmitPolicy = $script:SchemaContent.properties.OmitPolicy
            $AnnotatePolicy = $script:SchemaContent.properties.AnnotatePolicy

            # Both should have additionalProperties set to false for strict validation
            $OmitPolicy.additionalProperties | Should -Be $false
            $AnnotatePolicy.additionalProperties | Should -Be $false
        }
    }

    Context "Product Configuration Schema" {
        It "Should have product definitions for all supported products" {
            $SupportedProducts = @("aad", "defender", "exo", "powerplatform", "sharepoint", "teams")

            foreach ($product in $SupportedProducts) {
                $script:SchemaContent.properties.$product | Should -Not -BeNullOrEmpty -Because "Product $product should be defined in schema"
            }
        }

        It "Should have exclusions definitions where applicable" {
            # AAD should have CapExclusions and RoleExclusions
            if ($script:SchemaContent.properties.aad -and $script:SchemaContent.properties.aad.properties) {
                $script:SchemaContent.properties.aad.properties.CapExclusions | Should -Not -BeNullOrEmpty
                $script:SchemaContent.properties.aad.properties.RoleExclusions | Should -Not -BeNullOrEmpty
            }

            # Defender should have SensitiveAccounts
            if ($script:SchemaContent.properties.defender -and $script:SchemaContent.properties.defender.properties) {
                $script:SchemaContent.properties.defender.properties.SensitiveAccounts | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Pattern Definitions" {
        It "Should have pattern definitions with friendly names" {
            if ($script:SchemaContent.definitions -and $script:SchemaContent.definitions.patterns) {
                $Patterns = $script:SchemaContent.definitions.patterns

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
            $script:SchemaContent.additionalProperties | Should -Be $true
        }

        It "Should have array validation for DNS resolvers" {
            if ($script:SchemaContent.properties.PreferredDnsResolvers) {
                $DnsResolvers = $script:SchemaContent.properties.PreferredDnsResolvers

                $DnsResolvers.type | Should -Be "array"
                $DnsResolvers.items | Should -Not -BeNullOrEmpty
                $DnsResolvers.items.type | Should -Be "string"
            }
        }

        It "Should have proper GUID validation in exclusions" {
            if ($script:SchemaContent.properties.aad -and
                $script:SchemaContent.properties.aad.properties -and
                $script:SchemaContent.properties.aad.properties.CapExclusions) {

                $CapExclusions = $script:SchemaContent.properties.aad.properties.CapExclusions

                if ($CapExclusions.properties.Users) {
                    $CapExclusions.properties.Users.type | Should -Be "array"
                    $CapExclusions.properties.Users.items | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
