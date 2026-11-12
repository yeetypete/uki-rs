{ craneLib }:

let
  commonArgs = {
    src = craneLib.cleanCargoSource ../.;
    strictDeps = true;
  };
  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;
    passthru = { inherit commonArgs cargoArtifacts; };
    meta.mainProgram = "uki-rs";
  }
)
