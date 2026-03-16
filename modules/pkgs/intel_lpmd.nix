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
        Specifies the configuration data
        for Intel Energy Optimizer (LPMD) daemon.

        Target platform : Alder Lake / Raptor Lake (Family 6, Model 154)

        EPP scale (kernel patch, scaling factor 17):
          Power             = 221 (17x13)
          Balance Power     = 170 (17x10)  <- WLT_IDLE
          Balance Perf      = 119 (17x7)   <- WLT_BATTERY_LIFE / WLT_BATTERY_LIFE_GFX_BUSY
          Performance       =  17 (17x1)

        lp_mode_cpus hardcoded: ADL E-core module auto-detection is unreliable,
        picks one 4-core module instead of the full E-core pool (upstream issue #59).
    -->

    <Configuration>

        <lp_mode_cpus>8-15</lp_mode_cpus>

        <!--
            Mode 0: Cgroup v2.
            ADL cores share the same die — hard isolation (Mode 1) offers
            no additional power gating benefit unlike MTL/LNL.
        -->
        <Mode>0</Mode>

        <!--
            Performance: never enter LPM.
            Balanced: opportunistic — WLT drives transitions.
            Powersaver: always in LPM.
        -->
        <PerformanceDef>-1</PerformanceDef>
        <BalancedDef>0</BalancedDef>
        <PowersaverDef>1</PowersaverDef>

        <!-- HFI disabled — WLT is the primary signal source -->
        <HfiLpmEnable>0</HfiLpmEnable>
        <HfiSuvEnable>0</HfiSuvEnable>

        <!-- WLT: all three sources enabled for best workload classification -->
        <WLTHintEnable>1</WLTHintEnable>
        <WLTHintPollEnable>1</WLTHintPollEnable>
        <WLTProxyEnable>1</WLTProxyEnable>

        <!-- Utilization monitor disabled — WLT is the sole driver -->
        <util_entry_threshold></util_entry_threshold>
        <util_exit_threshold></util_exit_threshold>

        <EntryDelayMS>0</EntryDelayMS>
        <ExitDelayMS>0</ExitDelayMS>

        <!--
            Hysteresis: prevents rapid oscillation near threshold boundaries.
            Exit longer than entry — exiting LPM has more overhead,
            system should be confident load is sustained before restoring all cores.
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
                STATE 1 — WLT_BATTERY_LIFE
                Light active use. User is present, light workload in progress.
                Thresholds sit 10 percentage points above WLT_IDLE on every
                dimension to create clean separation and prevent oscillation.

                EPP 119 = 17x7 = balance_performance on patched kernel.
                IRQ migration enabled: still beneficial at this load level.
                GFX threshold 55%: tolerates moderate GPU activity
                (compositing, video, browser acceleration).
            -->
            <State>
                <ID>1</ID>
                <Name>WLT_BATTERY_LIFE</Name>
                <WLTType>1</WLTType>
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
                STATE 2 — WLT_BATTERY_LIFE_GFX_BUSY
                Borrowed from Intel's Lunar Lake UTIL_IDLE_GFX_BUSY concept.
                For GPU-heavy but CPU-light workloads: video playback, light gaming,
                GPU compute, hardware-accelerated browser content.

                Shares WLTType 1 with WLT_BATTERY_LIFE — lpmd differentiates
                them purely via the GFX load threshold gate.
                All cores active: GPU driver threads, DRM scheduler, and command
                submission need access to the full core pool.
                EPP 119 = 17x7: same as BATTERY_LIFE — GPU workloads need CPU
                headroom for driver work, not raw frequency.
                GFX threshold 85%: only enters when GPU is genuinely saturated,
                not triggered by compositor spikes or browser scrolling.
                No CPU load threshold — GPU load is the primary gate here.
                Polling tighter than BATTERY_LIFE: GPU workloads change quickly.
            -->
            <State>
                <ID>2</ID>
                <Name>WLT_BATTERY_LIFE_GFX_BUSY</Name>
                <WLTType>1</WLTType>
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
                STATE 3 — WLT_SUSTAINED
                Meaningful sustained CPU workload. All cores active.
                EPP 85 = 17x5: more performance headroom than battery life
                without fully unleashing the CPU.
                GFX threshold 65%: tolerates significant GPU activity
                alongside sustained CPU work. Distinct from both
                BATTERY_LIFE (55%) and BURSTY (75%).
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
                <EnterCPULoadThres>60</EnterCPULoadThres>
                <MinPollInterval>300</MinPollInterval>
                <PollIntervalIncrement>200</PollIntervalIncrement>
                <MaxPollInterval>1000</MaxPollInterval>
                <ITMTState>-1</ITMTState>
                <IRQMigrate>-1</IRQMigrate>
            </State>

            <!--
                STATE 4 — WLT_BURSTY
                Short unpredictable CPU spikes. All cores active, fastest polling.
                EPP 34 = 17x2: near-performance, aggressive frequency response.
                Low system threshold (40%): bursts spike individual cores without
                necessarily moving system average dramatically.
                GFX threshold 75%: bursty CPU work can coexist with
                significant GPU load.
            -->
            <State>
                <ID>4</ID>
                <Name>WLT_BURSTY</Name>
                <WLTType>3</WLTType>
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
    rev = "99d50c97e586a8fdd31fd6d4ede40e0bf8362bc7";
    hash = "sha256-qaVptiwhv+A3HCjnsGAcLhU+lVn6DsDW8SXxG6qDlRk=";
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

  postPatch = ''
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

    cp ${workaround} $out/etc/intel_lpmd/intel_lpmd_config.xml
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
