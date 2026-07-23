/*
 * Client-side behavior for the ScubaGear diff report (Invoke-SCuBADiff).
 * Three controls:
 *   1. "Show unchanged rows" toggles the visibility of Unchanged rows, which
 *      are hidden by default (see decision 4 in the ADR). This follows the same
 *      per-report script pattern used by the CreateReport module.
 *   2. Per-bucket filter checkboxes in the summary-table column headers. Each one
 *      (every bucket except Unchanged, which the toggle above owns) hides the
 *      matching rows in the product tables, dims its own summary column, and
 *      recomputes each product's Total. Unchanged is always counted in the Total.
 *   3. "Dark Mode" toggles the light/dark theme by setting data-theme on <html>,
 *      matching the mechanism in CreateReport/scripts/Utils.js.
 */
(function () {
    "use strict";

    function readFlag(id) {
        var el = document.getElementById(id);
        return el ? (el.textContent || "").trim() === "true" : false;
    }

    function setDarkMode(enabled) {
        document.documentElement.dataset.theme = enabled ? "dark" : "light";
    }

    // The buckets whose filter checkbox is currently unchecked (hidden).
    var hiddenBuckets = Object.create(null);
    // The "Uncheck all filters" / "Check all filters" button (assigned on load).
    var allFiltersBtn = null;

    function anyChecked(toggles) {
        for (var i = 0; i < toggles.length; i++) {
            if (toggles[i].checked) { return true; }
        }
        return false;
    }

    function updateAllFiltersButton(toggles) {
        if (!allFiltersBtn) { return; }
        // When at least one bucket is shown, the button clears them; once every
        // bucket is hidden it flips to restore them, so users are never stranded.
        var someChecked = anyChecked(toggles);
        allFiltersBtn.textContent = someChecked ? "Uncheck all filters" : "Check all filters";
        allFiltersBtn.setAttribute("aria-pressed", someChecked ? "false" : "true");
    }

    function applyRowFilter() {
        // Product transition rows carry data-bucket; summary rows do not. Unchanged
        // rows are governed by the "Show unchanged rows" toggle, so skip them here.
        var rows = document.querySelectorAll("tr[data-bucket]");
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i];
            if (row.classList.contains("diff-unchanged-row")) { continue; }
            var bucket = row.getAttribute("data-bucket");
            row.style.display = hiddenBuckets[bucket] ? "none" : "";
        }
    }

    function applyColumnDim() {
        var cells = document.querySelectorAll(".summary-table [data-bucket]");
        for (var i = 0; i < cells.length; i++) {
            var bucket = cells[i].getAttribute("data-bucket");
            if (hiddenBuckets[bucket]) { cells[i].classList.add("col-off"); }
            else { cells[i].classList.remove("col-off"); }
        }
    }

    function recomputeTotals() {
        var rows = document.querySelectorAll(".summary-table tr");
        for (var i = 0; i < rows.length; i++) {
            var totalCell = rows[i].querySelector(".summary-total");
            if (!totalCell) { continue; }
            var counts = rows[i].querySelectorAll("td[data-bucket]");
            var sum = 0;
            for (var j = 0; j < counts.length; j++) {
                var bucket = counts[j].getAttribute("data-bucket");
                // Unchanged is always counted; other buckets only when active.
                if (bucket === "Unchanged" || !hiddenBuckets[bucket]) {
                    sum += parseInt(counts[j].getAttribute("data-count"), 10) || 0;
                }
            }
            totalCell.textContent = String(sum);
        }
    }

    function refreshBucketFilters(toggles) {
        hiddenBuckets = Object.create(null);
        for (var i = 0; i < toggles.length; i++) {
            if (!toggles[i].checked) {
                hiddenBuckets[toggles[i].getAttribute("data-bucket")] = true;
            }
        }
        applyRowFilter();
        applyColumnDim();
        recomputeTotals();
        updateAllFiltersButton(toggles);
    }

    document.addEventListener("DOMContentLoaded", function () {
        // Unchanged-rows toggle. Default: unchanged rows hidden.
        var unchangedToggle = document.getElementById("toggle-unchanged");
        if (unchangedToggle) {
            unchangedToggle.addEventListener("change", function () {
                document.body.classList.toggle("show-unchanged", unchangedToggle.checked);
            });
        }

        // Per-bucket filter checkboxes in the summary header.
        var bucketToggles = document.querySelectorAll(".bucket-toggle");
        if (bucketToggles.length) {
            for (var i = 0; i < bucketToggles.length; i++) {
                bucketToggles[i].addEventListener("change", function () {
                    refreshBucketFilters(bucketToggles);
                });
            }

            // "Uncheck all filters" button: clears every bucket filter (and thus
            // hides every classified row); once all are off it restores them.
            allFiltersBtn = document.getElementById("toggle-all-filters");
            if (allFiltersBtn) {
                allFiltersBtn.addEventListener("click", function () {
                    var target = !anyChecked(bucketToggles);
                    for (var j = 0; j < bucketToggles.length; j++) {
                        bucketToggles[j].checked = target;
                    }
                    refreshBucketFilters(bucketToggles);
                });
            }

            // Establish the initial state (all checked -> nothing hidden).
            refreshBucketFilters(bucketToggles);
        }

        // Dark mode toggle. Default comes from the PowerShell -DarkMode switch.
        var darkDefault = readFlag("dark-mode-flag");
        var darkToggle = document.getElementById("toggle-dark");
        setDarkMode(darkDefault);
        if (darkToggle) {
            darkToggle.checked = darkDefault;
            darkToggle.addEventListener("change", function () {
                setDarkMode(darkToggle.checked);
            });
        }
    });
})();
