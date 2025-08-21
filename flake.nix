{
  description = "iommutests flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    libvfn.url = "github:Joelgranados/libvfn/7766ed4d1fd0e2a73e28b686735cb77abe19ff2b";
  };

  outputs = { self, nixpkgs, libvfn, ... }:
    let
      iommutVersion = "0.1.0";
      allSystems = [ "x86_64-linux" ];

      forAllSystems = fn:
        nixpkgs.lib.genAttrs allSystems
        (system: fn { pkgs = import nixpkgs { inherit system; }; });

    in {
      formatter = forAllSystems ({ pkgs }: pkgs.nixfmt);
      packages = forAllSystems ({ pkgs }: rec {

        iommut = pkgs.stdenv.mkDerivation {
          pname = "iommut";
          version = iommutVersion;
          src = ./.;
          nativeBuildInputs = with pkgs; [
            meson
            ninja
            pkg-config
            libvfn.packages.${pkgs.system}.default
          ];

        };
        default = iommut;
      });

      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            libvfn.packages.${pkgs.system}.default
            meson
            ninja
            git
            gnumake
            pkg-config
            cmake
            clang-tools
            pyright
            man-pages
            python311Packages.pytest
            python311Packages.pyudev
          ];
          hardeningDisable = ["fortify"];
        };
      });
    };
}
