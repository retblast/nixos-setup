let
  fixesOverlay =
    { inputs, ... }:
    (final: prev: {
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
        #postInstall = (old.postInstall or "") + ''
        #  wrapProgram $out/bin/firefox --set GTK_THEME Adwaita
        #'';
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
          # TODO: https://github.com/NixOS/nixpkgs/pull/501624
          #hyperpyyaml = scopePrev.hyperpyyaml.overrideAttrs (old: {
          #  patches = [ ./patches/unpin-ruamel-yaml.patch ];
          #  pythonRelaxDeps = [
          #    "ruamel-yaml"
          #  ];
          #  meta.broken = false;
          #});
          #ruamel-yaml = scopePrev.ruamel-yaml.overrideAttrs (old: {
          #  patches = [ ./patches/loader-max-depth.patch ];
          #});
        }
      );
      #TODO: Make a PR for this
      # Maybe it can be fixed in a different way
      gputils = prev.gputils.overrideAttrs (old: {
        env = prev.lib.optionalAttrs (!prev.stdenv.cc.isClang) {
          NIX_CFLAGS_COMPILE = "-std=gnu17";
        };
      });
      easytag = prev.easytag.overrideAttrs (old: {
        CFLAGS =
          old.CFLAGS or ""
          + " -std=c11"
          + " -Wno-error=pointer-compare"
          + " -Wno-error=cast-function-type"
          + " -Wno-error=implicit-function-declaration"
          + " -Wno-error=array-bounds"
          + " -Wno-error=enum-conversion"
          + " -Wno-error=deprecated-declarations";
        CXXFLAGS = old.CXXFLAGS or "" + " -Wno-error=deprecated-declarations";
        patches = old.patches or [ ] ++ [
          ./patches/0001-Fix-missing-strings.h-providing-strcasecmp.patch
          ./patches/0002-Fix-missing-const-qualifier.patch
        ];
      });
    });
in
fixesOverlay
