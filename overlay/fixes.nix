let
  fixesOverlay =
    { inputs, ... }:
    (final: prev: {
      thermald = prev.thermald.overrideAttrs (old: {
        patches = [
          ./patches/thermald-2.5.12-accept-short-itmt-v1.patch
        ];
      });
      # TODO: apply this as overlay somehow on flake.nix
      kwin-effects-better-blur-dx =
        inputs.kwin-effects-better-blur-dx.packages.${prev.stdenv.hostPlatform.system}.default;
      # TODO: Report the adw-gtk3
      # TLDR: using adw-gtk3 on firefox makes it so that firefox
      # inherits some font settings from the theme and that
      # bleeds over to the rendered webpages
      firefox-gnome = prev.firefox.overrideAttrs (old: {
        makeWrapperArgs = old.makeWrapperArgs ++ [
          "--set"
          "GTK_THEME"
          "Adwaita"
        ];
      });
      firefox-kde = prev.firefox.override {
        nativeMessagingHosts = prev.kdePackages.plasma-browser-integration;
      };
      # Remove the desktop application icon entries
      # Seriously, what the fuck
      lsp-plugins = prev.lsp-plugins.overrideAttrs (old: {
        preFixup = ''
          				rm -rf $out/share/applications
          				rm -rf $out/share/desktop-directories
          				rm -rf $out/etc
          			'';
      });
      python313Packages = prev.python313Packages.overrideScope (
        scopeFinal: scopePrev: {
          jedi-language-server = scopePrev.jedi-language-server.overrideAttrs (old: {
            pythonRelaxDeps = [
              "jedi"
            ];
          });
        }
      );
      python3Packages = prev.python3Packages.overrideScope (
        scopeFinal: scopePrev: {
          jedi-language-server = scopePrev.jedi-language-server.overrideAttrs (old: {
            pythonRelaxDeps = [
              "jedi"
            ];
          });
          opentype-feature-freezer-fixed = scopePrev.opentype-feature-freezer.overrideAttrs (old: {
            postPatch = ''
              	substituteInPlace src/opentype_feature_freezer/__init__.py \
              		--replace "import fontTools.ttLib as ttLib" \
              "import fontTools
              import fontTools.ttLib as ttLib"
            '';
          });
        }
      );
      # TODO: Fixing the bug that makes it so gamescope lags when switching apps
      gamescope = prev.gamescope.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          # ./patches/gamescope-same-buffer-diagnostics.patch
          ./patches/gamescope-same-buffer-fix.patch
        ];
      });
    });
in
fixesOverlay
