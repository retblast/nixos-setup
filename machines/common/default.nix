{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./fonts.nix
    ./hardware
    ./software
  ];

  # I don't use anything other than x86_64
  nixpkgs.hostPlatform = {
    system = "x86_64-linux";
  };

  # Running on KDE, so disable it
  # TODO: Enable this only when not running KDE
  # TODO: Reconsider not disabling this when apps can look proper
  # Like Dolphin, for example.
  system.replaceDependencies.replacements = [
    # Patch freetype to have stem darkening for TTFs
    {
      oldDependency = pkgs.freetype;
      newDependency = pkgs.freetype.overrideAttrs (old: {
        patches = old.patches ++ [
          ./patches/freetype-ttf-stem-darkening.patch
          ./patches/freetype-macos-like-darkening-curve.patch
        ];
      });
    }
    # Drop QT's forced override of the CFF no-stem-darkening property,
    # so that FREETYPE_PROPERTIES governs darkening uniformly. Also drop
    # the gamma-corrected blending expectation for CFF glyphs, so that
    # Qt Widgets composites text the same way the Qt Quick scene graph
    # does (naive sRGB). Without this, CFF fonts render differently
    # between widgets apps (Dolphin) and QML apps (System Settings),
    # while TTF fonts render the same in both.
    {
      oldDependency = pkgs.kdePackages.qtbase;
      newDependency = pkgs.kdePackages.qtbase.overrideAttrs (old: {
        patches = pkgs.kdePackages.qtbase.patches ++ [
          ./patches/drop-cff-darkening-override.patch
          ./patches/drop-gamma-corrected-blending.patch
        ];
      });
    }
    {
      oldDependency = pkgs.libsForQt5.qtbase;
      newDependency = pkgs.libsForQt5.qtbase.overrideAttrs (old: {
        patches = pkgs.libsForQt5.qtbase.patches ++ [
          ./patches/drop-cff-darkening-override-qt5.patch
          ./patches/drop-gamma-corrected-blending-qt5.patch
        ];
      });
    }
  ];

  # In this place goes things that are too general or too small that putting them in their own files is just cluttering

  #TODO: consider putting high level toggles here?
  # Like, stuff like the toggle for enabling kde or gnome, so that I can put better shaped conditionals on desktop-environment.nix
  console = {
    font = "Lat2-Terminus16";
  };

  programs.fish = {
    enable = true;
    useBabelfish = true;
  };

  environment = {
    # Create a folder in /etc that has a link to the current NixOS configuration
    # Very good in case of... an accident
    etc."current-nixos".source = ./.;
    localBinInPath = true;
    shells = with pkgs; [ fish ];
    sessionVariables = {
      # QT apps look better this way
      # QT_SCALE_FACTOR_ROUNDING_POLICY = "Round";
    };
  };

  system = {
    # Determines the NixOS version whose format for stateful data will be used.
    # Upgrading this number isn't really neccessary, but possible. Read the NixOS changelogs if so.
    # I aim to keep it at the latest released NixOS version
    stateVersion = "26.05";
    # Copy the running system's configuration.nix to /run/current-system/configuration.nix
    #copySystemConfiguration = true;
    autoUpgrade = {
      # Can also use the flags knob for adding flags like --upgrade-all. --upgrade is already set, duh.
      # Disable because of the input fonts messing with the execution.
      enable = false;
      dates = "sunday";
      persistent = true;
      operation = "boot";
    };
  };
}
