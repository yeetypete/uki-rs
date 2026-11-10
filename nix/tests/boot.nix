{ testers, vm }:

testers.runNixOSTest {
  name = "uki-rs-boot";
  nodes = { };
  testScript = ''
    machine = create_machine("${vm.startCommand}")
    machine.start()
    machine.wait_for_console_text("Hello, world!")
    # VMs from create_machine aren't stopped at cleanup, so quit QEMU here.
    machine.crash()
  '';
}
