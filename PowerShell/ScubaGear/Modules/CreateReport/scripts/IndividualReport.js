window.addEventListener('DOMContentLoaded', () => {
    const MAX_DNS_ENTRIES = 20;

    const darkMode = getJsonData('dark-mode-flag') === "true";
    const caps = getJsonData('cap-json');
    const riskyApps = getJsonData('risky-apps-json');
    const riskyThirdPartySPs = getJsonData('risky-third-party-sp-json');

    buildExpandableTable(caps, "caps", "caps", "Conditional Access Policies");
    buildExpandableTable(riskyApps, "riskyApps", "risky_apps_table", "Risky Applications");
    buildExpandableTable(riskyThirdPartySPs, "riskyThirdPartySPs", "risky_third_party_sps_table", "Risky Third Party Service Principals");

    colorRows();
    applyScopeAttributes();
    truncateSPFList(MAX_DNS_ENTRIES);
    truncateDNSTables(MAX_DNS_ENTRIES);
    mountDarkMode(darkMode, "Individual Report");
});