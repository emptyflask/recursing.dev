import { describe, it, expect } from "vitest";
import { buildLogoHtml } from "./logo-gradient.mjs";

describe("buildLogoHtml", () => {
  it("wraps output in a <pre class=\"logo-art\">", () => {
    const html = buildLogoHtml("██\n");
    expect(html.startsWith('<pre class="logo-art" aria-hidden="true">')).toBe(true);
    expect(html.trim().endsWith("</pre>")).toBe(true);
  });

  it("colors the first content row with the gradient's starting hue", () => {
    const html = buildLogoHtml("██\n██\n");
    expect(html).toContain('style="color:#fe8019"');
  });

  it("colors the last content row with the gradient's ending hue", () => {
    const html = buildLogoHtml("██\n██\n");
    expect(html).toContain('style="color:#83a598"');
  });

  it("preserves blank lines without emitting a span", () => {
    const html = buildLogoHtml("██\n\n██\n");
    const lines = html.split("\n");
    expect(lines[1]).toBe("");
  });

  it("escapes HTML-sensitive characters", () => {
    const html = buildLogoHtml("<&>\n");
    expect(html).toContain("&lt;&amp;&gt;");
  });
});
