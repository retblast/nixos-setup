{
  taihouConfig,
  pkgs,
  lib,
  ...
}:
{
  # GTK/Qt/dconf settings that serve desktop apps (Nautilus, Ptyxis, Papers, ...).
  # Previously gated on the GNOME desktop being enabled; the apps survive the
  # Hyprland migration, so these are now unconditional.
  xresources.properties = {
    "Xft.rgba" = "0";
    "Xft.lcdfilter" = "lcddefault";
    "Xft.autohint" = if taihouConfig.fonts.fontconfig.hinting.autohint then "1" else "0";
  };

  home.packages = with pkgs; [
    # GTK3 theme (GTK4 uses libadwaita)
    adw-gtk3
  ];

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3";
      # package = pkgs.adw-gtk3;
    };
    gtk4.extraConfig = {
      gtk-hint-font-metrics = false;

    };
    iconTheme = {
      name = "MoreWaita";
      package = pkgs.morewaita-icon-theme;
    };

  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    # adwaita-qt (no KDE deps)
    style.name = "adwaita";
  };

  # Batch 5 dconf trim (2026-10-14): everything consumed only by GNOME
  # Shell, gnome-settings-daemon, or apps that are no longer installed
  # (dash-to-dock, vitals, caffeine, azwallpaper, lockkeys, shell
  # favorites/app-switcher/weather, media-keys custom binds — now Hyprland
  # binds —, search-providers, power/mouse/mutter/datetime/locale/location,
  # and keys for removed apps: epiphany, Resources, Console, TextEditor,
  # gnome-system-monitor) is gone. Kept: the keys GTK apps and Nautilus
  # still read.
  dconf = {
    enable = true;
    settings = {
      "org/gtk/settings/file-chooser" = {
        show-hidden = true;
        sort-directories-first = true;
      };
      "org/gnome/nautilus/list-view" = {
        default-zoom-level = "small";
      };
      "org/gnome/nautilus" = {
        show-create-link = true;
        show-delete-permanently = true;
      };
      # App-facing: libadwaita/GTK CSD apps read this for button layout.
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "close:appmenu";
      };
      "org/gnome/desktop/interface" = {
        # Did this to work around the Chrome/Electron bug regarding
        # resolving generic font names (system-ui, sans, serif, monospace, ui-*)
        # to their actual values
        font-name = "${builtins.elemAt taihouConfig.fonts.fontconfig.defaultFonts.sansSerif 0} 10";
        document-font-name = "${builtins.elemAt taihouConfig.fonts.fontconfig.defaultFonts.sansSerif 0} 10";
        monospace-font-name = "${builtins.elemAt taihouConfig.fonts.fontconfig.defaultFonts.monospace 0} 10";
        font-hinting = "${taihouConfig.fonts.fontconfig.hinting.style}";
        font-rendering = "manual";
        gtk-enable-primary-paste = true;
        # Was set at runtime under GNOME (settings-daemon); make it declarative
        # so libadwaita and Qt apps stay dark.
        color-scheme = "prefer-dark";
      };
    };
  };
}
