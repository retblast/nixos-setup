{config, lib, pkgs, ... }:{
  imports = [
    ./gnome.nix
    ./hyprland.nix
    ./kde.nix
    ./memory.nix
    ./intel_lpmd.nix
  ];
}