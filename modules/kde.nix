{config, lib, pkgs, ...}:
	let cfg = config.localModule;
	in
	{
		options.localModule = {
			plasma.enable = lib.mkEnableOption "the KDE Plasma desktop environment";
			plasma.minimal.enable = lib.mkEnableOption "a minimal KDE Plasma installation";
		};

		config = lib.mkIf cfg.plasma.enable {
			services = {
				desktopManager.plasma6.enable = true;
				colord.enable = true;
				displayManager.sddm = {
					enable = true;
					wayland.enable = true;
				};
			};
			fonts.fontconfig.subpixel = {
				rgba = "rgb";
				lcdfilter = "default";
			};
			programs = {
				kdeconnect.enable = true;
					partition-manager.enable = true;
					kde-pim = {
						merkuro = true;
						kontact = true;
						kmail = true;
					};
					# https://github.com/NixOS/nixpkgs/issues/348919
					# k3b.enable = true;
			};

			environment = {
				systemPackages = with pkgs; [
					#  Extra KDE stuff
					kdePackages.filelight
					kdePackages.qtsvg
					kdePackages.kleopatra
					bibata-cursors
					kdePackages.kdevelop
					kdePackages.ksystemlog
					kdePackages.kcharselect
					kdePackages.skanpage
					kdePackages.k3b
					kdePackages.kamoso
					kdePackages.sweeper
					kdePackages.akregator
					kdePackages.kmplot
					kdePackages.kitinerary
				] ++ lib.optionals (! cfg.plasma.minimal.enable) [
					# Sound
					kid3-kde

					# Video players/MPV Frontends
					haruna vlc

					# Audio consumption
					# FTBFS https://github.com/NixOS/nixpkgs/issues/399801
					# fooyin
					kdePackages.kasts

					# Digital books
					kdePackages.arianna

					# Chat Apps
					kdePackages.neochat zapzap
			
					# Downloaders
					kdePackages.kget kdePackages.ktorrent

					# QT LO
					libreoffice-qt-fresh

					# AI
					kdePackages.alpaka

					# Video Production
					kdePackages.kdenlive

					# Extras
					kdePackages.yakuake

					# Images
					krita kdePackages.kolourpaint digikam kdePackages.kontrast

					# Development
					kdePackages.kompare kdePackages.kcachegrind kdePackages.umbrello

					# Learning
					kdePackages.kiten

					# Miscellanous
					kbibtex
				];
				sessionVariables = {
					# System wide stem darkening
					# Testing: Inconsistent in plasma/QT
					# FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
				};
			};
			# system.replaceDependencies.replacements = [
			# 	# https://bugs.kde.org/show_bug.cgi?id=479891#c114
			# 	{
			# 		oldDependency = pkgs.kdePackages.qqc2-desktop-style;
			# 		newDependency = pkgs.kdePackages.qqc2-desktop-style.overrideAttrs (old: {
			# 			# Doesn't have a patches attribute
			# 			patches = [ ./patches/qqc2-bug-report-print.patch ];
			# 		});
			# 	}
			# ];
		};
	}
