window.addEventListener('DOMContentLoaded', () => {
    const MAX_DNS_ENTRIES = 20;

    const darkMode = getJsonData('dark-mode-flag') === true;
    const caps = getJsonData('cap-json');
    const riskyApps = getJsonData('risky-apps-json');
    const riskyThirdPartySPs = getJsonData('risky-third-party-sp-json');
    const severityScoreWeights = getJsonData('severity-score-weights-json');
    const getSecuritySuiteData = (name) => getJsonData(`securitysuite-${name}-json`);

    buildExpandableTable(caps, "caps");
    buildExpandableTable(riskyApps, "riskyApps", severityScoreWeights);
    buildExpandableTable(riskyThirdPartySPs, "riskyThirdPartySPs", severityScoreWeights);
    buildSecuritySuiteConfigTables({
        sensitiveUsers: getSecuritySuiteData('sensitive-users'),
        partnerDomains: getSecuritySuiteData('partner-domains'),
        antiMalwarePolicies: getSecuritySuiteData('anti-malware-policies'),
        antiMalwareRules: getSecuritySuiteData('anti-malware-rules'),
        antiPhishPolicies: getSecuritySuiteData('anti-phish-policies'),
        antiPhishRules: getSecuritySuiteData('anti-phish-rules'),
        antiSpamPolicies: getSecuritySuiteData('anti-spam-policies'),
        antiSpamRules: getSecuritySuiteData('anti-spam-rules'),
        protectionPolicyRules: getSecuritySuiteData('protection-policy-rules'),
        acceptedDomains: getSecuritySuiteData('accepted-domains')
    });

    colorRows();
    applyScopeAttributes();
    truncateSPFList(MAX_DNS_ENTRIES);
    truncateDNSTables(MAX_DNS_ENTRIES);
    mountDarkMode(darkMode, "Individual Report");
});
