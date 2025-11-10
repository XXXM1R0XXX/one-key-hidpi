{
  description = "Declarative macOS HiDPI configuration for nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    {
      # nix-darwin modules
      darwinModules.hidpi = import ./modules/hidpi-display.nix;
      darwinModules.default = self.darwinModules.hidpi;

      # Helper libraries
      lib = import ./lib { inherit (nixpkgs) lib; };

      # Example configurations
      examples = {
        ultrafine-5k = import ./examples/ultrafine-5k-example.nix;
        dell-ultrasharp = import ./examples/dell-ultrasharp-example.nix;
        generic-1080p = import ./examples/generic-1080p-example.nix;
        generic-1440p = import ./examples/generic-1440p-example.nix;
      };

      # Utility packages
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Main one-key-hidpi interactive script package
          one-key-hidpi = pkgs.stdenv.mkDerivation {
            name = "one-key-hidpi";
            version = "1.0.0";
            
            src = ./.;
            
            nativeBuildInputs = [ pkgs.makeWrapper ];
            
            installPhase = ''
              mkdir -p $out/bin
              mkdir -p $out/share/one-key-hidpi
              
              # Copy the main script
              cp hidpi.sh $out/bin/one-key-hidpi
              chmod +x $out/bin/one-key-hidpi
              
              # Copy supporting files
              cp Icons.plist $out/share/one-key-hidpi/
              cp -r displayIcons $out/share/one-key-hidpi/
              
              # Wrap the script to set the correct working directory
              wrapProgram $out/bin/one-key-hidpi \
                --set ONE_KEY_HIDPI_DIR "$out/share/one-key-hidpi" \
                --prefix PATH : "${pkgs.coreutils}/bin"
            '';
            
            meta = with pkgs.lib; {
              description = "Interactive tool to enable HiDPI mode on macOS external displays";
              homepage = "https://github.com/XXXM1R0XXX/one-key-hidpi";
              license = licenses.mit;
              platforms = platforms.darwin;
              maintainers = [ ];
            };
          };

          # EDID extraction tool
          edid-extractor = pkgs.writeShellApplication {
            name = "edid-extractor";
            runtimeInputs = [ pkgs.coreutils ];
            text = builtins.readFile ./scripts/generate-edid.sh;
          };

          # Display icons package
          display-icons = pkgs.stdenv.mkDerivation {
            name = "hidpi-display-icons";
            src = ./displayIcons;
            installPhase = ''
              mkdir -p $out
              cp -r $src/* $out/
            '';
          };
          
          # Set default package
          default = self.packages.${system}.one-key-hidpi;
        }
      );

      # Development shell
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "one-key-hidpi-dev";
            buildInputs = with pkgs; [
              nixpkgs-fmt
              nil
            ];
          };
        }
      );
    };
}
