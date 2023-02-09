param (
)

Configuration Teams_2_3_Correct
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsMeetingPolicy Global
        {
            Ensure                                     = "Present";
            AutoAdmittedUsers                          = "EveryoneInCompanyExcludingGuests";
            AllowPSTNUsersToBypassLobby                = $False;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }

        TeamsMeetingPolicy Custom_Policy_1
        {
            Ensure                                     = "Present";
            AutoAdmittedUsers                          = "EveryoneInCompanyExcludingGuests";
            AllowPSTNUsersToBypassLobby                = $False;
            Identity                                   = "Custom Policy 1";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_2_3_Correct -ConfigurationData .\ConfigurationData.psd1
