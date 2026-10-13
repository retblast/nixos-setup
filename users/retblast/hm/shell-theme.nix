# Single source of truth for shell theming (fonts, sizes, colors).
# The HM option is `retTheme`. Consumers: the Quickshell shell (Theme.qml is
# generated from it in users/retblast/hm/quickshell/default.nix) and zed.nix.
# Do not hardcode these values anywhere else.
{
  lib,
  ...
}:
{
  options.retTheme = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    description = "Shell theme tokens: fonts, sizes and colors. Set only here.";
  };

  config.retTheme = {
    # Font families mirror machines/common/fonts.nix defaultFonts.
    sans = "SF Pro Text";
    sansSize = 10;
    mono = "SF Mono";
    monoSize = 10;

    # Colors: dark palette aligned with libadwaita dark.
    colors = {
      bg = "#1d1d20";
      bg-alt = "#242428";
      fg = "#ffffff";
      fg-dim = "#9a9a9f";
      accent = "#3584e4";
      urgent = "#e01b24";
      border = "rgba(53, 132, 228, 0.7)";
    };
  };
}
