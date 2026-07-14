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

/**
 * Creates a simple report table that matches the static ConvertTo-Html shape
 * expected by applyScopeAttributes.
 *
 * @param {Array<string>} columns The table columns.
 * @param {Array<Object>} rows The table rows.
 * @param {string} tableClass The CSS class to add to the table.
 * @returns {HTMLTableElement} The created table.
 */
const createSecuritySuiteTable = (columns, rows, tableClass) => {
    const table = document.createElement("table");
    table.classList.add("alternating", tableClass);

    const tbody = document.createElement("tbody");
    const header = document.createElement("tr");
    columns.forEach(column => {
        const th = document.createElement("th");
        th.textContent = column;
        header.appendChild(th);
    });
    tbody.appendChild(header);

    rows.forEach(row => {
        const tr = document.createElement("tr");
        columns.forEach(column => {
            const td = document.createElement("td");
            td.textContent = row[column] ?? "N/A";
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
 */
const buildSecuritySuiteConfigTables = (sensitiveUsers, partnerDomains) => {
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
};
