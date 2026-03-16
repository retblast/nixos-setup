{
  lib,
  fetchFromGitHub,
  stdenv,
  fonttools,
  fontmake,
  python3,
}:

stdenv.mkDerivation rec {
  pname = "roboto-otf";
  version = "3.015";

  src = fetchFromGitHub {
    owner = "googlefonts";
    repo = "roboto-3-classic";
    tag = "v${version}";
    hash = "sha256-voyRfTEM+VDqdBMfpuaI6Sj6eU6feeUUkK7HD6je0x8=";
  };

  nativeBuildInputs = [
    fonttools
    fontmake
    python3
  ];

  postPatch = ''
    cd sources
    # Add missing openTypeOS2WeightClass values to UFO files
    ${python3}/bin/python ${./fix-weight-class.py}
  '';

  buildPhase = ''
    mkdir -p fonts/otf
    fontmake -m Roboto.designspace -i -o otf --output-dir fonts/otf
  '';

  installPhase = ''
    		mkdir -p $out/share/fonts/${pname}
        mkdir -p $out/share/licenses/${pname}
        mv fonts/otf/*.otf $out/share/fonts/${pname}
    		mv ../OFL.txt $out/share/licenses/${pname}
    	'';

  meta = with lib; {
    homepage = "https://github.com/googlefonts/roboto-3-classic";
    description = "Google's signature family of fonts (OTF version)";
    license = with licenses; [ ofl ];
    maintainers = with maintainers; [ retblast ];
    platforms = platforms.linux;
  };
}
