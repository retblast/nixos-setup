let
  kdeExtrasOverlay = (
    final: prev: {
      kde-material-you-colors = final.callPackage ./localDerivations/kde-material-you-colors.nix {
        python-kde-material-you-colors = final.python3Packages.kde-material-you-colors;
      };
      # Technically should be a fix but it's for kde-material-you-colors
      python3Packages = prev.python3Packages.overrideScope (
        scopeFinal: scopePrev: {
          # TODO: https://github.com/NixOS/nixpkgs/pull/504351/commits/5e2e65eaab16ac1ddad8e4decf4b378baf93f9d6
          kde-material-you-colors = scopePrev.kde-material-you-colors.overrideAttrs (old: rec {
            patches = [
              ../overlay/patches/kde-material-you-colors-wcag-repair-pass.patch
              # ../overlay/patches/kde-material-you-colors-kde-role-matrix.patch
            ];
            postInstall = ''
                substituteInPlace $out/lib/python3.13/site-packages/kde_material_you_colors/data/kde-material-you-colors.desktop \
                  --replace "Exec=kde-material-you-colors" \
                  "Exec=$out/bin/kde-material-you-colors"

              substituteInPlace $out/lib/python3.13/site-packages/kde_material_you_colors/data/kde-material-you-colors-stop.desktop \
                  --replace "Exec=kde-material-you-colors" \
                  "Exec=$out/bin/kde-material-you-colors"
            '';
          });
        }
      );
    }
  );
in
kdeExtrasOverlay
