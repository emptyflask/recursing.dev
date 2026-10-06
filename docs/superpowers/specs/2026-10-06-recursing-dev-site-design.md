# recursing.dev — site design

## Purpose

A personal blog / CV / portfolio site for Jon at recursing.dev, built as a static
site and published on GitHub Pages. Themed as a gruvbox-colored, old-BBS-style
terminal, using the colorized ASCII wordmark in `ascii.txt` as the logo. May later
support independent contracting (not in v1 scope, but the architecture should make
adding a "hire me" page trivial).

## Tech stack & build

- **Jekyll** for content and templating (posts collection, layouts, Liquid includes).
  Chosen over Minuteman for its native GitHub Pages familiarity and ecosystem, even
  though we're bypassing GitHub's native Pages build (see below).
- **Vite** builds the front-end assets — Tailwind CSS and TypeScript — compiled to
  fixed (non-hashed) output filenames in `assets/dist/`, which Jekyll layouts
  reference directly via `<link>`/`<script>` tags. No manifest/hashing needed for a
  site this size.
- **Tailwind CSS**, configured with a custom gruvbox-dark theme (color tokens below),
  compiled via Vite rather than the Play CDN.
- **TypeScript** for the one bit of client-side scripting v1 needs: the mobile nav
  toggle. No other interactivity planned for v1.
- **GitHub Actions** workflow (`.github/workflows/deploy.yml`):
  1. `npm ci && npm run build` — Vite build of CSS/TS into `assets/dist/`
  2. `bundle exec jekyll build` — Jekyll build of the full site into `_site/`
  3. `actions/deploy-pages` — deploy `_site/` to GitHub Pages
  This is required because GitHub's native Jekyll-on-Pages build only runs Jekyll
  itself and can't execute a Vite build step.

### Repo layout (high level)

```
_posts/            Jekyll blog posts (markdown)
_layouts/          Jekyll layouts (default, post, page)
_includes/         Shared partials, including the pre-rendered logo.html
index.md           Homepage
blog/              Blog index + tag pages
resume.md          Resume/CV page
assets/
  dist/            Vite build output (gitignored, built in CI)
  resume.pdf        Placeholder downloadable resume PDF
src/
  main.ts          TS entry (nav toggle)
  styles.css       Tailwind entry
scripts/
  build-logo.mjs    One-off generator: ascii.txt -> _includes/logo.html
.github/workflows/deploy.yml
```

## Theme & visual design

- **Palette**: gruvbox-dark only (no light mode toggle — committing fully to the
  BBS feel). Wired into Tailwind as custom theme colors:
  - Backgrounds: `bg0 #282828`, `bg1 #3c3836`, `bg2 #504945`
  - Foreground: `fg0 #fbf1c7`, `fg1 #ebdbb2`
  - Accents: `red #fb4934`, `orange #fe8019`, `yellow #fabd2f`, `green #b8bb26`,
    `aqua #8ec07c`, `blue #83a598`, `purple #d3869b`, `gray #928374`
- **Logo**: the block-art wordmark in `ascii.txt`, colorized with a single
  top-to-bottom gradient sweep through `orange → yellow → green → aqua → blue`
  (interpolated per content row, no hue repeats, red/purple excluded so it reads
  as a cohesive sunset-to-ocean gradient rather than a full rainbow). Pre-rendered
  at build time by `scripts/build-logo.mjs` into `_includes/logo.html` as static
  colored `<span>` runs on the `bg0` background — no runtime cost, used in the site
  header.
- **Typography**: Fira Code for headers, nav, and code/UI chrome; system sans-serif
  stack (Tailwind's default `font-sans`) for blog post body copy, so long-form
  reading stays comfortable rather than full-monospace.
- **Layout**: "classic blog" structure — header bar with logo + horizontal nav
  (Home / Blog / Resume), content area as full-width stacked panels. Collapses to
  a mobile nav toggle (hamburger) below the responsive breakpoint.
- **ANSI box-drawing borders**: implemented as CSS borders (1px solid, muted
  `#665c54`) around panels/cards, with box-drawing corner glyphs (`┌ ┐ └ ┘`) as
  decorative `::before`/`::after` accents at the corners. Literal full ASCII-art
  frames don't reflow responsively, so this fakes the look while staying
  mobile-friendly.
- **Blinking cursor accent**: a decorative `█` block, animated via a CSS
  `@keyframes` blink rule, placed after the logo and page titles. Pure CSS, no JS.
- **Explicitly excluded from v1**: light mode, CRT/scanline overlays, blog
  search/filter, portfolio/projects page, contracting/hire-me page.

## Site structure & content

- **Blog**: standard Jekyll `_posts/` collection.
  - Index page: reverse-chronological list of posts
  - Per-post layout
  - Tags/categories: per-tag listing page via the `jekyll-archives` plugin — safe
    to use since the custom Actions build runs full Jekyll, not GitHub's
    plugin-allowlisted native build
  - RSS/Atom feed via the `jekyll-feed` plugin
- **Resume/CV page** (`/resume/`): Summary, Experience, Skills, Education sections,
  plus a "Download PDF" link pointing at `assets/resume.pdf` (placeholder file,
  swapped for the real resume later).
- **Homepage**: logo + short bio blurb + feed of recent posts.
- **Content for v1**: scaffolded as placeholders — 1–2 sample blog posts and
  placeholder resume section content — filled in with real content afterward.

## Testing / verification

- Jekyll build (`bundle exec jekyll build`) must succeed with no errors.
- Vite build (`npm run build`) must succeed and produce `assets/dist/` output
  referenced correctly by Jekyll layouts.
- Manual check in a browser: homepage, a blog post, a tag page, the RSS feed, and
  the resume page all render correctly with the gruvbox theme, logo gradient,
  mobile nav toggle, and box-border/cursor accents working as designed.
- GitHub Actions workflow runs green on push to `main` and successfully deploys to
  GitHub Pages.
