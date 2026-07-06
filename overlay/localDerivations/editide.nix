{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
  wrapGAppsHook4,
  makeWrapper,
  python3,
  gnugrep,
  ripgrep,
  gitMinimal,
  gdk-pixbuf,
  graphene,
  gtk4,
  gtksourceview5,
  libadwaita,
  libspelling ? null,
  gobject-introspection,
  universal-ctags,
  editorconfig-core-c,
}:

let
  pythonEnv = python3.withPackages (
    ps: with ps; [
      pycairo
      pygobject3
    ]
  );
in
assert lib.versionAtLeast python3.pythonVersion "3.13";
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "editide";
  version = "unstable-2026-06-28";

  src = fetchFromGitLab {
    domain = "framagit.org";
    owner = "editide";
    repo = "editide";
    rev = "cf221fc3124ae3529d751270b403a1abf8287741";
    hash = "sha256-AleohGF2xg9+wnp+AzlpyTUk4bE96hZjKhcgVcWfoEQ=";
  };

  nativeBuildInputs = [
    wrapGAppsHook4
    makeWrapper
    gobject-introspection
    pythonEnv
  ];

  buildInputs = [
    gdk-pixbuf
    graphene
    gtk4
    gtksourceview5
    libadwaita
  ]
  ++ lib.optionals (libspelling != null) [
    libspelling
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    		runHook preInstall

    		sitePackages=$out/${python3.sitePackages}
    		pkgdir=$sitePackages/editide
    		mkdir -p "$pkgdir" $out/bin $out/share/applications

    		cp -R \
    			__init__.py \
    			__main__.py \
    			COPYING \
    			HACKING.md \
    			README.md \
    			core \
    			data \
    			exts \
    			"$pkgdir/"

    		substituteInPlace "$pkgdir/__init__.py" \
    			--replace-fail "@defaultpaths@" "" \
    			--replace-fail "@localedir@" "$out/share/locale"

    		install -Dm644 data/editide.desktop $out/share/applications/localhost.EdiTidE4.desktop
    		substituteInPlace $out/share/applications/localhost.EdiTidE4.desktop \
    			--replace-fail "Exec=python3 -B -m editide -- %U" "Exec=editide %U"

    		install -Dm644 data/icons/hicolor/scalable/apps/editide.svg \
    			$out/share/icons/hicolor/scalable/apps/editide.svg
    		install -Dm644 data/icons/hicolor/scalable/apps/editide.svg \
    			$out/share/icons/hicolor/scalable/apps/localhost.EdiTidE4.svg
    		install -Dm644 data/icons/hicolor/symbolic/apps/editide-symbolic.svg \
    			$out/share/icons/hicolor/symbolic/apps/editide-symbolic.svg
    		install -Dm644 data/icons/hicolor/symbolic/apps/editide-symbolic.svg \
    			$out/share/icons/hicolor/symbolic/apps/localhost.EdiTidE4-symbolic.svg

    		makeWrapper ${pythonEnv}/bin/python3 $out/bin/editide \
    			--add-flags "-B" \
    			--add-flags "-m" \
    			--add-flags "editide" \
    			--prefix PYTHONPATH : "$sitePackages" \
    			--prefix PATH : ${
         lib.makeBinPath [
           gnugrep
           ripgrep
           gitMinimal
           universal-ctags
           editorconfig-core-c
         ]
       }

    		runHook postInstall
    	'';

  preFixup = ''
    		gappsWrapperArgs+=(
    			--prefix XDG_DATA_DIRS : "$out/share"
    		)
    	'';

  meta = {
    description = "Source-code editor with basic project support";
    homepage = "https://editide.frama.io/";
    license = lib.licenses.cc0;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "editide";
    platforms = lib.platforms.linux;
  };
})
