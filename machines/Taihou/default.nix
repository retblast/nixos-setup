{
  config,
  inputs,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    ./filesystems.nix
    ../common
    ./boot.nix
    ./programs.nix
    ./containers
    ../../users/retblast
    ../../users/testuser
  ];

  hardware.opentabletdriver = {
    enable = true;
  };

  # override to scx_bpfland
  # services.scx.scheduler = lib.mkForce "scx_bpfland";

  #nix.settings.system-features = [ "gccarch-alderlake" ];
  # Doesn't seem to work
  #nixpkgs = {
  #  hostPlatform = {
  #    gcc = {
  #      arch = "alderlake";
  #      tune = "alderlake";
  #    };
  #    system = "x86_64-linux";
  #  };
  #};

  # When set to auto, this uses the same amount of logical threads
  # It's also the same for cores when set to 0, so processes
  # and thus cpu & memory usage can skyrocket
  # Limit this to 4, seems reasonable enough.
  nix.settings.max-jobs = 4;

  networking.hostName = "Taihou";
  systemd = {
    services = {
      bt-mouse-fix = {
        enable = true;
        description = "Fixes the usb suspend mouse problem thing.";
        after = [
          "multi-user.target"
          "powertop.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          # Using "|| true" in case
          ExecStart = "${pkgs.bash}/bin/bash -c 'echo on | tee \'/sys/bus/usb/devices/1-3/power/control\' || true'";
        };
        wantedBy = [ "multi-user.target" ];
      };

      adl-cpu-efficiency = {
        enable = false;
        description = "Set the recommended max_perf_pct for ADL as highlighted by CaC";
        after = [
          "multi-user.target"
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.bash}/bin/bash -c 'echo 75 | tee /sys/devices/system/cpu/intel_pstate/max_perf_pct'";
        };
        wantedBy = [
          "multi-user.target"
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
      };

      adl-smp-affinity-list = {
        # Do not enable when using to intel lpmd
        enable = !config.localModule.intel_lpmd.enable;
        description = "Set the smp_affinity_list to the E-cores";
        after = [
          "multi-user.target"
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          # Some IRQs can't be modified, so use || true to work around this
          ExecStart = "${pkgs.bash}/bin/bash -c 'echo 8-11 | tee /proc/irq/*/smp_affinity_list || true'";
        };
        wantedBy = [
          "multi-user.target"
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
      };

      battery-charge-threshold = {
        # Kinda messes with performance
        enable = false;
        description = "Set the battery charge threshold";
        after = [ "multi-user.target" ];
        startLimitBurst = 0;
        serviceConfig = {
          Type = "oneshot";
          Restart = "on-failure";
          ExecStart = "${pkgs.bash}/bin/bash -c 'echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold'";
        };
        wantedBy = [ "multi-user.target" ];
      };

      resume-touchpad-fix = {
        enable = false;
        description = "Fixes the touchpad after resuming from suspend.";
        after = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          # Some IRQs can't be modified, so use || true to work around this
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.kmod}/bin/rmmod hid_generic && ${pkgs.kmod}/bin/rmmod hid_multitouch && ${pkgs.kmod}/bin/modprobe hid_generic && ${pkgs.kmod}/bin/modprobe hid_multitouch'";
        };
        wantedBy = [
          "suspend.target"
          "hibernate.target"
          "hybrid-sleep.target"
        ];
      };
    };
    tmpfiles = {
      rules = [
      ];
    };
  };

  # Desktop Environment
  localModule.gnome.enable = true;
  localModule.gnome.minimal.enable = false;
  # Trying it out!
  # Keep this for the future.
  # programs.singularity-desktop = {
  #   enable = false;
  #   greeter = {
  #     enable = false;
  #   };
  # };
  # I don't really know mateoalfaro, but I ran an AI scan on the repository fwiw...
  # singularity-flake.cache.enable = false;

  localModule.intel_lpmd.enable = false;
  localModule.intel_lpmd.debug = false;
  localModule.intel_lpmd.settings = ''
    <?xml version="1.0"?>

    <!--
    Utilization-based configuration for ADL (Family 6, Model 154).
    WLT hints fully disabled. State selection is purely utilization-driven.
    EPP values use kernel patch scaling factor of 17.
    lp_mode_cpus hardcoded: ADL auto-detection picks one E-core
    module (4 cores) instead of the full pool. See upstream issue #59.
    -->

    <Configuration>

        <lp_mode_cpus>8-15</lp_mode_cpus>
        <Mode>1</Mode>

        <PerformanceDef>-1</PerformanceDef>
        <BalancedDef>0</BalancedDef>
        <PowersaverDef>1</PowersaverDef>

        <HfiLpmEnable>0</HfiLpmEnable>
        <HfiSuvEnable>0</HfiSuvEnable>

        <WLTHintEnable>0</WLTHintEnable>
        <WLTHintPollEnable>0</WLTHintPollEnable>
        <WLTProxyEnable>0</WLTProxyEnable>

        <util_entry_threshold>15</util_entry_threshold>
        <util_exit_threshold>90</util_exit_threshold>

        <EntryDelayMS>2500</EntryDelayMS>
        <ExitDelayMS>2500</ExitDelayMS>

        <EntryHystMS>2500</EntryHystMS>
        <ExitHystMS>5000</ExitHystMS>

        <IgnoreITMT>0</IgnoreITMT>

        <States>
            <CPUFamily>6</CPUFamily>
            <CPUModel>154</CPUModel>
            <CPUConfig>*</CPUConfig>

            <State>
                <ID>1</ID>
                <Name>UTIL_IDLE</Name>
                <EnterCPULoadThres>15</EnterCPULoadThres>
                <EntrySystemLoadThres>6</EntrySystemLoadThres>
                <EPP>119</EPP>
                <EPB>9</EPB>
                <ActiveCPUs>lp</ActiveCPUs>
                <MinPollInterval>500</MinPollInterval>
                <PollIntervalIncrement>400</PollIntervalIncrement>
                <MaxPollInterval>2000</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>1</IRQMigrate>
            </State>

            <State>
                <ID>2</ID>
                <Name>UTIL_BATTERY_LIFE</Name>
                <EnterCPULoadThres>20</EnterCPULoadThres>
                <EntrySystemLoadThres>15</EntrySystemLoadThres>
                <EPP>85</EPP>
                <EPB>7</EPB>
                <ActiveCPUs>lp</ActiveCPUs>
                <MinPollInterval>400</MinPollInterval>
                <PollIntervalIncrement>300</PollIntervalIncrement>
                <MaxPollInterval>3000</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>1</IRQMigrate>
            </State>

            <State>
                <ID>4</ID>
                <Name>UTIL_HIGH</Name>
                <EnterCPULoadThres>75</EnterCPULoadThres>
                <EntrySystemLoadThres>50</EntrySystemLoadThres>
                <EPP>34</EPP>
                <EPB>2</EPB>
                <ActiveCPUs>all</ActiveCPUs>
                <MinPollInterval>200</MinPollInterval>
                <PollIntervalIncrement>100</PollIntervalIncrement>
                <MaxPollInterval>500</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>-1</IRQMigrate>
            </State>

        </States>

    </Configuration>
  '';
  localModule.performance.memory = {
    zswap = {
      enable = false;
      size = 23726;
      hibernation = {
        enable = false;
        device = "/dev/mapper/${config.disko.devices.disk.internalNVME.content.partitions.RootDisk.name}";
        resumeOffset = 10828120;
      };
    };
    zram = {
      enable = true;
      size = 200;
    };
  };

  services = {
    keyd = {
      enable = true;
      keyboards = {
        default = {
          ids = [ "*" ]; # Applies to all attached keyboards
          extraConfig = ''
            [main]
            # Tapping rightalt sends greater-than. Holding it acts as a layout layer.
            rightalt = overload(altgr, S-102nd)

            [shift]
            # Tapping rightalt while holding shift sends less-than.
            rightalt = 102nd
          '';
        };
      };
    };

    mysql = {
      # Enabled because of Uni
      # /run/mysqld/mysqld.sock is where the socket is
      # can be checked by running
      # $ mysql -u retblast
      # $ show variables like 'socket';
      enable = true;
      package = pkgs.mariadb;
      settings = {
        mysqld = {
          bind-address = "127.0.0.1";
          port = 3306;
          skip-networking = false;
        };
      };
      ensureUsers = [
        {
          name = "retblast";
          ensurePermissions = {
            "*.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };

    #TODO: Testing
    # thermald.enable = lib.mkForce false;

    ollama = {
      enable = false;
      package = pkgs.ollama-sycl;
      environmentVariables = {
        OLLAMA_INTEL_GPU = "1";
      };
      loadModels = [

      ];
    };
    # Currently not feasible to run
    # 1. Laptop iGPU 2 slow :(
    # 2. Llama-cpp with vulkan is slower
    open-webui = {
      enable = false;
      port = 8080;
      environment = {
        WEBUI_AUTH = "False";
        ENABLE_OPENAI_API = "False";
        ENABLE_OLLAMA_API = "True";
        OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      };
    };
  };

  services.fprintd = {
    enable = true;
    # tod.enable = true;
  };

  environment = {
    sessionVariables = {
      # https://discourse.nixos.org/t/add-ssh-key-to-agent-at-login-using-kwallet/25175/2?u=retblast
      SSH_ASKPASS_REQUIRE = "prefer";
    };
  };

  # ARGH mouse issues
  programs.ydotool.enable = true;
}
