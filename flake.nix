{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        stdenv = pkgs.stdenv;
        zig = pkgs.zig_0_13;
        test-zap = stdenv.mkDerivation {
          pname = "test-zap";
          version = "dev";

          src = ./.;

          nativeBuildInputs = [
            zig.hook
          ];

          zigBuildFlags = [
            "-Doptimize=Debug"
          ];

          postPatch = ''
            ln -s ${pkgs.callPackage ./deps.nix { }} $ZIG_GLOBAL_CACHE_DIR/p
          '';
        };
      in
      {
        # Use `nix fmt`
        formatter = treefmtEval.config.build.wrapper;

        # Use `nix flake check`
        checks = {
          inherit test-zap;
          formatting = treefmtEval.config.build.check self;
        };

        packages = {
          inherit test-zap;
          default = test-zap;
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            # Compiler
            zig

            # LSP
            pkgs.zls
            pkgs.nil
          ];

          shellHook = ''
            export PS1="\n[nix-shell:\w]$ "
          '';
        };
      }
    );
}
