import { describe, it, expect, beforeEach } from "vitest";
import { initNavToggle } from "./nav";

describe("initNavToggle", () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <button data-nav-toggle aria-expanded="false">menu</button>
      <nav data-nav-menu class="hidden"></nav>
    `;
  });

  it("shows the menu and sets aria-expanded=true on first click", () => {
    initNavToggle(document);
    const toggle = document.querySelector<HTMLButtonElement>("[data-nav-toggle]")!;
    const menu = document.querySelector<HTMLElement>("[data-nav-menu]")!;

    toggle.click();

    expect(menu.classList.contains("hidden")).toBe(false);
    expect(toggle.getAttribute("aria-expanded")).toBe("true");
  });

  it("hides the menu again on second click", () => {
    initNavToggle(document);
    const toggle = document.querySelector<HTMLButtonElement>("[data-nav-toggle]")!;
    const menu = document.querySelector<HTMLElement>("[data-nav-menu]")!;

    toggle.click();
    toggle.click();

    expect(menu.classList.contains("hidden")).toBe(true);
    expect(toggle.getAttribute("aria-expanded")).toBe("false");
  });

  it("does nothing if the toggle or menu elements are missing", () => {
    document.body.innerHTML = "";
    expect(() => initNavToggle(document)).not.toThrow();
  });
});
