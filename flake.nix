{
  description = "iommutests flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    libvfn.url = "github:Joelgranados/libvfn/d7756ae53b8fd2e2dbc8b1b972fb3736d122906d";
  };

  outputs = { self, nixpkgs, libvfn, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      system = "x86_64-linux";
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          libvfn.packages.${system}.default
          meson
          ninja
          git
          gnumake
          pkg-config
          cmake
          clang-tools
          man-pages
        ];
        hardeningDisable = ["fortify"];
      };
    };
}
