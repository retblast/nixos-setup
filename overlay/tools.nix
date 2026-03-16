let toolsOverlay = (final: prev: {
	intel_lpmd = prev.callPackage ../modules/pkgs/intel_lpmd.nix {};
		# Make ppd only use balance-performance
		# TODO: https://gitlab.freedesktop.org/upower/power-profiles-daemon/-/issues/151
		# TODO a test fails
		#power-profiles-daemon = prev.power-profiles-daemon.overrideAttrs (old: {
		#	patches = prev.power-profiles-daemon.patches ++ [ ./patches/ppd-intel-balance-performance.patch ];
		#});
		

	threadsFile = prev.runCommandLocal "cores-for-hardware-config" {} '' 
		mkdir $out
		nproc | tr -d '\n' | tee $out/numThreads
		echo '''$(($(nproc) / 2 ))| tr -d '\n' | tee $out/halfNumThreads
	'';
	nvtop = prev.nvtop.override {
		nvidia = false;
	};

	#TODO: Have to clone this lol
	ydotool = prev.ydotool.overrideAttrs(old: {
		src = prev.fetchFromGitHub {
			owner = "stereomato";
			repo = "ydotool";
			rev = "8e8a3d0776b59bf030c45a1458aa55473faa2400";
			hash = "sha256-MtanR+cxz6FsbNBngqLE+ITKPZFHmWGsD1mBDk0OVng=";
		};
	});


	reasonable-power-limits-adlh-fish = prev.writers.writeFishBin "reasonable-power-limits-adlh" ''
							#!/bin/env fish
							switch $argv[1]
								case battery
									echo 20000000 | tee /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
									echo 20000000 | tee /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_0_power_limit_uw
									echo 35000000 | tee /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw
									echo 35000000 | tee /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_1_power_limit_uw
									echo "Battery mode: PL1 20W / PL2 35W"

								case ac
									echo 35000000 | tee /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
									echo 35000000 | tee /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_0_power_limit_uw
									echo 60000000 | tee /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw
									echo 60000000 | tee /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_1_power_limit_uw
									echo "AC mode: PL1 35W / PL2 60W"

								case performance
									echo 55000000 | tee /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw
									echo 55000000 | tee /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_0_power_limit_uw
									echo 95000000 | tee /sys/class/powercap/intel-rapl/intel-rapl:0/constraint_1_power_limit_uw
									echo 95000000 | tee /sys/class/powercap/intel-rapl-mmio/intel-rapl-mmio:0/constraint_1_power_limit_uw
									echo "Performance mode: PL1 55W / PL2 95W"
							end
          					'';
});
in toolsOverlay
