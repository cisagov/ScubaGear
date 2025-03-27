function Invoke-SmokeTests {
    <#
        .SYNOPSIS
            Runs the smoke tests for ScubaGear.
        .PARAMETER Tenants
            Info about the tenants against which the smoke tests are conducted.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Tenants
    )

    Write-Warning "Invoking smoke tests..."

    # Access certificate functions
    . Testing/Functional/SmokeTest/SmokeTestUtils.ps1
    # Install Selenium
    . utils/workflow/Install-SeleniumForTesting.ps1
    Install-SeleniumForTesting
    # Install ScubaGear modules
    Import-Module -Name .\PowerShell\ScubaGear\ScubaGear.psd1
    Initialize-SCuBA

    Write-Warning "Identified $($Tenants['TestTenants'].Count) test tenants..."

    # ScubaGear currently requires the provisioning of a certificate for using a
    # ServicePrinicpal, rather than using Workload Identity Federation, which
    # would ordinarily be preferred for calling Microsoft APIs from GitHub actions.
    ForEach ($Tenant in $Tenants['TestTenants']) {
        # The alias is the key for each tenant, a string that represents the tenant
        # that is being smoke tested.
        $Alias = $Tenant.Keys[0]
        Write-Warning "Testing $Alias..."
        $OrgName = $Tenant.$Alias.DisplayName
        $DomainName = $Tenant.$Alias.DomainName
        $AppId = $Tenant.$Alias.AppId
        $PlainTextPassword = $Tenant.$Alias.CertificatePassword
        $M365Env = $Tenant.$Alias.M365Env
        $EncodedCertificate = $Tenant.$Alias.CertificateB64
        # This is not high risk because this code is only running on an ephemeral runner.
        $EncodedPassword = ConvertTo-SecureString -String $PlainTextPassword -Force -AsPlainText
        try {
            $Result = New-ServicePrincipalCertificate `
                -EncodedCertificate $EncodedCertificate `
                -CertificatePassword $EncodedPassword
            $Thumbprint = $Result[-1]
        }
        catch {
            Write-Warning "Failed to install certificate because"
            Write-Warning $_
        }
        $TestContainers = @()
        $TestContainers += New-PesterContainer `
            -Path "Testing/Functional/SmokeTest/SmokeTest001.Tests.ps1" `
            -Data @{ Thumbprint = $Thumbprint; Organization = $DomainName; AppId = $AppId; M365Environment = $M365Env }
        $TestContainers += New-PesterContainer `
            -Path "Testing/Functional/SmokeTest/SmokeTest002.Tests.ps1" `
            -Data @{ OrganizationDomain = $DomainName; OrganizationName = $OrgName }
        # Run the smoke tests just for this tenant.
        Invoke-Pester -Container $TestContainers -Output Detailed
        Remove-MyCertificates
    }
}