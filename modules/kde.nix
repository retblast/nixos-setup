{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.localModule;
in
{
  options.localModule = {
    plasma.enable = lib.mkEnableOption "the KDE Plasma desktop environment";
    plasma.minimal.enable = lib.mkEnableOption "a minimal KDE Plasma installation";
  };

  config = lib.mkIf cfg.plasma.enable {
    services = {
      desktopManager.plasma6.enable = true;
      colord.enable = true;
      displayManager = {
        sddm = {
          enable = false;
          wayland.enable = true;
        };
        plasma-login-manager.enable = true;
      };
    };

    # I notice it and its annoying
    #fonts.fontconfig.subpixel = {
    #  rgba = "none";
    #  lcdfilter = "default";
    #};
    programs = {
      kdeconnect.enable = true;
      partition-manager.enable = true;
      kde-pim = {
        merkuro = true;
        kontact = true;
        kmail = true;
      };
      # https://github.com/NixOS/nixpkgs/issues/348919
      # k3b.enable = true;
    };

    environment = {
      systemPackages =
        with pkgs;
        [
          # UI customization
          python3Packages.kde-material-you-colors
          klassy

          #  Extra KDE stuff
          kdePackages.filelight
          kdePackages.qtsvg
          kdePackages.kleopatra
          bibata-cursors
          kdePackages.kdevelop
          kdePackages.ksystemlog
          kdePackages.kcharselect
          kdePackages.skanpage
          kdePackages.k3b
          kdePackages.kamoso
          kdePackages.sweeper
          kdePackages.akregator
          kdePackages.kmplot
          kdePackages.kitinerary
        ]
        ++ lib.optionals (!cfg.plasma.minimal.enable) [

          # Useful
          drawy

          # Sound
          kid3-kde

          # Video players/MPV Frontends
          haruna
          vlc

          # Audio consumption
          # FTBFS https://github.com/NixOS/nixpkgs/issues/399801
          # fooyin
          kdePackages.kasts

          # Digital books
          kdePackages.arianna

          # Chat Apps
          kdePackages.neochat
          zapzap

          # Downloaders
          kdePackages.kget
          kdePackages.ktorrent

          # QT LO
          libreoffice-qt-fresh

          # AI
          kdePackages.alpaka

          # Video Production
          # https://github.com/NixOS/nixpkgs/pull/485356
          # https://github.com/NixOS/nixpkgs/issues/483540
          #kdePackages.kdenlive

          # Extras
          kdePackages.yakuake

          # Images
          krita
          kdePackages.kolourpaint
          digikam
          kdePackages.kontrast

          # Development
          kdePackages.kompare
          kdePackages.kcachegrind # kdePackages.umbrello

          # Learning
          kdePackages.kiten

          # Miscellanous
        ];
      sessionVariables = {

        # https://zamundaaa.github.io/wayland/2025/10/23/more-kms-offloading.html
        KWIN_USE_OVERLAYS = "1";
      };
    };

    # https://old.reddit.com/r/NixOS/comments/1pdtc3v/kde_plasma_is_slow_compared_to_any_other_distro/
    # https://github.com/NixOS/nixpkgs/issues/126590#issuecomment-3194531220
    nixpkgs.overlays = [
      (final: prev: {
        kdePackages = prev.kdePackages.overrideScope (
          kdeFinal: kdePrev: {
            plasma-workspace =
              let
                # the package we want to override
                basePkg = kdePrev.plasma-workspace;
                # a helper package that merges all the XDG_DATA_DIRS into a single directory
                xdgdataPkg = final.stdenv.mkDerivation {
                  name = "${basePkg.name}-xdgdata";
                  buildInputs = [ basePkg ];
                  dontUnpack = true;
                  dontFixup = true;
                  dontWrapQtApps = true;
                  installPhase = ''
                    mkdir -p $out/share
                    ( IFS=:
                      for DIR in $XDG_DATA_DIRS; do
                        if [[ -d "$DIR" ]]; then
                          ${prev.lib.getExe prev.lndir} -silent "$DIR" $out
                        fi
                      done
                    )
                  '';
                };
                # undo the XDG_DATA_DIRS injection that is usually done in the qt wrapper
                # script and instead inject the path of the above helper package
                derivedPkg = basePkg.overrideAttrs {
                  preFixup = ''
                    for index in "''${!qtWrapperArgs[@]}"; do
                      if [[ ''${qtWrapperArgs[$((index+0))]} == "--prefix" ]] && [[ ''${qtWrapperArgs[$((index+1))]} == "XDG_DATA_DIRS" ]]; then
                        unset -v "qtWrapperArgs[$((index+0))]"
                        unset -v "qtWrapperArgs[$((index+1))]"
                        unset -v "qtWrapperArgs[$((index+2))]"
                        unset -v "qtWrapperArgs[$((index+3))]"
                      fi
                    done
                    qtWrapperArgs=("''${qtWrapperArgs[@]}")
                    qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "${xdgdataPkg}/share")
                    qtWrapperArgs+=(--prefix XDG_DATA_DIRS : "$out/share")
                  '';
                };
              in
              derivedPkg;
          }
        );
      })
    ];

    # system.replaceDependencies.replacements = [
    # 	# https://bugs.kde.org/show_bug.cgi?id=479891#c114
    # 	{
    # 		oldDependency = pkgs.kdePackages.qqc2-desktop-style;
    # 		newDependency = pkgs.kdePackages.qqc2-desktop-style.overrideAttrs (old: {
    # 			# Doesn't have a patches attribute
    # 			patches = [ ./patches/qqc2-bug-report-print.patch ];
    # 		});
    # 	}
    # ];
  };
}
