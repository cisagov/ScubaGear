window.addEventListener('DOMContentLoaded', () => {
    const MAX_DNS_ENTRIES = 20;

    const darkMode = tryGetJsonData('dark-mode-flag') === "true";
    const caps = tryGetJsonData('cap-json');
    const riskyApps = tryGetJsonData('risky-apps-json');
    const riskyThirdPartySPs = tryGetJsonData('risky-third-party-sp-json');
    const severityScoreWeights = tryGetJsonData('severity-score-weights-json');

    buildExpandableTable(caps, "caps");
    buildExpandableTable(riskyApps, "riskyApps", severityScoreWeights);
    buildExpandableTable(riskyThirdPartySPs, "riskyThirdPartySPs", severityScoreWeights);

    colorRows();
    applyScopeAttributes();
    truncateSPFList(MAX_DNS_ENTRIES);
    truncateDNSTables(MAX_DNS_ENTRIES);
    mountDarkMode(darkMode, "Individual Report");
});