/**
 * Truncates the specified DNS table to the specified number of rows.
 * @param {number} logIndex The index of the table in the list of DNS tables.
 * @param {number} maxRows The number of rows to truncate the table to.
 */
const truncateDNSTable = (logIndex, maxRows) => {
    try {
        const ROW_INCREMENT = 10;
        let dnsLog = document.querySelectorAll('.dns-logs')[logIndex];
        let rows = dnsLog.querySelector('table').querySelectorAll('tr');
        for (let i = 0; i < rows.length; i++) {
            if (i > maxRows) {
                rows[i].style.display = 'none';
            }
            else {
                rows[i].style.display = 'table-row';
            }
        }
        dnsLog.querySelectorAll('.show-more').forEach(e => e.remove());
        if (rows.length > maxRows) {
            let showMoreMessage = document.createElement('p');
            showMoreMessage.classList.add('show-more');
            showMoreMessage.innerHTML = `${rows.length-maxRows} rows hidden. `;
            showMore = document.createElement('button');
            showMore.innerHTML = "Show more.";
            showMore.setAttribute('type', 'button');
            showMore.classList.add('show-more');
            showMore.onclick = () => {truncateDNSTable(logIndex, maxRows+ROW_INCREMENT);};
            showMoreMessage.appendChild(showMore);
            dnsLog.appendChild(showMoreMessage);
        }
    }
    catch (error) {
        console.error(`Error in truncateDNSTable`, error);
    }
}

/**
 * Truncates any DNS table that has more than maxRows rows.
 * @param {number} maxRows The number of rows to truncate the tables to.
 */
const truncateDNSTables = (maxRows) => {
    try {
        let dnsLogs = document.querySelectorAll('.dns-logs');
        for (let i = 0; i < dnsLogs.length; i++) {
            truncateDNSTable(i, maxRows);
        }
    }
    catch (error) {
        console.error(`Error in truncateDNSTables`, error);
    }
}

/**
 * Truncates list of domains without SPF to maxDomains.
* @param {number} maxDomains The number of domains to truncate the list to.
 */
const truncateSPFList = (maxDomains) => {
    try {
        const ROW_INCREMENT = 10;
        let spfList = document.querySelector('#spf-domains');
        if (spfList === null) {
            // No SPF list present so this report isn't for EXO
            return;
        }
        let domains = spfList.querySelectorAll('li');
        for (let i = 0; i < domains.length; i++) {
            if (i > maxDomains) {
                domains[i].style.display = 'none';
            }
            else {
                domains[i].style.display = 'list-item';
            }
        }
        spfList.querySelectorAll('.show-more').forEach(e => e.remove());
        if (domains.length > maxDomains) {
            let showMoreMessage = document.createElement('p');
            showMoreMessage.classList.add('show-more');
            showMoreMessage.innerHTML = `${domains.length-maxDomains} domains hidden. `;
            showMore = document.createElement('button');
            showMore.innerHTML = "Show more.";
            showMore.setAttribute('type', 'button');
            showMore.classList.add('show-more');
            showMore.onclick = () => {truncateSPFList(maxDomains+ROW_INCREMENT);};
            showMoreMessage.appendChild(showMore);
            spfList.appendChild(showMoreMessage);
        }
    }
    catch (error) {
        console.error(`Error in truncateSPFList`, error);
    }
}