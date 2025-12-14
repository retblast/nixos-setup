{
  taihouConfig,
  pkgs,
  lib,
  ...
}:
{
  programs.gnome-shell = {
    enable = taihouConfig.services.desktopManager.gnome.enable;
    extensions = [
      # Alphabetical App Grid
      { package = pkgs.gnomeExtensions.alphabetical-app-grid; }

      # Disabled given that I now use Vitals
      # System Monitor
      # {
      #	id = "system-monitor@gnome-shell-extensions.gcampax.github.com";
      #	package = pkgs.gnome-shell-extensions;
      # }

      # GTK3 Themes
      # For adw-gtk3
      {
        id = "user-theme@gnome-shell-extensions.gcampax.github.com";
        package = pkgs.gnome-shell-extensions;
      }
      # Lock Keys
      { package = pkgs.gnomeExtensions.lock-keys; }

      # Wallpaper slideshow
      { package = pkgs.gnomeExtensions.wallpaper-slideshow; }

      # Caffeine
      { package = pkgs.gnomeExtensions.caffeine; }

      # CamPeek
      # Doesn't really work
      # { package = pkgs.gnomeExtensions.campeek; }

      # Vitals
      { package = pkgs.gnomeExtensions.vitals; }

      # Dock from dash
      # Disabled until these 2 issues are fixed!
      # https://github.com/fthx/dock-from-dash/issues/102
      # https://github.com/fthx/dock-from-dash/issues/99
      #{ package = pkgs.gnomeExtensions.dock-from-dash; }
      # ddterm
      # Re-enable once https://github.com/ddterm/gnome-shell-extension-ddterm/pull/1209 is dealt with
      #{ package = pkgs.gnomeExtensions.ddterm; }
    ];
  };

  #programs.plasma = {
  #	enable = taihouConfig.services.desktopManager.plasma.enable;
  #};
  xresources.properties =
    if taihouConfig.services.desktopManager.plasma6.enable then
      {
        "Xft.rgba" = "rgb";
        "Xft.lcdfilter" = "lcddefault";
      }
    else
      { };

  home.packages =
    if taihouConfig.services.desktopManager.gnome.enable then
      with pkgs;
      [
        # Workaround for gtk.theme.package
        adw-gtk3
      ]
    else
      [ ];

  # TODO: does this break anything in KDE?
  # Probably not
  gtk = {
    enable = taihouConfig.services.desktopManager.gnome.enable;
    theme = {
      name = "adw-gtk3";
      # package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "MoreWaita";
      package = pkgs.morewaita-icon-theme;
    };
  };

  # qt = {
  #	platformTheme.name = "qtct";
  #	style.name = "kv";
  #};

  # TODO: does this break anything in KDE?
  # Probably not
  dconf = {
    enable = taihouConfig.services.desktopManager.gnome.enable;
    settings = {

      # "com/github/amezin/ddterm" = {
      # 	panel-icon-type = "none";
      # 	transparent-background = false;
      # 	window-position = "bottom";
      # };

      "org/gnome/nautilus/list-view" = {
        default-zoom-level = "small";
      };

      "org/gnome/epiphany" = {
        incognito-search-engine = "Google";
        default-search-engine = "Google";
        show-developer-actions = true;
        always-show-full-url = true;
      };

      "org/gnome/shell/extensions/vitals" = {
        menu-centered = true;
        show-gpu = true;
        include-static-info = true;
        include-static-gpu-info = true;
        update-time = lib.hm.gvariant.mkInt32 1;
        hot-sensors = lib.hm.gvariant.mkArray lib.hm.gvariant.type.string [
          "_processor_usage_"
          "_memory_allocated_"
          "_memory_swap_used_"
          "__network-rx_max__"
          "__network-tx_max__"
          "__temperature_avg__"
          "_system_load_1m_"
        ];
      };
      "org/gnome/shell/extensions/caffeine" = {
        trigger-apps-mode = "on-active-workspace";
      };
      "net/nokyan/Resources" = {
        sidebar-details = true;
        sidebar-description = true;
        sidebar-meter-type = "ProgressBar";
        processes-show-swap = true;
      };

      "org/gnome/shell/extensions/azwallpaper" = {
        slideshow-directory = "/home/retblast/Pictures/Wallpapers";
        slideshow-slide-duration = lib.hm.gvariant.mkTuple [
          1
          0
          0
        ];
      };
      "org/gnome/nautilus" = {
        show-create-link = true;
        show-delete-permanently = true;
      };
      "org/gnome/Console" = {
        ignore-scrollback-limit = true;
      };
      "org/gnome/settings-daemon/plugins/color" = {
      };
      "org/gnome/shell/extensions/lockkeys" = {
        style = "show-hide";
      };
      "org/gnome/TextEditor" = {
        show-line-numbers = true;
        tab-width = lib.hm.gvariant.mkUint32 2;
        show-grid = true;
        highlight-current-line = true;
        show-map = true;
        restore-session = false;
      };
      "org/gnome/gnome-system-monitor" = {
        update-interval = lib.hm.gvariant.mkInt32 1000;
        show-whose-processes = "all";
      };
      "org/gnome/desktop/peripherals/mouse" = {
        speed = lib.hm.gvariant.mkDouble "-0.75";
      };
      "org/gnome/desktop/sound" = {
        allow-volume-above-100-percent = true;
      };
      "org/gnome/shell" = {
        favorite-apps = lib.hm.gvariant.mkArray lib.hm.gvariant.type.string [
          "google-chrome.desktop"
          "org.gnome.Console.desktop"
          "org.gnome.Nautilus.desktop"
          "dev.zed.Zed.desktop"
          "com.usebottles.bottles.desktop"
        ];
      };
      "system/locale" = {
        region = "es_PE.UTF-8";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Control><Alt>ntilde";
        command = "env TERM=xterm-256color fish -c 'dmmm-mouse-fix'";
        name = "DMMM mouse fix";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "F12";
        command = "kgx";
        name = "Open terminal";
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = lib.hm.gvariant.mkArray lib.hm.gvariant.type.string [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };
      "org/gnome/desktop/search-providers" = {
        enabled = "org.gnome.Weather.desktop";
      };
      "org/gnome/shell/app-switcher" = {
        current-workspace-only = false;
      };
      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
      };
      "org/gnome/shell/weather" = {
        automatic-location = true;
      };
      "org/gnome/system/location" = {
        enabled = true;
      };
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "close:appmenu";
      };
      "org/gnome/desktop/datetime" = {
        automatic-timezone = true;
      };
      "org/gnome/desktop/interface" = {
        # icon-theme = "MoreWaita";
        font-name = "system-ui 11";
        document-font-name = "system-ui 11";
        monospace-font-name = "monospace 11";
        font-hinting = "slight";
        font-rendering = "manual";
      };
    };
  };
}
