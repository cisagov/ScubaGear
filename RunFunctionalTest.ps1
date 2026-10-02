$TestContainers = @()

### Instructions
###		When using this script decide if you are testing with Service Principal or Interactive Login.
###		An example of each is provided below. Comment out the one you are not using.

###		To execute a variant version of the test (e.g. AAD G3 tests) you would specify ProductName = "aad"; Variant="g3" to the -Data parameter.
###			This will execute the file named aad.g3.testplan.yaml

# Service Principal
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="pnp"; Thumbprint = "93fd41a761f434f12ee8ac3ff771347597435696"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; AppId = "db791fde-1ff0-493f-be3d-03d9ba6cb087"; ProductName = "sharepoint"; M365Environment = "commercial"; }
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Thumbprint = "93fd41a761f434f12ee8ac3ff771347597435696"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; AppId = "db791fde-1ff0-493f-be3d-03d9ba6cb087"; ProductName = "aad"; M365Environment = "commercial"; }
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="pnp"; Thumbprint = "93fd41a761f434f12ee8ac3ff771347597435696"; TenantDomain = "cisaent.onmicrosoft.com"; TenantDisplayName = "Cybersecurity and Infrastructure Security Agency"; AppId = "29730b8b-e222-41af-a94f-905bcdeaf7a3"; ProductName = "sharepoint"; M365Environment = "gcc"; }
$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Thumbprint = "a83362efcc1d9e8bc392224bcb67f70949741b20"; TenantDomain = "cisaent.onmicrosoft.com"; TenantDisplayName = "Cybersecurity and Infrastructure Security Agency"; AppId = "29730b8b-e222-41af-a94f-905bcdeaf7a3"; ProductName = "securitysuite"; M365Environment = "gcc"; }
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="pnp"; Thumbprint = "93fd41a761f434f12ee8ac3ff771347597435696"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; AppId = "db791fde-1ff0-493f-be3d-03d9ba6cb087"; ProductName = "sharepoint"; M365Environment = "commercial"; }
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Thumbprint = "93fd41a761f434f12ee8ac3ff771347597435696"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; AppId = "db791fde-1ff0-493f-be3d-03d9ba6cb087"; ProductName = "teams"; M365Environment = "commercial"; }

# Interactive Login
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="spo"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; ProductName = "sharepoint"; M365Environment = "commercial" }
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{Variant="spo"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; ProductName = "sharepoint"; M365Environment = "commercial"; }
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="spo"; TenantDomain = "cisaent.onmicrosoft.com"; TenantDisplayName = "Cybersecurity and Infrastructure Security Agency"; ProductName = "sharepoint"; M365Environment = "gcc"; }

### If you want to execute a specific test, uncomment the Filter node below and specificy the specific policy identifier
$PesterConfig = @{
	Run = @{
		Container = $TestContainers
	}
	Filter = @{
		# Tag = @("MS.AAD.1.1v1", "MS.AAD.2.1v1", "MS.AAD.2.3v1")
		#Tag = @("MS.AAD.3.1v1", "MS.AAD.3.2v1", "MS.AAD.3.6v1", "MS.AAD.3.7v1", "MS.AAD.3.8v1")
		Tag = @("MS.SECURITYSUITE.7.1v1", "MS.SECURITYSUITE.7.2v1", "MS.SECURITYSUITE.7.3v1")
		# Tag = @("MS.TEAMS.1.2v1")
		# Tag = @("MS.AAD.[2]*")s
		# Tag = @("MS\.AAD\.(1\.1|2\.(1|3)|3\.(1|2|6|7|8))v1")

	}
	Output = @{
		Verbosity = 'Detailed'
	}
}

$Config = New-PesterConfiguration -Hashtable $PesterConfig 

Invoke-Pester -Configuration $Config