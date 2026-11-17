// Make <picture> elements with `prefers-color-scheme` sources (used in the
// README so GitHub shows a dark/light variant) follow the pkgdown site theme
// (`data-bs-theme` on <html>) instead of the operating-system preference.
// Without this, a dark OS on a light-themed site shows the dark-mode image
// (light text) on a white background.
(function () {
  var root = document.documentElement;
  var osDark = window.matchMedia("(prefers-color-scheme: dark)");

  function siteTheme() {
    var theme = root.getAttribute("data-bs-theme");
    if (theme === "auto") return osDark.matches ? "dark" : "light";
    // Unset means no light-switch: Bootstrap renders the site light.
    return theme === "dark" ? "dark" : "light";
  }

  function sync() {
    var theme = siteTheme();
    var sources = document.querySelectorAll(
      'picture source[media*="prefers-color-scheme"], picture source[data-scheme]'
    );
    sources.forEach(function (src) {
      if (!src.dataset.scheme) {
        src.dataset.scheme = /dark/.test(src.getAttribute("media")) ? "dark" : "light";
      }
      src.setAttribute("media", src.dataset.scheme === theme ? "all" : "not all");
    });
  }

  document.addEventListener("DOMContentLoaded", sync);
  new MutationObserver(sync).observe(root, {
    attributes: true,
    attributeFilter: ["data-bs-theme"]
  });
  osDark.addEventListener("change", sync);
})();
