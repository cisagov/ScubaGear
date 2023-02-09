param (
)

Configuration Teams_2_5_Correct
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsFederationConfiguration Global
        {
            AllowTeamsConsumer                         = $False;
            AllowTeamsConsumerInbound                  = $True;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_2_5_Correct -ConfigurationData .\ConfigurationData.psd1
