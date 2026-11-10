{
  writeShellApplication,
  systemdUkify,
  _3cpio,
  uki,
  initrd,
}:

writeShellApplication {
  name = "uki-rs-inspect";
  runtimeInputs = [
    systemdUkify
    _3cpio
  ];
  text = ''
    echo "== UKI sections =="
    echo "${uki}"
    ukify inspect ${uki}
    echo
    echo "== initrd contents =="
    echo "${initrd}/initrd"
    exec 3cpio --list --verbose ${initrd}/initrd
  '';
}
