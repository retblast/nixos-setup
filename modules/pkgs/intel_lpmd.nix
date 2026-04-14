{
  lib,
  stdenv,
  fetchFromGitHub,

  autoreconfHook,
  pkg-config,

  # This was fixed too
  dbus,
  dbus-glib,

  glib,
  gtk-doc,
  libnl,
  libxml2,
  systemd,
  upower,

  coreutils,

  writers,
}:
# This is needed because neither intel_lpmd or thermald can read configuration files in the system put in
# /etc, for some reason.
# And, intel_lpmd doesn't have a flag to load a configuration file directly, at least until
# https://github.com/intel/intel-lpmd/issues/84 is fixed
# Accepts           <EnterGFXLoadThres>50</EnterGFXLoadThres> for gpu stuff

let
  workaround = writers.writeText "config-file.xml" ''
    <?xml version="1.0"?>

    <!--
        Intel Energy Optimizer (LPMD) — ADL/RPL configuration
        Target: Alder Lake / Raptor Lake (Family 6, Model 154)

        Signal source: pure utilization mode.
        WLT is fully disabled:
          - WLTHintEnable/WLTHintPollEnable: sysfs path
            /sys/bus/pci/devices/0000:00:04.0/workload_hint/ does not exist on ADL.
          - WLTProxyEnable: runs its own internal state machine that ignores all XML
            thresholds, maps to WLT types directly, and was observed to permanently
            classify coding+PiP workloads as WLT_BURSTY regardless of actual load.

        State selection is driven entirely by utilization:
          util_entry_threshold / util_exit_threshold  — outer LPM gate
          EntrySystemLoadThres / EnterCPULoadThres /
          EnterGFXLoadThres per state                 — inner state selection

        IMPORTANT: WLTType must be absent from all states. If present, utilization-
        based entry is disabled for that state regardless of all other settings.

        EPP scale (kernel patch, scaling factor 17):
          Power             = 221 (17x13)
          Balance Power     = 170 (17x10)
          Balance Perf      = 119 (17x7)
          Mid Perf          =  85 (17x5)
          Near Perf         =  51 (17x3)
          Performance       =  17 (17x1)

        lp_mode_cpus hardcoded: ADL E-core module auto-detection is unreliable,
        picks one 4-core module instead of the full E-core pool (upstream issue #59).

        State ladder (light to heavy):
          1. IDLE         — system nearly silent, E-cores only, EPP 170
          2. BATTERY_LIFE — light active use, E-cores only, EPP 119
          3. GFX_BUSY     — GPU saturated, CPU light, all cores, EPP 119
          4. SUSTAINED    — real CPU workload, all cores, EPP 85
          5. BURSTY       — spiky CPU load, all cores, EPP 51
    -->

    <Configuration>

        <!--
            Hardcoded to all E-cores (8-15).
            Auto-detection picks only one 4-core E-core module on ADL.
            See upstream issue #59.
        -->
        <lp_mode_cpus>8-15</lp_mode_cpus>

        <!--
            Mode 0: Cgroup v2 task migration.
            ADL cores share the same die — hard isolation (Mode 1) offers
            no additional power gating benefit unlike MTL/LNL.
        -->
        <Mode>0</Mode>

        <!--
            Performance: never enter LPM.
            Balanced: opportunistic — utilization drives transitions.
            Powersaver: always stay in LPM.
        -->
        <PerformanceDef>-1</PerformanceDef>
        <BalancedDef>0</BalancedDef>
        <PowersaverDef>1</PowersaverDef>

        <!-- HFI disabled — not functional on ADL -->
        <HfiLpmEnable>0</HfiLpmEnable>
        <HfiSuvEnable>0</HfiSuvEnable>

        <!-- WLT fully disabled — see rationale in header -->
        <WLTHintEnable>0</WLTHintEnable>
        <WLTHintPollEnable>0</WLTHintPollEnable>
        <WLTProxyEnable>0</WLTProxyEnable>

        <!--
            Outer LPM gate — controls whether lpmd attempts LPM at all.
            util_entry_threshold: system utilization must be at or below this
              value for lpmd to consider entering LPM. Empty or 0 disables
              the utilization monitor entirely.
            util_exit_threshold: if the busiest active LP core exceeds this,
              lpmd exits LPM and restores all cores immediately.

            20% entry: comfortably above observed idle+coding+PiP baseline
              (~16-20% system load) to avoid thrashing at the boundary.
            85% exit: gives E-cores substantial headroom before escalating.
        -->
        <util_entry_threshold>20</util_entry_threshold>
        <util_exit_threshold>85</util_exit_threshold>

        <EntryDelayMS>0</EntryDelayMS>
        <ExitDelayMS>0</ExitDelayMS>

        <!--
            Hysteresis prevents rapid oscillation near threshold boundaries.
            Exit longer than entry — restoring all cores has more overhead and
            the system should be confident load is sustained before doing so.
        -->
        <EntryHystMS>2000</EntryHystMS>
        <ExitHystMS>3000</ExitHystMS>

        <!-- ITMT toggled on LPM transitions for better scheduler decisions -->
        <IgnoreITMT>0</IgnoreITMT>

        <States>
            <CPUFamily>6</CPUFamily>
            <CPUModel>154</CPUModel>
            <CPUConfig>*</CPUConfig>

            <!--
                STATE 1 — IDLE
                System is nearly silent: no meaningful user-facing activity.
                E-cores only. EPP 170 = balance_power, strongly biases toward
                efficiency over frequency.
                IRQ migration on: keeps interrupts on LP cores, avoids waking
                P-cores for routine trackpad/USB/I2C interrupts.
                Entered when: system <=10%, any CPU <=20%, GFX <=30%.
                Intentionally tight — only genuine idle qualifies.
            -->
            <State>
                <ID>1</ID>
                <Name>IDLE</Name>
                <EPP>170</EPP>
                <EPB>10</EPB>
                <ActiveCPUs>lp</ActiveCPUs>
                <EnterGFXLoadThres>30</EnterGFXLoadThres>
                <EntrySystemLoadThres>10</EntrySystemLoadThres>
                <EnterCPULoadThres>20</EnterCPULoadThres>
                <MinPollInterval>600</MinPollInterval>
                <PollIntervalIncrement>400</PollIntervalIncrement>
                <MaxPollInterval>2000</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>1</IRQMigrate>
            </State>

            <!--
                STATE 2 — BATTERY_LIFE
                Light active use: user present, editor open, light background tasks.
                E-cores only. EPP 119 = balance_performance — enough headroom for
                responsive UI without burning frequency budget.
                IRQ migration on: still beneficial at this load level.
                Entered when: system <=30%, any CPU <=40%, GFX <=55%.
                GFX threshold 55% tolerates compositor and browser acceleration
                without blocking this state.
            -->
            <State>
                <ID>2</ID>
                <Name>BATTERY_LIFE</Name>
                <EPP>119</EPP>
                <EPB>7</EPB>
                <ActiveCPUs>lp</ActiveCPUs>
                <EnterGFXLoadThres>55</EnterGFXLoadThres>
                <EntrySystemLoadThres>30</EntrySystemLoadThres>
                <EnterCPULoadThres>40</EnterCPULoadThres>
                <MinPollInterval>400</MinPollInterval>
                <PollIntervalIncrement>300</PollIntervalIncrement>
                <MaxPollInterval>1500</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>1</IRQMigrate>
            </State>

            <!--
                STATE 3 — GFX_BUSY
                GPU saturated but CPU load remains light: video playback,
                light gaming, hardware-accelerated browser content, GPU compute.
                All cores active: GPU driver threads, DRM scheduler, and command
                submission need access to the full core pool.
                EPP 119 = balance_performance: GPU workloads need CPU headroom
                for driver work, not raw frequency.
                GFX threshold 85%: only enters when GPU is genuinely saturated,
                not from compositor spikes or browser scrolling.
                No CPU load threshold — GFX load is the sole gate here.
            -->
            <State>
                <ID>3</ID>
                <Name>GFX_BUSY</Name>
                <EPP>119</EPP>
                <EPB>7</EPB>
                <ActiveCPUs>all</ActiveCPUs>
                <EnterGFXLoadThres>85</EnterGFXLoadThres>
                <EntrySystemLoadThres>30</EntrySystemLoadThres>
                <MinPollInterval>300</MinPollInterval>
                <PollIntervalIncrement>200</PollIntervalIncrement>
                <MaxPollInterval>1000</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>-1</IRQMigrate>
            </State>

            <!--
                STATE 4 — SUSTAINED
                Real sustained CPU workload: compilation, encoding, heavy LSP work.
                All cores active. EPP 85 = 17x5: meaningful performance headroom
                without fully disabling frequency scaling.
                GFX threshold 65%: tolerates significant GPU activity alongside
                sustained CPU work.
                Entered when: system <=30%, any CPU <=60%, GFX <=65%.
            -->
            <State>
                <ID>4</ID>
                <Name>SUSTAINED</Name>
                <EPP>85</EPP>
                <EPB>5</EPB>
                <ActiveCPUs>all</ActiveCPUs>
                <EnterGFXLoadThres>65</EnterGFXLoadThres>
                <EntrySystemLoadThres>30</EntrySystemLoadThres>
                <EnterCPULoadThres>60</EnterCPULoadThres>
                <MinPollInterval>300</MinPollInterval>
                <PollIntervalIncrement>200</PollIntervalIncrement>
                <MaxPollInterval>1000</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>-1</IRQMigrate>
            </State>

            <!--
                STATE 5 — BURSTY
                Short unpredictable CPU spikes: keypress-triggered LSP analysis,
                JIT compilation, sudden I/O bursts.
                All cores active, fastest polling to react quickly.
                EPP 51 = 17x3: aggressive frequency response without going full
                performance mode.
                GFX threshold 75%: bursty CPU work can coexist with significant
                GPU load.
                Low system threshold (40%): bursts spike individual cores without
                necessarily moving system average much.
                Entered when: system <=40%, any CPU <=70%, GFX <=75%.
            -->
            <State>
                <ID>5</ID>
                <Name>BURSTY</Name>
                <EPP>51</EPP>
                <EPB>2</EPB>
                <ActiveCPUs>all</ActiveCPUs>
                <EnterGFXLoadThres>75</EnterGFXLoadThres>
                <EntrySystemLoadThres>40</EntrySystemLoadThres>
                <EnterCPULoadThres>70</EnterCPULoadThres>
                <MinPollInterval>200</MinPollInterval>
                <PollIntervalIncrement>100</PollIntervalIncrement>
                <MaxPollInterval>500</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>-1</IRQMigrate>
            </State>

        </States>

    </Configuration>
  '';
in
stdenv.mkDerivation (finalAttrs: {
  pname = "intel_lpmd";
  version = "0.1.0";

  src = fetchFromGitHub {
    # owner = "intel";
    owner = "maciejwieczorretman";
    repo = "intel-lpmd";
    rev = "ecf1de5829dbdea32ef9e6b21df27fe71744ad78";
    hash = "sha256-6IXHUHL8aj2Z7+TX4SrEj/mPCqt4Y6Mw3HG8neEVIIo=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config

    glib
    gtk-doc
    libnl
    # And here
    systemd
    upower
  ];

  # Here too
  buildInputs = [
    dbus
    dbus-glib
    libxml2
  ];

  patches = [
    # ./config_path_fix.patch
  ];

  postPatch = ''
      substituteInPlace src/lpmd_config.c \
        --replace-fail '#include <libxml/tree.h>' \
    '#include <libxml/tree.h>
    #include <unistd.h>
    #define FALLBACK_CONFDIR "/etc/intel_lpmd"
    #define CONFDIR (access(FALLBACK_CONFDIR, F_OK) == 0 ? FALLBACK_CONFDIR : TDCONFDIR)'
      substituteInPlace src/lpmd_config.c \
        --replace-fail 'TDCONFDIR, lpmd_config->cpu_family, lpmd_config->cpu_model, lpmd_config->tdp);' \
        'CONFDIR, lpmd_config->cpu_family, lpmd_config->cpu_model, lpmd_config->tdp);'
      substituteInPlace src/lpmd_config.c \
        --replace-fail 'TDCONFDIR, lpmd_config->cpu_family, lpmd_config->cpu_model);' \
        'CONFDIR, lpmd_config->cpu_family, lpmd_config->cpu_model);'
      substituteInPlace src/lpmd_config.c \
        --replace-fail '"%s/%s", TDCONFDIR, CONFIG_FILE_NAME' \
        '"%s/%s", CONFDIR, CONFIG_FILE_NAME'
      substituteInPlace "data/org.freedesktop.intel_lpmd.service.in" \
        --replace-fail "/bin/false" "${lib.getExe' coreutils "false"}"
        #   substituteInPlace "src/lpmd_dbus_server.c" \
        #     --replace-fail "src/intel_lpmd_dbus_interface.xml" "${placeholder "out"}/share/dbus-1/interfaces/org.freedesktop.intel_lpmd.xml"

  '';
  configureFlags = [
    # here too lmao
    "--sysconfdir=${placeholder "out"}/etc"
    "--localstatedir=/var"
    ''--with-dbus-sys-dir="${placeholder "out"}/share/dbus-1/system.d"''
    ''--with-systemdsystemunitdir="${placeholder "out"}/lib/systemd/system"''
  ];

  postInstall = ''
    install -Dm644 src/intel_lpmd_dbus_interface.xml $out/share/dbus-1/interfaces/org.freedesktop.intel_lpmd.xml

    #cp ${workaround} $out/etc/intel_lpmd/intel_lpmd_config.xml
  '';

  meta = with lib; {
    homepage = "https://github.com/intel/intel-lpmd";
    description = "Linux daemon used to optimize active idle power.";
    longDescription = ''
      Intel Low Power Model Daemon is a Linux daemon used to optimize active
      idle power. It selects a set of most power efficient CPUs based on
      configuration file or CPU topology. Based on system utilization and other
      hints, it puts the system into Low Power Mode by activate the power
      efficient CPUs and disable the rest, and restore the system from Low Power
      Mode by activating all CPUs.
    '';

    platforms = platforms.linux;
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ retblast ];

    mainProgram = "intel_lpmd";
  };
})
