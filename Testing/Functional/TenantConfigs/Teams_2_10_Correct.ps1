param (
)

Configuration Teams_2_10_Correct
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsMeetingBroadcastPolicy Global
        {
            Ensure                                     = "Present";
            BroadcastRecordingMode                     = "UserOverride";
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_2_10_Correct -ConfigurationData .\ConfigurationData.psd1
