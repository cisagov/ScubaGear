# Service Principal Troubleshooting & FAQ

This guide helps resolve common issues when working with ScubaGear service principals.

## Authentication Issues

### Issue: "Failed to connect to Microsoft Graph"

**Symptoms:**
- Error message: "Failed to connect to Microsoft Graph: ..."
- Functions fail before executing main logic

**Possible Causes & Solutions:**

#### 1. Missing Required Entra ID Role

**Cause:** Your user account lacks the necessary Entra ID role.

**Solution:** Ensure you have one of these roles assigned: [Reference Table](serviceprincipal-workflows.md#prerequisites)

#### 2. Interactive Login Required

**Cause:** Microsoft Graph requires interactive consent for the requested scopes.

**Solution:** Allow the authentication popup to appear and consent to the requested permissions.

## Power Platform Issues

### Issue: "Power Platform registration failed"

**Symptoms:**
- New-ScubaGearServicePrincipal fails at Power Platform registration step
- Error: "Service principal is not registered with Power Platform"

**Solutions:**

#### 1. Install Required Module

```powershell
Initialize-SCuBA
```

#### 2. Verify you have the correct permissions to register the Service Principal with Power Platform
- You will need to be a `Global Administrator` or `Power Platform Administrator`

## Frequently Asked Questions (FAQ)

### General Questions

| Question | Answer |
|----------|--------|
| **How long do certificates last?** | By default, certificates are valid for **6 months**. You can customize this with the `-CertValidityMonths` parameter (6 months is recommended, but a maximum of 12 months is allowed). |
| **Can I have multiple certificates on one service principal?** | Yes! This is recommended for zero-downtime certificate rotation. Add a new certificate before removing the old one. |
| **What's the difference between Application permissions and Delegated permissions?** | **Application permissions:** Used by service principals running unattended (ScubaGear's requirement)<br>**Delegated permissions:** Used when an application acts on behalf of a signed-in user (not for automation) |

---

### Permission Questions

**Why does Set-ScubaGearAppPermission remove some of my permissions?**

The function enforces **least privilege**. When you specify ProductNames, it removes permissions not required for those products. This is a security best practice.

```powershell
# Example: You originally set up for all products
New-ScubaGearServicePrincipal -ProductNames '*'

# Now you only need AAD - extra permissions will be removed (SharePoint, Exchange, etc.)
Get-ScubaGearAppPermission -AppID $AppID -ProductNames 'aad' | Set-ScubaGearAppPermission
```

**Can I manually add additional permissions not required by ScubaGear?**

Yes, but they'll be flagged as "ExtraPermissions" when you run Get-ScubaGearAppPermission. If you need custom permissions:

1. Add them manually through Azure Portal
2. Don't pipe to Set-ScubaGearAppPermission (which would remove them)

**What permissions does each product require?**

See the [Noninteractive Permissions](noninteractive.md) documentation for the complete permissions table by product.

---

### Certificate Questions

**Where are certificates stored?**

Certificates are stored in two places:
1. **Entra ID:** Public key attached to app registration
2. **Local machine:** Private key in `Cert:\CurrentUser\My`

You need both for authentication to work.

**Can I use the same certificate on multiple machines?**

Yes, but you must export the certificate with private key and import it on each machine that needs to authenticate. Or create a new certificate for each system and associate with the service principal.

**Can I use an existing certificate instead of creating a new one?**

Currently, New-ScubaGearServicePrincipal and New-ScubaGearAppCert create new certificates. To use an existing certificate, manually attach it through Entra Admin Center:
1. Go to App registrations > Your app > Certificates & secrets
2. Upload your certificate (.cer or .pem file)
3. Use its thumbprint with Invoke-ScubaGear

---

### Troubleshooting Questions

**How do I see detailed error information?**

Use the `-Verbose` parameter for detailed logging:

```powershell
Get-ScubaGearAppPermission -AppID $AppID -M365Environment commercial -ProductNames '*' -Verbose
```

**Can I test changes without applying them?**

Yes! Use `-WhatIf` on any function that modifies resources:

```powershell
New-ScubaGearServicePrincipal -ProductNames '*' -M365Environment commercial -WhatIf
Get-ScubaGearAppPermission -AppID $AppID -M365Environment commercial -ProductNames '*' | Set-ScubaGearAppPermission -WhatIf
Remove-ScubaGearAppCert -AppID $AppID -M365Environment commercial -CertThumbprint $Thumbprint -WhatIf
```

**What if Set-ScubaGearAppPermission fails partway through?**

The function is designed to be **safe to rerun**. It only makes necessary changes, so you can simply run it again:

```powershell
Get-ScubaGearAppPermission -AppID $AppID -M365Environment commercial -ProductNames '*' | Set-ScubaGearAppPermission -WhatIf
```

**How do I completely reset a service principal's permissions?**

```powershell
# Option 1: Remove extra permissions, then add correct ones
Get-ScubaGearAppPermission -AppID $AppID -M365Environment commercial -ProductNames 'aad' | Set-ScubaGearAppPermission

# Option 2: Delete and recreate
# 1. Delete app registration in Entra Admin Center
# 2. Remove local certificates
# 3. Create new service principal
$NewSP = New-ScubaGearServicePrincipal -M365Environment commercial -ProductNames '*'
```

## Getting Help

If you encounter issues not covered in this guide:

1. **Check verbose output:** Run commands with `-Verbose` flag
2. **Review error messages:** Look for specific error codes or API responses
3. **Consult workflow documentation:** See [serviceprincipal-workflows.md](serviceprincipal-workflows.md)
4. **Open an issue:** [ScubaGear GitHub Issues](https://github.com/cisagov/ScubaGear/issues)
