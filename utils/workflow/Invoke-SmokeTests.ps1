function Invoke-SmokeTests {
    <#
        .SYNOPSIS
            Runs the smoke tests for ScubaGear.
        .PARAMETER TestTenants
            Info about the tenants against which the smoke tests are conducted.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '')]
    param(
        [Parameter(Mandatory = $true)]
        [array]
        $TestTenants
    )

    Write-Warning "Invoking smoke tests..."
    Write-Warning "Identified $($TestTenants.Count) test tenants..."

    # Access certificate functions
    . Testing/Functional/SmokeTest/SmokeTestUtils.ps1
    # Install Selenium
    . utils/workflow/Install-SeleniumForTesting.ps1
    Install-SeleniumForTesting
    # Install ScubaGear modules
    Import-Module -Name .\PowerShell\ScubaGear\ScubaGear.psd1
    Initialize-SCuBA

    # ScubaGear currently requires the provisioning of a certificate for using a ServicePrincipal, rather than
    # using Workload Identity Federation, which would ordinarily be preferred for calling Microsoft APIs from
    # GitHub actions.
    $Index = 1
    $ReturnCode = 0
    ForEach ($TestTenantObj in $TestTenants) {
        $TestContainers = @()
        $TenantAlias = $TestTenantObj.PSObject.Properties.Name
        $TestTenant = $TestTenantObj.$TenantAlias
        $OrgName = $TestTenant.DisplayName
        Write-Warning "Testing tenant $TenantAlias..."
        $DomainName = $TestTenant.DomainName
        $AppId = $TestTenant.AppId
        $PlainTextPassword = $TestTenant.CertificatePassword
        # This is not high risk because this code is only running on an ephemeral runner.
        $CertPwd = ConvertTo-SecureString -String $PlainTextPassword -Force -AsPlainText
        $M365Env = $TestTenant.M365Env
        try {
            $Result = New-ServicePrincipalCertificate `
                -EncodedCertificate $TestTenant.CertificateB64 `
                -CertificatePassword $CertPwd
            $Thumbprint = $Result[-1]
        }
        catch {
            Write-Warning "Failed to install certificate for $OrgName because..."
            Write-Warning $_
        }
        $TestContainers += New-PesterContainer `
                -Path "Testing/Functional/SmokeTest/SmokeTest001.Tests.ps1" `
                -Data @{ Alias = $TenantAlias; Thumbprint = $Thumbprint; Organization = $DomainName; AppId = $AppId; M365Environment = $M365Env }
        $TestContainers += New-PesterContainer `
            -Path "Testing/Functional/SmokeTest/SmokeTest002.Tests.ps1" `
            -Data @{ Alias = $TenantAlias; OrganizationDomain = $DomainName; OrganizationName = $OrgName }
        # Run the smoke tests just for this tenant.
        $PesterConfig = New-PesterConfiguration
        $PesterConfig.Run.Exit = $true
        $PesterConfig.Run.Container = $TestContainers
        $PesterConfig.Output.Verbosity = 'Detailed'
        Invoke-Pester -Configuration $PesterConfig
        $ReturnCode += $LASTEXITCODE

        Remove-MyCertificates
        $Index = $Index + 1
    }

    # Return sum of return codes, which if non-zero is the number of failed tests.
    $ReturnCode
}