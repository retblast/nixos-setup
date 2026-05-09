{ prev }:

(import ./networking.nix {
  inherit prev;
})
// (import ./multimedia.nix {
  inherit prev;
})
// (import ./platform.nix {
  inherit prev;
})
// (import ./virtualization.nix {
  inherit prev;
})
