param (
)

Configuration Teams_2_9_Incorrect
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsMeetingPolicy Global
        {
            Ensure                                     = "Present";
            AllowCloudRecording                        = $true;
            AllowRecordingStorageOutsideRegion         = $false;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
        TeamsMeetingPolicy Custom_Policy_1
        {
            Ensure                                     = "Present";
            AllowCloudRecording                        = $true;
            AllowRecordingStorageOutsideRegion         = $true;
            Identity                                   = "Custom Policy 1";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_2_9_Incorrect -ConfigurationData .\ConfigurationData.psd1
