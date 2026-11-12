{ testers, vm }:

testers.runNixOSTest {
  name = "uki-rs-boot";
  nodes = { };
  testScript = ''
    import urllib.request

    machine = create_machine("${vm.startCommand}")
    machine.start()

    def hello_world(_last_try: bool) -> bool:
        try:
            with urllib.request.urlopen("http://127.0.0.1:${toString vm.port}", timeout=5) as response:
                return response.read() == b"Hello, world!\n"
        except OSError:
            return False

    retry(hello_world, timeout_seconds=60)

    # VMs from create_machine aren't stopped at cleanup, so quit QEMU here.
    machine.crash()
  '';
}
