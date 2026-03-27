BeforeDiscovery {
    # Create default OPA directory EARLY for tests (needed in CI environments like GitHub Actions)
    # This must happen BEFORE loading ScubaConfig module because module initialization validates OPA path
    $DefaultOPAPath = Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"
    if (-not (Test-Path $DefaultOPAPath)) {
        New-Item -Path $DefaultOPAPath -ItemType Directory -Force | Out-Null
    }
    
    # Create dummy OPA executable for default location
    $IsLinuxOS = (Test-Path variable:IsLinux) -and $IsLinux
    $IsMacOSOS = (Test-Path variable:IsMacOS) -and $IsMacOS
    if ($IsLinuxOS) {
        $OPAExeName = "opa_linux_amd64"
    }
    elseif ($IsMacOSOS) {
        $OPAExeName = "opa_darwin_amd64"
    }
    else {
        $OPAExeName = "opa_windows_amd64.exe"
    }
    $OPAExePath = Join-Path -Path $DefaultOPAPath -ChildPath $OPAExeName
    if (-not (Test-Path $OPAExePath)) {
        New-Item -Path $OPAExePath -ItemType File -Force | Out-Null
    }
    
    # Also create OPA in test directory (for OPAPath: . in orchestrator_config_test.yaml)
    $TestOPAPath = Join-Path -Path $PSScriptRoot -ChildPath $OPAExeName
    if (-not (Test-Path $TestOPAPath)) {
        New-Item -Path $TestOPAPath -ItemType File -Force | Out-Null
    }
    
    $ModuleRootPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\..\..\Modules'
    
    # Import ScubaConfig module (moved from 'using module' to ensure OPA setup happens first)
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'ScubaConfig\ScubaConfig.psm1') -Force
    
    # Import the branch version of Orchestrator
    Import-Module (Join-Path -Path $ModuleRootPath -ChildPath 'Orchestrator.psm1') -Force
}

InModuleScope Orchestrator {
    BeforeAll {
        # Set up all mocks ONCE for all tests
        $script:TestSplat = @{}
        
        # Create default OPA directory for tests (needed in CI environments like GitHub Actions)
        $script:DefaultOPAPath = Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"
        if (-not (Test-Path $script:DefaultOPAPath)) {
            New-Item -Path $script:DefaultOPAPath -ItemType Directory -Force | Out-Null
        }
        
        # Create a dummy OPA executable for testing (required for configuration validation)
        # Determine OS-specific executable name
        $IsLinuxOS = (Test-Path variable:IsLinux) -and $IsLinux
        $IsMacOSOS = (Test-Path variable:IsMacOS) -and $IsMacOS
        
        if ($IsLinuxOS) {
            $script:DummyOPAName = "opa_linux_amd64"
        }
        elseif ($IsMacOSOS) {
            $script:DummyOPAName = "opa_darwin_amd64"
        }
        else {
            $script:DummyOPAName = "opa_windows_amd64.exe"
        }
        $script:DummyOPAPath = Join-Path -Path $script:DefaultOPAPath -ChildPath $script:DummyOPAName
        # Create empty file to satisfy OPA validation
        if (-not (Test-Path $script:DummyOPAPath)) {
            New-Item -Path $script:DummyOPAPath -ItemType File -Force | Out-Null
        }
        
        # Also create OPA in test directory (for OPAPath: . in orchestrator_config_test.yaml)
        $TestOPAPath = Join-Path -Path $PSScriptRoot -ChildPath $script:DummyOPAName
        if (-not (Test-Path $TestOPAPath)) {
            New-Item -Path $TestOPAPath -ItemType File -Force | Out-Null
        }
        
        # Define stub functions that will be mocked
        function ConvertTo-ResultsCsv {throw 'this will be mocked'}
        function Disconnect-SCuBATenant {throw 'this will be mocked'}
        
        Mock -ModuleName Orchestrator Remove-Resources {}
        Mock -ModuleName Orchestrator Import-Resources {}
        Mock -ModuleName Orchestrator Invoke-Connection {
            if ($ScubaConfig) { $script:TestSplat['LogIn'] = $ScubaConfig.LogIn }
        }
        Mock -ModuleName Orchestrator Get-TenantDetail { '{"DisplayName": "displayName"}' }
        Mock -ModuleName Orchestrator Invoke-ProviderList {
            if ($ScubaConfig) {
                $script:TestSplat['AppID'] = $ScubaConfig.AppID
                $script:TestSplat['Organization'] = $ScubaConfig.Organization
                $script:TestSplat['CertificateThumbprint'] = $ScubaConfig.CertificateThumbprint
            }
        }
        Mock -ModuleName Orchestrator Invoke-RunRego {
            if ($ScubaConfig) {
                $script:TestSplat['OPAPath'] = $ScubaConfig.OPAPath
                $script:TestSplat['OutProviderFileName'] = $ScubaConfig.OutProviderFileName
                $script:TestSplat['OutRegoFileName'] = $ScubaConfig.OutRegoFileName
            }
        }
        Mock -ModuleName Orchestrator Invoke-ReportCreation {
            if ($ScubaConfig) {
                $script:TestSplat['ProductNames'] = $ScubaConfig.ProductNames
                $script:TestSplat['M365Environment'] = $ScubaConfig.M365Environment
                $script:TestSplat['OutPath'] = $ScubaConfig.OutPath
                $script:TestSplat['OutFolderName'] = $ScubaConfig.OutFolderName
                $script:TestSplat['OutReportName'] = $ScubaConfig.OutReportName
            }
        }
        Mock -ModuleName Orchestrator Merge-JsonOutput {
            if ($ScubaConfig) { $script:TestSplat['OutJsonFileName'] = $ScubaConfig.OutJsonFileName }
        }
        Mock -ModuleName Orchestrator ConvertTo-ResultsCsv {}
        Mock -ModuleName Orchestrator Disconnect-SCuBATenant {
            if ($ScubaConfig) { $script:TestSplat['DisconnectOnExit'] = $ScubaConfig.DisconnectOnExit }
        }
        Mock -CommandName New-Item {}
        Mock -CommandName Copy-Item {}
    }

    Context  "Parameter override test"{

        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba config with no command line override' {
            BeforeAll {
                # Reset TestSplat for this test
                $script:TestSplat = @{}
                
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@("teams")
                        M365Environment='commercial'
                        LogIn=$true
                        DisconnectOnExit=$false
                        OutPath=$PSScriptRoot
                        OutFolderName='ScubaReports'
                        OutProviderFileName='ProviderSettingsExport'
                        OutRegoFileName='TestResults'
                        OutReportName='BaselineReports'
                        OutJsonFileName='ScubaResults'
                        Organization='sub.domain.com'
                        AppID='12345678-1234-1234-1234-123456789012'
                        CertificateThumbprint='1234567890ABCDEF1234567890ABCDEF12345678'
                    }
                }
                Invoke-SCuBA -ConfigFilePath (Join-Path -Path $PSScriptRoot -ChildPath "orchestrator_config_test.yaml")
            }

            It "Verify parameter ""<parameter>"" with value ""<value>""" -ForEach @(
                @{ Parameter = "M365Environment";       Value = "commercial"           },
                @{ Parameter = "ProductNames";          Value = @("teams")             },
                @{ Parameter = "LogIn";                 Value = $true                  },
                @{ Parameter = "OutFolderName";         Value = "ScubaReports"         },
                @{ Parameter = "OutProviderFileName";   Value = "ProviderSettingsExport" },
                @{ Parameter = "OutRegoFileName";       Value = "TestResults"          },
                @{ Parameter = "OutReportName";         Value = "BaselineReports"      },
                @{ Parameter = "OutJsonFileName";       Value = "ScubaResults"         },
                @{ Parameter = "Organization";          Value = "sub.domain.com"       },
                @{ Parameter = "AppID";                 Value = "12345678-1234-1234-1234-123456789012"  },
                @{ Parameter = "CertificateThumbprint"; Value = "1234567890ABCDEF1234567890ABCDEF12345678"  }
                ){
                    $script:TestSplat[$Parameter] | Should -BeExactly $Value -Because "got $($script:TestSplat[$Parameter])"
            }
        }
        
        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba with command line ProductNames wild card override' {
            BeforeAll {
                # Reset TestSplat for this test
                $script:TestSplat = @{}
                
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@("teams")
                        M365Environment='commercial'
                        LogIn=$true
                        DisconnectOnExit=$false
                        OutPath=$PSScriptRoot
                        OutFolderName='ScubaReports'
                        OutProviderFileName='ProviderSettingsExport'
                        OutRegoFileName='TestResults'
                        OutReportName='BaselineReports'
                        OutJsonFileName='ScubaResults'
                        Organization='sub.domain.com'
                        AppID='12345678-1234-1234-1234-123456789012'
                        CertificateThumbprint='1234567890ABCDEF1234567890ABCDEF12345678'
                    }
                }
                Invoke-SCuBA `
                  -ProductNames "*" `
                  -ConfigFilePath (Join-Path -Path $PSScriptRoot -ChildPath "orchestrator_config_test.yaml")
            }

            It "Verify parameter, ProductNames, with wildcard CLI override"{
                $script:TestSplat['ProductNames'] | Should -BeExactly @('aad', 'defender', 'exo', 'powerplatform', 'sharepoint', 'teams') -Because "got $($script:TestSplat['ProductNames'])"
            }
        }

        Describe -Tag 'Orchestrator' -Name 'Invoke-Scuba with config file ProductNames wild card' {
            BeforeAll {
                # Reset TestSplat for this test
                $script:TestSplat = @{}
                
                function global:ConvertFrom-Yaml {
                    @{
                        ProductNames=@('aad', 'defender', 'exo', 'powerplatform', 'sharepoint', 'teams')
                        M365Environment='commercial'
                        Login=$true
                        OutPath=$PSScriptRoot
                        OutFolderName='ScubaReports'
                        OutProviderFileName='TenantSettingsExport'
                        OutRegoFileName='ScubaTestResults'
                        OutReportName='ScubaReports'
                        Organization='sub.domain.com'
                        AppID='12345678-1234-1234-1234-123456789012'
                        CertificateThumbprint='1234567890ABCDEF1234567890ABCDEF12345678'
                    }
                }
                Invoke-SCuBA `
                  -ConfigFilePath (Join-Path -Path $PSScriptRoot -ChildPath "product_wildcard_config_test.yaml")
            }

            It "Verify parameter, ProductNames, reflects all products"{
                $script:TestSplat['ProductNames'] | Should -BeExactly @('aad', 'defender', 'exo', 'powerplatform', 'sharepoint', 'teams') -Because "got $($script:TestSplat['ProductNames'])"
            }
        }
    }
    
    # Cleanup - remove dummy OPA executables
    AfterAll {
        # Clean up default location OPA
        if (Test-Path $script:DummyOPAPath) {
            Remove-Item -Path $script:DummyOPAPath -Force -ErrorAction SilentlyContinue
        }
        
        # Clean up test directory OPA (for OPAPath: . in orchestrator_config_test.yaml)
        $TestOPAPath = Join-Path -Path $PSScriptRoot -ChildPath $script:DummyOPAName
        if (Test-Path $TestOPAPath) {
            Remove-Item -Path $TestOPAPath -Force -ErrorAction SilentlyContinue
        }
    }
}
AfterAll {
    Remove-Module Orchestrator -ErrorAction SilentlyContinue
    
    # Clean up dummy OPA executables created in BeforeDiscovery
    # Default location
    $DefaultOPAPath = Join-Path -Path $env:USERPROFILE -ChildPath ".scubagear\Tools"
    $IsLinuxOS = (Test-Path variable:IsLinux) -and $IsLinux
    $IsMacOSOS = (Test-Path variable:IsMacOS) -and $IsMacOS
    if ($IsLinuxOS) {
        $OPAExeName = "opa_linux_amd64"
    }
    elseif ($IsMacOSOS) {
        $OPAExeName = "opa_darwin_amd64"
    }
    else {
        $OPAExeName = "opa_windows_amd64.exe"
    }
    
    $OPAExePath = Join-Path -Path $DefaultOPAPath -ChildPath $OPAExeName
    if (Test-Path $OPAExePath) {
        Remove-Item -Path $OPAExePath -Force -ErrorAction SilentlyContinue
    }
    
    # Test directory OPA (for OPAPath: . in orchestrator_config_test.yaml)
    $TestOPAPath = Join-Path -Path $PSScriptRoot -ChildPath $OPAExeName
    if (Test-Path $TestOPAPath) {
        Remove-Item -Path $TestOPAPath -Force -ErrorAction SilentlyContinue
    }
}