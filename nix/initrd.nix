{
  lib,
  makeInitrdNG,
  init,
}:

makeInitrdNG {
  name = "uki-rs-initrd";
  compressor = "zstd";
  contents = [
    {
      source = lib.getExe init;
      target = "/init";
    }
  ];
}
