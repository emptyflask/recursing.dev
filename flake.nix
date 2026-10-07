{
  description = "Dev environment for recursing.dev (Jekyll + Vite/Tailwind/TypeScript)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nodejs_22
              pkgs.bundler
              pkgs.ruby
              pkgs.libyaml
              pkgs.zlib
              pkgs.openssl
              pkgs.pkg-config
            ];

            # jekyll's dependency tree includes gems with native extensions
            # (ffi, google-protobuf). Precompiled "gnu"-platform gem binaries
            # assume a standard FHS glibc layout that doesn't exist on NixOS,
            # so force bundler to always build from source against the libs
            # listed above instead of downloading those precompiled binaries.
            BUNDLE_FORCE_RUBY_PLATFORM = "1";

            shellHook = ''
              echo "recursing.dev dev shell"
              echo "  node    $(node --version)"
              echo "  ruby    $(ruby --version | cut -d' ' -f2)"
              echo "  bundler $(bundle --version | cut -d' ' -f3)"
              echo ""
              echo "First-time / after pulling changes:"
              echo "  npm ci && npm run build && node scripts/build-logo.mjs && bundle install"
              echo "Then:"
              echo "  bundle exec jekyll serve"
            '';
          };
        });
    };
}
