# recursing.dev

Source for [recursing.dev](https://recursing.dev), a Jekyll + Vite + Tailwind site.

## Prerequisites

- Node.js >= 20
- Ruby >= 3.1

On NixOS (or anywhere with Nix + flakes enabled), skip installing these yourself —
run `nix develop` first to drop into a shell with the right Node/Ruby/Bundler and
the native libraries Jekyll's gems need (`ffi`, `google-protobuf`, `sass-embedded`
all require native extensions, which this shell builds from source instead of
using precompiled binaries that don't run on NixOS).

## Getting Started

```sh
pnpm install --frozen-lockfile
pnpm test
pnpm run build
bundle install
bundle exec jekyll build
```

The colorized ASCII logo (`_includes/logo.html`) is generated from `ascii.txt`
automatically — a Jekyll plugin (`_plugins/generate_logo.rb`) regenerates it on
every build, so there's no separate manual step and `jekyll serve --watch` picks
up `ascii.txt` changes too. Requires `node` on `PATH` (already true inside
`nix develop`).

For local development with live reload:

```
jekyll serve --port 4001 --livereload
```

`assets/resume.pdf` and `resume.md` are built fresh from the committed
[emptyflask/resume](https://github.com/emptyflask/resume) on every deploy (see
`.github/workflows/deploy.yml`) — both are gitignored, not committed here. For
local dev, `/resume/` and the "Download PDF" link 404 until you build them
yourself, e.g.:

```sh
nix build --refresh git+ssh://git@github.com/emptyflask/resume --out-link /tmp/resume-build
cp /tmp/resume-build/resume.pdf assets/resume.pdf
ruby scripts/resume2md.rb git+ssh://git@github.com/emptyflask/resume
```
