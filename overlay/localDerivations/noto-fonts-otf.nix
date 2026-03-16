{
  lib,
  fetchFromGitHub,
  stdenv,
}:

stdenv.mkDerivation rec {
  pname = "noto-fonts-otf";
  version = "2026.02.01";

  src = fetchFromGitHub {
    owner = "notofonts";
    repo = "notofonts.github.io";
    rev = "0dd6225462349adf863bf50d1a69ead98342e14d";
    hash = "sha256-vhu3jojG6QlgY5gP4bCbpJznsQ1gExAfcRT42FcZUp4=";
  };

  installPhase = ''
    		mkdir -p $out/share/fonts/${pname}
        mkdir -p $out/share/licenses/${pname}
        mv fonts/*/unhinted/otf/*.otf $out/share/fonts/${pname}
    		mv LICENSE -t $out/share/licenses/${pname}
    	'';

  meta = with lib; {
    homepage = "https://github.com/notofonts/notofonts.github.io";
    description = "Distribution site for Noto fonts.";
    license = with licenses; [ asl20 ];
    maintainers = with maintainers; [ retblast ];
    platforms = platforms.linux;
  };
}
