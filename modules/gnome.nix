{
  inputs,
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
    gnome.enable = lib.mkEnableOption "the GNOME desktop environment";
    gnome.minimal.enable = lib.mkEnableOption "a minimal GNOME setup.";
    #plasma.enable = lib.mkEnableOption "Enable the KDE Plasma desktop environment";
    #minimal.enable = lib.mkEnableOption "Build a minimal system, for like a live environment";
  };

  config = lib.mkIf (cfg.gnome.enable) {
    services = {
      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverridePackages = [ pkgs.mutter ];
        # There's a possible extra setting I could add here, but I don't know if it's necessary considering I modify font settings using fontconfing: https://www.reddit.com/r/gnome/comments/1grtn97/comment/lx9fiib/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
        # Removed 'xwayland-native-scaling' because it's annoying how it's implemented in Gnome, and I don't
        # give enough of a shit about blurry Xwayland apps honestly. Most end up working on wayland eventually
        extraGSettingsOverrides = ''
          						[org.gnome.mutter]
          						experimental-features=['scale-monitor-framebuffer' ]
          					'';
      };
      # The Gnome Display Manager
      displayManager.gdm.enable = true;
      # Extra gnome apps
      gnome = {
        core-developer-tools.enable = true;
        # I don't need this, lmao
        games.enable = false;
      };
    };
    fonts.fontconfig.subpixel = {
      rgba = "none";
      lcdfilter = "none";
    };
    programs = {
      # TODO: ask why these 2 and gnome-power-manager aren't in any of the 3 gnome toggles.
      # TODO: https://github.com/NixOS/nixpkgs/pull/368610/commits/8c17fbe4656087e9a86a573b5a0d76e939225f21
      calls.enable = false;
      # There's no "Open in Ptyxis" element in the right click menu of Files so... add it
      # Ptyxis has to be installed.
      nautilus-open-any-terminal = {
        enable = true;
        terminal = "ptyxis";
      };
    };

    environment = {
      gnome.excludePackages = with pkgs; [
      ];
      systemPackages =
        with pkgs;
        [
          # Code editor
          editide
          # Thumbnailers
          # TODO: Write about this
          gnome-epub-thumbnailer
          gnome-kra-ora-thumbnailer
          # totem-video-thumbnailer
          totem

          # gdctl
          mutter
          # Default PDF viewer
          papers
          # Miscellanous Gnome apps
          gnome-icon-theme
          gnome-tweaks
          ptyxis
          gnome-boxes
          showtime
          morewaita-icon-theme
          mission-center
          resources
          gnome-power-manager
          # This is needed for file-roller to open .debs
          binutils
          file-roller
          ghostty

          # Normal LO
          libreoffice-fresh
        ]
        ++ lib.optionals (!cfg.gnome.minimal.enable) [

          # Writing
          typesetter

          # Note Taking
          rnote

          # Fedi
          tuba

          # Extra Gnome Circle apps
          metadata-cleaner
          warp
          wike
          gnome-solanum
          newsflash
          gtg
          gnome-graphs

          # Font management
          fontforge-gtk

          # AI
          alpaca
          newelle

          # Chat apps
          fractal

          # Downloaders
          fragments

          # Digital books (epubs, manga)
          foliate

          # Digital media players/readers/streamers/frontends
          gapless
          gthumb
          celluloid

          # Images
          pinta
          gnome-obfuscate
          eyedropper # upscaler

          # Video
          # pitivi

          # Download manager
          varia
        ];
    };

    nixpkgs.overlays = [
      (self: super: {
        zoom-us = super.zoom-us.override {
          gnomeXdgDesktopPortalSupport = true;
        };

        # TODO: Update manually to version 105
        # Update this manually upstream someday
        gnomeExtensions = super.gnomeExtensions // {
          dash-to-dock = super.gnomeExtensions.dash-to-dock.override {
            version = "105";
            metadata = "ewogICJfZ2VuZXJhdGVkIjogIkdlbmVyYXRlZCBieSBTd2VldFRvb3RoLCBkbyBub3QgZWRpdCIsCiAgImRlc2NyaXB0aW9uIjogIkEgZG9jayBmb3IgdGhlIEdub21lIFNoZWxsLiBUaGlzIGV4dGVuc2lvbiBtb3ZlcyB0aGUgZGFzaCBvdXQgb2YgdGhlIG92ZXJ2aWV3IHRyYW5zZm9ybWluZyBpdCBpbiBhIGRvY2sgZm9yIGFuIGVhc2llciBsYXVuY2hpbmcgb2YgYXBwbGljYXRpb25zIGFuZCBhIGZhc3RlciBzd2l0Y2hpbmcgYmV0d2VlbiB3aW5kb3dzIGFuZCBkZXNrdG9wcy4gU2lkZSBhbmQgYm90dG9tIHBsYWNlbWVudCBvcHRpb25zIGFyZSBhdmFpbGFibGUuIiwKICAiZ2V0dGV4dC1kb21haW4iOiAiZGFzaHRvZG9jayIsCiAgIm5hbWUiOiAiRGFzaCB0byBEb2NrIiwKICAib3JpZ2luYWwtYXV0aG9yIjogIm1pY3hneEBnbWFpbC5jb20iLAogICJzaGVsbC12ZXJzaW9uIjogWwogICAgIjQ1IiwKICAgICI0NiIsCiAgICAiNDciLAogICAgIjQ4IiwKICAgICI0OSIsCiAgICAiNTAiCiAgXSwKICAidXJsIjogImh0dHBzOi8vbWljaGVsZWcuZ2l0aHViLmlvL2Rhc2gtdG8tZG9jay8iLAogICJ1dWlkIjogImRhc2gtdG8tZG9ja0BtaWN4Z3guZ21haWwuY29tIiwKICAidmVyc2lvbiI6IDEwNQp9";
            sha256 = "0bzsl74m6vxl1clzjipqcibn8p07n3azy4n2v47imf2bb80kbp5p";
          };
        };

        start-ollama-on-demand-fish = super.writers.writeFishBin "start-ollama-on-demand" ''
          						# Need to write a script that starts ollama-intel-gpu, waits until it's finished
          						# And then starts alpaca.
          						# When alpaca is closed, the script stops ollama-intel-gpu

          						systemctl start --user ollama-intel-gpu.service

          						# TODO: Need to figure out how to properly detect that ollama is already listening
          						sleep 5

          						alpaca

          						systemctl stop --user ollama-intel-gpu.service
          					'';

        wike = super.callPackage ./wike.nix { };

        # TODO: until https://github.com/ollama/ollama/pull/8072 is fixed
        # alpaca = super.alpaca.overrideAttrs (old: {
        # 	postInstall = ''
        # 		substituteInPlace $out/share/applications/com.jeffser.Alpaca.desktop --replace-fail Exec=alpaca Exec=${pkgs.start-ollama-on-demand-fish}/bin/start-ollama-on-demand
        # 	'';
        # });
      })
    ];
  };
}
