let
  forwardportsOverlay =
    { inputs, system, ... }:
    (final: prev: {
      stable = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
      usable-whisperx = import inputs.nixpkgs-usable-whisperx {
        inherit system;
        config.allowUnfree = true;
      };
      usable-easyeffects = import inputs.nixpkgs-usable-easyeffects {
        inherit system;
        config.allowUnfree = true;
      };
      usable-opencode = import inputs.nixpkgs-fixed-opencode {
        inherit system;
        config.allowUnfree = true;
      };
    });
in
forwardportsOverlay
