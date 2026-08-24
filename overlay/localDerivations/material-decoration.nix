{
	pkgs,
	lib,
	stdenv,
	fetchFromGitHub,

	cmake,
	extra-cmake-modules,

	kdePackages,
}:

stdenv.mkDerivation {
	pname = "material-decoration";
	version = "unstable-2026-08-05";

	src = fetchFromGitHub {
		owner = "guiodic";
		repo = "material-decoration";
		rev = "6e0bde2a6345d584914606171d6ee5732cc6f9c9";
		hash = "sha256-d0xOn6hDSVHxVOioLKFpLBPcWABdiHmwzSXddSsUqO8=";
	};

	nativeBuildInputs = [
		cmake
		kdePackages.extra-cmake-modules
	];

	buildInputs = with kdePackages; [
		qtbase
		qttools
		kconfig
		kconfigwidgets
		kcoreaddons
		kguiaddons
		ki18n
		kiconthemes
		kwindowsystem

		kdecoration
		kwin
	];

	dontWrapQtApps = true;

	cmakeFlags = [
		"-DKDE_INSTALL_USE_QT_SYS_PATHS=ON"
	];

	meta = {
		description = "Material-ish window decoration theme for KWin";
		homepage = "https://github.com/guiodic/material-decoration";
		license = lib.licenses.gpl3Only;
		platforms = lib.platforms.linux;
	};
}