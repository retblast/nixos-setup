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
          ExecStart = "${pkgs.bash}/bin/bash -c 'echo 12-15 | tee /proc/irq/*/smp_affinity_list || true'";
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
        # Might not be very useful
        # PL1 = 45W (rated TDP for i5-12500H), PL2 = 65W (meaningful burst headroom)
        # MSR path
        # "w /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw  - - - - 45000000"
        # "w /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw  - - - - 65000000"
        # MMIO path — must match, otherwise firmware wins
        # "w /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_0_power_limit_uw - - - - 45000000"
        # "w /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_1_power_limit_uw - - - - 65000000"
      ];
    };
  };

  # Desktop Environment
  localModule.plasma.enable = true;
  localModule.plasma.minimal.enable = false;

  localModule.intel_lpmd.enable = true;
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
        <Mode>0</Mode>

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

        <EntryDelayMS>0</EntryDelayMS>
        <ExitDelayMS>0</ExitDelayMS>

        <EntryHystMS>2000</EntryHystMS>
        <ExitHystMS>3000</ExitHystMS>

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
                <EPP>170</EPP>
                <EPB>10</EPB>
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
                <EnterCPULoadThres>25</EnterCPULoadThres>
                <EntrySystemLoadThres>15</EntrySystemLoadThres>
                <EPP>119</EPP>
                <EPB>7</EPB>
                <ActiveCPUs>lp</ActiveCPUs>
                <MinPollInterval>400</MinPollInterval>
                <PollIntervalIncrement>300</PollIntervalIncrement>
                <MaxPollInterval>2000</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>1</IRQMigrate>
            </State>

            <!--
            UTIL_MODERATE restored as intermediate ladder rung.
            Transient spikes land here rather than jumping straight
            to HIGH (EPP 34). EPP stays at 119 — same as BATTERY_LIFE,
            but all cores are active and IRQ migration is off.
            -->
            <State>
                <ID>3</ID>
                <Name>UTIL_MODERATE</Name>
                <EnterCPULoadThres>55</EnterCPULoadThres>
                <EntrySystemLoadThres>35</EntrySystemLoadThres>
                <EPP>85</EPP>
                <EPB>5</EPB>
                <ActiveCPUs>all</ActiveCPUs>
                <MinPollInterval>600</MinPollInterval>
                <PollIntervalIncrement>300</PollIntervalIncrement>
                <MaxPollInterval>1500</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>-1</IRQMigrate>
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
      enable = true;
      size = 23726;
      hibernation = {
        enable = false;
        device = "/dev/mapper/${config.disko.devices.disk.internalNVME.content.partitions.RootDisk.name}";
        resumeOffset = 10828120;
      };
    };
    zram = {
      enable = false;
      size = 200;
    };
  };

  services = {
    # Might not be very useful
    # udev.extraRules = ''
    #  # More reasonable power limits
    #  SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.reasonable-power-limits-adlh-fish}/bin/reasonable-power-limits-adlh battery"
    #  SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.reasonable-power-limits-adlh-fish}/bin/reasonable-power-limits-adlh ac"
    # '';
    mysql = {
      # Enabled because of Uni
      # /run/mysqld/mysqld.sock is where the socket is
      # can be checked by running
      # $ mysql -u retblast
      # $ show variables like 'socket';
      enable = true;
      package = pkgs.mariadb;
      ensureUsers = [
        {
          name = "retblast";
          ensurePermissions = {
            "*.*" = "ALL PRIVILEGES";
          };
        }
      ];
    };
    thermald.enable = lib.mkForce false;

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
