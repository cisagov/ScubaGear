# ScubaGear Configuration File

ScubaGear allows users to specify most of the `Invoke-SCuBA` cmdlet [parameters](parameters.md) in a configuration file. The path of the file is specified by the `-ConfigFilePath` parameter, and its contents can be formatted as YAML or JSON. Important details about executing ScubaGear with a configuration file are listed below.

- Executing ScubaGear with a modified configuration file is required to pass or omit specific ScubaGear policy checks. See [SCuBA Compliance Configuration](#scuba-compliance-configuration) and the associated sample configuration file for details.

- The configuration file allows users to add additional fields to embed within the ScubaGear output JSON for supplemental metadata purposes.

- The configuration files use the Pascal case convention for variables, and their names are consistent with the parameters.

> Important: When a parameter is specified on both the command line and the configuration file, the parameter value provided on the command line has precedence and the configuration file value will be disregarded.

## Sample Configuration Files

[Sample config files](../../PowerShell/ScubaGear/Sample-Config-Files) are available in the repo. Several of these sample config files are explained in more detail in the sections below.

### SCuBA Compliance Configuration

The [SCuBA compliance](../../PowerShell/ScubaGear/Sample-Config-Files/scuba_compliance.yaml) example config file is the **recommended starting point** for organizations seeking to meet SCuBA compliance checks. This configuration file contains:

- Essential parameters for SCuBA baseline compliance
- Fields for adding conditional access policy exceptions
- Fields for omitting ScubaGear policy checks with proper rationale
- Additional organizational documentation fields
- Examples of exclusions, annotations, and omissions

Users are highly encouraged to read all the configuration file documentation sections to understand what each field is for and to modify those fields to successfully pass ScubaGear's SCuBA baseline compliance checks.

This configuration file includes the additional `OrgName` and `OrgUnitName` fields for documenting the organization and organizational subunit owner of the M365 tenant ScubaGear is running against.

```yaml
OrgName: Department of Example
OrgUnitName: Subdepartment of Example  
```

ScubaGear can be invoked with this config file:

```powershell
# Invoke with SCuBA compliance config
Invoke-SCuBA -ConfigFilePath scuba_compliance.yaml
```

### Full Configuration Reference

The [full config file](../../PowerShell/ScubaGear/Sample-Config-Files/full_config.yaml) shows **all available parameters** supported by ScubaGear specified in the config file. This serves as a complete reference for all possible configuration options. Any parameter may be commented out - if not specified or commented out, ScubaGear will supply the default value unless overridden on the command line.

**Note**: Default values do not apply to authentication parameters (Organization, AppID, CertificateThumbprint).

```powershell
# Invoke with full configuration reference
Invoke-SCuBA -ConfigFilePath full_config.yaml
```

### Alternative Configuration Approaches

While the SCuBA compliance and full configuration files above are recommended, you can also create simpler configurations:

**Basic Configuration**: Specify only essential parameters (ProductNames and M365Environment):
```yaml
ProductNames: ['aad', 'defender', 'exo']
M365Environment: commercial
```

### Non-Interactive Authentication

For automated or unattended execution, you can configure ScubaGear to use service principal authentication by adding the **Organization**, **App ID**, and **Certificate Thumbprint** parameters to your configuration file. This method is ideal for scheduled assessments or CI/CD pipelines.

**Important**: The certificate's private key must be available in the certificate store, and config files with sensitive authentication data should be protected appropriately.

Example configuration with service principal authentication:

```yaml
Organization: "contoso.onmicrosoft.com"
AppID: "abcdef01-2345-6789-abcd-e0123456789a"  # Application (client) ID
CertificateThumbprint: "FEDCBA9876543210FEDCBA9876543210FEDCBA98"  # 40-character hex string
ProductNames: ['aad', 'defender', 'exo']
M365Environment: commercial
```

You can also override authentication parameters at runtime:

```powershell
# Override authentication parameters on command line
Invoke-SCuBA `
  -ConfigFilePath myconfig.yaml `
  -Organization contoso.onmicrosoft.com `
  -AppID abcdef0123456789abcde01234566789 `
  -CertificateThumbprint fedcba9876543210fedcba9876543210fedcba98
```

For more details on setting up service principal authentication, see the [Non-Interactive Permissions](../prerequisites/noninteractive.md) documentation.

## Generate Configuration Files

ScubaGear provides two methods for creating configuration files: a command-line utility and a graphical user interface.

### Method 1: Configuration UI (Recommended)

The **Configuration UI** provides an intuitive graphical interface for creating and managing ScubaGear configuration files:

```powershell
# Launch the Configuration UI
Invoke-SCuBAConfigAppUI
```

The Configuration UI offers:
- **User-friendly interface** with guided setup
- **Real-time validation** of all configuration options
- **YAML preview** before saving
- **Import/export** existing configurations
- **Microsoft Graph integration** for browsing users and groups
- **Built-in help** and examples for all settings

This is the **recommended method** for users who prefer visual interfaces or are new to ScubaGear configuration.

For complete documentation on using the Configuration UI, see the [Configuration UI Guide](../scubaconfigui.md).

### Method 2: Command-Line Generation

You can also generate an empty sample configuration file using the command line. The `New-SCuBAConfig` cmdlet will create a template configuration file called `SampleConfig.yaml`:

```powershell
# Create an empty config file
New-SCuBAConfig
```

Parameters can be passed to the `New-SCuBAConfig` cmdlet to pre-populate values in the sample configuration:

```powershell
# Create config with pre-set values
New-SCuBAConfig -Organization "contoso.onmicrosoft.com" -ProductNames "aad,defender"
```

The generated file can then be manually edited to add your specific configuration settings.

## Omit Policies

In some cases, it may be appropriate to omit specific policies from ScubaGear evaluation. For example:
- When a policy is implemented by a third-party service that ScubaGear does not audit
- When a policy is not applicable to your organization (e.g., policy MS.EXO.4.3v1 is only applicable to federal, executive branch, departments and agencies)

The `OmitPolicy` top-level key, shown in this [example ScubaGear configuration file](../../PowerShell/ScubaGear/Sample-Config-Files/omit_policies.yaml), allows the user to specify the policies that should be omitted from the ScubaGear report. Omitted policies will show up as "Omitted" in the HTML report and will be colored gray. Omitting policies must only be done if the omissions are approved within an organization's security risk management process. **Exercise care when omitting policies because this can inadvertently introduce blind spots when assessing your system.**

For each omitted policy, the config file allows you to indicate the following:
- `Rationale`: The reason the policy should be omitted from the report. This value will be displayed in the "Details" column of the report. ScubaGear will output a warning if no rationale is provided.
- `Expiration`: Optional. A date after which the policy should no longer be omitted from the report. The expected format is yyyy-mm-dd.

## Annotate Policies

ScubaGear supports annotating results for individual policies. Annotated policies will be shown in the HTML with the
annotation appended to the details column. Annotated policies are intended to:
- Document action plans for any failed controls. ScubaGear will output a warning for any failing controls that are not
documented in the config file, though this warning can be silenced with the `-SilenceBODWarnings` flag.
- Allow users to identify incorrect results
- Help contextualize results

The `AnnotatePolicy` top-level key, shown in this [example ScubaGear configuration file](../../PowerShell/ScubaGear/Sample-Config-Files/annotate_policies.yaml), allows the user to specify the policies that should be annotated.

For each annotated policy, the config file allows you to indicate the following:
- `IncorrectResult`: Boolean, whether or not to mark the result incorrect. Optional, defaults to false.
- `Comment`: The annotation to add to the report. A warning will be printed if control is marked incorrect with no comment provided as justification.
- `RemediationDate`: Optional. The date a failing control is anticipated to be implemented. The expected format is yyy-mm-dd.

**Exercise care when marking incorrect results because this can inadvertently introduce blind spots when assessing your system.**

## Product-specific Configuration

Config files can include a top-level level key for a given product whose values are related to that specific product. For example, look for the value of `Defender` in this [Defender config file](../../PowerShell/ScubaGear/Sample-Config-Files/defender_config.yaml). Currently, only Entra ID, Defender, and Exchange Online use this extra configuration.

Under a product key, there can be policy keys that provide configuration values unique to the product. In the Defender config file, for example, there is the `MS.DEFENDER.1.4v1` key.

### Entra ID Configuration

The ScubaGear configuration file provides the capability to exclude specific users or groups from some of the Entra ID policy checks. For example, a user could exclude emergency access accounts from some of the policy checks. Exclusions must only be used if they are approved within an organization's security risk acceptance process. **Exclusions can introduce grave risks to your system and must be managed carefully**.

An example configuration file for Entra ID can be found in this sample [configuration](../../PowerShell/ScubaGear/Sample-Config-Files/aad_config.yaml).

#### Conditional Access Policy Exclusions

The `Aad` top level key in the [configuration](../../PowerShell/ScubaGear/Sample-Config-Files/aad_config.yaml) allows the user to specify configurations specific to the Entra Id baseline. Under the `Aad` key is the policy identifier such as `MS.AAD.1.1v1` and under that is the `CapExclusions` key where the excluded users or groups are defined. The `CapExclusions` key supports both a `Users` or `Groups` list with each entry representing the UUID of a user or group from the tenant that will be excluded from the respective policy check.

CapExclusions are supported for the following policies:

- MS.AAD.1.1v1
- MS.AAD.2.1v1
- MS.AAD.2.3v1
- MS.AAD.3.1v1
- MS.AAD.3.2v1
- MS.AAD.3.6v1
- MS.AAD.3.7v1
- MS.AAD.3.8v1

#### Privileged User Policy Exclusions

In addition to defining exclusions for conditional access policies, the [configuration](../../PowerShell/ScubaGear/Sample-Config-Files/aad_config.yaml) also supports user or group exclusions related to Entra Id policy section 7 which is related to highly privileged user access. The `RoleExclusions` key supports both a `Users` and `Groups` list with each entry representing the UUID of a user or group from the tenant that will be excluded from the respective policy check.

RoleExclusions are supported for the following policies:

- MS.AAD.7.4v1

### Defender Configuration

The M365 Defender Secure Configuration Baseline includes several policies that help ensure an organization has configured protections for sensitive accounts, groups, or domains. The ScubaGear configuration file can be used along with policy-specific variables to inform the ScubaGear assessment checks which accounts, groups, and domains the organization considers sensitive.

All Defender related policy-specific variables are found under the `Defender` configuration namespace key within the ScubaGear configuration file. Defender policy items with associated configuration variables are:

- MS.DEFENDER.1.4v1
- MS.DEFENDER.1.5v1
- MS.DEFENDER.2.1v1
- MS.DEFENDER.2.2v1
- MS.DEFENDER.2.3v1

Several examples of using Defender policy-specific variables can be found in this [sample configuration](../../PowerShell/ScubaGear/Sample-Config-Files/defender_config.yaml). The sample configuration file also uses [Anchors and Aliases](#anchors-and-aliases) notation to reuse variable definitions across policy items with the same values.

#### Sensitive Accounts

The Defender baseline defines sensitive accounts as a set of user accounts that have access to sensitive and high-value information. As a result, these accounts may be at a higher risk of being targeted. The organization itself determines the set of sensitive user accounts within their M365 tenants.

The Defender baseline policies `MS.DEFENDER.1.4v1` and `MS.DEFENDER.1.5v1` dictate that accounts the organization designates as sensitive shall be assigned to the Strict Preset Security Profile. Accounts are assigned to a profile by an associated filter that specifies included and excluded users, groups, and domains. ScubaGear needs to know which accounts are considered sensitive to adequately assess these baseline policies.

Policies `MS.DEFENDER.1.4v1` and `MS.DEFENDER.1.5v1` both take a variable called `SensitiveAccounts` to define the filter that should be used to assign sensitive user accounts to the Strict Preset Security Profile. `MS.DEFENDER.1.4v1` defines the filter for applying Exchange Online Protection policies, while `MS.DEFENDER.1.5v1` sets the filter for applying Defender for Office365 protection policies.

Values for each key match those shown in the **Apply Defender for Office 365 protection** section of the manage protection settings dialog and are:

- `IncludedUsers`
- `IncludedGroups`
- `IncludedDomains`
- `ExcludedUsers`
- `ExcludedGroups`
- `ExcludedDomains`

See the sample configuration file shown in the previous section [Defender Configuration](#defender-configuration) for an example of sensitive account filter settings.

#### User impersonation protection

The policy `MS.DEFENDER.2.1v1` supports a variable called `SensitiveUsers` that can be defined as a list of sensitive user accounts denoted by a display name and email address in the Strict and Standard Preset Security Policies impersonation protection section.

Each value should be a string in the form of the display name and email address separated by a semicolon (e.g.,`John Doe;jdoe@example.com`).

#### Agency Domain Impersonation Protection

The policy `MS.DEFENDER.2.2v1` supports a variable called `AgencyDomains` that can be defined as a list of sensitive organization-controlled DNS domains for which impersonation protection should be enabled in both the Standard and Strict Preset Security Profiles.

Each domain in the list should be shown as the fully-qualified domain name associated with the agency.  Note that domains already associated with the tenant will already be given domain impersonation protection by default. This setting is to support adding additional agency domains not already associated with the tenant directly. Within the impersonation protection settings, this is associated with the `Include custom domains` within the associated anti-phishing policy.

#### Agency Partner Domain Impersonation

The policy `MS.DEFENDER.2.3v1` supports a variable called `PartnerDomains` that can be defined as a list of sensitive DNS domains used by important partner organizations for which impersonation protection should be enabled in both the Standard and Strict Preset Security Profiles.

Each domain in the list should be shown as the fully-qualified domain name associated with the partner organization. These domains are also added to the `Include custom domains` list, but the variable is kept separate to document the association with the associated Defender baseline policy.

### Exchange Online Configuration

The ScubaGear configuration file provides the capability to exclude specific domains from the MS.EXO.1.1v2 policy check.

#### Automatic Forwarding to Remote Domains

The policy `MS.EXO.1.1v2` supports a variable called `AllowedForwardingDomains` that expects a list of domain names for which automatic forwarding should be allowed.
Each domain in the list should be given as the fully-qualified domain name.
Exercise caution when allowing automatic forwarding to an external domain, as adversaries can use automatic forwarding to gain persistent access to a victim's email.
Refer to the EXO [example ScubaGear configuration file](../../PowerShell/ScubaGear/Sample-Config-Files/exo_config.yaml) for more details.

## Anchors and Aliases

If YAML is chosen as the config file format, YAML [anchors and aliases](https://smcleod.net/2022/11/yaml-anchors-and-aliases/) can be used to avoid repeating policy values. For example, in the [Defender config file](../../PowerShell/ScubaGear/Sample-Config-Files/defender_config.yaml), `&CommonSensitiveAccountFilter` is an anchor whose value is referenced later by `*CommonSensitiveAccountFilter`, an alias.

Using anchors and aliases is optional, but supports reuse in a way that allows for updating variable values in a consistent way when they apply to multiple policies.

## Muting the Version Check Warnings

To prevent ScubaGear from trying to determine if a newer release is available and emitting a warning at import time, set the environment variable `SCUBAGEAR_SKIP_VERSION_CHECK` to any non-whitespace value.