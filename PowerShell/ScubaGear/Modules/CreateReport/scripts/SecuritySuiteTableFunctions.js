/**
 * Parses a SecuritySuite SensitiveUsers config entry into table data.
 *
 * SensitiveUsers accepts either an email address or "Username;Email".
 *
 * @param {Array|string|null} sensitiveUsers The configured SensitiveUsers values.
 * @returns {Array<Object>} The normalized table rows.
 */
const getSensitiveUserRows = (sensitiveUsers) => {
    return normalizeToArray(sensitiveUsers)
        .map(user => String(user ?? "").trim())
        .filter(user => user.length > 0)
        .map(user => {
            const separatorIndex = user.indexOf(";");
            if (separatorIndex === -1) {
                return {
                    "Username": "N/A",
                    "Email": user
                };
            }

            const username = user.slice(0, separatorIndex).trim();
            const email = user.slice(separatorIndex + 1).trim();
            return {
                "Username": username || "N/A",
                "Email": email || "N/A"
            };
        });
};

/**
 * Parses SecuritySuite PartnerDomains config values into table data.
 *
 * @param {Array|string|null} partnerDomains The configured PartnerDomains values.
 * @returns {Array<Object>} The normalized table rows.
 */
const getPartnerDomainRows = (partnerDomains) => {
    return normalizeToArray(partnerDomains)
        .map(domain => String(domain ?? "").trim())
        .filter(domain => domain.length > 0)
        .map(domain => ({ "Partner Domain": domain }));
};

const SAFETY_TIP_FIELDS = [
    ["First contact", "EnableFirstContactSafetyTips"],
    ["Similar users", "EnableSimilarUsersSafetyTips"],
    ["Similar domains", "EnableSimilarDomainsSafetyTips"],
    ["Unusual characters", "EnableUnusualCharactersSafetyTips"],
    ["Via tag", "EnableViaTag"],
    ["Unauthenticated sender", "EnableUnauthenticatedSender"]
];

const RECIPIENT_SCOPE_FIELDS = [
    "SentTo",
    "SentToMemberOf",
    "RecipientDomainIs",
    "ExceptIfSentTo",
    "ExceptIfSentToMemberOf",
    "ExceptIfRecipientDomainIs"
];

const SPAM_ACTION_FIELDS = [
    ["Spam", "SpamAction"],
    ["High confidence spam", "HighConfidenceSpamAction"],
    ["Phishing", "PhishSpamAction"],
    ["High confidence phishing", "HighConfidencePhishAction"],
    ["Bulk", "BulkSpamAction"]
];

// This column holds 50+ short file-extension strings. A bulleted list puts one per line and
// makes the row extremely tall when expanded; a wrapped, comma-separated line (matching how
// the Defender admin console displays the same file types) reads far better at that volume.
const COMMA_SEPARATED_COLUMNS = new Set(["Blocked File Types"]);

const ANTI_MALWARE_TABLE_CLASS = "securitysuite-anti-malware-policies-table";
const ANTI_PHISH_TABLE_CLASS = "securitysuite-anti-phish-policies-table";
const ANTI_SPAM_TABLE_CLASS = "securitysuite-anti-spam-policies-table";
const EXPANDABLE_TABLE_CLASSES = new Set([
    ANTI_MALWARE_TABLE_CLASS,
    ANTI_PHISH_TABLE_CLASS,
    ANTI_SPAM_TABLE_CLASS
]);

// Read by applyScopeAttributes so it doesn't need to know each policy table by name.
const EXPANDABLE_ROWS_CLASS = "expandable-policy-rows";

// Each policy family is referenced by a different field on its assigning rules.
const ANTI_MALWARE_RULE_FIELDS = ["MalwareFilterPolicy", "Policy", "PolicyName"];
const ANTI_PHISH_RULE_FIELDS = ["AntiPhishPolicy", "Policy", "PolicyName"];
const ANTI_SPAM_RULE_FIELDS = ["HostedContentFilterPolicy", "Policy", "PolicyName"];

// Some EOP list properties come back as objects rather than strings, such as
// { Sender: { Address } } or { DomainName }, which would render as
// "[object Object]".
const getPolicyValueText = (value) => {
    if (value === null || value === undefined) return "";
    if (typeof value !== "object") return String(value).trim();

    const nestedValue = value.Sender ?? value.Address ?? value.Domain ??
        value.DomainName ?? value.Name ?? value.Identity;
    return nestedValue === null || nestedValue === undefined ? "" : getPolicyValueText(nestedValue);
};

const isEnabled = (value) => value === true || String(value).toLowerCase() === "true";

const getNonEmptyValues = (value) => normalizeToArray(value)
    .map(getPolicyValueText)
    .filter(item => item.length > 0);

const getProtectedValues = (values) => {
    const protectedValues = getNonEmptyValues(values);
    return protectedValues.length > 0 ? protectedValues : "None";
};

// Prefers RecommendedPolicyType so the table agrees with SecuritySuiteConfig.rego,
// which keys off the same field. Preset names are a fallback.
const getPresetPolicyType = (policy) => {
    const recommendedType = String(policy?.RecommendedPolicyType ?? "").trim();
    if (recommendedType === "Strict" || recommendedType === "Standard") return recommendedType;

    const policyName = String(policy?.Name ?? policy?.Identity ?? policy?.Id ?? "").trim();
    if (policyName.startsWith("Strict Preset Security Policy")) return "Strict";
    if (policyName.startsWith("Standard Preset Security Policy")) return "Standard";
    return null;
};

// IsDefault is what SecuritySuiteConfig.rego uses to find the default policy.
const isDefaultPolicy = (policy) => policy?.IsDefault === true;

const ruleMatchesPolicy = (rule, policy, ruleFields) => {
    const policyIdentifiers = [policy.Name, policy.Identity, policy.Id]
        .map(value => String(value ?? "").trim().toLowerCase())
        .filter(value => value.length > 0);
    const rulePolicyIdentifiers = ruleFields
        .map(field => rule[field])
        .flatMap(getNonEmptyValues)
        .map(value => value.toLowerCase());

    return rulePolicyIdentifiers.some(identifier => policyIdentifiers.includes(identifier));
};

const isProtectionPolicyRuleEnabled = (rule) =>
    isEnabled(rule?.Enabled) || String(rule?.State ?? "").toLowerCase() === "enabled";

const ruleAppliesToAllUsers = (rule, tenantDomains) => {
    const hasNoRecipientScope = RECIPIENT_SCOPE_FIELDS
        .every(field => getNonEmptyValues(rule[field]).length === 0);
    if (hasNoRecipientScope) return true;

    const hasOtherRecipientScope = RECIPIENT_SCOPE_FIELDS
        .filter(field => field !== "RecipientDomainIs")
        .some(field => getNonEmptyValues(rule[field]).length > 0);
    const recipientDomains = getNonEmptyValues(rule.RecipientDomainIs)
        .map(domain => domain.toLowerCase());
    const normalizedTenantDomains = getNonEmptyValues(tenantDomains)
        .map(domain => domain.toLowerCase());

    return !hasOtherRecipientScope && normalizedTenantDomains.length > 0 &&
        normalizedTenantDomains.every(domain => recipientDomains.includes(domain));
};

const formatScopeCounts = (rules) => {
    const scopeCounts = [
        ["Users included", "user", "SentTo"],
        ["Groups included", "group", "SentToMemberOf"],
        ["Domains included", "domain", "RecipientDomainIs"],
        ["Users excluded", "user", "ExceptIfSentTo"],
        ["Groups excluded", "group", "ExceptIfSentToMemberOf"],
        ["Domains excluded", "domain", "ExceptIfRecipientDomainIs"]
    ];

    return scopeCounts.map(([label, singularNoun, field]) => {
        const values = rules.flatMap(rule => getNonEmptyValues(rule[field]));
        const count = new Set(values.map(value => value.toLowerCase())).size;
        if (count === 0) return null;
        return `${label}: ${count} ${singularNoun}${count === 1 ? "" : "s"}`;
    }).filter(Boolean);
};

const getMatchingRules = (policy, ruleFields, ...ruleSets) => ruleSets
    .flatMap(normalizeToArray)
    .filter(rule => rule && typeof rule === "object")
    .filter(rule => ruleMatchesPolicy(rule, policy, ruleFields));

const hasMatchingEnabledRule = (policy, rules, ruleFields) =>
    getMatchingRules(policy, ruleFields, rules).some(isProtectionPolicyRuleEnabled);

const getPolicyApplicability = (policy, policyRules, protectionPolicyRules, acceptedDomains, ruleFields) => {
    if (getPresetPolicyType(policy) &&
        !hasMatchingEnabledRule(policy, protectionPolicyRules, ruleFields)) {
        return "Not assigned";
    }

    const rules = getMatchingRules(policy, ruleFields, policyRules, protectionPolicyRules);
    const tenantDomains = getNonEmptyValues(acceptedDomains);

    if (rules.some(rule => ruleAppliesToAllUsers(rule, tenantDomains))) return "All Users";
    if (rules.length > 0) {
        const scopeCounts = formatScopeCounts(rules);
        return scopeCounts.length > 0 ? scopeCounts : "Scoped";
    }
    return isDefaultPolicy(policy) ? "All Users" : "Not available";
};

const getPolicyEnabledState = (policy, policyRules, protectionPolicyRules, ruleFields) => {
    // Presets are switched on and off by their protection policy rule.
    if (getPresetPolicyType(policy)) {
        return hasMatchingEnabledRule(policy, protectionPolicyRules, ruleFields);
    }

    if (policy?.Enabled !== undefined && policy?.Enabled !== null) {
        return isEnabled(policy.Enabled);
    }

    // Anti-spam policies carry no Enabled flag, and the default one always applies.
    if (isDefaultPolicy(policy)) return true;
    return hasMatchingEnabledRule(policy, policyRules, ruleFields);
};

const getPolicyPriority = (policy, policyRules, protectionPolicyRules, ruleFields) => {
    if (getPresetPolicyType(policy)) return "--";
    if (isDefaultPolicy(policy)) return "Lowest";

    const priorities = getMatchingRules(policy, ruleFields, policyRules, protectionPolicyRules)
        .map(rule => rule.Priority)
        .filter(priority => priority !== null && priority !== undefined && String(priority).trim() !== "");

    return priorities.length > 0
        ? [...new Set(priorities)].sort((first, second) => Number(first) - Number(second)).join(", ")
        : "N/A";
};

/**
 * Ranks a policy by the order Microsoft applies it: Strict preset, Standard
 * preset, custom policies by priority, then the default policy.
 *
 * @param {Object} policy The exported policy.
 * @param {string|number} priority The rendered Priority column value.
 * @returns {Array<number>} The [tier, priority] sort key.
 */
const getPolicySortKey = (policy, priority) => {
    const presetPolicyType = getPresetPolicyType(policy);
    if (presetPolicyType === "Strict") return [0, 0];
    if (presetPolicyType === "Standard") return [1, 0];
    if (isDefaultPolicy(policy)) return [3, 0];

    const firstPriority = Number(String(priority).split(",")[0].trim());
    return [2, Number.isFinite(firstPriority) ? firstPriority : Number.MAX_SAFE_INTEGER];
};

/**
 * Converts exported protection policies into rows for a policy table.
 *
 * Policy, Enabled, Priority, and Applicability are shared by every policy
 * family; getPolicyColumns supplies the columns specific to one family.
 *
 * @param {Array<Object>|null} policies The exported policies.
 * @param {Array<Object>|null} policyRules The rules that assign those policies.
 * @param {Array<Object>|null} protectionPolicyRules The exported EOP protection rules.
 * @param {Array<Object>|null} acceptedDomains The tenant's accepted domains.
 * @param {Array<string>} ruleFields The rule fields that reference the policy.
 * @param {function} getPolicyColumns Returns the family-specific columns for a policy.
 * @returns {Array<Object>} Unique policy rows, in the order the policies apply.
 */
const getProtectionPolicyRows = (
    policies,
    policyRules,
    protectionPolicyRules,
    acceptedDomains,
    ruleFields,
    getPolicyColumns
) => {
    const seenPolicies = new Set();

    const entries = normalizeToArray(policies).reduce((entries, policy) => {
        if (!policy || typeof policy !== "object") return entries;

        const policyName = String(policy.Name ?? policy.Identity ?? "Unnamed policy").trim() || "Unnamed policy";
        const policyKey = String(policy.Identity ?? policyName).trim().toLowerCase();
        if (seenPolicies.has(policyKey)) return entries;
        seenPolicies.add(policyKey);

        const priority = getPolicyPriority(policy, policyRules, protectionPolicyRules, ruleFields);
        entries.push({
            sortKey: getPolicySortKey(policy, priority),
            row: {
                "Policy": policyName,
                "Enabled": getPolicyEnabledState(policy, policyRules, protectionPolicyRules, ruleFields),
                "Priority": priority,
                "Applicability": getPolicyApplicability(
                    policy,
                    policyRules,
                    protectionPolicyRules,
                    acceptedDomains,
                    ruleFields
                ),
                ...getPolicyColumns(policy)
            }
        });
        return entries;
    }, []);

    return entries
        .sort((first, second) =>
            first.sortKey[0] - second.sortKey[0] ||
            first.sortKey[1] - second.sortKey[1] ||
            first.row.Policy.localeCompare(second.row.Policy))
        .map(entry => entry.row);
};

const getEnabledText = (value) => isEnabled(value) ? "Enabled" : "Disabled";

/**
 * Converts anti-malware policy settings into rows for the protection-policy
 * table.
 *
 * Shows the common attachments filter and its file types, which
 * MS.SECURITYSUITE.1.1v1 checks for .exe, .cmd, and .vbe, and zero-hour auto
 * purge, which MS.SECURITYSUITE.1.2v1 requires.
 *
 * @param {Array<Object>|null} antiMalwarePolicies The exported malware filter policies.
 * @param {Array<Object>|null} antiMalwareRules The exported malware filter rules.
 * @param {Array<Object>|null} protectionPolicyRules The exported EOP protection rules.
 * @param {Array<Object>|null} acceptedDomains The tenant's accepted domains.
 * @returns {Array<Object>} Unique policy rows.
 */
const getAntiMalwarePolicyRows = (
    antiMalwarePolicies,
    antiMalwareRules,
    protectionPolicyRules,
    acceptedDomains
) => getProtectionPolicyRows(
    antiMalwarePolicies,
    antiMalwareRules,
    protectionPolicyRules,
    acceptedDomains,
    ANTI_MALWARE_RULE_FIELDS,
    policy => ({
        "Common Attachments Filter": getEnabledText(policy.EnableFileFilter),
        "Blocked File Types": getProtectedValues(policy.FileTypes),
        "Zero-hour Auto Purge": getEnabledText(policy.ZapEnabled)
    })
);

/**
 * Converts anti-phish policy settings into rows for the protection-policy table.
 *
 * @param {Array<Object>|null} antiPhishPolicies The exported anti-phish policies.
 * @param {Array<Object>|null} antiPhishRules The exported anti-phish rules.
 * @param {Array<Object>|null} protectionPolicyRules The exported EOP protection rules.
 * @param {Array<Object>|null} acceptedDomains The tenant's accepted domains.
 * @returns {Array<Object>} Unique policy rows.
 */
const getAntiPhishPolicyRows = (
    antiPhishPolicies,
    antiPhishRules,
    protectionPolicyRules,
    acceptedDomains
) => getProtectionPolicyRows(
    antiPhishPolicies,
    antiPhishRules,
    protectionPolicyRules,
    acceptedDomains,
    ANTI_PHISH_RULE_FIELDS,
    policy => ({
        "Impersonation Protection": getProtectedValues(policy.TargetedUsersToProtect),
        "Partner Domains Protected": getProtectedValues(policy.TargetedDomainsToProtect),
        "Safety Indicators": SAFETY_TIP_FIELDS
            .map(([label, field]) => ({
                label,
                enabled: isEnabled(policy[field])
            }))
    })
);

/**
 * Converts inbound anti-spam policy settings into rows for the
 * protection-policy table.
 *
 * Shows the four spam actions MS.SECURITYSUITE.6.1v1 checks (bulk is listed
 * for context but is not part of that check), and the allowed sender domains
 * MS.SECURITYSUITE.6.2v1 checks, next to the senders the baseline permits.
 *
 * @param {Array<Object>|null} antiSpamPolicies The exported hosted content filter policies.
 * @param {Array<Object>|null} antiSpamRules The exported hosted content filter rules.
 * @param {Array<Object>|null} protectionPolicyRules The exported EOP protection rules.
 * @param {Array<Object>|null} acceptedDomains The tenant's accepted domains.
 * @returns {Array<Object>} Unique policy rows.
 */
const getAntiSpamPolicyRows = (
    antiSpamPolicies,
    antiSpamRules,
    protectionPolicyRules,
    acceptedDomains
) => getProtectionPolicyRows(
    antiSpamPolicies,
    antiSpamRules,
    protectionPolicyRules,
    acceptedDomains,
    ANTI_SPAM_RULE_FIELDS,
    policy => ({
        "Spam Actions": SPAM_ACTION_FIELDS
            .map(([label, field]) => `${label}: ${String(policy[field] ?? "N/A").trim() || "N/A"}`),
        "Allowed Senders": getProtectedValues(policy.AllowedSenders),
        "Allowed Sender Domains": getProtectedValues(policy.AllowedSenderDomains)
    })
);

/**
 * Creates a simple report table that matches the static ConvertTo-Html shape
 * expected by applyScopeAttributes.
 *
 * @param {Array<string>} columns The table columns.
 * @param {Array<Object>} rows The table rows.
 * @param {string} tableClass The CSS class to add to the table.
 * @returns {HTMLTableElement} The created table.
 */
const appendPolicyCell = (cell, value, expanded, onExpand, column) => {
    if (Array.isArray(value) && COMMA_SEPARATED_COLUMNS.has(column)) {
        const COLLAPSED_PREVIEW_COUNT = 5;
        const items = expanded ? value : value.slice(0, COLLAPSED_PREVIEW_COUNT);
        cell.appendChild(document.createTextNode(items.join(", ")));
        if (!expanded && value.length > COLLAPSED_PREVIEW_COUNT) {
            cell.appendChild(document.createTextNode(", "));
            cell.appendChild(createRowActionButton({
                title: "Show more policy information",
                className: "truncated-dots",
                expanded: false,
                onClick: onExpand,
                contentBuilder: () => document.createTextNode("...")
            }));
        }
        return;
    }

    if (Array.isArray(value)) {
        const list = document.createElement("ul");
        const items = expanded ? value : value.slice(0, 1);
        items.forEach(itemValue => {
            const item = document.createElement("li");
            item.textContent = typeof itemValue === "object" && itemValue !== null
                ? `${itemValue.label}: ${itemValue.enabled ? "Enabled" : "Disabled"}`
                : itemValue;
            list.appendChild(item);
        });
        cell.appendChild(list);
        if (!expanded && value.length > 1) {
            cell.appendChild(createRowActionButton({
                title: "Show more policy information",
                className: "truncated-dots",
                expanded: false,
                onClick: onExpand,
                contentBuilder: () => document.createTextNode("...")
            }));
        }
        return;
    }

    const lines = String(value ?? "N/A").split("\n");
    cell.textContent = expanded ? lines.join("\n") : lines[0];
    cell.style.whiteSpace = "pre-line";
    if (!expanded && lines.length > 1) {
        cell.appendChild(createRowActionButton({
            title: "Show more policy information",
            className: "truncated-dots",
            expanded: false,
            onClick: onExpand,
            contentBuilder: () => document.createTextNode("...")
        }));
    }
};

const renderPolicyRow = (row, columns, data, expanded) => {
    row.textContent = "";
    const expand = () => renderPolicyRow(row, columns, data, true);

    const actionCell = document.createElement("td");
    actionCell.appendChild(createRowActionButton({
        title: expanded ? "Show less policy information" : "Show more policy information",
        className: "chevron",
        expanded,
        onClick: () => renderPolicyRow(row, columns, data, !expanded),
        contentBuilder: () => createChevronIcon(expanded ? "down" : "right", expanded ? 14 : 10)
    }));
    row.appendChild(actionCell);

    columns.forEach((column, index) => {
        const cell = document.createElement("td");
        // Re-rendering discards the scope applyScopeAttributes set on page load.
        if (index === 0) cell.setAttribute("scope", "row");
        appendPolicyCell(cell, data[column], expanded, expand, column);
        row.appendChild(cell);
    });
};

const createSecuritySuiteTable = (columns, rows, tableClass) => {
    const table = document.createElement("table");
    table.classList.add("alternating", tableClass);
    const hasExpandableRows = EXPANDABLE_TABLE_CLASSES.has(tableClass);
    if (hasExpandableRows) table.classList.add(EXPANDABLE_ROWS_CLASS);

    const tbody = document.createElement("tbody");
    const header = document.createElement("tr");
    if (hasExpandableRows) {
        const th = document.createElement("th");
        th.setAttribute("aria-label", "Expand policy details");
        header.appendChild(th);
    }
    columns.forEach(column => {
        const th = document.createElement("th");
        th.textContent = column;
        header.appendChild(th);
    });
    tbody.appendChild(header);

    rows.forEach(row => {
        const tr = document.createElement("tr");
        if (hasExpandableRows) {
            renderPolicyRow(tr, columns, row, false);
            tbody.appendChild(tr);
            return;
        }
        columns.forEach(column => {
            const td = document.createElement("td");
            const value = row[column] ?? "N/A";
            if (column === "Safety Indicators" && Array.isArray(value)) {
                const list = document.createElement("ul");
                value.forEach(indicator => {
                    const item = document.createElement("li");
                    item.textContent = `${indicator.label}: ${indicator.enabled ? "Enabled" : "Disabled"}`;
                    list.appendChild(item);
                });
                td.appendChild(list);
            } else {
                td.textContent = value;
                td.style.whiteSpace = "pre-line";
            }
            tr.appendChild(td);
        });
        tbody.appendChild(tr);
    });

    table.appendChild(tbody);
    return table;
};

/**
 * Appends a titled table section, or an empty-state message when no rows exist.
 *
 * @param {HTMLElement} parent The parent element to append into.
 * @param {string} title The section title.
 * @param {Array<string>} columns The table columns.
 * @param {Array<Object>} rows The table rows.
 * @param {string} tableClass The CSS class to add to the table.
 * @param {string} emptyMessage The message shown when no rows exist.
 */
const appendSecuritySuiteTableSection = (parent, title, columns, rows, tableClass, emptyMessage) => {
    const h2 = document.createElement("h2");
    h2.textContent = title;
    h2.id = tableClass;
    parent.appendChild(h2);

    if (rows.length === 0) {
        const noDataWarning = document.createElement("p");
        noDataWarning.textContent = emptyMessage;
        parent.appendChild(noDataWarning);
        return;
    }

    parent.appendChild(createSecuritySuiteTable(columns, rows, tableClass));
};

/**
 * Builds the SecuritySuite config tables at the bottom of the report.
 *
 * @param {Array|string|null} sensitiveUsers The configured SensitiveUsers values.
 * @param {Array|string|null} partnerDomains The configured PartnerDomains values.
 * @param {Array<Object>|null} antiMalwarePolicies The exported malware filter policies.
 * @param {Array<Object>|null} antiMalwareRules The exported malware filter rules.
 * @param {Array<Object>|null} antiPhishPolicies The exported anti-phish policies.
 * @param {Array<Object>|null} antiPhishRules The exported anti-phish rules.
 * @param {Array<Object>|null} antiSpamPolicies The exported hosted content filter policies.
 * @param {Array<Object>|null} antiSpamRules The exported hosted content filter rules.
 * @param {Array<Object>|null} protectionPolicyRules The exported EOP protection rules.
 * @param {Array<Object>|null} acceptedDomains The tenant's accepted domains.
 */
const buildSecuritySuiteConfigTables = ({
    sensitiveUsers,
    partnerDomains,
    antiMalwarePolicies,
    antiMalwareRules,
    antiPhishPolicies,
    antiPhishRules,
    antiSpamPolicies,
    antiSpamRules,
    protectionPolicyRules,
    acceptedDomains
}) => {
    if (sensitiveUsers === undefined || sensitiveUsers === null ||
        partnerDomains === undefined || partnerDomains === null) {
        return;
    }

    const section = document.createElement("section");
    section.className = "securitysuite-config-tables";

    const main = document.querySelector("main");
    if (!main) return;

    main.appendChild(section);
    section.appendChild(document.createElement("hr"));

    const configNote = document.createElement("p");
    configNote.textContent =
        "Sensitive Users and Partner Domains are configured in the SecuritySuite config file. " +
        "Protection Policies are exported from the tenant, and are shown in priority order with " +
        "the highest priority policies listed first. ";
    section.appendChild(configNote);

    appendSecuritySuiteTableSection(
        section,
        "Sensitive Users",
        ["Username", "Email"],
        getSensitiveUserRows(sensitiveUsers),
        "securitysuite-sensitive-users-table",
        "No sensitive users defined in the config file."
    );

    appendSecuritySuiteTableSection(
        section,
        "Partner Domains",
        ["Partner Domain"],
        getPartnerDomainRows(partnerDomains),
        "securitysuite-partner-domains-table",
        "No partner domains defined in the config file."
    );

    appendSecuritySuiteTableSection(
        section,
        "Anti-Malware Protection Policies",
        ["Policy", "Enabled", "Priority", "Applicability", "Common Attachments Filter", "Blocked File Types", "Zero-hour Auto Purge"],
        getAntiMalwarePolicyRows(antiMalwarePolicies, antiMalwareRules, protectionPolicyRules, acceptedDomains),
        ANTI_MALWARE_TABLE_CLASS,
        "No anti-malware policies were exported."
    );

    appendSecuritySuiteTableSection(
        section,
        "Anti-Phish Protection Policies",
        ["Policy", "Enabled", "Priority", "Applicability", "Impersonation Protection", "Partner Domains Protected", "Safety Indicators"],
        getAntiPhishPolicyRows(antiPhishPolicies, antiPhishRules, protectionPolicyRules, acceptedDomains),
        ANTI_PHISH_TABLE_CLASS,
        "No anti-phish policies were exported."
    );

    appendSecuritySuiteTableSection(
        section,
        "Anti-Spam Protection Policies",
        ["Policy", "Enabled", "Priority", "Applicability", "Spam Actions", "Allowed Senders", "Allowed Sender Domains"],
        getAntiSpamPolicyRows(antiSpamPolicies, antiSpamRules, protectionPolicyRules, acceptedDomains),
        ANTI_SPAM_TABLE_CLASS,
        "No anti-spam policies were exported."
    );
};
