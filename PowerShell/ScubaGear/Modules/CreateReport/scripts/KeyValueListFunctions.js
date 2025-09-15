const getCredentialState = (cred) => {
    if (!cred || typeof cred !== "object") return "Unknown";
    const start = parseDotNetDate(cred.StartDateTime);
    const end = parseDotNetDate(cred.EndDateTime);
    const now = new Date();

    if (start && end) {
        if (now < start) return "Inactive";
        if (now > end)   return "Expired";
        return "Active";
    }

    if (end && now > end) return "Expired";
    return "Active";
};

const filterBySearch = (arr, term) => {
    if (!term) return arr;
    const lower = term.toLowerCase();
    return arr.filter(o => {
        if (!o || typeof o !== "object") return false;
        return Object.values(o).some(v => String(v).toLowerCase().includes(lower));
    });
};

const renderObject = (obj) => {
    const li = document.createElement("li");
    li.classList.add("kv-item");
    Object.entries(obj).forEach(([key, value], idx, arr) => {
        const strong = document.createElement("strong");
        strong.textContent = `${key}:`;
        li.appendChild(strong);
        let content = value;
        if (typeof value === "string" && (key === "StartDateTime" || key === "EndDateTime")) {
            const date = parseDotNetDate(value);
            content = date ? date.toLocaleString() : value;
        }
        li.appendChild(document.createTextNode(` ${String(content)}`));
        if (idx < arr.length - 1) li.appendChild(document.createElement("br"));
    });
    return li;
};

const groupPermissions = (data, groupKey) => {
    if (groupKey === "none") return { All: data };
    const map = {};
    data.forEach(obj => {
        let keyVal = obj?.[groupKey];
        if (groupKey === "IsAdminConsented" || groupKey === "IsRisky") {
            keyVal = (keyVal === true) ? "True" : (keyVal === false) ? "False" : "Unknown";
        }
        if (keyVal === "" || keyVal === undefined || keyVal === null) keyVal = "Unknown";
        (map[keyVal] ||= []).push(obj);
    });
    return map;
};

const renderAdvancedKeyValueList = (items, dataType) => {
    const wrapper = document.createElement("div");
    wrapper.classList.add("kv-advanced");

    const controls = document.createElement("div");
    controls.classList.add("kv-controls");
    wrapper.appendChild(controls);

    const searchInput = document.createElement("input");
    searchInput.type = "search";
    searchInput.placeholder = "Search...";
    controls.appendChild(searchInput);

    // The option to group by is only present for permissions. Credentials only has "active"/"expired" fields.
    let groupSelect = null;
    if (dataType === "Permissions") {
        groupSelect = document.createElement("select");
        const groupOptions = [
            { value: "none", label: "No grouping" },
            { value: "RoleType", label: "Role type" },
            { value: "IsAdminConsented", label: "Admin consent" },
            { value: "IsRisky", label: "Risky" }
        ];

        groupOptions.forEach(o => {
            const option = document.createElement("option");
            option.value = o.value;
            option.textContent = o.label;
            groupSelect.appendChild(option);
        });
        controls.appendChild(groupSelect);
    }

    const contentHost = document.createElement("div");
    contentHost.classList.add("kv-results");
    wrapper.appendChild(contentHost);

    const state = {
        search: "",
        groupBy: "none"
    };

    const renderGroupSection = (title, itemsArr) => {
        const section = document.createElement("section");
        section.classList.add("kv-group");

        const h4 = document.createElement("h4");
        h4.textContent = `${title} (${itemsArr.length})`;
        section.appendChild(h4);

        const ul = document.createElement("ul");
        itemsArr.forEach(o => ul.appendChild(renderObject(o)));
        section.appendChild(ul);
        contentHost.appendChild(section);
    };

    const render = () => {
        contentHost.textContent = "";
        const filtered = filterBySearch(items, state.search);

        if (dataType === "Credentials") {
            const active  = filtered.filter(c => getCredentialState(c) === "Active");
            const expired = filtered.filter(c => getCredentialState(c) === "Expired");
            renderGroupSection("Active", active);
            renderGroupSection("Expired", expired);
            return;
        }

        if (dataType === "Permissions") {
            const groups = groupPermissions(filtered, state.groupBy);
            Object.entries(groups).forEach(([name, arr]) => renderGroupSection(name, arr));
            return;
        }

        renderGroupSection("All", filtered);
    };

    searchInput.addEventListener("input", e => {
        state.search = e.target.value;
        render();
    });

    if (groupSelect) {
        groupSelect.addEventListener("change", e => {
            state.groupBy = e.target.value;
            render();
        });
    }

    render();
    return wrapper;
};