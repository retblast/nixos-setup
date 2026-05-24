{
  config,
  lib,
  pkgs,
  ...
}:
{

  hardware.intel-gpu-tools.enable = true;
  # GPU support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      # HW media acceleration
      vpl-gpu-rt
      intel-media-driver

      # Compute
      intel-compute-runtime
      level-zero
      # Mangohud layers
      mangohud
    ];
    extraPackages32 = with pkgs; [
      # HW media acceleration
      driversi686Linux.intel-media-driver

      # Mangohud layers
      pkgsi686Linux.mangohud
    ];
  };
}
