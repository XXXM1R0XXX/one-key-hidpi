{
  description = "Declarative macOS HiDPI configuration for nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }: {
    # Darwin module for nix-darwin integration
    darwinModules.default = import ./darwin-module.nix;
    
    # Package for display-info script
    packages = nixpkgs.lib.genAttrs [ "x86_64-darwin" "aarch64-darwin" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        display-info = pkgs.stdenv.mkDerivation {
          pname = "display-info";
          version = "1.0.0";
          
          src = ./.;
          
          installPhase = ''
            mkdir -p $out/bin
            cp ${./display-info.sh} $out/bin/display-info
            chmod +x $out/bin/display-info
          '';
          
          meta = with pkgs.lib; {
            description = "Display information utility for macOS";
            platforms = platforms.darwin;
          };
        };
        
        default = self.packages.${system}.display-info;
      }
    );
  };
}
