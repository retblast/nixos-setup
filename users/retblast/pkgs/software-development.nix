{ pkgs, ... }:
{

  users.users.retblast.packages = with pkgs; [
    # Android
    android-tools
    # https://github.com/NixOS/nixpkgs/issues/242322#issuecomment-2264995861
    # Text editors, IDEs
    my-vscode

    # Linux containers just in case
    toolbox
    distrobox

    # Computer Graphics
    blender

    # Compilers, configurers
    patchelf

    # Nix tooling
    nixd
    nixfmt

    # Debuggers
    gdb
    valgrind

    # Documentation tools
    # FTBFS https://github.com/NixOS/nixpkgs/pull/455354
    # zeal

    # Java libraries
    commons-io

    # Gamedev
    #unityhub # https://nixpk.gs/pr-tracker.html?pr=368851
  ];
}
