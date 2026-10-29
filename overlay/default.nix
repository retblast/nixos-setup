let
  overlay =
    { inputs, system, ... }:
    [
      (import ./apps.nix)
      (import ./apps.nix)
      (import ./fonts.nix)
      (import ./fixes.nix { inputs = inputs;})
      (import ./kde-extras.nix)
      (import ./kernels.nix)
      (import ./pro-audio.nix)
      (import ./tools.nix)
      (import ./forwardports.nix { inputs = inputs; system = system; })
    ];
in
overlay
