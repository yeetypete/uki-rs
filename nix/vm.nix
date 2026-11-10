{
  lib,
  stdenv,
  path,
  writeShellApplication,
  qemu_test,
  OVMF,
  uki,
}:

let
  # nixpkgs only ships qemu-common as a file under nixos/lib instead of as a package.
  qemu-common = import "${path}/nixos/lib/qemu-common.nix" { inherit lib stdenv; };
  bootFile = "BOOT${lib.toUpper stdenv.hostPlatform.efiArch}.EFI";
in
# Boot the UKI from an ESP the way firmware would, not via -kernel.
writeShellApplication {
  name = "uki-rs-vm";
  text = ''
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    mkdir -p "$tmp/esp/EFI/BOOT"
    cp ${uki} "$tmp/esp/EFI/BOOT/${bootFile}"
    install -m 644 ${OVMF.variables} "$tmp/vars.fd"

    if [ $# -eq 0 ]; then
      set -- -serial mon:stdio
    fi

    ${qemu-common.qemuBinary qemu_test} \
      -m 512 \
      -display none \
      -no-reboot \
      -drive if=pflash,format=raw,readonly=on,file=${OVMF.firmware} \
      -drive if=pflash,format=raw,file="$tmp/vars.fd" \
      -drive if=virtio,format=raw,readonly=on,file=fat:"$tmp/esp" \
      "$@"
  '';
}
