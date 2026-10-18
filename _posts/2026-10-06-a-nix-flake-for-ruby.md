---
title: "A Nix flake for Ruby"
tags: [nix, ruby]
---

This is the nix config I use as a starting point for all Ruby projects.

We can't run `bundle install` here, so instead just use it to regenerate the lock file, and use [inscapist's fork of bundix](https://github.com/inscapist/bundix.git) to build a `gemset.nix`:

```sh
bundle lock && bundix && direnv reload
```

## flake.nix
```nix
{
  description = "Ruby on Nix";

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

        gemset =
          if builtins.pathExists ./gemset.nix
          then import ./gemset.nix
          else {};

        # some gems may need a little help with their dependencies. this is a real example:
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

        rubyNix = inputs.ruby-nix.lib pkgs;

        # use whatever is listed in .ruby-version
        rubyVersion = nixpkgs.lib.fileContents ./.ruby-version;

        ruby = pkgs."${rubyVersion}".override {jemallocSupport = true;};

        bundixcli = inputs.bundix.packages.${system}.default;
      in rec {

        inherit
          (rubyNix {
            inherit gemset ruby;
            name = "rails";
            gemConfig = pkgs.defaultGemConfig // gemConfig;
            # Use the 'toolbox' group for gems that I might use in development, but don't want loaded by the app
            groups = ["default" "development" "test" "toolbox"];
          }) env;

        devShells = {
          default = pkgs.mkShell {
            buildInputs =
              [env bundixcli]
              ++ (with pkgs; [
                act
                biome
                corepack_24
                rufo
                typescript
                typescript-language-server
              ]);
          };
        };
      });
}
```
