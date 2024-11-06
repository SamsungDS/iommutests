{
  description = "iommutests flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          meson
          ninja
          git
          gnumake
          pkg-config
          cmake
          clang-tools
        ];
        hardeningDisable = ["fortify"];
      };
    };
}

