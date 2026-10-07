---
title: "A note on gruvbox"
tags: [meta, design]
---

Placeholder second post — replace with real content. Exists to prove the tag
index page (`/blog/tags/meta/`) lists more than one post.


```nix
{
  description = "SXSW Chronos";

  nixConfig = {
    extra-substituters = "https://nixpkgs-ruby.cachix.org";
    extra-trusted-public-keys = "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ruby-nix = {
      url = "github:inscapist/ruby-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    bundix = {url = "github:inscapist/bundix/main";};
    flake-utils.url = "github:numtide/flake-utils";
    bob-ruby = {
      url = "github:bobvanderlinden/nixpkgs-ruby";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
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

        gemConfig = {
          faiss = attrs: {
            buildInputs = [pkgs.llvmPackages.openmp pkgs.openblas];
            dontBuild = false;
            postPatch = ''
              # Fix numo-narray detection for Nix environment
              substituteInPlace ext/faiss/extconf.rb \
                --replace 'numo = File.join(Gem.loaded_specs["numo-narray-alt"].require_path, "numo")' \
                          'numo = File.join(Gem::Specification.find_by_name("numo-narray-alt").gem_dir, "ext", "numo", "narray")'
            '';
          };
          mittens = attrs: {buildInputs = [pkgs.libstemmer];};
        };

        rubyVersion = nixpkgs.lib.fileContents ./.ruby-version;

        ruby = pkgs."${rubyVersion}".override {jemallocSupport = true;};

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
            name = "sxsw-chronos";
            gemConfig = pkgs.defaultGemConfig // gemConfig;
            groups = ["default" "development" "mover" "test" "toolbox"];
          })
          env
          ;

        devShells = {
          default = pkgs.mkShell {
            buildInputs =
              [env bundixcli]
              ++ (with pkgs; [
                act
                biome
                corepack_24
                pass
                rufo
                typescript
                typescript-language-server
              ]);
          };
        };
      });
}
```
