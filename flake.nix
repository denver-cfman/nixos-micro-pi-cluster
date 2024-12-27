#
# nix flake check --no-build github:denver-cfman/nixos-micro-pi-cluster?ref=main
# nix flake show --no-build github:denver-cfman/nixos-micro-pi-cluster?ref=main
#
{
  description = "Flake for building a Raspberry Pi Zero 2 SD image";

  inputs = {
    #nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    colmena.url = "github:zhaofengli/colmena";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = {
    self,
    nixpkgs,
    deploy-rs,
    colmena,
    nixos-hardware
  }@inputs:
    let
      # see https://github.com/NixOS/nixpkgs/issues/154163
      overlays = [
        (final: super: {
          makeModulesClosure = x:
            super.makeModulesClosure (x // { allowMissing = true; });
        })
      ];
      specialArgs = {
        inherit nixos-hardware inputs;
      };
    in rec {
      nixosConfigurations = {
         _1b5a4d6b = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./1b5a4d6b.nix
          ];
        };
         _004f17e5 = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./004f17e5.nix
          ];
        };
        fe127cb3 = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./fe127cb3.nix
          ];
        };
        _04a91ec3 = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./04a91ec3.nix
          ];
        };
        _8d4cb64d = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./8d4cb64d.nix
          ];
        };
      };
      
      colmena = {
        meta = { 
          allowApplyAll = false;
          nixpkgs = import nixpkgs {
            system = "aarch64-linux";
            overlays = [];
          };
        };
        _8d4cb64d = { name, nodes, pkgs, ... }: {
          deployment = {
            targetHost = "10.0.85.10";
            targetUser = "giezac";
            tags = [ "head" ];
          };
        };
      };

      deploy = {
        user = "root";
        sshOpts = [ "-i" "/home/giezac/.ssh/pzw2.rsa" ];
        # Timeout for profile activation.
        # This defaults to 240 seconds.
        activationTimeout = 600;
      
        # Timeout for profile activation confirmation.
        # This defaults to 30 seconds.
        confirmTimeout = 60;
        nodes = {
          _1b5a4d6b = {
            hostname = "1b5a4d6b";
            profiles.system.path =
              deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations._1b5a4d6b;
            #remoteBuild = true;
            
          };
          _04a91ec3 = {
            hostname = "04a91ec3";
            profiles.system.path =
              deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations._04a91ec3;
            #remoteBuild = true;
            
          };
          _004f17e5 = {
            hostname = "004f17e5";
            profiles.system.path =
              deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations._004f17e5;
            #remoteBuild = true;
            
          };
          fe127cb3 = {
            hostname = "fe127cb3";
            profiles.system.path =
              deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.fe127cb3;
            #remoteBuild = true;
            
          };
          _8d4cb64d = {
            hostname = "clusterhat";
            profiles.system.path =
              deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations._8d4cb64d;
            #remoteBuild = true;
            
          };  
        };
      };
    };
}
