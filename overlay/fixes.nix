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
	}
);
in fixesOverlay