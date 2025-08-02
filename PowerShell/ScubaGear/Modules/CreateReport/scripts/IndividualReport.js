window.addEventListener('DOMContentLoaded', () => {
    const MAX_DNS_ENTRIES = 20;

    const darkMode = getJsonData('dark-mode-flag') === "true";
    const caps = getJsonData('cap-json');
    const riskyApps = getJsonData('risky-apps-json');
    const riskyThirdPartySPs = getJsonData('risky-third-party-sp-json');

    colorRows();
    //fillCAPTable(caps);
    //buildRiskyAppsTable(riskyApps);
    //buildRiskyThirdPartySPsTable(riskyThirdPartySPs);

    buildExpandableTable(caps, "caps", "caps", "Conditional Access Policies");
    buildExpandableTable(riskyApps, "risky_apps", "risky_apps_wrapper", "Risky Applications");
    buildExpandableTable(riskyThirdPartySPs, "risky_third_party_service_principals", "risky_third_party_sps_wrapper", "Risky Third Party Service Principals");

    applyScopeAttributes();
    truncateSPFList(MAX_DNS_ENTRIES);
    truncateDNSTables(MAX_DNS_ENTRIES);
    mountDarkMode(darkMode, "Individual Report");
});