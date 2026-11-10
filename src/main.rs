use std::io;

use rustix::mount::{MountFlags, mount};

fn main() {
    setup().expect("setup failed");

    println!("Hello, world!");

    // PID 1 must never exit, or the kernel panics.
    loop {
        std::thread::park();
    }
}

/// Mount the kernel filesystems.
fn setup() -> io::Result<()> {
    let restricted = MountFlags::NOSUID | MountFlags::NOEXEC | MountFlags::NODEV;
    mount_fs("devtmpfs", "/dev", MountFlags::NOSUID)?;
    mount_fs("proc", "/proc", restricted)?;
    mount_fs("sysfs", "/sys", restricted)?;
    Ok(())
}

/// Mount a filesystem of type `fstype` at `target`.
fn mount_fs(fstype: &str, target: &str, flags: MountFlags) -> io::Result<()> {
    std::fs::create_dir_all(target)?;
    mount(fstype, target, fstype, flags, None)?;
    Ok(())
}
