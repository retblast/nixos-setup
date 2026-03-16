{ pkgs, ... }:
{
  users.users.retblast.packages = with pkgs; [
    # Windows related stuff
    wineWow64Packages.stagingFull
    dxvk
    winetricks
    bottles

    # Games & Fun
    protontricks
    sl
    protonplus

    # Emulators
    dolphin-emu
    ppsspp-sdl-wayland # pcsx2
  ];
}
