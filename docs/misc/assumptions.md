# Assumptions

## M365 Product License Assumption

ScubaGear has been tested against tenants that have an M365 E3 or G3 and E5 or G5 license bundle. It may still function for tenants that do not have one of these bundles.

> **Note**: DOD endpoints are included, but have not been tested. Please open an issue if you encounter bugs.

Some of the policy checks in the baselines rely on the following licenses, which are included by default in M365 E5 and G5:
* Microsoft Entra ID P2
* Microsoft Defender for Office 365 Plan 1 or 2

All controls that require a license beyond E3 or G3 note the required license in its respective "License Requirements" section. In all cases, the requirement for controls that require an additional license can be met using a third-party service. In order to prevent ScubaGear from reporting failures for any controls you implement using a third-party service, you will need to document that you use a third-party service by configuring ScubaGear to omit the relevant controls. See [Omit Policies](https://github.com/cisagov/ScubaGear/blob/main/docs/configuration/configuration.md#omit-policies) for more details.
