{
  description = "GPU tests with the NixOS integration test driver";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs =
    inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      genSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = genSystems (
        system:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
              cudaForwardCompat = false;
              cudaCapabilities = [ "6.1" ];
            };
            overlays = [ (import ./overlay.nix) ];
          };
        in
        {
          saxpy-test = (pkgs.testers.runNixOSTest ./saxpy.nix).overrideTestDerivation (old: {
            requiredSystemFeatures = old.requiredSystemFeatures ++ [ "cuda" ];
          });
        }
      );

    };
}
