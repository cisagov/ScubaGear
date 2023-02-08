# Generated with Microsoft365DSC version 1.23.201.1
# For additional information on how to use Microsoft365DSC, please visit https://aka.ms/M365DSC
param (
)

Configuration Teams_2_1_Correct
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
            Identity                                   = "Global";
            ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
            TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
            CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        }
        # TeamsMeetingPolicy Tag_AllOn
        # {
        #     Ensure                                     = "Present";
        #     AllowExternalParticipantGiveRequestControl = $False;
        #     Identity                                   = "Tag:AllOn";
        #     ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
        #     TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
        #     CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        # }
        # TeamsMeetingPolicy Tag_RestrictedAnonymousAccess
        # {
        #     Ensure                                     = "Present";
        #     AllowExternalParticipantGiveRequestControl = $False;
        #     Identity                                   = "Tag:RestrictedAnonymousAccess";
        #     ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
        #     TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
        #     CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        # }
        # TeamsMeetingPolicy Tag_AllOff
        # {
        #     Ensure                                     = "Present";
        #     AllowExternalParticipantGiveRequestControl = $False;
        #     Identity                                   = "Tag:AllOff";
        #     ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
        #     TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
        #     CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        # }
        # TeamsMeetingPolicy Tag_RestrictedAnonymousNoRecording
        # {
        #     Ensure                                     = "Present";
        #     AllowExternalParticipantGiveRequestControl = $False;
        #     Identity                                   = "Tag:RestrictedAnonymousNoRecording";
        #     ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
        #     TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
        #     CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        # }
        # TeamsMeetingPolicy Tag_Default
        # {
        #     Ensure                                     = "Present";
        #     AllowExternalParticipantGiveRequestControl = $False;
        #     Identity                                   = "Tag:Default";
        #     ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
        #     TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
        #     CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        # }
        # TeamsMeetingPolicy Tag_Kiosk
        # {
        #     Ensure                                     = "Present";
        #     AllowExternalParticipantGiveRequestControl = $False;
        #     Identity                                   = "Tag:Kiosk";
        #     ApplicationId                              = $ConfigurationData.NonNodeData.ApplicationId;
        #     TenantId                                   = $ConfigurationData.NonNodeData.TenantId;
        #     CertificateThumbprint                      = $ConfigurationData.NonNodeData.CertificateThumbprint;
        # }
    }
}

Teams_2_1_Correct -ConfigurationData .\ConfigurationData.psd1
