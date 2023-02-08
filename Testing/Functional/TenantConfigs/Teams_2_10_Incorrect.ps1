# Generated with Microsoft365DSC version 1.23.201.1
# For additional information on how to use Microsoft365DSC, please visit https://aka.ms/M365DSC
param (
)

Configuration Teams_2_10_Incorrect
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsMeetingBroadcastPolicy Global
        {
            Ensure                                     = "Present";
            BroadcastRecordingMode                     = "AlwaysEnabled";
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_2_10_Incorrect -ConfigurationData .\ConfigurationData.psd1
