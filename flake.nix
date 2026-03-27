{
  description = "GPU tests with the NixOS integration test driver";

  inputs = {
    # currently obtaining this from master
    # Can switch to cached nixos-unstable when the following PR is published there:
    # https://nixpk.gs/pr-tracker.html?pr=503686
    #nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
            # We're patching the test driver to inject 2 lines of code.
            # In the future, the test driver will provide a somewhat generic
            # input for this change.
            overlays = [ (import ./overlay.nix) ];
          };

          # in the future, this should not be necessary as reqs should be
          # communicated from within the test.
          addRequiredFeatures =
            reqs: drv:
            drv.overrideTestDerivation (old: {
              requiredSystemFeatures = old.requiredSystemFeatures ++ reqs;
            });
        in
        {
          cuda-container-test = addRequiredFeatures [ "cuda" ] (
            pkgs.testers.runNixOSTest ./cuda-in-container.nix
          );

          cuda-sandbox = pkgs.callPackage ./cuda-in-sandbox.nix { };
        }
      );

    };
}
