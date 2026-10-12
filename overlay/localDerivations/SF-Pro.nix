{
	lib
,	fetchurl
,	writeScript
,	stdenv
,	p7zip
,	emoji-removal
, cpio
}:

stdenv.mkDerivation rec {
	actualName = "SF-Pro";
	# Cant use this, but asked about it on reddit and telegram...
	#specialHandlingBits = {
	#	a = "SF";
	#	b = "Mono";
	#	c = "Fonts";
	#};

	# Use this instead
	specialHandlingBit1 = "SF";
	specialHandlingBit2 = "Pro";
	specialHandlingBit3 = "Fonts";

# Drop the -patched moniker as it seems to not need this anymore?
#	pname = "${actualName}-patched";
	pname = "${actualName}";
	# Doesn't really matter, just gets incremented when I update the derivation
	version = "1";

	src = fetchurl {
		url = https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg;
		hash = "sha256-loqzuLH5LC2K9h6waA9cIiTE541ZuYa/AEUCp/wBKRg=";
	};

	nativeBuildInputs = [
		p7zip
		emoji-removal
		cpio
	];

	unpackCmd = ''
	  7z x $curSrc
	  cpio -id < Payload~
	'';
	phases = "unpackPhase installPhase fixupPhase";

	installPhase = ''
		# Doesn't work due to the script bug...
		find . -name \*.otf -execdir emoji-removal {} \;
		mkdir -p $out/share/fonts/${specialHandlingBit1}${specialHandlingBit2}${specialHandlingBit3}
		find . -name \*.otf -execdir mv {} $out/share/fonts/${specialHandlingBit1}${specialHandlingBit2}${specialHandlingBit3} \;
	'';

	meta = with lib; {
		homepage = "https://developer.apple.com/fonts/";
		description = "This neutral, flexible, sans-serif typeface is the system font for iOS, iPad OS, macOS and tvOS. SF Pro features nine weights, variable optical sizes for optimal legibility, four widths, and includes a rounded variant. SF Pro supports over 150 languages across Latin, Greek, and Cyrillic scripts.";
		license = with licenses; [ unfree ];
		maintainers = with maintainers; [ retblast ];
		platforms = platforms.linux;
	};
}
