# GPU/CUDA in the NixOS integration test driver

This repository contains everything needed to run CUDA inside the NixOS integration test driver.

- To learn how to configure your system and run this, see [Getting started](#getting-started)
- In the section [Necessary patches](#necessary-patches), we explain the residual things that are not (*yet*!) in nixpkgs.

## [Getting started]

To run CUDA inside the sandbox, a list of host paths need to be mapped into the sandbox.
Hence, the first step is configuring the host.

### Host configuration

At first, make sure that your Nix daemon is configured to run [the relatively new NixOS integration test container feature](https://nixcademy.com/posts/faster-cheaper-nixos-integration-tests-with-containers/) at all:

```nix
{
  nix.settings.auto-allocate-uids = true;

  nix.settings.experimental-features = [
    "auto-allocate-uids"
    "cgroups"
  ];

  nix.settings.extra-system-features = [
    "uid-range"
  ];

  # this one is only necessary vor container <-> VM networking
  nix.settings.extra-sandbox-paths = [
    "/dev/net"
  ];
}
```

#### NVIDIA

On NVIDIA hosts, also enable the following configuration to ensure the right paths are visible inside the sandbox:

```nix
{
  hardware.graphics.enable = true;

  # ensure proprietary driver
  boot.blacklistedKernelModules = [ "nouveau" ];
  services.xserver.videoDrivers = [ "nvidia" ];

  # ensure proprietary and performance settings and latest driver
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  # ensure sandbox paths
  programs.nix-required-mounts = {
    enable = true;
    presets.nvidia-gpu.enable = true;
  };
}
```

#### [AMD]

Similar to the NVIDIA scenario, but slightly different configuration is necessary on AMD GPU hosts.

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

#### Running GPU/CUDA stuff in the sandbox

To check if your nix daemon sandbox settings are correct, first run the minimal [saxpy](https://developer.nvidia.com/blog/six-ways-saxpy/) demo app in the sandbox without the NixOS integration test driver:

```console
$ nix build -L .#cuda-sandbox
saxdemo> Start
saxdemo> Runtime version: 12090
saxdemo> Driver version: 13010
saxdemo> Host memory initialized, copying to the device
saxdemo> Scheduled a cudaMemcpy, calling the kernel
saxdemo> Scheduled a kernel call
saxdemo> Max error: 0.000000
```

If the output looks roughly like this without errors, your Nix sandbox works with CUDA!

To run the minimal saxpy demo app in the prepared minimal container test, run:

```console
$ nix build -L .#cuda-container-test-nvidia
# ...
vm-test-run-saxpy-cuda-test> container: (finished: must succeed: saxpy 2>&1, in 3.38 seconds)
vm-test-run-saxpy-cuda-test> (finished: run the VM test script, in 3.38 seconds)
vm-test-run-saxpy-cuda-test> test script finished in 3.41s
vm-test-run-saxpy-cuda-test> cleanup
# ...
```

The same test but prepared for AMD GPUs exists as attribute `.#cuda-container-test-amd`.

## [Necessary patches]

### GPU support in the NixOS test driver

The foregoing work to upstream the necessary capabilities in nixpkgs happened in these PRs, which already **have** been merged:

- [`nixos/nspawn-container: init a new nspawn-container profile` #470248](https://github.com/NixOS/nixpkgs/pull/470248)
- [`nixos/test-driver: add support for nspawn containers` #478109 ](https://github.com/NixOS/nixpkgs/pull/478109)
- [`nixos/doc: document systemd-nspawn test containers` #479968](https://github.com/NixOS/nixpkgs/pull/479968)
- [`nixos-test-driver: Make overridable` #503686](https://github.com/NixOS/nixpkgs/pull/503686)

This work implements containers in the test driver but does not yet allow for everything.

What's missing are the following two things:

- the test driver needs to be patched to provide certain `/run/...` paths from the host sandbox to the container
  - this flake uses the following [overlay.nix file to inject this change](./overlay.nix)
- it is necessary to attach `"cuda"` as a required feature to the test derivation
  - this flake does this [here](https://github.com/applicative-systems/nixos-gpu-tests/blob/main/flake.nix#L48)

For you as an outside user of this feature, this means:

1. Use this [overlay.nix](./overlay.nix) when importing nixpkgs ([like here](https://github.com/applicative-systems/nixos-gpu-tests/blob/main/flake.nix#L36))
2. Add the `"cuda"` feature to the required list of your GPU test derivation ([like here](https://github.com/applicative-systems/nixos-gpu-tests/blob/main/flake.nix#L48))

These patches will likely disappear in the future - we will keep this repository up2date.

### Sandbox configuration with AMD and ZLUDA

*(ignore this section if you are only interested in NVIDIA)*

The configuration snippet in the [AMD](#amd) section will only work with upstream nixpkgs after the following PRs have been finalized and merged:

- [`nix-required-mounts: fix paths` #500971](https://github.com/NixOS/nixpkgs/pull/500971)
  - This PR fixes bugs in `nix-required-mounts`. This application is being used as a prebuild hook that educates the nix daemon about the necessary paths in the sandbox to provde access to the GPU and libraries.
- [`programs.nix-required-mounts.profiles.zluda.enable: init` #501095](https://github.com/NixOS/nixpkgs/pull/501095)
  - This PR introduces a handy helper configuration attribute to automatically configure `nix-required-mounts` for AMD GPUs.
