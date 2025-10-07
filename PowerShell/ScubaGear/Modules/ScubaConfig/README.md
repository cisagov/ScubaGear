# ScubaConfig Module

The ScubaConfig module provides configuration management for ScubaGear, including YAML configuration file validation, default value management, and runtime configuration handling.

## Overview

The ScubaConfig module consists of several key components that work together to provide a robust, configuration-driven system:

- **ScubaConfig.psm1** - Main configuration class (singleton pattern)
- **ScubaConfigValidator.psm1** - YAML validation and schema enforcement
- **ScubaConfigDefaults.json** - Default values and reference data
- **ScubaConfigSchema.json** - JSON Schema for validation rules

## Configuration Files: Schema vs Defaults

### ScubaConfigSchema.json - The "Rules & Structure"

This is a **JSON Schema** that defines the validation rules and structure for configuration files.

#### Purpose

- **Data Structure & Validation Rules** - What properties are allowed in a ScubaGear configuration file
- **Data Types** - Defines whether each property should be a string, boolean, array, etc.
- **Validation Patterns** - Regular expressions for format checking (GUIDs, domain names, etc.)
- **Value Constraints** - Min/max length, allowed enum values, numeric ranges

#### Example Usage

```json
"Organization": {
  "type": "string",
  "description": "Organization domain name",
  "pattern": "^[a-zA-Z0-9.-]+\\.(onmicrosoft\\.com|onmicrosoft\\.us)$"
}
```

This defines: *"Organization must be a string that matches the Microsoft domain pattern"*

#### Runtime Role

- Used to **validate user-provided YAML config files** at runtime
- Ensures the configuration meets structural and format requirements
- Catches errors like invalid GUIDs, wrong data types, malformed patterns

---

### ScubaConfigDefaults.json - The "Default Values & Reference Data"

This contains **actual data values** and **configuration metadata** used by the system.

#### Purpose

1. **Default Values** - Fallback values when users don't specify configuration options
2. **System Configuration** - Behavioral settings like required fields and validation rules
3. **Reference Data** - Lookup tables and environment-specific information

#### Structure

##### 1. Default Values Section

```json
"defaults": {
  "M365Environment": "commercial",
  "LogIn": true,
  "OutPath": ".",
  "ProductNames": ["aad", "defender", "exo", "sharepoint", "teams"],
  "OPAVersion": "1.6.0"
}
```

These are the **actual values** used when users don't specify them in their configuration.

##### 2. Required Fields Configuration

```json
"minRequired": [
  "ProductNames",
  "M365Environment",
  "Organization",
  "OrgName",
  "OrgUnitName"
]
```

Defines **which fields are mandatory** for a valid configuration (used by validation logic).

##### 3. Reference Data

```json
"M365Environment": {
  "commercial": {
    "name": "Commercial",
    "description": "Production environment for public tenants",
    "endpoints": {
      "graph": "https://graph.microsoft.com",
      "login": "https://login.microsoftonline.com"
    }
  },
  "gcc": {
    "name": "Government Community Cloud",
    "endpoints": {
      "graph": "https://graph.microsoft.us",
      "login": "https://login.microsoftonline.us"
    }
  }
}
```

Contains **lookup data** like environment configurations, product definitions, privileged roles, etc.

---

## Key Differences

| **ScubaConfigSchema.json** | **ScubaConfigDefaults.json** |
|---|---|
| **Validation rules** | **Actual values** |
| Defines *structure* | Provides *defaults* |
| Used to *validate* user input | Used to *fill in* missing values |
| JSON Schema format | Regular JSON data |
| Describes *what's allowed* | Defines *what's recommended* |
| Static validation rules | Dynamic configuration data |

## How They Work Together

### 1. Configuration Loading Process

```
User YAML Config → Schema Validation → Default Value Application → Final Configuration
```

1. **User provides a YAML config** → Schema validates it's structurally correct
2. **Missing values** → Defaults.json provides fallback values
3. **Required fields check** → Uses `minRequired` from Defaults.json
4. **Runtime behavior** → Uses reference data from Defaults.json

### 2. Example Flow

```yaml
# User's config.yaml (minimal)
ProductNames: ["aad", "exo"]
Organization: "contoso.onmicrosoft.com"
OrgName: "Contoso Corp"
OrgUnitName: "IT Security"
```

**Processing:**

1. **Schema validation** - Ensures ProductNames is an array, Organization matches domain pattern
2. **Required field check** - Verifies all fields in `minRequired` are present
3. **Default application** - Adds M365Environment: "commercial", LogIn: true, etc.
4. **Final config** - Complete configuration ready for use

## Architecture Benefits

### Configuration-Driven Design

The module uses a **configuration-driven approach** that eliminates hardcoded values:

- **Adding new defaults** - Just add to `ScubaConfigDefaults.json`, no PowerShell code changes needed
- **Modifying validation** - Update schema or `minRequired` array without touching business logic
- **Environment customization** - Easy to maintain different configurations for different environments

### Separation of Concerns

- **Schema** = Structure and format rules (what's valid)
- **Defaults** = Business logic and data (what's recommended)
- **Validator** = Enforcement engine (how validation works)
- **Config Class** = Runtime management (how it's used)

## Usage Examples

### Loading Configuration

```powershell
# Load and validate configuration
$Config = [ScubaConfig]::GetInstance()
$Config.LoadConfig("path\to\config.yaml")

# Access configuration values
$Products = $Config.Configuration.ProductNames
$Environment = $Config.Configuration.M365Environment
```

### Getting Default Values

```powershell
# Get default values (automatically resolved from Defaults.json)
$DefaultProducts = [ScubaConfig]::ScubaDefault('DefaultProductNames')
$AllProducts = [ScubaConfig]::ScubaDefault('AllProductNames')
$OPAVersion = [ScubaConfig]::ScubaDefault('DefaultOPAVersion')
```

### Validation Only

```powershell
# Validate without loading
$ValidationResult = [ScubaConfig]::ValidateConfigFile("path\to\config.yaml")
if (-not $ValidationResult.IsValid) {
    foreach ($Error in $ValidationResult.ValidationErrors) {
        Write-Error $Error
    }
}
```

## Analogy

Think of the configuration system like a house:

- **Schema** = "The building code (rules for what makes a valid house)"
  - Must have doors, windows, electrical outlets in correct format
  - Defines what rooms are allowed and how they should be structured

- **Defaults** = "The standard furnishings and utilities"
  - Default furniture, standard electrical outlets, default paint colors
  - Provides what you get if you don't specify custom options

- **User Config** = "Your personal customizations"
  - Choose your own paint colors, furniture, room layouts
  - Must still follow building code but can customize within those rules

## Development Guidelines

### Adding New Configuration Options

1. **Add to Schema** - Define validation rules in `ScubaConfigSchema.json`
2. **Add to Defaults** - Provide default value in `ScubaConfigDefaults.json`
3. **Test** - No PowerShell code changes needed thanks to configuration-driven design!

### Modifying Validation Rules

- **Format validation** - Update patterns in Schema
- **Required fields** - Update `minRequired` array in Defaults
- **Business logic** - Update reference data in Defaults

The configuration-driven approach means most changes only require JSON updates, not PowerShell code modifications.

## Testing

The module includes comprehensive unit tests that verify:

- Configuration loading and validation
- Default value resolution
- Schema enforcement
- Error handling and reporting
- Configuration-driven behavior

Run tests with:

```powershell
Invoke-Pester .\Testing\Unit\PowerShell\ScubaConfig\
```