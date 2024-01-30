function New-ServicePrincipalCertificate{
    <#
    .SYNOPSIS
    Add certificate into 'My' certificate store of current user.

    .DESCRIPTION
    This script adds a certificate into the 'My' certificate store of the current user.

    .PARAMETER EncodedCertificate
    A base 64 encoded PFX certificate

    .PARAMETER CertificatePassword
    The password of the certificate

    .OUTPUTS
    Thumbprint of the added certificate. <System.String>

    .EXAMPLE
    $CertPwd = ConvertTo-SecureString -String $PlainTextPassword -Force -AsPlainText
    $M365Env = $TestTenant.M365Env
    try {
      $Result = New-ServicePrincipalCertificate `
        -EncodedCertificate $TestTenant.CertificateB64 `
        -CertificatePassword $CertPwd
      $Thumbprint = $Result[-1]
    }
    catch {
      Write-Output "Failed to install certificate for $OrgName"
    }
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Object[]]$EncodedCertificate,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$CertificatePassword
    )

    Set-Content -Path .\ScubaExecutionCert.txt -Value $EncodedCertificate
    certutil -decode .\ScubaExecutionCert.txt .\ScubaExecutionCert.pfx
    $Certificate = Import-PfxCertificate -FilePath .\ScubaExecutionCert.pfx -CertStoreLocation Cert:\CurrentUser\My -Password $CertificatePassword
    $Thumbprint = ([System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate).Thumbprint
    Remove-Item -Path .\ScubaExecutionCert.txt
    Remove-Item -Path .\ScubaExecutionCert.pfx
    return $Thumbprint
}

function Remove-MyCertificates{
    <#
    .SYNOPSIS
    Remove all certificates from 'My' certificate store of current user.

    .DESCRIPTION
    This script removes all certificates from the 'My' certificxate store of the current user.

    .EXAMPLE
    Remove-MyCertificates
    #>
    Get-ChildItem Cert:\CurrentUser\My | ForEach-Object {
        Remove-Item -Path $_.PSPath -Recurse -Force
    }
}

function Install-SmokeTestExternalDependencies{
    <#
    .SYNOPSIS
    Install dependencies on GitHub runner to support smoke test.

    .DESCRIPTION
    This script installs dependencies needed by the SCuBA smoke test.  For example, Selenium and the Open Policy Agent.

    .EXAMPLE
    Install-SmokeTestExternalDependencies
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'PNPPOWERSHELL_UPDATECHECK',
        Justification = 'Variable defined outside this scope')]
    $PNPPOWERSHELL_UPDATECHECK = 'Off'

    #Import Selenium and update drivers
    Install-Module -Name Selenium -Scope CurrentUser -Force
    Import-Module -Name Selenium -Force
    Testing/Functional/SmokeTest/UpdateSelenium.ps1
}