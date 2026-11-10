{
  lib,
  stdenv,
  path,
  buildPackages,
  runCommand,
  writeText,
  systemd,
  init,
  linux,
  initrd,
}:

let
  platform = stdenv.hostPlatform;
  # nixpkgs only ships qemu-common as a file under nixos/lib instead of as a package.
  qemu-common = import "${path}/nixos/lib/qemu-common.nix" { inherit lib stdenv; };
  cmdline = [
    "console=${qemu-common.qemuSerialDevice}"
    "panic=-1" # reboot immediately on kernel panic
  ];
  osRelease = writeText "os-release" ''
    ID=uki-rs
    NAME=uki-rs
    VERSION_ID=${init.version}
  '';
in
# ukify defaults to the stub from its own systemd, built for buildPlatform.
# Set --stub explicitly to the hostPlatform stub so cross builds work.
runCommand "uki-rs.efi" { } ''
  ${buildPackages.systemdUkify}/lib/systemd/ukify build \
    --linux=${linux}/${linux.target} \
    --initrd=${initrd}/initrd \
    --os-release=@${osRelease} \
    --cmdline=${lib.escapeShellArg (lib.concatStringsSep " " cmdline)} \
    --stub=${systemd}/lib/systemd/boot/efi/linux${platform.efiArch}.efi.stub \
    --output=$out
''
