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

        app = pkgs.callPackage ./nix/app.nix { inherit craneLib; };
        nixos = nixpkgs.lib.nixosSystem {
          modules = [
            ./nix/system.nix
            { nixpkgs.hostPlatform = system; }
          ];
          specialArgs = { inherit app; };
        };
        initrd = nixos.config.system.build.initialRamdisk;
        uki = nixos.config.system.build.uki;
        ukiFile = "${uki}/${nixos.config.system.boot.loader.ukiFile}";
        vm = pkgs.callPackage ./nix/vm.nix { uki = ukiFile; };
        inspect = pkgs.callPackage ./nix/inspect.nix {
          inherit initrd;
          uki = ukiFile;
        };
      in
      {
        packages = {
          inherit app initrd uki;
          default = uki;
        };

        apps = {
          vm = {
            type = "app";
            program = pkgs.lib.getExe vm;
            meta.description = "Boot the UKI in a VM";
          };
          inspect = {
            type = "app";
            program = pkgs.lib.getExe inspect;
            meta.description = "List the UKI's sections and initrd contents";
          };
        };

        checks = {
          inherit app;

          clippy = craneLib.cargoClippy (
            app.commonArgs
            // {
              inherit (app) cargoArtifacts;
              cargoClippyExtraArgs = "--all-targets -- --deny warnings";
            }
          );

          fmt = craneLib.cargoFmt { inherit (app.commonArgs) src; };

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
