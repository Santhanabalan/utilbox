export function initNavigation(): void {
  const tabs = Array.from(
    document.querySelectorAll<HTMLButtonElement>(".nav-tab"),
  );

  function show(pageId: string): void {
    for (const tab of tabs) {
      const active = tab.dataset.page === pageId;
      tab.classList.toggle("nav-tab--active", active);
      tab
        .querySelector(".nav-icon")
        ?.classList.toggle("nav-icon--filled", active);
      if (active) tab.setAttribute("aria-current", "page");
      else tab.removeAttribute("aria-current");
      const page = tab.dataset.page
        ? document.getElementById(tab.dataset.page)
        : null;
      if (page) page.hidden = !active;
    }
    window.scrollTo({ top: 0 });
  }

  for (const tab of tabs) {
    tab.addEventListener("click", () => {
      if (tab.dataset.page) show(tab.dataset.page);
    });
  }
  const initial = tabs.find((tab) => tab.classList.contains("nav-tab--active"))
    ?.dataset.page;
  if (initial) show(initial);
}
