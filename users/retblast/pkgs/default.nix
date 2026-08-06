{ pkgs, ... }:
{
  imports = [
    ./imports
    ./media
    ./gaming.nix
    ./internet.nix
    ./software-development.nix
    ./uni-software.nix
  ];

  users.users.retblast.packages = with pkgs; [
    # TODO: Organize better

    # AI
    whisperx
    koboldcpp
    stable-diffusion-cpp-vulkan # just for sd-cli's quantization ability

    # Virt
    virt-manager

    # Cryptocurrency
    monero-gui
    xmrig-mo

    # File compressors
    rar
    p7zip

    # Phone stuff
    scrcpy
    nmap
  ];
}
