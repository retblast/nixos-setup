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
        enable = false;
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
        # PL1 = 45W (rated TDP for i5-12500H), PL2 = 65W (meaningful burst headroom)
        # MSR path
        "w /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw  - - - - 45000000"
        "w /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw  - - - - 65000000"
        # MMIO path — must match, otherwise firmware wins
        "w /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_0_power_limit_uw - - - - 45000000"
        "w /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_1_power_limit_uw - - - - 65000000"
      ];
    };
  };

  # Desktop Environment
  localModule.gnome.enable = true;
  localModule.gnome.minimal.enable = false;

  localModule.intel_lpmd.enable = true;
  localModule.intel_lpmd.debug = false;
  localModule.intel_lpmd.settings = ''
    <?xml version="1.0"?>

    <!--
        Specifies the configuration data
        for Intel Energy Optimizer (LPMD) daemon.

        Target platform : Alder Lake / Raptor Lake (Family 6, Model 154)
        Design philosophy: Inspired by Intel's Lunar Lake reference config.
          - Power profiles all forced off; lpmd is driven purely by WLT hints
            with utilization monitoring as a passive, high-threshold safety net.
          - WLT_IDLE state omitted — hardware manages genuine idle natively;
            WLT_BATTERY_LIFE serves as the lightest active state instead.
          - Dedicated GFX-busy state borrowed from LNL for GPU-heavy light workloads.
          - EPP values derived from kernel patch scaling factor of 17
            (balance_power=170, balance_performance=119).
          - lp_mode_cpus hardcoded due to known ADL E-core module
            auto-detection issues in intel-lpmd.
    -->

    <Configuration>

        <!--
            Hardcoded to all E-cores (8-15).
            Auto-detection unreliable on ADL — picks one E-core module (4 cores)
            instead of the full E-core pool. See upstream issue #59.
        -->
        <lp_mode_cpus>8-15</lp_mode_cpus>

        <!--
            Mode values
            0: Cgroup v2
            1: Cgroup v2 isolate
            2: CPU idle injection
            ADL uses Mode 0 — all cores share the same die, hard isolation
            (Mode 1) offers no additional power gating benefit unlike MTL/LNL.
        -->
        <Mode>0</Mode>

        <!--
            All power profiles forced off.
            LNL design philosophy: lpmd is not triggered by power profile selection.
            WLT hints and utilization are the sole drivers of state transitions.
            The user's power profile governs EPP at the kernel level independently.
        -->
        <PerformanceDef>-1</PerformanceDef>
        <BalancedDef>-1</BalancedDef>
        <PowersaverDef>-1</PowersaverDef>

        <!--
            HFI disabled — WLT is the primary signal source.
            HFI LPM and SUV hints are redundant when WLT is active
            and add unnecessary complexity.
        -->
        <HfiLpmEnable>0</HfiLpmEnable>
        <HfiSuvEnable>0</HfiSuvEnable>

        <!--
            WLT hints: all three sources enabled.
            Hardware hints, polling, and software proxy together give lpmd
            the most complete picture of workload type.
        -->
        <WLTHintEnable>1</WLTHintEnable>
        <WLTHintPollEnable>1</WLTHintPollEnable>
        <WLTProxyEnable>1</WLTProxyEnable>

        <!--
            Utilization monitor re-enabled as a passive safety net,
            mirroring LNL philosophy.
            Entry at 15%: readily enter LPM on light load.
            Exit at 90%: only force-exit if LP cores are nearly saturated.
            In practice WLT hints will drive transitions long before
            these thresholds are reached — this is a last-resort fallback
            for cases where WLT hints misbehave or are delayed.
        -->
        <util_entry_threshold>15</util_entry_threshold>
        <util_exit_threshold>90</util_exit_threshold>

        <!--
            Entry/exit delays both 0 — let WLT and hysteresis govern timing
            rather than fixed delays.
        -->
        <EntryDelayMS>0</EntryDelayMS>
        <ExitDelayMS>0</ExitDelayMS>

        <!--
            Hysteresis enabled to prevent rapid oscillation near threshold boundaries.
            2000ms entry: ignore enter requests if recent LPM sessions were very short.
            3000ms exit: ignore exit requests if system keeps leaving LPM quickly.
            Exit slightly longer than entry — exiting has more overhead and
            the system should be confident load is sustained before restoring all cores.
        -->
        <EntryHystMS>2000</EntryHystMS>
        <ExitHystMS>3000</ExitHystMS>

        <!--
            ITMT toggled during LPM transitions.
            Allows scheduler to make better core selection decisions
            when switching between LP-only and all-core configurations.
        -->
        <IgnoreITMT>0</IgnoreITMT>

        <States>
            <CPUFamily>6</CPUFamily>
            <CPUModel>154</CPUModel>
            <CPUConfig>*</CPUConfig>

            <!--
                STATE 1 — WLT_BATTERY_LIFE (lightest active state)
                WLT_IDLE omitted: hardware manages genuine idle natively on ADL,
                and observed real-world behavior shows WLT_IDLE is only occupied
                briefly at boot before immediately transitioning here.
                This state serves as the floor for all active use.

                EPP 170 = 17x10 = balance_power on patched kernel.
                IRQ migration enabled: keeps interrupts on LP cores during light use,
                reducing spurious P-core wakeups from trackpad/I2C/USB interrupts.
                GFX threshold 50%: tolerates moderate GPU activity (compositing,
                video, browser acceleration) without blocking this state.
            -->
            <State>
                <ID>1</ID>
                <Name>WLT_BATTERY_LIFE</Name>
                <WLTType>1</WLTType>
                <EPP>170</EPP>
                <EPB>10</EPB>
                <ActiveCPUs>lp</ActiveCPUs>
                <EnterGFXLoadThres>50</EnterGFXLoadThres>
                <EntrySystemLoadThres>15</EntrySystemLoadThres>
                <EnterCPULoadThres>35</EnterCPULoadThres>
                <MinPollInterval>400</MinPollInterval>
                <PollIntervalIncrement>300</PollIntervalIncrement>
                <MaxPollInterval>1500</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>1</IRQMigrate>
            </State>

            <!--
                STATE 2 — WLT_BATTERY_LIFE_GFX_BUSY
                Borrowed from LNL's UTIL_IDLE_GFX_BUSY concept.
                Activated when GPU is heavily loaded but CPU workload
                remains light — video playback, light gaming, GPU compute.
                All cores active to service GPU driver threads and command
                submission without starving the CPU side.

                EPP 119 = 17x7 = balance_performance on patched kernel.
                Higher than pure battery life to give GPU driver threads
                the CPU headroom they need.
                GFX threshold 85%: only enter when GPU is genuinely busy,
                not just from compositing spikes.
                No CPU load threshold — GPU load is the primary gate here.
            -->
            <State>
                <ID>2</ID>
                <Name>WLT_BATTERY_LIFE_GFX_BUSY</Name>
                <WLTType>1</WLTType>
                <EPP>119</EPP>
                <EPB>7</EPB>
                <ActiveCPUs>all</ActiveCPUs>
                <EnterGFXLoadThres>85</EnterGFXLoadThres>
                <EntrySystemLoadThres>15</EntrySystemLoadThres>
                <MinPollInterval>300</MinPollInterval>
                <PollIntervalIncrement>200</PollIntervalIncrement>
                <MaxPollInterval>1000</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>-1</IRQMigrate>
            </State>

            <!--
                STATE 3 — WLT_SUSTAINED
                Meaningful sustained CPU workload. All cores active.
                EPP 85 = 17x5: more performance headroom than battery life
                but not fully unleashed.
                GFX threshold 65%: tolerates significant GPU activity
                alongside sustained CPU work.
            -->
            <State>
                <ID>3</ID>
                <Name>WLT_SUSTAINED</Name>
                <WLTType>2</WLTType>
                <EPP>85</EPP>
                <EPB>5</EPB>
                <ActiveCPUs>all</ActiveCPUs>
                <EnterGFXLoadThres>65</EnterGFXLoadThres>
                <EntrySystemLoadThres>30</EntrySystemLoadThres>
                <MinPollInterval>300</MinPollInterval>
                <PollIntervalIncrement>200</PollIntervalIncrement>
                <MaxPollInterval>1000</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>-1</IRQMigrate>
            </State>

            <!--
                STATE 4 — WLT_BURSTY
                Short unpredictable spikes. All cores active, fastest polling.
                EPP 34 = 17x2: near-performance, aggressive frequency response.
                GFX threshold 75%: high tolerance, bursty CPU work can
                coexist with significant GPU load.
                Low system threshold (35%) — bursts often spike individual
                cores without moving system average dramatically.
            -->
            <State>
                <ID>4</ID>
                <Name>WLT_BURSTY</Name>
                <WLTType>3</WLTType>
                <EPP>34</EPP>
                <EPB>2</EPB>
                <ActiveCPUs>all</ActiveCPUs>
                <EnterGFXLoadThres>75</EnterGFXLoadThres>
                <EntrySystemLoadThres>35</EntrySystemLoadThres>
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
        enable = true;
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
    udev.extraRules = ''
      # More reasonable power limits
      SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.reasonable-power-limits-adlh-fish}/bin/reasonable-power-limits-adlh battery"
      SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.reasonable-power-limits-adlh-fish}/bin/reasonable-power-limits-adlh ac"
    '';
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
