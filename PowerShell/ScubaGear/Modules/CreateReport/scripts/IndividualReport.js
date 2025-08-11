window.addEventListener('DOMContentLoaded', () => {
    const MAX_DNS_ENTRIES = 20;

    const darkMode = getJsonData('dark-mode-flag') === "true";
    const caps = getJsonData('cap-json');
    const riskyApps = getJsonData('risky-apps-json');
    const riskyThirdPartySPs = getJsonData('risky-third-party-sp-json');

    buildExpandableTable(caps, "caps", "expandable_wrapper", "Conditional Access Policies");
    buildExpandableTable(riskyApps, "riskyApps", "expandable_wrapper", "Risky Applications");
    buildExpandableTable(riskyThirdPartySPs, "riskyThirdPartySPs", "expandable_wrapper", "Risky Third Party Service Principals");

    colorRows();
    applyScopeAttributes();
    truncateSPFList(MAX_DNS_ENTRIES);
    truncateDNSTables(MAX_DNS_ENTRIES);
    mountDarkMode(darkMode, "Individual Report");
});