{
  lib,
  fetchFromGitHub,
  stdenv,
  fontmake,
}:

stdenv.mkDerivation rec {
  pname = "jetbrains-mono-otf";
  version = "2.304";

  src = fetchFromGitHub {
    owner = "JetBrains";
    repo = "JetBrainsMono";
    rev = "cd5227bd1f61dff3bbd6c814ceaf7ffd95e947d9";
    hash = "sha256-SW9d5yVud2BWUJpDOlqYn1E1cqicIHdSZjbXjqOAQGw=";
  };

  nativeBuildInputs = [
    fontmake
  ];

  buildPhase = ''
    fontmake -g sources/JetBrainsMono.glyphs -o otf -i
    fontmake -g sources/JetBrainsMono-Italic.glyphs -o otf -i
  '';

  installPhase = ''
    		mkdir -p $out/share/fonts/${pname}
        mkdir -p $out/share/licenses/${pname}
        mv instance_otf/*.otf $out/share/fonts/${pname}
    		mv OFL.txt -t $out/share/licenses/${pname}
    	'';

  meta = with lib; {
    homepage = "https://github.com/JetBrains/JetBrainsMono";
    description = "Distribution site for Noto fonts.";
    license = with licenses; [ ofl ];
    maintainers = with maintainers; [ retblast ];
    platforms = platforms.linux;
  };
}
