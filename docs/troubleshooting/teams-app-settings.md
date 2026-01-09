# Teams Org-Wide App Settings Authentication Limitation

## Issue
The `Get-M365UnifiedTenantSettings` cmdlet, which retrieves organization-wide Teams app settings (DefaultApp, GlobalApp, PrivateApp), **does not support certificate-based or application-only authentication**, even with the following permissions:
- `TeamworkAppSettings.Read.All`
- `TeamworkAppSettings.ReadWrite.All`
- `Exchange.ManageAsApp`

## Affected Policies
This limitation impacts the following ScubaGear policies:
- **MS.TEAMS.5.1v2** - Block third-party apps by default
- **MS.TEAMS.5.2v2** - Block custom apps by default
- **MS.TEAMS.5.3v2** - User consent for apps accessing data

## Microsoft API Limitation
The backend API endpoint requires delegated (user) authentication tokens with one of these token types:
- `app_asserted_user_v1` (app acting on behalf of a user)
- `service_asserted_app_v1` (service principal with user context)

Certificate-based authentication provides an application-only token, which the API explicitly rejects with HTTP 401.

## Workaround: Hybrid Authentication

### Option 1: Use Interactive Authentication (Recommended)
When you need to validate org-wide app settings:

```powershell
# Connect with user credentials instead of certificate
Connect-MicrosoftTeams

# Run ScubaGear
Invoke-SCuBA -ProductNames teams -OutPath "C:\ScubaResults"
```

### Option 2: Run with Certificate Auth (Legacy Validation Only)
ScubaGear will automatically fall back to validating legacy app permission policies:

```powershell
# Certificate-based auth (automated scenarios)
Invoke-SCuBA -ProductNames teams `
    -CertificateThumbprint "YOUR_THUMBPRINT" `
    -AppID "YOUR_APP_ID" `
    -Organization "yourtenant.onmicrosoft.com" `
    -OutPath "C:\ScubaResults"
```

**Result:** Policies 5.1v2, 5.2v2, and 5.3v2 will validate using `Get-CsTeamsAppPermissionPolicy` only. The report will note: "Get-M365UnifiedTenantSettings requires interactive authentication; falling back to legacy policy validation."

## How ScubaGear Handles This

1. **Attempts to call** `Get-M365UnifiedTenantSettings`
2. **If it fails** (with cert auth), the error is logged but execution continues
3. **Rego validation** checks both:
   - Legacy app permission policies (always available with cert auth)
   - Org-wide tenant settings (only available with user auth)
4. **Policy passes if EITHER**:
   - Legacy policies are compliant, OR
   - Org-wide settings are set to "None"

## Technical Details

### Error Response
```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer token_types="app_asserted_user_v1 service_asserted_app_v1"
```

### API Endpoint
The cmdlet calls an internal Exchange Online endpoint that enforces user context requirements.

### Graph API Equivalent
The Microsoft Graph API endpoint also has the same limitation:
```
GET https://graph.microsoft.com/beta/teamwork/teamsAppSettings
Error: "Requested API is not supported in application-only context"
```

## Recommendation for Microsoft
Microsoft should enable application-only authentication for this API by:
1. Supporting the `TeamworkAppSettings.Read.All` app permission
2. Allowing service principals to read (not modify) these tenant-wide settings
3. This would align with other Teams settings that support cert-based auth

## Related Issues
- Microsoft Teams PowerShell Module version: 7.3.1
- This is not a ScubaGear bug, but a Microsoft API design limitation
- Similar limitations exist for other Teams Admin Center "Org-wide settings"

## Further Reading
- [Teams App Permission Policies](https://learn.microsoft.com/microsoftteams/teams-app-permission-policies)
- [ScubaGear Teams Baseline](../../baselines/teams.md)
