// Start the player in NetEase's own dark theme once, to match Omarchy's dark
// desktop. After that the stored choice (localStorage currentTheme) is left alone.
try {
  if (!localStorage.getItem("omarchyDarkApplied")) {
    localStorage.setItem("currentTheme", "dark");
    localStorage.setItem("omarchyDarkApplied", "1");
  }
} catch (e) {}
