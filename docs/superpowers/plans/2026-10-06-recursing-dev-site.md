# recursing.dev Site Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and deploy a Jekyll + Vite + Tailwind + TypeScript static site for recursing.dev, themed as a gruvbox-dark BBS terminal, with a colorized ASCII logo, a blog, and a resume page, published via GitHub Actions to GitHub Pages.

**Architecture:** Jekyll handles content/templating (collections, layouts, Liquid). Vite compiles a small TypeScript bundle and a Tailwind CSS bundle to fixed filenames in `assets/dist/`, which Jekyll layouts reference directly. A one-off Node script turns `ascii.txt` into a pre-rendered, gradient-colorized HTML include consumed by the Jekyll header. GitHub Actions runs the Node build, the logo generator, and the Jekyll build, then deploys `_site/` to GitHub Pages.

**Tech Stack:** Jekyll 4.x (Ruby), Vite 6+, TypeScript (strict), Tailwind CSS v4 (CSS-first `@theme` config via `@tailwindcss/vite`), Vitest + jsdom for TS unit tests, `jekyll-feed` and `jekyll-archives` plugins, GitHub Actions (`actions/deploy-pages`).

## Global Constraints

- Node.js >= 20 (required by Tailwind CSS v4 / `@tailwindcss/vite`).
- Ruby >= 3.1 (required by Jekyll 4.3+ and `jekyll-archives` 2.3+).
- Gruvbox-dark only — no light mode. Exact palette (from the design doc):
  `bg0 #282828`, `bg1 #3c3836`, `bg2 #504945`, `fg0 #fbf1c7`, `fg1 #ebdbb2`,
  `red #fb4934`, `orange #fe8019`, `yellow #fabd2f`, `green #b8bb26`,
  `aqua #8ec07c`, `blue #83a598`, `purple #d3869b`, `gray #928374`.
- Logo gradient: top-to-bottom sweep through exactly `#fe8019 → #fabd2f → #b8bb26 → #8ec07c → #83a598` (orange/yellow/green/aqua/blue), no red/purple, no hue repeats.
- Headers/nav/code use Fira Code (`--font-mono`); body copy uses the system sans stack (Tailwind default `font-sans`).
- TypeScript only for the mobile nav toggle — no other client-side scripting in v1.
- `_includes/logo.html` is a generated artifact (from `ascii.txt` via `scripts/build-logo.mjs`) and must never be hand-edited or committed — it's gitignored and regenerated on every build.

---

### Task 1: Vite + TypeScript scaffold with nav toggle

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `vite.config.ts`
- Create: `vitest.config.ts`
- Create: `src/nav.ts`
- Create: `src/main.ts`
- Test: `src/nav.test.ts`

**Interfaces:**
- Produces: `initNavToggle(doc: Document): void` — exported from `src/nav.ts`. Finds `[data-nav-toggle]` (a button) and `[data-nav-menu]` (the menu element) in `doc`; clicking the toggle flips the menu's `hidden` class and sets the toggle's `aria-expanded` attribute to `"true"`/`"false"` accordingly. No-ops silently if either element is missing.
- Produces: `npm run build` → `assets/dist/main.js` (ES module entry that calls `initNavToggle(document)` on `DOMContentLoaded`).
- Produces: `npm test` → runs Vitest once (CI-friendly, non-watch).

- [ ] **Step 1: Initialize `package.json` and install dependencies**

Run:
```bash
npm init -y
npm install -D vite typescript vitest jsdom @types/node
```

Edit `package.json` to add:
```json
{
  "type": "module",
  "scripts": {
    "build": "vite build",
    "dev": "vite build --watch",
    "test": "vitest run"
  }
}
```

- [ ] **Step 2: Write `tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "lib": ["ES2020", "DOM"],
    "skipLibCheck": true,
    "noEmit": true
  },
  "include": ["src"]
}
```

- [ ] **Step 3: Write the failing test for the nav toggle**

`src/nav.test.ts`:
```ts
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
```

- [ ] **Step 4: Write `vitest.config.ts` so the test can run**

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "jsdom",
  },
});
```

- [ ] **Step 5: Run the test to verify it fails**

Run: `npm test`
Expected: FAIL — `src/nav.ts` does not exist / `initNavToggle` is not defined.

- [ ] **Step 6: Implement `src/nav.ts`**

```ts
export function initNavToggle(doc: Document): void {
  const toggle = doc.querySelector<HTMLButtonElement>("[data-nav-toggle]");
  const menu = doc.querySelector<HTMLElement>("[data-nav-menu]");
  if (!toggle || !menu) return;

  toggle.addEventListener("click", () => {
    const hidden = menu.classList.toggle("hidden");
    toggle.setAttribute("aria-expanded", String(!hidden));
  });
}
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `npm test`
Expected: PASS — all 3 tests in `src/nav.test.ts` green.

- [ ] **Step 8: Write the entry point and wire up `vite.config.ts`**

`src/main.ts`:
```ts
import { initNavToggle } from "./nav";

document.addEventListener("DOMContentLoaded", () => {
  initNavToggle(document);
});
```

`vite.config.ts`:
```ts
import { defineConfig } from "vite";
import { resolve } from "node:path";

export default defineConfig({
  build: {
    outDir: "assets/dist",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: resolve(__dirname, "src/main.ts"),
      },
      output: {
        entryFileNames: "[name].js",
      },
    },
  },
});
```

- [ ] **Step 9: Run the build and verify the output**

Run: `npm run build && test -f assets/dist/main.js && echo OK`
Expected: `OK` printed, confirming `assets/dist/main.js` was produced.

- [ ] **Step 10: Add build output and deps to `.gitignore`, then commit**

Confirm `.gitignore` (created during brainstorming) already contains `node_modules/` and `assets/dist/` — both are already present. No edit needed.

```bash
git add package.json package-lock.json tsconfig.json vite.config.ts vitest.config.ts src/nav.ts src/nav.test.ts src/main.ts
git commit -m "feat: scaffold Vite/TypeScript build with nav toggle"
```

---

### Task 2: Tailwind gruvbox theme and BBS component styles

**Files:**
- Create: `src/styles.css`
- Modify: `vite.config.ts` (add Tailwind plugin + `styles` build entry)

**Interfaces:**
- Consumes: nothing from Task 1 except the existing `vite.config.ts` structure (adds a second `rollupOptions.input` entry).
- Produces: `assets/dist/styles.css`, containing:
  - CSS custom properties for every gruvbox color in the Global Constraints palette (e.g. `--color-bg0: #282828;`), from Tailwind's `@theme` block.
  - `--font-mono: "Fira Code", ui-monospace, monospace;` theme variable.
  - A `.bbs-panel` component class (bordered panel with `┌`/`┘` corner glyph accents) used by every Task 4+ layout/include.
  - A `.blink-cursor` component class (animated block-cursor accent) used by Task 4+ pages.
  - Base typography rules for `h1`/`h2`/`h3`/`p` so raw Jekyll/Markdown content (Tasks 5–7) isn't unstyled.

- [ ] **Step 1: Install Tailwind CSS v4**

Run: `npm install -D tailwindcss @tailwindcss/vite`

- [ ] **Step 2: Write `src/styles.css`**

```css
@import "tailwindcss";

/* Jekyll templates live outside src/, so register them explicitly
   alongside Tailwind's automatic project-wide content detection. */
@source "../_layouts";
@source "../_includes";
@source "../_posts";
@source "../*.md";

@theme {
  --color-bg0: #282828;
  --color-bg1: #3c3836;
  --color-bg2: #504945;
  --color-fg0: #fbf1c7;
  --color-fg1: #ebdbb2;
  --color-red: #fb4934;
  --color-orange: #fe8019;
  --color-yellow: #fabd2f;
  --color-green: #b8bb26;
  --color-aqua: #8ec07c;
  --color-blue: #83a598;
  --color-purple: #d3869b;
  --color-gray: #928374;
  --font-mono: "Fira Code", ui-monospace, "SFMono-Regular", monospace;
}

@layer base {
  h1, h2, h3 {
    font-family: var(--font-mono);
    color: var(--color-orange);
    margin-top: 1.5em;
    margin-bottom: 0.5em;
  }
  p {
    margin-bottom: 1em;
  }
  a {
    text-underline-offset: 2px;
  }
}

@layer components {
  .bbs-panel {
    @apply relative border border-gray bg-bg1 p-4;
  }
  .bbs-panel::before,
  .bbs-panel::after {
    @apply absolute text-gray font-mono select-none pointer-events-none text-lg;
  }
  .bbs-panel::before {
    content: "┌";
    top: -0.6em;
    left: -0.4em;
  }
  .bbs-panel::after {
    content: "┘";
    bottom: -0.6em;
    right: -0.4em;
  }

  .blink-cursor {
    @apply inline-block w-[0.6em] h-[1em] bg-orange align-middle ml-1;
    animation: bbs-blink 1s steps(2, start) infinite;
  }
}

@keyframes bbs-blink {
  to {
    visibility: hidden;
  }
}
```

- [ ] **Step 3: Wire the Tailwind plugin and a `styles` build entry into `vite.config.ts`**

```ts
import { defineConfig } from "vite";
import { resolve } from "node:path";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [tailwindcss()],
  build: {
    outDir: "assets/dist",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: resolve(__dirname, "src/main.ts"),
        styles: resolve(__dirname, "src/styles.css"),
      },
      output: {
        entryFileNames: "[name].js",
        assetFileNames: "[name][extname]",
      },
    },
  },
});
```

- [ ] **Step 4: Build and verify the compiled CSS contains the expected output**

Run:
```bash
npm run build
grep -q -- "--color-bg0: #282828" assets/dist/styles.css && echo "theme vars OK"
grep -q "\.bbs-panel" assets/dist/styles.css && echo "bbs-panel OK"
grep -q "\.blink-cursor" assets/dist/styles.css && echo "blink-cursor OK"
grep -q "bbs-blink" assets/dist/styles.css && echo "keyframes OK"
```
Expected: all four `OK` lines printed. CSS output isn't meaningfully unit-testable (no logic to assert against, just declarations), so this build-and-grep check is the test for this task.

- [ ] **Step 5: Commit**

```bash
git add package.json package-lock.json src/styles.css vite.config.ts
git commit -m "feat: add gruvbox Tailwind theme and BBS panel/cursor components"
```

---

### Task 3: Logo gradient generator script

**Files:**
- Create: `scripts/logo-gradient.mjs`
- Create: `scripts/logo-gradient.test.mjs`
- Create: `scripts/build-logo.mjs`
- Modify: `.gitignore` (add `_includes/logo.html`)

**Interfaces:**
- Produces: `buildLogoHtml(asciiText: string): string` — exported from `scripts/logo-gradient.mjs`. Pure function: reads block-art text, returns an HTML string `<pre class="logo-art" aria-label="recursing.dev">...</pre>` where each non-blank line is wrapped in `<span style="color:#rrggbb">` with color interpolated top-to-bottom across the stop sequence `#fe8019, #fabd2f, #b8bb26, #8ec07c, #83a598`; blank lines pass through as plain newlines (no span).
- Produces: running `node scripts/build-logo.mjs` writes `_includes/logo.html`, consumed by `_includes/header.html` in Task 4 via `{% include logo.html %}`.

- [ ] **Step 1: Write the failing test**

`scripts/logo-gradient.test.mjs`:
```js
import { describe, it, expect } from "vitest";
import { buildLogoHtml } from "./logo-gradient.mjs";

describe("buildLogoHtml", () => {
  it("wraps output in a <pre class=\"logo-art\">", () => {
    const html = buildLogoHtml("██\n");
    expect(html.startsWith('<pre class="logo-art" aria-label="recursing.dev">')).toBe(true);
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `npm test`
Expected: FAIL — `scripts/logo-gradient.mjs` does not exist.

- [ ] **Step 3: Implement `scripts/logo-gradient.mjs`**

```js
function esc(s) {
  return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function hexToRgb(hex) {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function rgbToHex([r, g, b]) {
  return "#" + [r, g, b].map((v) => Math.round(v).toString(16).padStart(2, "0")).join("");
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

const STOPS = ["#fe8019", "#fabd2f", "#b8bb26", "#8ec07c", "#83a598"].map(hexToRgb);

function colorAt(t) {
  const segments = STOPS.length - 1;
  const pos = t * segments;
  const i = Math.min(Math.floor(pos), segments - 1);
  const localT = pos - i;
  const rgb = [0, 1, 2].map((k) => lerp(STOPS[i][k], STOPS[i + 1][k], localT));
  return rgbToHex(rgb);
}

export function buildLogoHtml(asciiText) {
  const lines = asciiText.replace(/\n$/, "").split("\n");
  const totalContentRows = lines.filter((l) => l.trim() !== "").length;

  const out = ['<pre class="logo-art" aria-label="recursing.dev">'];
  let rowCounter = 0;
  for (const line of lines) {
    if (line.trim() === "") {
      out.push("\n");
      continue;
    }
    const t = totalContentRows <= 1 ? 0 : rowCounter / (totalContentRows - 1);
    const color = colorAt(t);
    rowCounter++;
    out.push(`<span style="color:${color}">${esc(line)}</span>\n`);
  }
  out.push("</pre>");
  return out.join("");
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `npm test`
Expected: PASS — all 5 tests in `scripts/logo-gradient.test.mjs` green.

- [ ] **Step 5: Implement the CLI wrapper `scripts/build-logo.mjs`**

```js
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { buildLogoHtml } from "./logo-gradient.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");

const asciiText = readFileSync(join(ROOT, "ascii.txt"), "utf8");
writeFileSync(join(ROOT, "_includes/logo.html"), buildLogoHtml(asciiText));
console.log("Wrote _includes/logo.html");
```

- [ ] **Step 6: Create the `_includes` directory and run the generator**

Run:
```bash
mkdir -p _includes
node scripts/build-logo.mjs
head -c 200 _includes/logo.html
```
Expected: `Wrote _includes/logo.html` printed, and the file starts with `<pre class="logo-art" aria-label="recursing.dev"><span style="color:#fe8019">`.

- [ ] **Step 7: Add the generated include to `.gitignore`**

Append to `.gitignore`:
```
_includes/logo.html
```

- [ ] **Step 8: Commit**

```bash
git add scripts/logo-gradient.mjs scripts/logo-gradient.test.mjs scripts/build-logo.mjs .gitignore
git commit -m "feat: generate colorized ASCII logo include from ascii.txt"
```

---

### Task 4: Jekyll base scaffolding (layout, header, nav)

**Files:**
- Create: `Gemfile`
- Create: `_config.yml`
- Create: `_layouts/default.html`
- Create: `_includes/header.html`

**Interfaces:**
- Consumes: `assets/dist/main.js`, `assets/dist/styles.css` (Tasks 1–2); `_includes/logo.html` (Task 3, must be regenerated via `node scripts/build-logo.mjs` before any `jekyll build`); `initNavToggle`'s expected DOM contract — a `[data-nav-toggle]` button and a `[data-nav-menu]` element, the latter starting with the `hidden` class.
- Produces: the `default` layout (`layout: default`) consumed by every page/post in Tasks 5–7; `_includes/header.html` rendering the nav links `/`, `/blog/`, `/resume/` used by Tasks 5–7's pages.

- [ ] **Step 1: Write the `Gemfile`**

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.3"
gem "jekyll-feed", "~> 0.17"
gem "jekyll-archives", "~> 2.3"
gem "webrick", "~> 1.8"
```

Run: `bundle install`

- [ ] **Step 2: Write `_config.yml`**

```yaml
title: recursing.dev
description: "Jon's personal blog, CV, and portfolio"
url: "https://recursing.dev"
baseurl: ""
markdown: kramdown

permalink: /blog/:year/:month/:day/:title/

plugins:
  - jekyll-feed
  - jekyll-archives

jekyll-archives:
  enabled: [tags]
  layout: tag
  permalinks:
    tag: "/blog/tags/:name/"

feed:
  path: feed.xml

defaults:
  - scope:
      path: ""
      type: posts
    values:
      layout: post
  - scope:
      path: ""
    values:
      layout: default

exclude:
  - node_modules
  - src
  - scripts
  - package.json
  - package-lock.json
  - vite.config.ts
  - vitest.config.ts
  - tsconfig.json
  - docs
  - ascii.txt
  - Gemfile
  - Gemfile.lock
```

- [ ] **Step 3: Write `_layouts/default.html`**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ page.title | default: site.title }}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="{{ '/assets/dist/styles.css' | relative_url }}">
</head>
<body class="bg-bg0 text-fg1 font-sans min-h-screen">
  {% include header.html %}
  <main class="max-w-3xl mx-auto px-4 py-8">
    {{ content }}
  </main>
  <script type="module" src="{{ '/assets/dist/main.js' | relative_url }}"></script>
</body>
</html>
```

- [ ] **Step 4: Write `_includes/header.html`**

```html
<header class="bbs-panel mx-4 my-4 md:mx-auto md:max-w-3xl flex items-center justify-between flex-wrap gap-4">
  <a href="{{ '/' | relative_url }}" class="shrink-0">
    {% include logo.html %}
  </a>
  <button type="button" data-nav-toggle aria-expanded="false" aria-controls="primary-nav"
    class="md:hidden font-mono text-fg1 border border-gray px-2 py-1">
    menu
  </button>
  <nav id="primary-nav" data-nav-menu class="hidden md:flex md:gap-6 w-full md:w-auto font-mono">
    <a href="{{ '/' | relative_url }}" class="block py-1 text-fg1 hover:text-orange">Home</a>
    <a href="{{ '/blog/' | relative_url }}" class="block py-1 text-fg1 hover:text-orange">Blog</a>
    <a href="{{ '/resume/' | relative_url }}" class="block py-1 text-fg1 hover:text-orange">Resume</a>
  </nav>
</header>
```

- [ ] **Step 5: Regenerate the logo include and build the site**

Run:
```bash
node scripts/build-logo.mjs
npm run build
bundle exec jekyll build
```
Expected: builds with no errors, producing `_site/`.

- [ ] **Step 6: Verify the rendered homepage contains the expected structure**

There's no homepage content yet (Task 6), but Jekyll still renders a bare page for any `.md`/`.html` file at the root — to verify the layout itself, check the build output doesn't error and that `_site` contains the header markup once any page exists. Since no root page exists yet, verify via the layout file directly:

Run: `grep -q "data-nav-toggle" _layouts/default.html _includes/header.html && grep -q "primary-nav" _includes/header.html && echo OK`
Expected: `OK` — confirms the nav toggle/menu attributes `initNavToggle` depends on are present and spelled correctly. Full end-to-end rendering is verified in Task 6 once a homepage exists.

- [ ] **Step 7: Commit**

```bash
git add Gemfile Gemfile.lock _config.yml _layouts/default.html _includes/header.html
git commit -m "feat: scaffold Jekyll layout, header, and nav"
```

---

### Task 5: Blog collection (posts, tags, RSS)

**Files:**
- Create: `_layouts/post.html`
- Create: `_layouts/tag.html`
- Create: `blog/index.html`
- Create: `_posts/2026-01-10-hello-recursing-dev.md`
- Create: `_posts/2026-02-03-a-note-on-gruvbox.md`

**Interfaces:**
- Consumes: `default` layout, `.bbs-panel`/`.blink-cursor` classes (Tasks 2, 4).
- Produces: `site.posts` (standard Jekyll collection, used by Task 6's homepage to list recent posts) and the `/blog/`, `/blog/tags/<tag>/`, and `/feed.xml` routes.

- [ ] **Step 1: Write `_layouts/post.html`**

```html
---
layout: default
---
<article class="bbs-panel mb-8">
  <h1 class="font-mono text-2xl text-orange mb-2">{{ page.title }}</h1>
  <p class="font-mono text-sm text-gray mb-4">
    {{ page.date | date: "%Y-%m-%d" }}
    {% if page.tags.size > 0 %}
      &middot;
      {% for tag in page.tags %}
        <a href="{{ '/blog/tags/' | append: tag | append: '/' | relative_url }}" class="text-aqua hover:text-orange">#{{ tag }}</a>
      {% endfor %}
    {% endif %}
  </p>
  {{ content }}
</article>
```

- [ ] **Step 2: Write `_layouts/tag.html`**

```html
---
layout: default
---
<h1 class="font-mono text-2xl text-orange mb-6">Tag: {{ page.title }}<span class="blink-cursor"></span></h1>
<ul class="space-y-6">
  {% for post in page.posts %}
    <li class="bbs-panel">
      <a href="{{ post.url | relative_url }}" class="font-mono text-lg text-fg0 hover:text-orange">{{ post.title }}</a>
      <p class="font-mono text-sm text-gray">{{ post.date | date: "%Y-%m-%d" }}</p>
    </li>
  {% endfor %}
</ul>
```

- [ ] **Step 3: Write `blog/index.html`**

```html
---
layout: default
title: Blog
permalink: /blog/
---
<h1 class="font-mono text-2xl text-orange mb-6">Blog<span class="blink-cursor"></span></h1>
<ul class="space-y-6">
  {% for post in site.posts %}
    <li class="bbs-panel">
      <a href="{{ post.url | relative_url }}" class="font-mono text-lg text-fg0 hover:text-orange">{{ post.title }}</a>
      <p class="font-mono text-sm text-gray">{{ post.date | date: "%Y-%m-%d" }}</p>
    </li>
  {% endfor %}
</ul>
```

- [ ] **Step 4: Write the two placeholder posts**

`_posts/2026-01-10-hello-recursing-dev.md`:
```markdown
---
title: "Hello, recursing.dev"
tags: [meta]
---

Placeholder first post — replace with real content. This is where the site's
first real update will go.
```

`_posts/2026-02-03-a-note-on-gruvbox.md`:
```markdown
---
title: "A note on gruvbox"
tags: [meta, design]
---

Placeholder second post — replace with real content. Exists to prove the tag
index page (`/blog/tags/meta/`) lists more than one post.
```

- [ ] **Step 5: Build and verify**

Run:
```bash
node scripts/build-logo.mjs
npm run build
bundle exec jekyll build
test -f _site/blog/index.html && echo "blog index OK"
test -f _site/blog/tags/meta/index.html && echo "tag page OK"
test -f _site/feed.xml && echo "rss OK"
grep -q "Hello, recursing.dev" _site/blog/index.html && echo "post listed OK"
```
Expected: all four `OK` lines printed.

- [ ] **Step 6: Commit**

```bash
git add _layouts/post.html _layouts/tag.html blog/index.html _posts/
git commit -m "feat: add blog collection with tags and RSS feed"
```

---

### Task 6: Homepage

**Files:**
- Create: `index.md`

**Interfaces:**
- Consumes: `site.posts` (Task 5), `default` layout and `.bbs-panel`/`.blink-cursor` classes (Tasks 2, 4).

- [ ] **Step 1: Write `index.md`**

```markdown
---
layout: default
title: Home
permalink: /
---

<section class="bbs-panel mb-8">
  <p class="font-mono text-fg1">
    Hi, I'm Jon. This is recursing.dev — placeholder bio copy, replace this
    with the real thing.
  </p>
</section>

<h2 class="font-mono text-xl text-orange mb-4">Recent posts<span class="blink-cursor"></span></h2>
<ul class="space-y-6">
  {% for post in site.posts limit: 5 %}
    <li class="bbs-panel">
      <a href="{{ post.url | relative_url }}" class="font-mono text-lg text-fg0 hover:text-orange">{{ post.title }}</a>
      <p class="font-mono text-sm text-gray">{{ post.date | date: "%Y-%m-%d" }}</p>
    </li>
  {% endfor %}
</ul>
```

- [ ] **Step 2: Build and verify**

Run:
```bash
node scripts/build-logo.mjs
npm run build
bundle exec jekyll build
grep -q "Hi, I'm Jon" _site/index.html && echo "bio OK"
grep -q "Hello, recursing.dev" _site/index.html && echo "recent posts OK"
grep -q "logo-art" _site/index.html && echo "logo OK"
```
Expected: all three `OK` lines printed — this is the first full end-to-end render (layout + header + logo + nav + posts all together).

- [ ] **Step 3: Commit**

```bash
git add index.md
git commit -m "feat: add homepage with bio and recent posts"
```

---

### Task 7: Resume page

**Files:**
- Create: `resume.md`
- Create: `assets/resume.pdf`

**Interfaces:**
- Consumes: `default` layout and `.bbs-panel`/`.blink-cursor` classes (Tasks 2, 4).

- [ ] **Step 1: Generate the placeholder PDF**

Run this exact command (builds a minimal, byte-correct, valid one-page PDF with calculated xref offsets — not hand-typed bytes):
```bash
mkdir -p assets
node -e '
const fs = require("fs");
const header = "%PDF-1.4\n";
const obj1 = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n";
const obj2 = "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n";
const obj3 = "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n";
const obj4 = "4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n";
const streamContent = "BT /F1 24 Tf 72 700 Td (Placeholder resume - replace this file.) Tj ET";
const obj5 = "5 0 obj\n<< /Length " + streamContent.length + " >>\nstream\n" + streamContent + "\nendstream\nendobj\n";

let offset = header.length;
const offsets = [0];
for (const obj of [obj1, obj2, obj3, obj4, obj5]) {
  offsets.push(offset);
  offset += obj.length;
}
const xrefStart = offset;

const body = header + obj1 + obj2 + obj3 + obj4 + obj5;
let xref = "xref\n0 6\n0000000000 65535 f \n";
for (let i = 1; i <= 5; i++) {
  xref += String(offsets[i]).padStart(10, "0") + " 00000 n \n";
}
const trailer = "trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n" + xrefStart + "\n%%EOF";

fs.writeFileSync("assets/resume.pdf", body + xref + trailer, "binary");
console.log("wrote assets/resume.pdf");
'
```

- [ ] **Step 2: Verify the PDF is valid**

Run: `file assets/resume.pdf`
Expected: output contains `PDF document, version 1.4` (confirms valid PDF header/structure, not just a renamed text file).

- [ ] **Step 3: Write `resume.md`**

```markdown
---
layout: default
title: Resume
permalink: /resume/
---

<div class="bbs-panel mb-8 flex items-center justify-between flex-wrap gap-4">
  <h1 class="font-mono text-2xl text-orange m-0">Resume<span class="blink-cursor"></span></h1>
  <a href="{{ '/assets/resume.pdf' | relative_url }}" class="font-mono text-aqua hover:text-orange border border-gray px-3 py-1">Download PDF</a>
</div>

## Summary

Placeholder summary — replace with the real bio/summary.

## Experience

**Placeholder Role — Placeholder Company** <span class="text-gray">(2024 – present)</span>

Placeholder description of responsibilities and impact.

## Skills

- Placeholder skill one
- Placeholder skill two
- Placeholder skill three

## Education

**Placeholder Degree — Placeholder Institution** <span class="text-gray">(2020)</span>
```

- [ ] **Step 4: Build and verify**

Run:
```bash
node scripts/build-logo.mjs
npm run build
bundle exec jekyll build
grep -q "Download PDF" _site/resume/index.html && echo "pdf link OK"
grep -q "Placeholder summary" _site/resume/index.html && echo "summary OK"
test -f _site/assets/resume.pdf && echo "pdf copied OK"
```
Expected: all three `OK` lines printed.

- [ ] **Step 5: Commit**

```bash
git add resume.md assets/resume.pdf
git commit -m "feat: add resume page with placeholder content and PDF download"
```

---

### Task 8: GitHub Actions deploy workflow

**Files:**
- Create: `.github/workflows/deploy.yml`

**Interfaces:**
- Consumes: `npm run build` (Tasks 1–2), `node scripts/build-logo.mjs` (Task 3), `bundle exec jekyll build` (Task 4) — runs the exact same three commands CI will run, in the same order, as its own verification.

- [ ] **Step 1: Write `.github/workflows/deploy.yml`**

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - run: npm ci
      - run: npm run build
      - run: node scripts/build-logo.mjs

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"
          bundler-cache: true

      - run: bundle exec jekyll build

      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: _site

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 2: Verify the build sequence locally, matching CI exactly**

Run:
```bash
rm -rf _site assets/dist _includes/logo.html
npm ci
npm run build
node scripts/build-logo.mjs
bundle exec jekyll build
test -d _site && echo "full pipeline OK"
```
Expected: `full pipeline OK` printed — this is the same command sequence the `build` job runs, confirming CI will succeed once pushed. (Actually exercising GitHub Pages deployment requires pushing to `main` and enabling Pages in the repo settings, which is outside what a local run can verify.)

- [ ] **Step 3: Manual visual check in a browser**

Run: `bundle exec jekyll serve`, then open `http://localhost:4000/` and check by eye:
- Homepage: gradient logo, bio blurb, recent posts list, gruvbox colors, box-border panel corners, blinking cursor next to "Recent posts".
- A blog post page (`/blog/2026/01/10/hello-recursing-dev/`): post renders with tag link.
- A tag page (`/blog/tags/meta/`): lists both placeholder posts.
- `/feed.xml`: valid RSS/Atom XML.
- `/resume/`: all four sections render, "Download PDF" link downloads the placeholder PDF.
- Resize the browser below the `md` breakpoint: nav collapses behind the "menu" toggle button, and clicking it shows/hides the nav links.

Stop the server (Ctrl-C) when done.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/deploy.yml
git commit -m "feat: add GitHub Actions workflow to build and deploy to Pages"
```

- [ ] **Step 5: Tell the user the remaining manual step**

This step has no file changes — it's a reminder: GitHub Pages must be switched to "GitHub Actions" as its build source in the repo's Settings → Pages, and the repo must be pushed to GitHub, before the workflow can actually deploy. Flag this to the user rather than silently assuming it's done.
