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
npm ci
npm test
npm run build
node scripts/build-logo.mjs
bundle install
bundle exec jekyll build
```

For local development with live reload, run `bundle exec jekyll serve` instead of
`bundle exec jekyll build` as the last step.
