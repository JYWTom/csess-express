{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:usertam/nix-systems";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.fenix.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, systems, fenix }: let
    forAllSystems = with nixpkgs.lib; genAttrs systems.systems;
    forAllPkgs = pkgsWith: forAllSystems (system: pkgsWith
      nixpkgs.legacyPackages.${system}
      fenix.packages.${system}
    );
  in {
    devShells = forAllPkgs (pkgs: fenix: {
      default = pkgs.mkShell {
        name = "email-gen-dev";
        packages = [
          (fenix.combine [
            fenix.stable.toolchain
            fenix.targets.wasm32-unknown-unknown.stable.rust-std
          ])
          pkgs.wasm-pack
          pkgs.pkg-config
          pkgs.libiconv
        ];
        CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER = "lld";
      };
    });
  };
}
