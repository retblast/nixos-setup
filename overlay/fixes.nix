let fixesOverlay = (
	final: prev: {
		# Remove the desktop application icon entries
		# Seriously, what the fuck
		lsp-plugins = prev.lsp-plugins.overrideAttrs(old: {
			preFixup = ''
				rm -rf $out/share/applications
				rm -rf $out/share/desktop-directories
				rm -rf $out/etc
			'';
		});
		python3Packages = prev.python3Packages.overrideScope(scopeFinal: scopePrev: {
			opentype-feature-freezer-fixed = scopePrev.opentype-feature-freezer.overrideAttrs(old: {
			postPatch = ''
	substituteInPlace src/opentype_feature_freezer/__init__.py \
		--replace "import fontTools.ttLib as ttLib" \
"import fontTools
import fontTools.ttLib as ttLib"
'';
			});
		});
	}
);
in fixesOverlay