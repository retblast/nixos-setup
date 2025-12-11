{ config, lib, pkgs, ... }:{

	fonts = {
		#TODO: find out a way to not install freefont_ttf (gnu free fonts)
		# (because of the braille font being butt ugly)
		# I could just add a fontconfig rule to put freemono really low but eh
		enableDefaultPackages = false;
		packages = with pkgs; [

			anonymousPro
			Bitter-Pro
			noto-fonts
			# noto-fonts-emoji
			noto-fonts-emoji-blob-bin
			noto-fonts-cjk-sans
			noto-fonts-cjk-serif
			cascadia-code
			fira
			fira-mono
			fira-code
			# joypixels
			ibm-plex
			# iosevka-retblast
			manrope
			roboto
			roboto-slab
			roboto-mono
			jetbrains-mono-variable
			input-fonts
			source-sans
			source-serif
			source-code-pro
			source-han-sans
			source-han-mono
			source-han-serif
			source-han-code-jp
			victor-mono
			inconsolata
			courier-prime
			pretendard
			pretendard-jp
			pretendard-std
			ia-writer-duospace
			Playfair-Display
			ANRT-Baskervville
			terminus_font_ttf
			terminus_font

			inter-otf
			# Using commit-mono-retblast due to QT and Electron not respecting freetype font feature settings
			# commit-mono
			commit-mono-retblast
			nerd-fonts.geist-mono
			geist-font
			# SF-Mono
			# SF-Pro
			# SF-Arabic
			# SF-Compact
			# New-York

			adwaita-fonts
		];

		fontDir.enable = true;
		fontconfig = {
			cache32Bit = true;
			useEmbeddedBitmaps = false;
			hinting = {
				enable = true;
				style = "slight";
				autohint = true;
			};
			localConf = ''
				<fontconfig>
				<alias>
					<family>system-ui</family>
					<prefer>
						<family>Inter</family>
						<family>Cantarell</family>
					</prefer>
				</alias>

				<alias>
					<family>ui-sans-serif</family>
					<prefer>
						<family>Inter</family>
						<family>Cantarell</family>
					</prefer>
				</alias>

				<alias>
					<family>ui-serif</family>
					<prefer>
						<family>Roboto Slab</family>
						<family>Cantarell</family>
					</prefer>
				</alias>

				<alias>
					<family>ui-monospace</family>
					<prefer>
						<family>Input Mono Condensed</family>
						<family>Cantarell</family>
					</prefer>
				</alias>

				<match target="font">
					<test name="family" compare="eq" ignore-blanks="true">
						<string>CommitMono</string>
					</test>
					<edit name="fontfeatures" mode="append">
						<string>ss03 on</string> <!-- Smart case -->
						<string>ss04 on</string> <!-- Symbol spacing -->
						<string>ss05 on</string> <!-- Smart kerning -->
						<string>cv02 on</string> <!-- Alt g -->
						<string>cv06 on</string> <!-- Alt 6/9 -->
						<string>cv10 on</string> <!-- Alt l -->
					</edit>
				</match>

				</fontconfig>
			'';
			# TODO: Ask that these also set the ui-{whatever} font aliases.
			defaultFonts = {
				sansSerif = [
						"Inter"
						# "IBM Plex Sans"
						"Cantarell"
					];
				serif = [ "Roboto Slab" ];
				monospace = [ "Input Mono Condensed" ];
				emoji = [ "Blobmoji" ];
			};
		};
	};
}
