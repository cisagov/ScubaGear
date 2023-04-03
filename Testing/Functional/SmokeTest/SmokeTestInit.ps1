function New-ServicePrincipalCertificate{
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
    return $Thumbprint
}

function Install-SmokeTestExternalDependencies{
    #Workaround till update to version 2.0+
    Install-Module -Name "PnP.PowerShell" -RequiredVersion 1.12 -Force
    ./SetUp.ps1 -SkipUpdate

    #TODO: Install OPA if needed

    #Import Selenium and update drivers
    Import-Module Selenium
    Testing/Functional/SmokeTest/UpdateSelenium.ps1
}