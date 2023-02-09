param (
)

Configuration Teams_AllSettings_Correct
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsMeetingPolicy Global
        {
            Ensure                                     = "Present";
            AllowExternalParticipantGiveRequestControl = $False;
            AllowAnonymousUsersToStartMeeting          = $False;
            AllowAnonymousUsersToJoinMeeting           = $True;
            AllowPSTNUsersToBypassLobby                = $False;
            AutoAdmittedUsers                          = "EveryoneInCompanyExcludingGuests";
            AllowCloudRecording                        = $False;
            AllowRecordingStorageOutsideRegion         = $False;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }

        TeamsMeetingPolicy Custom_Policy_1
        {
            Ensure                                     = "Present";
            AllowExternalParticipantGiveRequestControl = $False;
            AllowAnonymousUsersToStartMeeting          = $False;
            AllowAnonymousUsersToJoinMeeting           = $True;
            AllowPSTNUsersToBypassLobby                = $False;
            AutoAdmittedUsers                          = "EveryoneInCompanyExcludingGuests";
            AllowCloudRecording                        = $False;
            AllowRecordingStorageOutsideRegion         = $True;
            Identity                                   = "Custom Policy 1";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
        TeamsFederationConfiguration Meeting_Settings
        {
            AllowFederatedUsers                         = $False;
            AllowPublicUsers                            = $False;
            AllowedDomains                              = @("cisa.gov");
            AllowTeamsConsumer                          = $False;
            AllowTeamsConsumerInbound                   = $True;
            Identity                                    = "Global";
            ApplicationId                               = $ConfigurationData.NonNodeData.ApplicationId;
            CertificateThumbprint                       = $ConfigurationData.NonNodeData.CertificateThumbprint;
            TenantId                                    = $ConfigurationData.NonNodeData.TenantId;
        }
        TeamsClientConfiguration Global
        {
            AllowEmailIntoChannel                      = $True;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
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

Teams_AllSettings_Correct -ConfigurationData .\ConfigurationData.psd1
