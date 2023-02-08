# Generated with Microsoft365DSC version 1.23.201.1
# For additional information on how to use Microsoft365DSC, please visit https://aka.ms/M365DSC
param (
)

Configuration Teams_2_1_Incorrect
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
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
#         TeamsMeetingPolicy Tag_AllOn
#         {
#             Ensure                                     = "Present";
#             AllowExternalParticipantGiveRequestControl = $True;
#             Identity                                   = "Tag:AllOn";
#             ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
#             TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
#             CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
#         }
#         TeamsMeetingPolicy Tag_RestrictedAnonymousAccess
#         {
#             Ensure                                     = "Present";
#             AllowExternalParticipantGiveRequestControl = $True;
#             Identity                                   = "Tag:RestrictedAnonymousAccess";
#             ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
#             TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
#             CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
#         }
#         TeamsMeetingPolicy Tag_AllOff
#         {
#             Ensure                                     = "Present";
#             AllowExternalParticipantGiveRequestControl = $True;
#             Identity                                   = "Tag:AllOff";
#             ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
#             TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
#             CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
#         }
#         TeamsMeetingPolicy Tag_RestrictedAnonymousNoRecording
#         {
#             Ensure                                     = "Present";
#             AllowExternalParticipantGiveRequestControl = $True;
#             Identity                                   = "Tag:RestrictedAnonymousNoRecording";
#             ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
#             TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
#             CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
#         }
#         TeamsMeetingPolicy Tag_Default
#         {
#             Ensure                                     = "Present";
#             AllowExternalParticipantGiveRequestControl = $True;
#             Identity                                   = "Tag:Default";
#             ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
#             TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
#             CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
#         }
#         TeamsMeetingPolicy Tag_Kiosk
#         {
#             Ensure                                     = "Present";
#             AllowExternalParticipantGiveRequestControl = $True;
#             Identity                                   = "Tag:Kiosk";
#             ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
#             TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
#             CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
#        }
    }
}

Teams_2_1_Incorrect -ConfigurationData .\ConfigurationData.psd1
