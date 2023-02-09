param (
)

Configuration Teams_2_6_Correct
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsFederationConfiguration Global
        {
            AllowPublicUsers                           = $False;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_2_6_Correct -ConfigurationData .\ConfigurationData.psd1
