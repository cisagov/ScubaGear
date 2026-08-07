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

const ANTI_PHISH_TABLE_CLASS = "securitysuite-anti-phish-policies-table";

const getProtectedValues = (values) => {
    const normalizedValues = normalizeToArray(values)
        .map(value => String(value ?? "").trim())
        .filter(value => value.length > 0);
    return normalizedValues.length > 0 ? normalizedValues : ["None"];
};

const formatProtectedValues = (values) => {
    return getProtectedValues(values).join("\n");
};

const isEnabled = (value) => value === true || String(value).toLowerCase() === "true";

const getNonEmptyValues = (value) => normalizeToArray(value)
    .map(item => String(item ?? "").trim())
    .filter(item => item.length > 0);

const ruleMatchesPolicy = (rule, policy) => {
    const policyIdentifiers = [policy.Name, policy.Identity, policy.Id]
        .map(value => String(value ?? "").trim().toLowerCase())
        .filter(value => value.length > 0);
    const rulePolicyIdentifiers = [rule.AntiPhishPolicy, rule.Policy, rule.PolicyName]
        .flatMap(getNonEmptyValues)
        .map(value => value.toLowerCase());

    return rulePolicyIdentifiers.some(identifier => policyIdentifiers.includes(identifier));
};

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
    }).filter(Boolean).join("\n");
};

const getPolicyApplicability = (policy, antiPhishRules, protectionPolicyRules, acceptedDomains) => {
    const rules = [...normalizeToArray(antiPhishRules), ...normalizeToArray(protectionPolicyRules)]
        .filter(rule => rule && typeof rule === "object")
        .filter(rule => ruleMatchesPolicy(rule, policy));
    const tenantDomains = normalizeToArray(acceptedDomains)
        .map(domain => domain?.DomainName ?? domain?.Name ?? domain?.Identity ?? domain)
        .flatMap(getNonEmptyValues);

    if (rules.some(rule => ruleAppliesToAllUsers(rule, tenantDomains))) return "All Users";
    if (rules.length > 0) return formatScopeCounts(rules) || "Scoped";
    return policy.IsDefault ? "All Users" : "Not available";
};

/**
 * Converts anti-phish policy settings into rows for the protection-policy table.
 *
 * @param {Array<Object>|null} antiPhishPolicies The exported anti-phish policies.
 * @returns {Array<Object>} Unique policy rows.
 */
const getAntiPhishPolicyRows = (
    antiPhishPolicies,
    antiPhishRules,
    protectionPolicyRules,
    acceptedDomains
) => {
    const seenPolicies = new Set();

    return normalizeToArray(antiPhishPolicies).reduce((rows, policy) => {
        if (!policy || typeof policy !== "object") return rows;

        const policyName = String(policy.Name ?? policy.Identity ?? "Unnamed policy").trim() || "Unnamed policy";
        const policyKey = String(policy.Identity ?? policyName).trim().toLowerCase();
        if (seenPolicies.has(policyKey)) return rows;
        seenPolicies.add(policyKey);

        rows.push({
            "Policy": policyName,
            "Enabled": isEnabled(policy.Enabled),
            "Applicability": getPolicyApplicability(
                policy,
                antiPhishRules,
                protectionPolicyRules,
                acceptedDomains
            ),
            "Users Protected": getProtectedValues(policy.TargetedUsersToProtect),
            "Partner Domains Protected": formatProtectedValues(policy.TargetedDomainsToProtect),
            "Safety Indicators": SAFETY_TIP_FIELDS
                .map(([label, field]) => ({
                    label,
                    enabled: isEnabled(policy[field])
                }))
        });
        return rows;
    }, []);
};

/**
 * Creates a simple report table that matches the static ConvertTo-Html shape
 * expected by applyScopeAttributes.
 *
 * @param {Array<string>} columns The table columns.
 * @param {Array<Object>} rows The table rows.
 * @param {string} tableClass The CSS class to add to the table.
 * @returns {HTMLTableElement} The created table.
 */
const appendAntiPhishPolicyCell = (cell, value, expanded, onExpand) => {
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

const renderAntiPhishPolicyRow = (row, columns, data, expanded) => {
    row.textContent = "";
    const expand = () => renderAntiPhishPolicyRow(row, columns, data, true);

    const actionCell = document.createElement("td");
    actionCell.appendChild(createRowActionButton({
        title: expanded ? "Show less policy information" : "Show more policy information",
        className: "chevron",
        expanded,
        onClick: () => renderAntiPhishPolicyRow(row, columns, data, !expanded),
        contentBuilder: () => createChevronIcon(expanded ? "down" : "right", expanded ? 14 : 10)
    }));
    row.appendChild(actionCell);

    columns.forEach(column => {
        const cell = document.createElement("td");
        appendAntiPhishPolicyCell(cell, data[column], expanded, expand);
        row.appendChild(cell);
    });
};

const createSecuritySuiteTable = (columns, rows, tableClass) => {
    const table = document.createElement("table");
    table.classList.add("alternating", tableClass);
    const hasExpandableRows = tableClass === ANTI_PHISH_TABLE_CLASS;

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
            renderAntiPhishPolicyRow(tr, columns, row, false);
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
 * @param {Array<Object>|null} antiPhishPolicies The exported anti-phish policies.
 * @param {Array<Object>|null} antiPhishRules The exported anti-phish rules.
 * @param {Array<Object>|null} protectionPolicyRules The exported EOP protection rules.
 * @param {Array<Object>|null} acceptedDomains The tenant's accepted domains.
 */
const buildSecuritySuiteConfigTables = (
    sensitiveUsers,
    partnerDomains,
    antiPhishPolicies,
    antiPhishRules,
    protectionPolicyRules,
    acceptedDomains
) => {
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
        "Anti-Phish Protection Policies are exported from the tenant.";
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
        "Anti-Phish Protection Policies",
        ["Policy", "Enabled", "Applicability", "Users Protected", "Partner Domains Protected", "Safety Indicators"],
        getAntiPhishPolicyRows(antiPhishPolicies, antiPhishRules, protectionPolicyRules, acceptedDomains),
        "securitysuite-anti-phish-policies-table",
        "No anti-phish policies were exported."
    );
};
