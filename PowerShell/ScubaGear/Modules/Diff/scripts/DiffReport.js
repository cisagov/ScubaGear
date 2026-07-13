/*
 * Client-side behavior for the ScubaGear diff report (Invoke-SCuBADiff).
 * Two controls:
 *   1. "Show unchanged rows" toggles the visibility of Unchanged rows, which
 *      are hidden by default (see decision 4 in the ADR). This follows the same
 *      per-report script pattern used by the CreateReport module.
 *   2. "Dark Mode" toggles the light/dark theme by setting data-theme on <html>,
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

    document.addEventListener("DOMContentLoaded", function () {
        // Unchanged-rows toggle. Default: unchanged rows hidden.
        var unchangedToggle = document.getElementById("toggle-unchanged");
        if (unchangedToggle) {
            unchangedToggle.addEventListener("change", function () {
                document.body.classList.toggle("show-unchanged", unchangedToggle.checked);
            });
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
