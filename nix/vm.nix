{
  lib,
  stdenv,
  path,
  runCommand,
  writeShellApplication,
  qemu_test,
  OVMF,
  uki,
}:

let
  # nixpkgs only ships qemu-common as a file under nixos/lib instead of as a package.
  qemu-common = import "${path}/nixos/lib/qemu-common.nix" { inherit lib stdenv; };
  bootFile = "BOOT${lib.toUpper stdenv.hostPlatform.efiArch}.EFI";

  esp = runCommand "uki-rs-esp" { } ''
    mkdir -p $out/EFI/BOOT
    cp ${uki} $out/EFI/BOOT/${bootFile}
  '';

  # Boot the UKI from an ESP the way firmware would, not via -kernel.
  # snapshot=on gives OVMF a writable UEFI variable store whose changes are discarded on exit.
  startCommand = lib.concatStringsSep " " [
    (qemu-common.qemuBinary qemu_test)
    "-m 512"
    "-drive if=pflash,format=raw,readonly=on,file=${OVMF.firmware}"
    "-drive if=pflash,format=raw,snapshot=on,file=${OVMF.variables}"
    "-drive if=virtio,format=raw,readonly=on,file=fat:${esp}"
  ];
in
writeShellApplication {
  name = "uki-rs-vm";
  text = ''
    if [ $# -eq 0 ]; then
      set -- -serial mon:stdio
    fi

    exec ${startCommand} -display none -no-reboot "$@"
  '';
  passthru = { inherit startCommand; };
}
