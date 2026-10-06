export function initNavToggle(doc: Document): void {
  const toggle = doc.querySelector<HTMLButtonElement>("[data-nav-toggle]");
  const menu = doc.querySelector<HTMLElement>("[data-nav-menu]");
  if (!toggle || !menu) return;

  toggle.addEventListener("click", () => {
    const hidden = menu.classList.toggle("hidden");
    toggle.setAttribute("aria-expanded", String(!hidden));
  });
}
