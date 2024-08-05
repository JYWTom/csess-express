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
    packages = forAllPkgs (pkgs: fenix: {
      default = pkgs.rustPlatform.buildRustPackage {
        pname = "email-gen";
        version = "0.1.0";
        src = self;
        cargoLock.lockFile = ./Cargo.lock;
        nativeBuildInputs = [
          # need patch on darwin: https://github.com/NixOS/nix/issues/9625
          # extra-sandbox-paths = [ "/private/etc/ssl/openssl.cnf" ]
          (fenix.combine [
            fenix.stable.toolchain
            fenix.targets.wasm32-unknown-unknown.stable.rust-std
          ])
          pkgs.binaryen
          pkgs.lld
          pkgs.wasm-bindgen-cli
          pkgs.wasm-pack
        ];
        doCheck = false;
        RUSTFLAGS = "-C linker=lld";
        HOME = "$TMPDIR/source";
        buildPhase = ''
          wasm-pack build --target web --no-typescript --no-pack
        '';
        installPhase = ''
          mkdir -p $out
          cp -r pkg/ docs/ index.html $out
        '';
      };
    });

    devShells = forAllPkgs (pkgs: fenix: {
      default = pkgs.mkShell {
        name = "email-gen-dev";
        packages = self.packages.${pkgs.system}.default.nativeBuildInputs;
      };
    });
  };
}
