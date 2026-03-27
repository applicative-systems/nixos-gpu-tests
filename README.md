# GPU/CUDA in the NixOS integration test driver

This repository contains everything needed to run CUDA inside the NixOS integration test driver.

## Getting started

To run CUDA inside the sandbox, a list of host paths need to be mapped into the sandbox.
Hence, the first step is configuring the host.

### Host configuration

#### AMD

On AMD devices, ZLUDA and paths need to be configured.

This configuration snippet, based on the not-yet-upstreamed [nixpkgs branch](https://github.com/tfc/nixpkgs/tree/zluda-profile), contains the minimal needed configuration for AMD devices:

```nix
{
  hardware.graphics.enable = true;
  hardware.amdgpu.zluda.enable = true;

  programs.nix-required-mounts = {
    enable = true;
    presets.zluda.enable = true;
  };
}
```
