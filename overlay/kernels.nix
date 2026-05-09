let
  kernelsOverlay = (
    final: prev: {
      # XanMod Kernel
      linux-xanmod-retblast = prev.linuxPackages_xanmod_latest.extend (
        kfinal: kprev: {
          kernel = kprev.kernel.override {
            argsOverride = {
              structuredExtraConfig =
                # Merge the zen kernel's own config with this one using the // operator
                prev.linuxPackages_xanmod_latest.kernel.structuredExtraConfig
                // (import ./kernel {
                  prev = prev;
                });
            };
            ignoreConfigErrors = true;
          };
        }
      );
      # Zen kernel
      # TODO: Find where this comes from, and how it works? But, https://github.com/shiryel/nixos-dotfiles/blob/master/overlays/overrides/linux/default.nix# helped a lot!
      linux-retblast-zen = prev.linuxPackages_zen.extend (
        kfinal: kprev: {
          kernel = kprev.kernel.override {
            argsOverride = {
              structuredExtraConfig =
                with prev.lib.kernel;
                # Merge the zen kernel's own config with this one using the // operator
                prev.linuxPackages_zen.kernel.structuredExtraConfig
                // (import ./kernel {
                  prev = prev;
                });
            };
            ignoreConfigErrors = true;
          };
        }
      );

      # Default
      linux-retblast = prev.linuxPackages_latest.extend (
        kfinal: kprev: {
          kernel = kprev.kernel.override {
            argsOverride = {
              structuredExtraConfig =
                with prev.lib.kernel;
                # Merge the kernel's own config with this one using the // operator
                prev.linuxPackages_latest.kernel.structuredExtraConfig
                // (import ./kernel {
                  prev = prev;
                });
            };
            ignoreConfigErrors = true;
          };
        }
      );
    }
  );
in
kernelsOverlay
