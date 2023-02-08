# Generated with Microsoft365DSC version 1.23.201.1
# For additional information on how to use Microsoft365DSC, please visit https://aka.ms/M365DSC
param (
)

Configuration Teams_2_3_Incorrect
{
    param (
    )

    Import-DscResource -ModuleName 'Microsoft365DSC'

    Node localhost
    {
        TeamsMeetingPolicy Global
        {
            Ensure                                     = "Present";
            AutoAdmittedUsers                          = "Everyone";
            AllowPSTNUsersToBypassLobby                = $True;
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }

        TeamsMeetingPolicy Custom_Policy_1
        {
            Ensure                                     = "Present";
            AutoAdmittedUsers                          = "Everyone";
            AllowPSTNUsersToBypassLobby                = $True;
            Identity                                   = "Custom Policy 1";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
    }
}

Teams_2_3_Incorrect -ConfigurationData .\ConfigurationData.psd1
