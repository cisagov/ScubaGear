$TestContainers = @()

# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="pnp"; Thumbprint="10731ec5a37ea2553f8faa54d95e965928145480"; TenantDomain = "scubag3forthee.onmicrosoft.com"; TenantDisplayName = "scubag3forthee"; AppId="ed2cb57b92084abeb99c3acf35c91f5f"; ProductName = "sharepoint"; M365Environment = "gcc" }
$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="pnp"; Thumbprint="10731ec5a37ea2553f8faa54d95e965928145480"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; AppId="db791fde1ff0493fbe3d03d9ba6cb087"; ProductName = "sharepoint"; M365Environment = "commercial" }
$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="pnp"; Thumbprint="10731ec5a37ea2553f8faa54d95e965928145480"; TenantDomain = "cisaent.onmicrosoft.com"; TenantDisplayName = "cisaent"; AppId="29730b8be22241afa94f905bcdeaf7a3"; ProductName = "sharepoint"; M365Environment = "gcc" }
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="pnp"; Thumbprint="10731ec5a37ea2553f8faa54d95e965928145480"; TenantDomain = "scubagcchigh.onmicrosoft.com"; TenantDisplayName = "scubagcchigh"; AppId="0734a54de2c84bccb074639f39e35fd7"; ProductName = "sharepoint"; M365Environment = "gcchigh" }
$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="spo"; TenantDomain = "y2zj1.onmicrosoft.com"; TenantDisplayName = "y2zj1"; ProductName = "sharepoint"; M365Environment = "commercial" }
$TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="spo"; TenantDomain = "cisaent.onmicrosoft.com"; TenantDisplayName = "cisaent"; ProductName = "sharepoint"; M365Environment = "gcc" }
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="spo"; TenantDomain = "scubag3forthee.onmicrosoft.com"; TenantDisplayName = "scubag3"; ProductName = "sharepoint"; M365Environment = "gcc" }
# $TestContainers += New-PesterContainer -Path "Testing/Functional/Products" -Data @{ Variant="spo"; TenantDomain = "scubagcchigh.onmicrosoft.com"; TenantDisplayName = "scubagcchigh"; ProductName = "sharepoint"; M365Environment = "gcchigh" }


$PesterConfig = @{
  Run = @{
    Container = $TestContainers
  }
  Output = @{
    Verbosity = 'Detailed'
  }
}



$Config = New-PesterConfiguration -Hashtable $PesterConfig



Invoke-Pester -Configuration $Config