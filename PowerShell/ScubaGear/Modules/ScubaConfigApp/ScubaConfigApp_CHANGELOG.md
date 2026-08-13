
:  # SCUBACONFIGAPPUI CHANGELOG
## 2.8.12 (build 1500) [08/13/2026] - App-independent Baseline Policy Viewer, control cleanup, Analyzer online-baseline toggle

### Enhancements
- Made the Baseline Policy Viewer app-independent: moved its module into `ScubaBaselinePolicyViewerHelpers`, externalized its inline XAML to `ScubaConfigAppResources\ScubaBaselinePolicyViewerUI.xaml`, and gave it its own `ScubaBaselineViewer_Control_en-US.json` (window chrome + product/section mappings) at the module root. It is now imported on demand by both ScubaConfigApp and the Config Analyzer.
- Wired the `EnablePolicyViewer` flag so it actually gates the per-policy **View Baseline Policies** button on each Exclusion/Annotation/Omission card (previously the flag was unused and the button always showed). Shown unless explicitly `false`.
- Config Analyzer: externalized all file paths into `ScubaConfigAnalyzer_Control_en-US.json` (window resources — XAML/logo/icon — and the helpers folder stay hardcoded as foundational).
- Config Analyzer: made AAD mandatory in the product selector — EXO, Defender/Security Suite, and other products can be unchecked, but AAD is re-selected if a user tries to uncheck it.
- Config Analyzer: added an independent `PullOnlineBaselines` developer toggle (`OnlineBaselineSchemaURL` / `OnlineApiCatalogURL`) so developers can test not-yet-published analyzer schemas; downloads to `$env:TEMP` and falls back to the local schemas on failure.

### Bug Fixes
- Removed the now-dead `showInViewer` field (all products) and the entire `policyViewerSettings` block from `ScubaConfigApp_Control_en-US.json`; these only served the Baseline Policy Viewer and now live solely in `ScubaBaselineViewer_Control_en-US.json` (single source of truth, no stale duplicate).

### Code Improvements
- Added `ScubaConfigAnalyzer_Control_REFERENCE.md` and `ScubaBaselineViewer_Control_REFERENCE.md` documenting the Config Analyzer and Baseline Policy Viewer control files.
- Updated `ScubaConfigApp_Control_REFERENCE.md`: clarified `EnablePolicyViewer` and `PullOnlineBaselines` (shared by app + viewer; Analyzer is independent), removed `showInViewer`, and noted the policy-viewer config moved to the companion control file.

## 2.8.11 (build 1500) [08/11/2026] - Added comment control and walkthorugh viewer

### Enhancements
- Added support for the `ConfigLocation` parameter and related configuration-path handling improvements.
- Added a Help / Walkthrough window that resolves the walkthrough markdown path from the config and opens in-app guidance for the Scuba Config App.
- Updated the Scuba Config App UI to support comments on exclusion cards, including a cleaner add/remove toggle experience and preserved expanded state when comments exist.
- Added M365 environment and app ID support updates in the config app, improving compatibility with tenant and app configuration scenarios.
- Updated language handling and UI copy to better reflect the app’s supported configuration workflows.
- Improved default option behavior and config analyzer integration for more predictable startup and configuration behavior.
- Added support documentation updates and refreshed Pester validation coverage to keep the app aligned with current behavior.

### Bug Fixes
- Fixed a stale comment persistence bug where clearing a comment did not remove the stored comment entry and the old value kept reappearing in YAML output.
- Fixed the comment panel state so it stays expanded when a comment exists and collapses cleanly when the comment is removed.
- Hardened legacy policy migration import logic so malformed legacy config entries (string values where a dictionary was expected) are skipped safely instead of crashing with "Unable to index into an object of type System.String."
- Removed stray debug output noise and cleaned up the app behavior around config output and UI state.

### Code Improvements
- Refreshed the config app changelog and support documentation to reflect the current branch updates.
- Synced the UI resource, helper module, and test updates for the latest config app behavior.
- Cleaned up unused debug output and standardized the latest config app logic around comments, migration, and support-state handling.

## 2.6.1 (build 1400) [06/01/2026] - Security Suite Baseline, Config Externalization, and UX Polish

### Bug Fixes
- Fixed removing policies from an imported configuration file - data was not actually being removed from the output structure.
- Fixed online mode incorrectly pulling baselines from GitHub instead of local schema. Online mode controls tenant connectivity only; `PullOnlineBaselines` in the control config governs whether baselines are fetched from GitHub.
- Fixed policy viewer internal cross-reference links (e.g. "MS.SECURITYSUITE.3.1v1 Instructions") to correctly navigate to the referenced policy in the left nav panel instead of failing silently.

### Enhancements
- Added SecuritySuite product to replace legacy Defender product in the product list and throughout the configuration.
- Implemented legacy policy migration system to automatically remap Defender and EXO policy IDs to their SecuritySuite equivalents when importing older YAML configuration files.
- Migration report popup now displays auto-migrated, split, and removed policies with per-section summaries after import.
- Import now detects legacy policy IDs and auto-migrates them to current equivalents; a migration report popup summarizes migrated, split, and removed policies.
- Required input fields that fail validation on save are now highlighted with a red border, which clears automatically as soon as the user interacts with the field.
- YAML export header now includes the ScubaGear version.
- Externalized all migration behavior, locale strings, and popup content for the migration report into the JSON control file under `policyMigration` and `localeReportWindow`.
- Removed `productCodeMap` from the JSON config; the product code map is now derived at runtime from the `products` array so adding new products requires no code changes.
- Unified log prefix tokens under `localeReportWindow.sections` as the single source of truth, removing the redundant `logPrefixes` block.
- Renamed `reportWindow` to `localeReportWindow` to align with the existing locale naming convention used throughout the config file.
- Updated SCuBA detailed walkthrough documentation to cover the policy migration workflow.

### Code Improvements
- Added `ScubaConfigApp_Control_REFERENCE.md` documenting the full UI architecture, data flow, control configuration schema, and runspace model.
- Removed `ScubaConfigAppBaselineHelper.psm1` - baseline schema generation is now part of the repo build process, not a runtime app concern.
- Removed `ConvertTo-MigrationEntry` helper function; CSV parsing logic was consolidated directly into `Get-PolicyMigrationMap`.
- Policy migration map is cached in `$env:TEMP` to avoid re-parsing the CSV on every import.
- Updated encoding on several helper modules to UTF-8 with BOM for consistent PowerShell parsing across environments.
- Added 23 Pester unit tests covering `Get-PolicyMigrationMap`, `Invoke-PolicyMigration` Pass 1 (product exclusion blocks), and Pass 2 (annotation and omission keys).

## 2.4.13 [4/13/2026] - Extended CAPExclusions Support and UI Enhancements

### Enhancements
- Extended `CapExclusions` support to `Applications` and `GuestUserTypes`.
- Added multi select list boxes in the UI for easier management of guest user type exclusions.

## 2.3.16 (03/16/2026) - Baseline Loading Performance Enhancement

### Bug Fixes
- Fixed baseline policy viewer failure when using pre-generated baseline schema

### Enhancements
- Added Strategy 0 to Start-SCuBAConfigApp to prioritize loading pre-generated ScubaBaseline.json from schema folder
- Updated Show-SCuBABaselinePolicyViewer to use published baseline from schema folder instead of regenerating from markdown
- Significantly improved startup performance by eliminating markdown parsing overhead for standard use cases
- Maintained backward compatibility for custom baseline directories and GitHub URL scenarios

### Code Improvements
- Implemented cascading baseline loading strategy with published schema as highest priority
- Retained markdown generation fallback for development and testing workflows
- Aligned baseline loading logic with branch design for published baseline schema package


## 2.3.16 (03/16/2026) - Baseline Loading Performance Enhancement

### Bug Fixes
- Fixed baseline policy viewer failure when using pre-generated baseline schema

### Enhancements
- Added Strategy 0 to Start-SCuBAConfigApp to prioritize loading pre-generated ScubaBaseline.json from schema folder
- Updated Show-SCuBABaselinePolicyViewer to use published baseline from schema folder instead of regenerating from markdown
- Significantly improved startup performance by eliminating markdown parsing overhead for standard use cases
- Maintained backward compatibility for custom baseline directories and GitHub URL scenarios

### Code Improvements
- Implemented cascading baseline loading strategy with published schema as highest priority
- Retained markdown generation fallback for development and testing workflows
- Aligned baseline loading logic with branch design for published baseline schema package


## 2.3.16 (03/16/2026) - Baseline Loading Performance Enhancement

### Bug Fixes
- Fixed baseline policy viewer failure when using pre-generated baseline schema

### Enhancements
- Added Strategy 0 to Start-SCuBAConfigApp to prioritize loading pre-generated ScubaBaselines.json from schema folder
- Updated Show-SCuBABaselinePolicyViewer to use published baseline from schema folder instead of regenerating from markdown
- Significantly improved startup performance by eliminating markdown parsing overhead for standard use cases
- Maintained backward compatibility for custom baseline directories and GitHub URL scenarios

### Code Improvements
- Implemented cascading baseline loading strategy with published schema as highest priority
- Retained markdown generation fallback for development and testing workflows
- Aligned baseline loading logic with branch design for published baseline schema package


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
- Enhanced debug logging and validation error handling with field-level detail and better error messages
- Standardized control naming patterns and data structure handling across save/remove operations
- Implemented clear-and-rebuild strategy for baseline exclusions to prevent data persistence issues

### Configuration Updates
- Updated field configuration to align PreferredDnsResolvers naming with ScubaGear YAML format requirements
- Enhanced exclusion data structure handling for proper field removal and YAML compatibility

## 1.8.14 [08/14/2025] - Test Framework and Module Architecture Enhancement
-  Implemented changelog display functionality with `Show-ChangelogWindow` function for easy access to version history
-  Moved functions from main module to 17 specialized helper modules for better organization and maintainability
-  Resolved product-specific report display issues to properly show ScubaGear execution results
-  Implemented Pester test suite for all 17 helper modules with 10 test contexts covering file existence, syntax validation, Unicode character detection, import validation, dependencies, and documentation
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
- Resolved debug queue array index errors and added error handling and validation

## 1.7.28 [07/28/2025] - UI Optimization and Debug Enhancement
- Enhanced debug functionality with Pester testing framework, proper null checking for debug queue operations, and detailed error logging with stack traces
- Fixed timer event handler array index issues and optimized UI refresh cycles for improved performance
- Disabled debug mode for production builds and implemented UI optimization improvements

## 1.7.23 [07/23/2025] - Module Architecture Modernization
- Moved UI to dedicated module with modular architecture for better maintainability and enhanced component separation
- Modernized vertical scrollbar design and functionality for improved user experience

## 1.7.22 [07/22/2025] - Documentation and Visual Updates
- Updated markdown documentation with improved project structure and enhanced visual presentation for better user guidance
- Enhanced images and visual assets for clearer project documentation

## 1.7.21 [07/21/2025] - Core Configuration System Implementation
- Added configuration system with detailed comments, enhanced anchor mention functionality, and removed old configuration files with updated README
- Implemented ScubaConfig UI foundation with online feature functionality, debug capabilities, and enhanced UI responsiveness and error handling
- Fixed YAML output formatting issues, resolved YAML export functionality, and created robust YAML import/export functionality with proper data management
- Established configuration data structures with GeneralSettings vs AdvancedSettings separation and implemented advanced settings toggle functionality
- Added multiple locale language support, fixed JSON M365 environment configuration, and updated markdown documentation and related modules
- Converted SVG icons to XAML format for WPF integration and developed debug message queue system
- Removed trailing spaces, fixed formatting cleanup issues (newline improvements, missing start spaces, empty space formatting)