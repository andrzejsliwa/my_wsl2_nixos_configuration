{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nur.url = "github:nix-community/NUR";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    with inputs; let
      secrets = builtins.fromJSON (builtins.readFile "${self}/secrets.json");

      nixpkgsWithOverlays = system: (import nixpkgs rec {
        inherit system;

        config = {
          allowUnfree = true;
          permittedInsecurePackages = [];
        };

        overlays = [
          nur.overlay

          (_final: prev: {
            unstable = import nixpkgs-unstable {
              inherit (prev) system;
              inherit config;
            };
          })
        ];
      });

      configurationDefaults = args: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
        home-manager.extraSpecialArgs = args;
      };

      argDefaults = {
        inherit secrets inputs self nix-index-database;
        channels = {inherit nixpkgs nixpkgs-unstable;};
      };

      mkNixosConfiguration = {
        system ? "x86_64-linux",
        hostname,
        username,
        args ? {},
        modules,
      }: let
        specialArgs = argDefaults // {inherit hostname username;} // args;
      in
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          pkgs = nixpkgsWithOverlays system;
          modules =
            [
              (configurationDefaults specialArgs)
              home-manager.nixosModules.home-manager
            ]
            ++ modules;
        };
    in {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

      nixosConfigurations.nixos = mkNixosConfiguration {
        hostname = "nixos";
        username = "andrzejsliwa"; # FIXME: replace with your own username!

        modules = [nixos-wsl.nixosModules.wsl ./wsl.nix];
      };
    };
}
