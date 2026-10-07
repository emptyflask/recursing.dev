# _includes/logo.html is generated from ascii.txt by scripts/build-logo.mjs
# and gitignored (never hand-edited or committed). Regenerate it before
# Jekyll reads any includes, so `jekyll build`/`serve` always has it ready
# without a separate manual step — and `serve --watch` picks up ascii.txt
# changes automatically on every rebuild.
Jekyll::Hooks.register :site, :after_reset do |site|
  script = File.join(site.source, "scripts", "build-logo.mjs")
  system("node", script, exception: true)
end
