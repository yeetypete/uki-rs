{
  description = "Run a Rust application from a single UKI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.mkLib pkgs;

        init = pkgs.callPackage ./nix/init.nix { inherit craneLib; };
        initrd = pkgs.callPackage ./nix/initrd.nix { inherit init; };
        uki = pkgs.callPackage ./nix/uki.nix { inherit init initrd; };
        vm = pkgs.callPackage ./nix/vm.nix { inherit uki; };
      in
      {
        packages = {
          inherit
            init
            initrd
            uki
            vm
            ;
          default = uki;
        };

        checks = {
          inherit init;

          clippy = craneLib.cargoClippy (
            init.commonArgs
            // {
              inherit (init) cargoArtifacts;
              cargoClippyExtraArgs = "--all-targets -- --deny warnings";
            }
          );

          fmt = craneLib.cargoFmt { inherit (init.commonArgs) src; };

          boot = pkgs.callPackage ./nix/tests/boot.nix { inherit vm; };
        };

        devShells.default = craneLib.devShell {
          checks = self.checks.${system};
          packages = [ pkgs.rust-analyzer ];
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
