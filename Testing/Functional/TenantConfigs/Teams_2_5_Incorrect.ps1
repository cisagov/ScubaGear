param (
)

Configuration Teams_2_5_Incorrect
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsFederationConfiguration Global
        {
            AllowTeamsConsumer                         = $True;
            AllowTeamsConsumerInbound                  = $True;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_2_5_Incorrect -ConfigurationData .\ConfigurationData.psd1
