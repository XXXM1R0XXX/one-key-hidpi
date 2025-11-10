# one-key-hidpi Nix Flake

Declarative macOS HiDPI configuration for nix-darwin.

## Quick Start

### 1. Add to your nix-darwin flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin";
    one-key-hidpi.url = "github:XXXM1R0XXX/one-key-hidpi";
  };

  outputs = { self, nixpkgs, darwin, one-key-hidpi }: {
    darwinConfigurations."your-hostname" = darwin.lib.darwinSystem {
      modules = [
        one-key-hidpi.darwinModules.default
        {
          programs.hidpi = {
            enable = true;
            displays = [
              {
                vendorId = "1e6d";  # LG Display
                productId = "5b11";
                resolutions = [
                  "1920x1080"
                  "1680x945"
                  "1440x810"
                  "1280x720"
                ];
              }
            ];
          };
        }
      ];
    };
  };
}
```

### 2. Get your display information

Use the included `display-info` script to find your display's Vendor ID and Product ID:

```bash
nix run github:XXXM1R0XXX/one-key-hidpi#display-info
```

Output format:
```
 1 | 1e6d | 5b11 | LG Display
```

### 3. Apply the configuration

```bash
darwin-rebuild switch --flake .#your-hostname
```

Reboot your system for changes to take effect.

## Configuration Options

### `programs.hidpi.enable`
Type: `boolean`  
Default: `false`

Enable HiDPI configuration.

### `programs.hidpi.displays`
Type: `list of display configurations`  
Default: `[]`

List of displays to configure.

#### Display Configuration Options

- **`vendorId`** (string, required): Display Vendor ID in hex format (e.g., `"1e6d"`)
- **`productId`** (string, required): Display Product ID in hex format (e.g., `"5b11"`)
- **`resolutions`** (list of strings): List of resolutions to enable (default: `["1920x1080" "1680x945" "1440x810" "1280x720"]`)
- **`icon`** (null or enum): Optional display icon (not yet implemented)
- **`enableEDID`** (boolean): Enable EDID patching for Intel Macs (default: `false`)
- **`edidData`** (null or string): Custom EDID data in base64 format (optional)

## Examples

### Single Display (1920x1080)
```nix
programs.hidpi = {
  enable = true;
  displays = [{
    vendorId = "1e6d";
    productId = "5b11";
    resolutions = [
      "1920x1080"
      "1680x945"
      "1440x810"
      "1280x720"
    ];
  }];
};
```

### Multiple Displays
```nix
programs.hidpi = {
  enable = true;
  displays = [
    {
      vendorId = "1e6d";
      productId = "5b11";
      resolutions = ["1920x1080" "1680x945"];
    }
    {
      vendorId = "0610";  # Apple Display
      productId = "a032";
      resolutions = ["2560x1440" "1920x1080"];
    }
  ];
};
```

### 2560x1440 Display
```nix
programs.hidpi = {
  enable = true;
  displays = [{
    vendorId = "1e6d";
    productId = "5b11";
    resolutions = [
      "2560x1440"
      "2048x1152"
      "1920x1080"
      "1680x945"
      "1440x810"
      "1280x720"
    ];
  }];
};
```

## How It Works

This flake provides a nix-darwin module that:
1. Generates proper plist files for each configured display
2. Places them in `/Library/Displays/Contents/Resources/Overrides/`
3. Enables HiDPI in macOS system preferences
4. Applies changes during `darwin-rebuild switch`

The configuration is fully declarative - just define your displays in your flake and rebuild.

## Disabling HiDPI

To disable HiDPI for a display, simply remove it from the `displays` list and rebuild. To completely disable the feature:

```nix
programs.hidpi.enable = false;
```

Then manually remove the override files if needed:
```bash
sudo rm -rf /Library/Displays/Contents/Resources/Overrides
```
