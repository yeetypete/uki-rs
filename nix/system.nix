# NixOS configuration for the UKI initrd. systemd runs our app from the initrd.
{
  config,
  lib,
  pkgs,
  app,
  ...
}:

let
  # nixpkgs only ships qemu-common as a file under nixos/lib instead of as a package.
  qemu-common = import "${pkgs.path}/nixos/lib/qemu-common.nix" {
    inherit lib;
    inherit (pkgs) stdenv;
  };
in
{
  system.stateVersion = "26.05";
  system.nixos = {
    distroId = "uki-rs";
    distroName = "uki-rs";
  };

  boot.kernelParams = [
    "console=${qemu-common.qemuSerialDevice}"
    "panic=-1" # reboot immediately on kernel panic
    "systemd.journald.forward_to_console=1" # service logs on the console
  ];

  # Built as config.system.build.uki.
  boot.uki = {
    name = "uki-rs";
    settings.UKI = {
      # Only add our kernel parameters. The default includes init= pointing
      # to a full NixOS system, which we never boot but Nix would still build.
      Cmdline = toString config.boot.kernelParams;
      # The default would build the unused system's whole /etc.
      OSRelease = "@${config.environment.etc."os-release".source}";
    };
  };

  # No root filesystem, everything runs from the initrd.
  boot.initrd.systemd.root = null;
  boot.loader.grub.enable = false;

  # Minimize the initrd.
  services.lvm.enable = false;
  boot.initrd.systemd.tpm2.enable = false;

  boot.initrd = {
    # Only include the virtio network driver needed for QEMU, loaded by udev.
    includeDefaultModules = false;
    availableKernelModules = [
      "virtio_pci"
      "virtio_net"
    ];

    network.enable = true;

    systemd = {
      # There is no NixOS system to switch to, so stay in the initrd.
      suppressedUnits = [
        "initrd-find-nixos-closure.service"
        "initrd-parse-etc.service"
        "initrd-cleanup.service"
      ];

      storePaths = [ (lib.getExe app) ];

      services.hello = {
        description = "Hello world HTTP server";
        wantedBy = [ "initrd.target" ];
        serviceConfig = {
          ExecStart = lib.getExe app;
          DynamicUser = true;
        };
      };
    };
  };
}
