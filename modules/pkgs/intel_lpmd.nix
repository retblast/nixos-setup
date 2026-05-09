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

stdenv.mkDerivation (finalAttrs: {
  pname = "intel_lpmd";
  version = "0.1.0";

  src = fetchFromGitHub {
    # owner = "intel";
    owner = "intel";
    repo = "intel-lpmd";
    rev = "876db2042df2c168a7ff68f91c2f8c152f4e99a8";
    hash = "sha256-6maTFZL7cfvXg89bUNggj9X2HBBpVSVZmrIroM9zqYc=";
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
