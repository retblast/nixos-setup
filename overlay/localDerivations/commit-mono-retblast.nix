{
  stdenvNoCC,
  commit-mono-retblast-script,
  commit-mono,
  python3,
  fonttools,
}:
stdenvNoCC.mkDerivation rec {
  pname = "${commit-mono.pname}-retblast";
  version = "${commit-mono.version}";

  # Copy the source from commit-mono
  src = commit-mono.src;
  nativeBuildInputs = [
    fonttools
    python3
  ];

  dontConfigure = true;
  dontPatch = true;
  dontBuild = true;
  dontFixup = true;
  doCheck = false;
  installPhase =  ''
        # No longer using OTFs
        rm -rf $out/share/fonts/opentype
        # ${commit-mono-retblast-script}/bin/cmsc --srcPath=${commit-mono}/share/fonts/opentype --localPath=$out/share/fonts/opentype --inputFontFormat=otf --outputFontFormat=otf
        ${commit-mono-retblast-script}/bin/cmsc --srcPath=${commit-mono}/share/fonts/truetype --localPath=$out/share/fonts/truetype --inputFontFormat=ttf --outputFontFormat=ttf
        for font in "$out"/share/fonts/truetype/*.ttf "$out"/share/fonts/opentype/*.otf; do
    			[ -e "$font" ] || continue
    			${python3}/bin/python ${./bake-line-height.py} "$font"
    		done
  '';
}
