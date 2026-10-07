{
  description = "Dev environment for recursing.dev (Jekyll + Vite/Tailwind/TypeScript)";

  nixConfig = {
    extra-substituters = "https://nixpkgs-ruby.cachix.org";
    extra-trusted-public-keys = "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    ruby-nix = {
      url = "github:inscapist/ruby-nix";
    };
    bundix = {
      url = "github:inscapist/bundix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    bob-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs:
    with inputs.flake-utils.lib;
      eachDefaultSystem (system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            inputs.bob-ruby.overlays.default
            (final: prev: {nodejs = prev.nodejs_24;})
          ];
        };

        rubyNix = inputs.ruby-nix.lib pkgs;

        gemset =
          if builtins.pathExists ./gemset.nix
          then import ./gemset.nix
          else {};

        gemConfig = {};

        rubyVersion = nixpkgs.lib.fileContents ./.ruby-version;

        ruby = pkgs."${rubyVersion}";

        bundixcli = inputs.bundix.packages.${system}.default;
      in rec {
        nixConfig = {
          substituters = ["https://nixpkgs-ruby.cachix.org"];
          trusted-public-keys = [
            "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM="
          ];
        };

        inherit
          (rubyNix {
            inherit gemset ruby;
            name = "recursing-dev";
            gemConfig = pkgs.defaultGemConfig // gemConfig;
            groups = ["default"];
          })
          env
          ;

        devShells = {
          default = pkgs.mkShell {
            buildInputs =
              [env bundixcli]
              ++ (with pkgs; [
                biome
                corepack_24
                typescript
                typescript-language-server
              ]);

            shellHook = ''
              echo "recursing.dev dev shell"
              echo "  node    $(node --version)"
              echo "  ruby    $(ruby --version | cut -d' ' -f2)"
              echo "  bundler $(bundle --version | cut -d' ' -f3)"
              echo ""
              echo "First-time / after pulling changes:"
              echo "  pnpm install --frozen-lockfile && pnpm run build && bundle install"
              echo "Then:"
              echo "  bundle exec jekyll serve"
            '';
          };
        };
      });
}
