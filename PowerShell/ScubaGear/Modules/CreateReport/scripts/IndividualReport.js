window.addEventListener('DOMContentLoaded', () => {
    const MAX_DNS_ENTRIES = 20;

    const darkMode = getJsonData('dark-mode-flag') === "true";
    const caps = getJsonData('cap-json');
    const riskyApps = getJsonData('risky-apps-json');
    const riskyThirdPartySPs = getJsonData('risky-third-party-sp-json');

    buildExpandableTable(caps, "caps");
    buildExpandableTable(riskyApps, "riskyApps");
    buildExpandableTable(riskyThirdPartySPs, "riskyThirdPartySPs");

    colorRows();
    applyScopeAttributes();
    truncateSPFList(MAX_DNS_ENTRIES);
    truncateDNSTables(MAX_DNS_ENTRIES);
    mountDarkMode(darkMode, "Individual Report");
});