# uki-rs

Run a Rust application from a single
[UKI](https://uapi-group.org/specifications/specs/unified_kernel_image/).

uki-rs uses Nix to package a Rust application together with a Linux kernel
and systemd into a ~37 MB EFI binary. No root filesystem or Linux distribution
needed!

> [!WARNING]
> This is an experimental "hello world" application only meant to serve as a
> demonstration of what's possible with Nix and UKIs.

## How it works

Nix builds a UKI containing the kernel, its command line and a NixOS systemd
initramfs holding the application.

1. The firmware boots the UKI, which starts the kernel.
2. The kernel unpacks the initramfs into memory and runs systemd as PID 1.
3. systemd sets up the network and runs the application from the initramfs.

```txt
uki-rs.efi
├── systemd-stub
├── .linux      kernel
├── .cmdline    kernel command line
└── .initrd
    ├── init -> /nix/store/…-systemd/lib/systemd/systemd
    ├── nix/store/…-uki-rs/bin/uki-rs
    └── nix/store/…   systemd and shared libraries
```

## TODO

- [x] Boot a Rust application as PID 1 from a UKI.
- [x] VM test booting the UKI.
- [x] Networking.
- [ ] Run a GPU workload.
- [ ] Signed UKI for Secure Boot.

## Development

```sh
nix build          # build the UKI with the Rust application
nix run .#vm       # boot it in a VM (Ctrl-a x to quit)
nix run .#inspect  # list the UKI's sections and initrd contents
nix flake check    # build, lint and run the VM test
nix develop        # Rust toolchain
nix fmt            # format
```

When running `nix run .#vm`, the server listens on port 8080:

```sh
curl http://127.0.0.1:8080  # Hello, world!
```

## License

`uki-rs` is released under the [MIT License](LICENSE).
