window.addEventListener('DOMContentLoaded', () => {
    const MAX_DNS_ENTRIES = 20;

    const darkMode = getJsonData('dark-mode-flag') === true;
    const caps = getJsonData('cap-json');
    const riskyApps = getJsonData('risky-apps-json');
    const riskyThirdPartySPs = getJsonData('risky-third-party-sp-json');
    const severityScoreWeights = getJsonData('severity-score-weights-json');
    const securitySuiteSensitiveUsers = getJsonData('securitysuite-sensitive-users-json');
    const securitySuitePartnerDomains = getJsonData('securitysuite-partner-domains-json');
    const securitySuiteAntiPhishPolicies = getJsonData('securitysuite-anti-phish-policies-json');
    const securitySuiteAntiPhishRules = getJsonData('securitysuite-anti-phish-rules-json');
    const securitySuiteAntiSpamPolicies = getJsonData('securitysuite-anti-spam-policies-json');
    const securitySuiteAntiSpamRules = getJsonData('securitysuite-anti-spam-rules-json');
    const securitySuiteProtectionPolicyRules = getJsonData('securitysuite-protection-policy-rules-json');
    const securitySuiteAcceptedDomains = getJsonData('securitysuite-accepted-domains-json');

    buildExpandableTable(caps, "caps");
    buildExpandableTable(riskyApps, "riskyApps", severityScoreWeights);
    buildExpandableTable(riskyThirdPartySPs, "riskyThirdPartySPs", severityScoreWeights);
    buildSecuritySuiteConfigTables({
        sensitiveUsers: securitySuiteSensitiveUsers,
        partnerDomains: securitySuitePartnerDomains,
        antiPhishPolicies: securitySuiteAntiPhishPolicies,
        antiPhishRules: securitySuiteAntiPhishRules,
        antiSpamPolicies: securitySuiteAntiSpamPolicies,
        antiSpamRules: securitySuiteAntiSpamRules,
        protectionPolicyRules: securitySuiteProtectionPolicyRules,
        acceptedDomains: securitySuiteAcceptedDomains
    });

    colorRows();
    applyScopeAttributes();
    truncateSPFList(MAX_DNS_ENTRIES);
    truncateDNSTables(MAX_DNS_ENTRIES);
    mountDarkMode(darkMode, "Individual Report");
});
