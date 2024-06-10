# ScubaGear Configuration File

Most of the `Invoke-SCuBA` cmdlet [parameters](parameters.md) can be placed into a configuration file in order to make execution easier. The path of the file is specified by the `-ConfigFilePath` parameter, and it contents can be formatted as YAML or JSON.

> **Note**: If a parameter is also specified in a configuration file, the command-line parameter has precedence over the config file. 

> **Note**: The config files use the Pascal case convention for variables, and their names are consistent with the parameters.

## Sample Configuration Files

[Sample config files](https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/Sample-Config-Files) are available in the repo. Four of these sample config files are explained in more detail in the sections below.

### Basic Use

The [basic use](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/basic_config.yaml) example config file only specifies a product name and an M365 environment.

ScubaGear can be invoked with this config file:

```powershell
# Invoke with a config file
Invoke-SCuBA -ConfigFilePath basic_config.yaml
```

It can also be invoked while overriding the the `M365Environment` parameter:

```powershell
# Invoke with an override
Invoke-SCuBA `
  -M365Environment gcc `
  -ConfigFilePath minimal_config.yaml
```

### Typical Use

The [typical use](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/typical_config.yaml) example config file includes multiple products specified as a list and an M365 environment. Additional product values are commented out and will not be included in the testing, but they are retained in the config file to easily add them back later.

ScubaGear can be invoked with this config file:

```powershell
# Invoke with config file
Invoke-SCuBA -ConfigFilePath typical_config.yaml
```

It can also be invoked while specifying non-interactive mode authentication parameters:

```powershell
# Invoke with non-interactive authentication
Invoke-SCuBA `
  -ConfigFilePath typical_config.yaml `
  -Organization contoso.onmicrosoft.com `
  -AppID abcdef0123456789abcde01234566789 `
  -CertificateThumbprint fedcba9876543210fedcba9876543210fedcba98
```

### Credential Use

The [credential user](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/creds_config.yaml) example config file supplies credentials using a service principal, appId, and certificate thumbprint. (The associated private key is still required.)  Config files with sensitive data should be protected appropriately.

ScubaGear can be invoked with this config file:

```powershell
# Invoke with config file
Invoke-SCuBA -ConfigFilePath creds_config.yaml
```

It can also be invoked by overriding the product names:

```powershell
# Invoke with a different product name
Invoke-SCuBA `
  -ConfigFilePath typical_config.yaml `
  -ProductNames defender
```

### Full Use

The [full config file](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/full_config.yaml) shows all of the global parameters supported by ScubaConfig specified in the config file. Any one of these parameters may be commented out. If not specified or if commented out, ScubaConfig will supply the default value, unless it's overridden on the command line. Default values do not apply to authentication parameters.

```powershell
# Invoke without any overrides
Invoke-SCuBA -ConfigFilePath full_config.yaml
```

## Generate an Empty Sample Configuration File

ScubaGear's support module can generate an empty sample config file. Running the `New-Config` cmdlet will generate a full sample config called `SampleConfig.yaml` that can be filled out based on the guidance below. Parameters can be passed to the `New-Config` cmdlet to change values inside the sample config.

```powershell
# Create an empty config file
New-Config
```

## Product-specific Configuration

Config files can include a top-level level key for a given product whose values are related to that specific product. For example, look for the value of `Defender` in this [Defender config file](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/defender-config.yaml). Currently, only Entra ID and Defender use this extra configuration.

Under a product key, there can be policy keys that provide configuration values unique to the product. In the Defender config file, for example, there is the `MS.DEFENDER.1.4v1` key.

### Entra ID Configuration

The ScubaGear configuration file provides the capability to exclude specific users or groups from some of the Entra ID policy checks. For example, a user could exclude emergency access accounts from some of the policy checks. Exclusions must only be used if they are approved within an organization's security risk acceptance process. **Exclusions can introduce grave risks to your system and must be managed carefully**.

An example configuration file for Entra ID can be found in this sample [configuration](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/aad-config.yaml).

#### Conditional Access Policy Exclusions

The `Aad` top level key in the [configuration](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/aad-config.yaml) allows the user to specify configurations specific to the Entra Id baseline. Under the `Aad` key is the policy identifier such as `MS.AAD.1.1v1` and under that is the `CapExclusions` key where the excluded users or groups are defined. The `CapExclusions` key supports both a `Users` or `Groups` list with each entry representing the UUID of a user or group from the tenant that will be excluded from the respective policy check.

CapExclusions are supported for the following policies:

- MS.AAD.1.1v1
- MS.AAD.2.1v1
- MS.AAD.2.3v1
- MS.AAD.3.1v1
- MS.AAD.3.2v1
- MS.AAD.3.6v1
- MS.AAD.3.8v1

#### Privileged User Policy Exclusions

In addition to defining exclusions for conditional access policies, the [configuration](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/aad-config.yaml) also supports user or group exclusions related to Entra Id policy section 7 which is related to highly privileged user access. The `RoleExclusions` key supports both a `Users` and `Groups` list with each entry representing the UUID of a user or group from the tenant that will be excluded from the respective policy check.

RoleExclusions are supported for the following policies:

- MS.AAD.7.4v1

### Defender Configuration

An example for Defender can be found in this [configuration](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/defender-config.yaml).  More details will be coming soon.

## Anchors and Aliases

If YAML is chosen as the config file format, YAML [anchors and aliases](https://smcleod.net/2022/11/yaml-anchors-and-aliases/) can be used to avoid repeating policy values. For example, in the [Defender config file](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/Sample-Config-Files/defender-config.yaml), `&CommonSensitiveAccountFilter` is an anchor whose value is referenced later by `*CommonSensitiveAccountFilter`, an alias.
