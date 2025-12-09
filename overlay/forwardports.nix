let forwardportsOverlay = {inputs, ...}: (
  final: prev: {
    stable = import inputs.nixpkgs-stable {
      localSystem = final.stdenv.hostPlatform;
      config.allowUnfree = true;
    };
    usable-whisperx = import inputs.nixpkgs-usable-whisperx {
      localSystem = final.stdenv.hostPlatform;
      config.allowUnfree = true;
    };
    usable-easyeffects = import inputs.nixpkgs-usable-easyeffects {
      localSystem = final.stdenv.hostPlatform;
      config.allowUnfree = true;
    };
  }
);
in forwardportsOverlay