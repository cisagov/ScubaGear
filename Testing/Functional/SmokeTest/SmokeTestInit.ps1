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

    if (-Not $Certificate.Verify()){
        throws "Import of service principal certificate failed."
    }
}


##### By default we want the Cmdlets to stop the pipeline when errors occur
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

##### Just some debugging info like the branch, Powershell version and current directory
Write-Output 'Branch: ${{ github.ref }}'
$PSVersionTable
Get-Location

##### Get the certificate from GitHub secrets and import it into the local cert store
Set-Content -Path .\ScubaExecutionCert.txt -Value $env:SCUBA_EXECUTION_CERT_PFX
certutil -decode .\ScubaExecutionCert.txt .\ScubaExecutionCert.pfx
$CertPwd = ConvertTo-SecureString -String "$env:SCUBA_EXECUTION_CERT_PW" -Force -AsPlainText
Import-PfxCertificate -FilePath .\ScubaExecutionCert.pfx -CertStoreLocation Cert:\CurrentUser\My -Password $CertPwd

##### Install MS Graph and all the dependencies
./SetUp.ps1

##### Run ScubaGear with a service principal
Import-Module -Name ./PowerShell/ScubaGear
Invoke-Scuba -CertificateThumbPrint "A9D4870B12F94A344C20BB3FC5774C89F8B5EF33" -AppID "b682d3a5-bc68-450e-80ba-018b97aa2b21" -Organization "cisaent.onmicrosoft.com" -ProductNames "onedrive" -M365Environment "gcc"

##### Get the output folder path
$ReportFolders = Get-ChildItem . -directory -Filter "M365BaselineConformance*" | Sort-Object -Property LastWriteTime -Descending
$OutputFolder = $ReportFolders[0]

##### Test that the TestResults.json file is a structurally valid JSON document
$JSONContent = Get-Content ".\$OutputFolder\TestResults.json" -Raw | ConvertFrom-Json