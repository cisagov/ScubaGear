window.addEventListener('DOMContentLoaded', () => {
    const darkMode = getJsonData('dark-mode-flag') === "true";

    applyScopeAttributes();
    mountDarkMode(darkMode, "Parent Report");
});