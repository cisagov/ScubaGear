param (
)

Configuration Teams_All_Incorrect
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsMeetingPolicy Global
        {
            Ensure                                     = "Present";
            AllowExternalParticipantGiveRequestControl = $True;
            AllowAnonymousUsersToStartMeeting          = $True;
            AutoAdmittedUsers                          = "Everyone";
            AllowPSTNUsersToBypassLobby                = $True;
            AllowAnonymousUsersToJoinMeeting           = $False;
            AllowCloudRecording                        = $true;
            AllowRecordingStorageOutsideRegion         = $false;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
        TeamsMeetingBroadcastPolicy Global
        {
            Ensure                                     = "Present";
            BroadcastRecordingMode                     = "AlwaysEnabled";
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
        TeamsFederationConfiguration Meeting_Settings
        {
            AllowFederatedUsers                         = $True;
            AllowedDomains                              = @();
            AllowTeamsConsumer                         = $True;
            AllowTeamsConsumerInbound                  = $True;
            AllowPublicUsers                           = $true;
            AllowCloudRecording                        = $true;
            AllowRecordingStorageOutsideRegion         = $true;
            Identity                                    = "Global";
            ApplicationId                               = $ConfigurationData.NonNodeData.ApplicationId;
            CertificateThumbprint                       = $ConfigurationData.NonNodeData.CertificateThumbprint;
            TenantId                                    = $ConfigurationData.NonNodeData.TenantId;
        }
        TeamsMeetingPolicy Custom_Policy_1
        {
            Ensure                                     = "Present";
            AllowExternalParticipantGiveRequestControl = $True;
            AllowAnonymousUsersToStartMeeting          = $True;
            AutoAdmittedUsers                          = "Everyone";
            AllowPSTNUsersToBypassLobby                = $True;
            AllowAnonymousUsersToJoinMeeting           = $False;
            Identity                                   = "Custom Policy 1";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_All_Incorrect -ConfigurationData .\ConfigurationData.psd1
