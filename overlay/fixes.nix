let
  fixesOverlay =
    { inputs, ... }:
    (final: prev: {
      libfprint = prev.libfprint.overrideAttrs (old: {
        patches = (old.patches or []) ++ [
          ./patches/libfprint-elanspi-04f3-3212.patch
          ./patches/libfprint-elanspi-bz3-threshold.patch
          ./patches/libfprint-elanspi-capture-tune.patch
          ./patches/libfprint-bozorth-min-computable.patch
        ];
        postInstall = (old.postInstall or "") + ''
              mkdir -p $out/bin
              cp -a examples/img-capture examples/enroll examples/verify examples/clear-storage $out/bin/
            '';


      });

      thermald = prev.thermald.overrideAttrs (old: {
        patches = [
          ./patches/thermald-2.5.12-accept-short-itmt-v1.patch
          ./patches/thermald-2.5.12-rapl-dual-path-sync.patch
        ];
      });
      # 0.56.2 lost the empty-workspace reap: markInert() exists but
      # nothing calls it, so emptied workspaces linger after focus-away
      # and confuse the shell's workspace pill (no delete dispatcher
      # exists in the Lua API). Restore it: tryReap() marks empty,
      # non-special, non-persistent, non-active workspaces inert,
      # called after a window leaves a workspace (unmap /
      # moveToWorkspace, deferred) and by a debounced sweep on every
      # workspace switch. The switch itself must not reap: the OUT
      # animation and the user's slide pass still read the demoted
      # workspace's id, and invalidating it mid-flight flips the
      # animation direction (verified live 2026-10-19).
      #
      # The strip-swipe patch adds what a 1:1 workspace swipe across
      # monitors needs: Lua bindings for the render offset, the alpha
      # and the forced rendering of a workspace, plus the renderer rule
      # that draws a force-rendered workspace on every monitor its
      # offset box touches. Without the renderer rule the strip stops
      # at the monitor border, because 0.56.2 draws a workspace only on
      # the monitor that owns it.
      hyprland = prev.hyprland.overrideAttrs (old: {
        patches = (old.patches or []) ++ [
          ./patches/hyprland-0.56.2-reap-empty-workspaces.patch
          ./patches/hyprland-0.56.2-strip-swipe.patch
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
