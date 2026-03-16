{
  stdenvNoCC,
  commit-mono-retblast-script,
  commit-mono,
}:
stdenvNoCC.mkDerivation rec {
  pname = "${commit-mono.pname}-retblast";
  version = "${commit-mono.version}";

  # Copy the source from commit-mono
  src = commit-mono.src;

  dontConfigure = true;
  dontPatch = true;
  dontBuild = true;
  dontFixup = true;
  doCheck = false;
  installPhase = commit-mono.installPhase + ''
    # No longer using OTFs
    rm -rf $out/share/fonts/opentype
    # ${commit-mono-retblast-script}/bin/cmsc --srcPath=${commit-mono}/share/fonts/opentype --localPath=$out/share/fonts/opentype --inputFontFormat=otf --outputFontFormat=otf
    ${commit-mono-retblast-script}/bin/cmsc --srcPath=${commit-mono}/share/fonts/truetype --localPath=$out/share/fonts/truetype --inputFontFormat=ttf --outputFontFormat=ttf
  '';
}
