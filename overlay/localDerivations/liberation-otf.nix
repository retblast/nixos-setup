{
  lib,
  fetchFromGitHub,
  stdenv,
  fonttools,
  fontforge,
}:

stdenv.mkDerivation rec {
  pname = "liberation_ttf";
  version = "2.1.5";

  src = fetchFromGitHub {
    owner = "liberationfonts";
    repo = "liberation-fonts";
    tag = "${version}";
    hash = "sha256-Wg1uoD2k/69Wn6XU+7wHqf2KO/bt4y7pwgmG7+IUh4Q=";
  };

  nativeBuildInputs = [
    fonttools
    fontforge
  ];

  buildPhase = ''
    mkdir -p build/otf
    for sfd in src/*.sfd; do
        base=$(basename "$sfd" .sfd)
        echo "Generating build/otf/$base.otf..."
        fontforge -lang=ff -c "Open('$sfd'); Generate('build/otf/$base.otf')"
    done
  '';

  installPhase = ''
    		mkdir -p $out/share/fonts/${pname}
        mkdir -p $out/share/licenses/${pname}
        mv build/otf/*.otf $out/share/fonts/${pname}
    		mv LICENSE $out/share/licenses/${pname}
    	'';

  meta = with lib; {
    homepage = "https://github.com/liberationfonts/liberation-fonts";
    description = "Font family which aims at metric compatibility with Arial, Times New Roman, and Courier New. OTF Version.";
    license = with licenses; [ ofl ];
    maintainers = with maintainers; [ retblast ];
    platforms = platforms.linux;
  };
}
