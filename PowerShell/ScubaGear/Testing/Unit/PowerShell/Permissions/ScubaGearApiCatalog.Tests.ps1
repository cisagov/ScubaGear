BeforeDiscovery {
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Permissions' -Resolve
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'PermissionsHelper.psm1') -Force

    $CatalogFile = Join-Path -Path $PSScriptRoot -ChildPath '../../../../schemas/ScubaGearApiCatalog.json' -Resolve
    $CatalogEntries = @((Get-Content -Path $CatalogFile -Raw | ConvertFrom-Json) | ForEach-Object { $_ })

    $script:RestHelperCases = @(
        $CatalogEntries |
            Where-Object { $_.functionName -and $_.category -eq 'Provider REST helper' } |
            ForEach-Object { @{ FunctionName = $_.functionName; Entry = $_ } }
    )
    $script:ProductCases = 'aad', 'exo', 'securitysuite', 'teams', 'sharepoint', 'powerplatform' | ForEach-Object { @{ Product = $_ } }
}

# The catalog holds two kinds of entries side by side: Graph/REST API records keyed by moduleCmdlet (read by
# Get-ScubaGearPermissions) and REST call entries keyed by functionName (read by Get-ScubaGearRestEndpoint).
Describe -Tag 'PermissionsHelper' -Name 'ScubaGearApiCatalog.json structure' {
    BeforeAll {
        $CatalogFile = Join-Path -Path $PSScriptRoot -ChildPath '../../../../schemas/ScubaGearApiCatalog.json' -Resolve
        $script:Catalog = @((Get-Content -Path $CatalogFile -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
    }

    It 'parses as a JSON array' {
        $script:Catalog.Count | Should -BeGreaterThan 0
    }

    It 'gives every entry exactly one identifying key (moduleCmdlet, functionName or _meta)' {
        $Bad = $script:Catalog | Where-Object {
            $Keys = $_.PSObject.Properties.Name
            (@('moduleCmdlet', 'functionName', '_meta') | Where-Object { $Keys -contains $_ }).Count -ne 1
        }
        $Bad | Should -BeNullOrEmpty
    }

    It 'has no duplicate functionName entries' {
        $Names = $script:Catalog | Where-Object { $_.functionName } | ForEach-Object { $_.functionName }
        ($Names | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name) | Should -BeNullOrEmpty
    }

    It 'keeps moduleCmdlet records first so consumers that read the file as a Graph catalog see them unchanged' {
        $FirstRest = [array]::IndexOf($script:Catalog.ForEach({ [bool]$_.moduleCmdlet }), $false)
        $FirstRest | Should -BeGreaterThan 0
        @($script:Catalog[$FirstRest..($script:Catalog.Count - 1)] | Where-Object { $_.moduleCmdlet }) | Should -BeNullOrEmpty
    }
}

Describe -Tag 'PermissionsHelper' -Name 'REST helper permissions in ScubaGearApiCatalog.json' {
    BeforeAll {
        # Other test files in this folder remove the module in AfterAll, so import it again for this run.
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../../../Modules/Permissions/PermissionsHelper.psm1') -Force
        $CatalogFile = Join-Path -Path $PSScriptRoot -ChildPath '../../../../schemas/ScubaGearApiCatalog.json' -Resolve
        $script:Catalog = @((Get-Content -Path $CatalogFile -Raw | ConvertFrom-Json) | ForEach-Object { $_ })
        $script:Records = @($script:Catalog | Where-Object { $_.moduleCmdlet })
        $script:RepoRoot = Join-Path -Path $PSScriptRoot -ChildPath '../../../../../..' -Resolve

        # leastPermissions / spRolePermissions use empty strings or empty arrays when nothing is required.
        function Get-RecordValues($Records, $Field) {
            @($Records | ForEach-Object { $_.$Field } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
        }
    }

    Context 'Every provider REST helper documents its permissions' {
        It 'has a complete permissions object for <FunctionName>' -ForEach $script:RestHelperCases {
            $Entry.permissions | Should -Not -BeNullOrEmpty
            $Keys = $Entry.permissions.PSObject.Properties.Name
            foreach ($Required in 'applicationPermissions', 'servicePrincipalRoles', 'interactiveRoles', 'prohibitedPermissions',
                'otherRequirements', 'permissionsRef', 'docs', 'verified') {
                $Keys | Should -Contain $Required
            }
            $Entry.permissions.verified | Should -BeOfType [bool]
        }

        It 'lists documentation files that exist for <FunctionName>' -ForEach $script:RestHelperCases {
            foreach ($Doc in @($Entry.permissions.docs)) {
                Join-Path -Path $script:RepoRoot -ChildPath $Doc | Should -Exist
            }
        }

        It 'never both requires and prohibits the same permission for <FunctionName>' -ForEach $script:RestHelperCases {
            $Overlap = @($Entry.permissions.applicationPermissions) | Where-Object { $_ -in @($Entry.permissions.prohibitedPermissions) }
            $Overlap | Should -BeNullOrEmpty
        }
    }

    Context 'Permissions agree with the product-level records that grant them' {
        It 'resolves every permissionsRef for <FunctionName> to an existing moduleCmdlet record' -ForEach $script:RestHelperCases {
            foreach ($Ref in @($Entry.permissions.permissionsRef)) {
                @($script:Records | Where-Object { $_.moduleCmdlet -eq $Ref }).Count | Should -BeGreaterThan 0 -Because "'$Ref' should be a moduleCmdlet in the catalog"
            }
        }

        It 'matches the referenced records for <FunctionName>' -ForEach ($script:RestHelperCases | Where-Object { @($_.Entry.permissions.permissionsRef).Count -gt 0 }) {
            $Refs = @($Entry.permissions.permissionsRef)
            $Referenced = @($script:Records | Where-Object { $_.moduleCmdlet -in $Refs })

            $GrantedPermissions = Get-RecordValues $Referenced 'leastPermissions'
            $GrantedRoles = Get-RecordValues $Referenced 'spRolePermissions'

            @($Entry.permissions.applicationPermissions | Sort-Object -Unique) | Should -Be $GrantedPermissions
            @($Entry.permissions.servicePrincipalRoles | Sort-Object -Unique) | Should -Be $GrantedRoles
        }
    }

    Context 'Known requirements that are not simple grants' {
        It 'records that Power BI must not be granted Tenant.Read.All' {
            $Entry = $script:Catalog | Where-Object { $_.functionName -eq 'Get-PowerBITenantSettingsRest' }
            $Entry.permissions.prohibitedPermissions | Should -Contain 'Tenant.Read.All'
            $Entry.permissions.applicationPermissions | Should -Not -Contain 'Tenant.Read.All'
        }

        It 'flags the Teams unified settings roles as not verified against the catalog' {
            $Entry = $script:Catalog | Where-Object { $_.functionName -eq 'Get-TeamsM365UnifiedTenantSettingsRest' }
            $Entry.permissions.verified | Should -BeFalse
        }
    }

    Context 'REST entries do not leak into permission lookups' {
        It 'returns only moduleCmdlet records for <Product>' -ForEach $script:ProductCases {
            $Records = @(Get-ScubaGearPermissions -Product $Product -ServicePrincipal -OutAs all)
            $Records.Count | Should -BeGreaterThan 0
            @($Records | Where-Object { $_.PSObject.Properties.Name -contains 'functionName' }) | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Remove-Module PermissionsHelper -ErrorAction SilentlyContinue
}
