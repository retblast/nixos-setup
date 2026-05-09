{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  kdePackages,
  glib,
  nix-update-script,
  python-kde-material-you-colors,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kde-material-you-colors";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "luisbocanegra";
    repo = "kde-material-you-colors";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sN7u3jePevJnTHhQL6eAYKU2AD2QNW7VYuEHLN5RsK8=";
  };

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
  ];

  buildInputs = [
    kdePackages.kdeplasma-addons
    kdePackages.plasma-desktop
    python-kde-material-you-colors
  ];

  strictDeps = true;

  patches = [
    ../patches/kde-material-you-colors-procname.patch
  ];

  cmakeFlags = [
    (lib.cmakeFeature "Qt6_DIR" "${kdePackages.qtbase}/lib/cmake/Qt6")
    "-DINSTALL_PLASMOID=ON"
  ];

  postInstall = ''
    	substituteInPlace $out/share/plasma/plasmoids/luisbocanegra.kdematerialyou.colors/contents/ui/FullRepresentation.qml \
    		--replace "property string execName: 'kde-material-you-colors'" \
    		          "property string execName: '${lib.getExe python-kde-material-you-colors}'"

      # Put the python executable in $PATH so that it can be autostarted
      # TODO: Dunno how proper this is...
      ln -s ${lib.getExe python-kde-material-you-colors} $out/bin/
  '';

  propagatedUserEnvPkgs = [ glib ];

  dontWrapQtApps = true;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Automatic color scheme generator from your wallpaper for KDE Plasma powered by Material You";
    homepage = "https://github.com/luisbocanegra/kde-material-you-colors";
    changelog = "https://github.com/luisbocanegra/kde-material-you-colors/blob/main/CHANGELOG.md";
    license = lib.licenses.gpl2Plus;
    maintainers = with lib.maintainers; [ retblast ];
    inherit (kdePackages.kwindowsystem.meta) platforms;
  };
})
