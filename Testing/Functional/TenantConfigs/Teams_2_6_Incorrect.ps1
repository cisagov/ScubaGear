param (
)

Configuration Teams_2_6_Incorrect
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsFederationConfiguration Global
        {
            AllowPublicUsers                           = $true;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_2_6_Incorrect -ConfigurationData .\ConfigurationData.psd1
