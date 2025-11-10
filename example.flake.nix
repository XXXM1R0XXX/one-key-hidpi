# Example nix-darwin configuration using one-key-hidpi
#
# This file shows how to integrate the one-key-hidpi flake into your
# nix-darwin configuration.

{
  description = "Example macOS configuration with HiDPI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    one-key-hidpi.url = "github:XXXM1R0XXX/one-key-hidpi";
  };

  outputs = { self, nixpkgs, darwin, one-key-hidpi }: {
    darwinConfigurations = {
      # Replace "hostname" with your actual hostname
      hostname = darwin.lib.darwinSystem {
        system = "aarch64-darwin";  # or "x86_64-darwin" for Intel Macs
        modules = [
          # Import the one-key-hidpi module
          one-key-hidpi.darwinModules.default
          
          # Your configuration
          ({ pkgs, ... }: {
            # Enable HiDPI for your displays
            programs.hidpi = {
              enable = true;
              displays = [
                # Example 1: 1920x1080 Display
                {
                  vendorId = "1e6d";  # Use display-info script to get these values
                  productId = "5b11";
                  resolutions = [
                    "1920x1080"
                    "1680x945"
                    "1440x810"
                    "1280x720"
                    "1024x576"
                  ];
                }
                
                # Example 2: 2560x1440 Display (uncomment if you have this display)
                # {
                #   vendorId = "04d9";
                #   productId = "fa23";
                #   resolutions = [
                #     "2560x1440"
                #     "2048x1152"
                #     "1920x1080"
                #     "1680x945"
                #     "1440x810"
                #     "1280x720"
                #   ];
                # }
              ];
            };
            
            # Other nix-darwin configuration...
            system.stateVersion = 4;
          })
        ];
      };
    };
  };
}
