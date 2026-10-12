{
  config,
  lib,
  pkgs,
  ...
}:
let
  ssdtSource = ./patches/ssdt-x1605za-kbd.dsl;

  acpiOverrideKeyboardBacklightFix =
    pkgs.runCommand "x1605za-keyboard-backlight-acpi-override"
      {
        nativeBuildInputs = [
          pkgs.acpica-tools
          pkgs.cpio
        ];
      }
      ''
        		set -eu

        		mkdir -p build/kernel/firmware/acpi
        		cp ${ssdtSource} build/ssdt-x1605za-kbd.dsl

        		iasl \
        			-p build/kernel/firmware/acpi/ssdt-x1605za-kbd \
        			-tc \
        			build/ssdt-x1605za-kbd.dsl

        		# Only the AML table belongs in the early uncompressed cpio.
        		rm -f \
        			build/kernel/firmware/acpi/*.hex \
        			build/kernel/firmware/acpi/*.lst

        		cd build
        		find kernel -print0 \
        			| sort -z \
        			| cpio --null --quiet -o -H newc > "$out"
        	'';
in
{
  boot = {
    tmp.cleanOnBoot = true;
    initrd.prepend = lib.mkAfter [ "${acpiOverrideKeyboardBacklightFix}" ];
    kernelPackages = lib.mkForce pkgs.linux-retblast-zen;
    kernelPatches = [
      {
        # https://www.phoronix.com/news/Linux-6.2-Power-Management
        name = "Set the Intel EPP change to ADL, adapted from EPB. Check patch comment for details.";
        patch = ./patches/intel-epp-fix.patch;
      }
      {
        #
        name = "KConfig for ZSTD level";
        patch = ./patches/0001-crypto-zstd-make-default-compression-level-a-Kconfig-knob.patch;
      }
      # {
      #   # Keyboard backlight fix
      #   name = "Keyboard backlight fix";
      #   patch = ./patches/keyboard-backlight-fix.patch;
      # }
    ];
    kernelParams = [
      # Enable deep sleep
      # Eh...
      # "mem_sleep_default=deep"

      # Might be needed for suspend to ram
      # Eh...
      # "atkbd.reset=1"

      # Testing the Xe kernel driver
      # "i915.force_probe=!46a6"
      # "xe.force_probe=46a6"

      # Enable Intel IOMMU
      "intel_iommu=on"

      # Use the LITTLE cores more
      "irqaffinity=0,12-15"

      # Intel Pstate
      # "intel_pstate=passive"
    ];
    extraModprobeConfig = ''
      			# Godforsaken MT7921
      			# options mt7921e disable_aspm=Y
            # For the fingerprint sensor
            options spidev bufsiz=16642
      		'';

    # initrd.availableKernelModules = [ "" ];
    # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/tasks/filesystems/zfs.nix#L18
    # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/tasks/filesystems/zfs.nix#L19
    supportedFilesystems.zfs = lib.mkForce false;
    initrd.supportedFilesystems.zfs = lib.mkForce false;
  };
}
