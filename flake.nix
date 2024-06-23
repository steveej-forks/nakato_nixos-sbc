{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    forSystems = systems: f: nixpkgs.lib.genAttrs systems (system: f system);
    systems = ["aarch64-linux" "riscv64-linux"];
    forAllSystems = forSystems systems;

    bootstrapSystem = {
      modules,
      system ? "aarch64-linux",
      ...
    } @ config:
      nixpkgs.lib.nixosSystem (
        config
        // {
          inherit system;
          modules =
            modules
            ++ [
              self.nixosModules.default
              {
                sbc.bootstrap.initialBootstrapImage = true;
                sbc.version = "0.2";
              }
            ];
        }
      );
  in {
    formatter = forSystems (builtins.attrNames nixpkgs.legacyPackages) (
      system:
        nixpkgs.legacyPackages.${system}.alejandra
    );

    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        import ./pkgs {inherit pkgs;}
    );

    nixosModules = import ./modules;
    # deviceBuilder is an unstable API.  I'm throwing it in quickly
    # to unblock my usage.
    deviceBuilder = {
      rtc.ds3231 = import ./lib/devices/rtc/ds3231/create.nix;
    };

    nixosConfigurations = {
      bananapi-bpir3 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.bananapi.bpir3
        ];
      };

      bananapi-bpir3_cross = bootstrapSystem {
        modules = [
          self.nixosModules.boards.bananapi.bpir3
          {
            nixpkgs.buildPlatform.system = "x86_64-linux";
            nixpkgs.hostPlatform.system = "aarch64-linux";
          }
        ];
      };

      pine64-rock64v2 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.pine64.rock64v2
        ];
      };
      pine64-rock64v3 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.pine64.rock64v3
        ];
      };
      raspberrypi-rpi4 = bootstrapSystem {
        modules = [
          self.nixosModules.boards.raspberrypi.rpi4
        ];
      };
      xunlong-opi5b = bootstrapSystem {
        modules = [
          self.nixosModules.boards.xunlong.opi5b
        ];
      };
    };
  };
}
