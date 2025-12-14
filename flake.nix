{
  description = "retblast's NixOS setup";

  inputs = {
    # nixpkgs.url = "nixpkgs/7df7ff7";
    # nixOS unstable, which is what I actually run
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # Should be the current stable
    # I use this for things I need the stable version for
    # Basically, easy "forwardporting"
    # Currently for:
    # TODO: ollama 0.12.11 (https://github.com/NixOS/nixpkgs/tree/c97c47f2bac4fa59e2cbdeba289686ae615f8ed4)
    #
    nixpkgs-stable.url = "nixpkgs/c97c47f2bac4fa59e2cbdeba289686ae615f8ed4";
    # As of writing, 6th december 2025, nixpkgs has pyannote-audio 4.0.1, which doesn't work with whisperX
    # TODO: https://github.com/m-bain/whisperX/issues/1241
    nixpkgs-usable-whisperx.url = "nixpkgs/baa35fb3cd45d75c9e4e4466a191e6c99c3b2d31";
    # TODO: https://github.com/NixOS/nixpkgs/issues/467263
    # In general, the QT update was a mess, I'll try again with normal EE when this gets fixed.
    nixpkgs-usable-easyeffects.url = "nixpkgs/21a328d166594e938deb8d5c668ff3527ca3d9a0";
    # nixpkgs.url = "nixpkgs/9da7f1c";
    # nixpkgs.url = "github:NixOS/nixpkgs/pull/426048/head";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Let's not try this
    # plasma-manager = {
    # 	url = "github:nix-community/plasma-manager";
    # 	inputs.nixpkgs.follows = "nixpkgs";
    # 	inputs.home-manager.follows = "home-manager";
    # };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-index-database,
      disko,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        # TODO: Delete this if overlays work fine under each system.
        # TODO: Consider making general overlays for multiple machines
        overlays = [
          # TODO: Someday get how the n-v-e overlay works/is constructed
          inputs.nix-vscode-extensions.overlays.default
        ]
        ++ import ./overlay { inherit inputs; };
        hostPlatform = system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
          joypixels.acceptLicense = true;
          input-fonts.acceptLicense = true;
          permittedInsecurePackages = [
            # FIXME: https://github.com/NixOS/nixpkgs/issues/269713
            # It's for steam
            "openssl-1.1.1w"
            # No Packet Tracer 9 yet.
            "ciscoPacketTracer8-8.2.2"
            # Because of Neochat
            "olm-3.2.16"

          ];
        };
      };
    in
    rec {
      nixosConfigurations = {
        Taihou = nixpkgs.lib.nixosSystem {
          system = system;
          pkgs = pkgs;
          modules = [
            nix-index-database.nixosModules.nix-index
            disko.nixosModules.disko
            ./modules/default.nix
            ./machines/Taihou
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "homeManagerBackupFile";
              home-manager.users.retblast = import ./users/retblast/hm;
              # home-manager.sharedModules = [ plasma-manager.homeModules.plasma-manager ];
              home-manager.extraSpecialArgs = {
                # Read my laptop config
                taihouConfig = nixosConfigurations.Taihou.config;
                username = "retblast";
                inherit inputs;
                installPath = "/etc/nixos";
              };
              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
          ];
          specialArgs = {
            inherit inputs;
            username = "retblast";
          };
        };

        # nix build .#nixosConfigurations.TaihouLite.config.system.build.isoImage
        TaihouLite = nixpkgs.lib.nixosSystem {
          system = system;
          pkgs = pkgs;
          modules = [
            nix-index-database.nixosModules.nix-index
            disko.nixosModules.disko
            ./modules/default.nix
            ./machines/TaihouLite
          ];
          specialArgs = {
            inherit inputs;
            username = "retblast";
          };
        };

        Hearts = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/Hearts
            ./modules/default.nix
            nix-index-database.nixosModules.nix-index
          ];
          specialArgs = { inherit inputs; };
        };
      };
      # TODO: An example of homeConfigurations should be @ the home-manager manual
      # Unneeded now
      # homeConfigurations = {
      # 	"retblast@Taihou" = home-manager.lib.homeManagerConfiguration {
      # 		inherit pkgs;
      # 		# backupFileExtension = "hm-backup";
      # 		extraSpecialArgs = {
      # 			# Read my laptop config
      # 			taihouConfig = nixosConfigurations.Taihou.config;
      # 			username = "retblast";
      # 			inherit inputs;
      # 			installPath = "/home/retblast/Documents/Software Development/Repositories/Personal/nixos-setup";
      # 		};
      # 		modules = [
      # 			./users/retblast/hm
      # 			nix-index-database.homeModules.nix-index
      # 		];
      # 	};
      # };
    };
}
