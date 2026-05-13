window.addEventListener('DOMContentLoaded', () => {
    const MAX_DNS_ENTRIES = 20;

    const darkMode = getJsonData('dark-mode-flag') === "true";
    const caps = getJsonData('cap-json');
    const riskyApps = getJsonData('risky-apps-json');
    const riskyThirdPartySPs = getJsonData('risky-third-party-sp-json');
    const severityScoreWeights = getJsonData('severity-score-weights-json');

    buildExpandableTable(caps, "caps");
    buildExpandableTable(riskyApps, "riskyApps", severityScoreWeights);
    buildExpandableTable(riskyThirdPartySPs, "riskyThirdPartySPs", severityScoreWeights);

    colorRows();
    applyScopeAttributes();
    truncateSPFList(MAX_DNS_ENTRIES);
    truncateDNSTables(MAX_DNS_ENTRIES);
    mountDarkMode(darkMode, "Individual Report");
});