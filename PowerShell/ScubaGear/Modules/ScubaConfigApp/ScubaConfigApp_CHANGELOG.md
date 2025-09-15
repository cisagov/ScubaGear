:  # SCUBACONFIGAPPUI CHANGELOG

## 1.9.22 [09/15/2025] - UI & Usability Improvements

### Bug Fixes
 - Fixed Result Path button – now opens to the correct folder based on Outpath or default.
 - Removed debug log null message from ScubaRun when no process is running.
 - Fixed search and filter clearing issue when selecting cards.
 - Fixed ESC key toggle. To allow UI to be in front or behind
 - Fixed reports json parser to look for special characters in org name such as & % $

### Enhancements
- Added ScubaGear icon to UI windows (using Scuba-themed PNG).
- Renamed Changelog button to What’s New (shows latest changes only). Added separate button for Full Changelog.
- Policy import now updates cards for Exclusions, Annotations, and Omissions – providing an easier editing experience.
- Added a green status dot next to configured items for quick visual recognition.
- Updated Scuba Run button to show gray when disabled, removeing confusion if enabled.
- Add Filter control for saved configurations; allowing a better user experience when managing cards
- Minimzed UI when launching full report; this reduced multple click and helps users make sure they see the report open

### Code Improvements
- Added a title property to each Graph query in JSON – now displayed in the selector window for clearer guidance.
- Removed unnecessary update functions; integrated logic directly into card generation functions for cleaner code.
- Sped up launch time by developing runspace for results scan and reduced maximum reports to 10

## 1.8.18 [08/18/2025] - GlobalSettings and Baseline Exclusion Management Enhancement

### Bug Fixes
- Fixed GlobalSettings remove functionality and case sensitivity issues with field naming across configuration files
- Resolved baseline exclusion data persistence where removing all items from fields would leave stale data in YAML output
- Corrected UI control clearing and naming patterns in remove operations to properly clear all field types
- Fixed AutoSave integration parameter mismatches for GlobalSettings remove operations

### Enhancements
- Added -OutPolicyOnly parameter to New-FieldListCard for simplified GlobalSettings data flow with direct storage
- Enhanced ScubaRun with dynamic mode detection status messages and automatic configuration export with viewer
- Replaced hardcoded baseline filtering with configuration-driven approach using supportsAllProducts property

### Code Improvements
- Removed deprecated GlobalSettings sync functions and cleaned up legacy calls across helper modules
- Enhanced debug logging and validation error handling with comprehensive field-level detail and better error messages
- Standardized control naming patterns and data structure handling across save/remove operations
- Implemented clear-and-rebuild strategy for baseline exclusions to prevent data persistence issues

### Configuration Updates
- Updated field configuration to align PreferredDnsResolvers naming with ScubaGear YAML format requirements
- Enhanced exclusion data structure handling for proper field removal and YAML compatibility

## 1.8.14 [08/14/2025] - Comprehensive Test Framework and Module Architecture Enhancement
-  Implemented changelog display functionality with `Show-ChangelogWindow` function for easy access to version history
-  Moved functions from main module to 17 specialized helper modules for better organization and maintainability
-  Resolved product-specific report display issues to properly show ScubaGear execution results
-  Implemented comprehensive Pester test suite for all 17 helper modules with 10 test contexts covering file existence, syntax validation, Unicode character detection, import validation, dependencies, and documentation
-  Added validation for 94+ functions across helper modules ensuring all expected functions are present and properly organized
-  Implemented Unicode character detection tests to prevent PowerShell parsing errors from problematic characters (emojis, special symbols)

## 1.8.10 [08/10/2025] - ScubaGear Execution Experience Enhancement
- Implemented enhanced completion status reporting with baseline conformance report path display
- Added fixed-width text display capabilities with wrapping, vertical scrolling, and text selection functionality
- Improved ScubaGear execution workflow and ehanced execution montiring to near real team.
- Resolved graph connection and proper disconnections

## 1.8.7 [08/07/2025] - ScubaGear Execution Output Text Wrapping Enhancement
- Built a fully JSON-driven ScubaGear execution framework with dynamic PowerShell command construction, including cmdlet selection, module imports, parameter type handling (string/boolean), and UI control mapping.
- Implemented graph comamnd for application id retriveal
- Improved execution workflow stability with variable scope fixes in background jobs, temporary YAML file generation and cleanup, and robust error handling.
- Refined YAML generation process by correcting function calls and ensuring accurate preview/export behavior.

## 1.8.6 [08/06/2025] - YAML Generation and Input Validation Enhancements
- Fixed baseline controls loop in YAML preview to properly display field names and values for exclusions, annotations, and omissions
- Corrected data structure access pattern for flipped structure (Product -> FieldType -> PolicyId -> FieldData) in annotations and omissions processing
- Implemented YAML pipe syntax (|) for multiline strings with proper indentation instead of escaped quotes and \n characters
- Separated baseline policies and UI configuration into distinct JSON files for improved maintainability

## 1.8.4 [08/04/2025] - Global Settings Implementation and Placeholder Text Fixes
- Implemented global settings tab with DNS resolver array controls and DoH boolean settings
- Fixed placeholder text restoration bug; reliable behavior across multiple focus cycles
- Enhanced UI control stability with proper variable scoping in event handler closures
- Improved data structure synchronization between nested cards and flat YAML output
- Implemented language-agnostic MessageBox system with new `localeTitles` JSON configuration section for standardized titles and messages
- Improved internationalization readiness and standardized MessageBox presentation across all UI components for multi-language support

## 1.7.30 [07/30/2025] - Import Functionality and UI Enhancements
- Fixed `ContainsKey` method errors for OrderedDictionary objects and removed timer to speed up UI response
- Enhanced YAML import workflow with automatic UI synchronization, wildcard (*) expansion handling, and proper ProductNames checkbox selection
- Implemented `Update-AllUIFromData` function with automatic checkbox checking and input field population during import
- Enhanced OPA Path browser with default `$env:UserProfile\.scubagear\Tools` directory and added fallback logic for proper path selection and validation

## 1.7.29 [07/29/2025] - Unit Testing and Code Analysis
- Added script analyzer suppress for runspace and updated unit test for sample config
- Fixed YAML import functionality to populate both GeneralSettings and AdvancedSettings with proper data structure
- Resolved debug queue array index errors and added comprehensive error handling and validation

## 1.7.28 [07/28/2025] - UI Optimization and Debug Enhancement
- Enhanced debug functionality with Pester testing framework, proper null checking for debug queue operations, and detailed error logging with stack traces
- Fixed timer event handler array index issues and optimized UI refresh cycles for improved performance
- Disabled debug mode for production builds and implemented comprehensive UI optimization improvements

## 1.7.23 [07/23/2025] - Module Architecture Modernization
- Moved UI to dedicated module with modular architecture for better maintainability and enhanced component separation
- Modernized vertical scrollbar design and functionality for improved user experience

## 1.7.22 [07/22/2025] - Documentation and Visual Updates
- Updated markdown documentation with improved project structure and enhanced visual presentation for better user guidance
- Enhanced images and visual assets for clearer project documentation

## 1.7.21 [07/21/2025] - Core Configuration System Implementation
- Added comprehensive configuration system with detailed comments, enhanced anchor mention functionality, and removed old configuration files with updated README
- Implemented ScubaConfig UI foundation with online feature functionality, debug capabilities, and enhanced UI responsiveness and error handling
- Fixed YAML output formatting issues, resolved YAML export functionality, and created robust YAML import/export functionality with proper data management
- Established configuration data structures with GeneralSettings vs AdvancedSettings separation and implemented advanced settings toggle functionality
- Added multiple locale language support, fixed JSON M365 environment configuration, and updated markdown documentation and related modules
- Converted SVG icons to XAML format for WPF integration and developed debug message queue system
- Removed trailing spaces, fixed formatting cleanup issues (newline improvements, missing start spaces, empty space formatting)