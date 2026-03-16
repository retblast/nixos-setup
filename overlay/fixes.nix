let
  fixesOverlay =
    { inputs, ... }:
    (final: prev: {
      # Remove the desktop application icon entries
      # Seriously, what the fuck
      lsp-plugins = prev.lsp-plugins.overrideAttrs (old: {
        preFixup = ''
          				rm -rf $out/share/applications
          				rm -rf $out/share/desktop-directories
          				rm -rf $out/etc
          			'';
      });
      python3Packages = prev.python3Packages.overrideScope (
        scopeFinal: scopePrev: {
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
      libopusenc = inputs.nixpkgs-usable-libopusenc.legacyPackages.x86_64-linux.libopusenc;
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
