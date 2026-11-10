# uki-rs

Run a Rust application from a single
[UKI](https://uapi-group.org/specifications/specs/unified_kernel_image/).

uki-rs uses Nix to package a Rust application together with a Linux kernel
into a tiny ~15 MB EFI binary. The application runs as PID 1. No init system
or Linux distribution needed!

> [!WARNING]
> This is an experimental "hello world" application only meant to serve as a
> demonstration of what's possible with Nix and UKIs.

## How it works

Nix builds a UKI containing the kernel, its command line and an initramfs
holding the application as `/init`, together with only the shared libraries it
needs.

1. The firmware boots the UKI, which starts the kernel.
2. The kernel unpacks the initramfs into memory and runs `/init` as PID 1.
3. The application mounts `/dev`, `/proc` and `/sys` by itself and runs.

```txt
uki-rs.efi
├── systemd-stub
├── .linux      kernel
├── .cmdline    kernel command line
└── .initrd
    ├── init -> /nix/store/…-uki-rs/bin/init
    └── nix/store/…   glibc and other shared libraries
```

## TODO

- [x] Boot a Rust application as PID 1 from a UKI.
- [x] VM test booting the UKI.
- [ ] Networking.
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

When running `nix run .#vm`, you should see "Hello, world!" on the serial
console.

## License

`uki-rs` is released under the [MIT License](LICENSE).
