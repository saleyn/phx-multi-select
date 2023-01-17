// Color Theme Changer
// ===================
// Sets html's attribute 'data-theme' and class="dark"|"light"
// Additionally adds the onclick event to the "color-scheme-switch" element, and
// toggles "hidden" class on the elements with ID:
// "color-scheme-dark-icon" and "color-scheme-dark-icon".
// The persistent storage of the color theme is done in localStorage.scheme.

"use strict";

// LiveView support
const ThemeChangerHook = {
  deadViewCompatible: true,

  mounted() {
    this.el.addEventListener("click", () => this.toggleTheme());
    this.init(localStorage.scheme);
  },
  updated() { this.init(localStorage.scheme) },

  init(scheme) { this.toggleTheme(scheme) },

  toggleTheme(scheme) {
    if (!scheme)
      scheme = document.documentElement.classList.contains('dark') ? 'light' : 'dark'

    let main_el = document.documentElement;
    let icon_dk = document.querySelectorAll(".color-scheme-dark-icon");
    let icon_lt = document.querySelectorAll(".color-scheme-light-icon");
    if (scheme === "light") {
      main_el.classList.remove('dark')
      icon_dk.forEach((i) => i.classList.add("hidden"));
      icon_lt.forEach((i) => i.classList.remove("hidden"));
    } else {
      main_el.classList.add('dark')
      icon_dk.forEach((i) => i.classList.remove("hidden"));
      icon_lt.forEach((i) => i.classList.add("hidden"));
    }
    localStorage.scheme = scheme
  }
};

// Initialize

(function () {
  let found  = 'scheme' in localStorage
  let scheme = (localStorage.scheme === 'dark' ||
    (!found && window.matchMedia('(prefers-color-scheme: dark)').matches))
    ? "dark" : "light";

  ThemeChangerHook.toggleTheme(scheme)
})()

export default ThemeChangerHook;