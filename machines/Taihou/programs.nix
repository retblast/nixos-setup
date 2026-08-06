{ pkgs, lib, config, ... }:
{

  programs = {
    fish = {
    	shellInit = ''
      			if status is-interactive
      				# Commands to run in interactive sessions can go here
      			end

      			# Fish settings
      			set -gx fish_greeting ""

      			# Path tweaks
      			# Not needed because of environment.localBinInPath
      			#fish_add_path $HOME/.local/share/bin
      			# Not needed on nixOS
      			#fish_add_path /usr/sbin
      			#fish_add_path /sbin
      		'';
      		shellAliases = {
      edit-fish-config = "nano $HOME/.config/fish/config.fish";
      disable-pstate = "sudo bash -c 'echo passive >  /sys/devices/system/cpu/intel_pstate/status'";
      enable-pstate = "sudo bash -c 'echo active >  /sys/devices/system/cpu/intel_pstate/status'";
      schedutil-tweak = "sudo bash -c 'echo 0 > /sys/devices/system/cpu/cpufreq/schedutil/rate_limit_us'";
      update-grub = "sudo grub-mkconfig -o /boot/grub/grub.cfg";
      memstats = "watch -n 0.5 cat /proc/meminfo";
      mic-latency-fix = "pw-cli s 49 Props '{ params = [ \"api.alsa.headroom\" 256 ] }'";
      mirror-phone = "scrcpy -b 10M --max-fps 60 -w -S";
      normalize-MONKE = "find . -name \*.ape -execdir loudgain -a -k -s e '{}' +";
      normalize-m4a = "find . -name \*.m4a -execdir loudgain -a -k -s e '{}' +";
      vscode-folder-fix = "gio mime inode/directory org.gnome.Nautilus.desktop";
      vmware-modules-fix = "sudo CPATH=/usr/src/kernels/$(uname -r)/include/linux vmware-modconfig --console --install-all";
      gpu-stats = "sudo intel_gpu_top";
      zswap_stats = "sudo (which zswap-stats)";
      dl-music-wav = "yt-dlp -x --audio-format wav --audio-quality 0";
      dl-music = "yt-dlp -x --audio-quality 0";
      mangohud-intel-workaround = "sudo chmod o+r /sys/class/powercap/intel-rapl\:0/energy_uj && echo 'Remember to run disable-mangohud-intel-workaround!'";
      disable-mangohud-intel-workaround = "sudo chmod o-r /sys/class/powercap/intel-rapl\:0/energy_uj";
      #wav2wvc = "find . -name \*.wav -execdir wavpack --allow-huge-tags -b256 -hh -x4 -c --import-id3 -m -v -w Encoder -w Settings {} -o ~/Music/WavPack/{}.temp \; -execdir wvgain ~/Music/WavPack/{}.temp \;";
      loudgain4wavs = "find . -name \*.wav -execdir loudgain -a -k --tagmode=e '{}' \;";
      connect2phone = "scrcpy --tcpip=192.168.1.50:39241 --power-off-on-close --turn-screen-off -b 10M --disable-screensaver --stay-awake";
      update-input-font-hash-old = "nix-prefetch-url 'https://input.djr.com/build/?fontSelection=whole&a=0&g=ss&i=serif&l=serif&zero=slash&asterisk=0&braces=straight&preset=default&line-height=1.2&accept=I+do&email=&.zip' --unpack --name input-fonts-1.2";
      update-input-font-hash = "nix hash convert --to sri (update-input-font-hash-old)";
      };
    };
    gamescope = {
      enable = true;
      # https://github.com/NixOS/nixpkgs/issues/351516
      # https://discourse.nixos.org/t/unable-to-activate-gamescope-capsysnice-option/37843/15
      capSysNice = false;
    };
    steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      extraPackages = with pkgs; [
        openssl_1_1
        curl
        libssh2
        openal
        zlib
        libpng
        # https://github.com/NixOS/nixpkgs/issues/236561
        attr
        libXcursor
        libXi
        libXinerama
        libXScrnSaver
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        libkrb5
        keyutils
        pkgsi686Linux.gtk3-x11
        pkgsi686Linux.pipewire
        pkgsi686Linux.libpulseaudio
        pkgsi686Linux.libvdpau
      ];
    };
    # nix-index conflicts with this, so let's disable it.
    command-not-found.enable = false;
  };
}
