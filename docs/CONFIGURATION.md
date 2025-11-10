# Configuration Guide

This guide provides detailed information on configuring HiDPI settings for your external displays using the one-key-hidpi nix-darwin module.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Module Options](#module-options)
3. [Display Configuration](#display-configuration)
4. [Resolution Presets](#resolution-presets)
5. [Custom Resolutions](#custom-resolutions)
6. [Display Icons](#display-icons)
7. [EDID Injection](#edid-injection)
8. [Multiple Displays](#multiple-displays)
9. [Advanced Configuration](#advanced-configuration)

## Quick Start

1. Add one-key-hidpi to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    one-key-hidpi.url = "github:XXXM1R0XXX/one-key-hidpi";
  };
}
```

2. Import the module in your nix-darwin configuration:

```nix
{
  darwinConfigurations.my-mac = darwin.lib.darwinSystem {
    modules = [
      one-key-hidpi.darwinModules.hidpi
      {
        system.display.hidpi = {
          enable = true;
          displays = [
            # Your display configuration here
          ];
        };
      }
    ];
  };
}
```

3. Find your display's Vendor ID and Product ID:

```bash
# Intel Macs:
ioreg -lw0 | grep -i "IODisplayEDID"

# Apple Silicon Macs:
ioreg -l | grep "DisplayAttributes" -A 10

# Or use the extraction tool:
nix run github:XXXM1R0XXX/one-key-hidpi#edid-extractor
```

4. Add your display configuration and rebuild:

```bash
darwin-rebuild switch --flake .#my-mac
```

5. Reboot for changes to take effect.

## Module Options

### `system.display.hidpi.enable`

**Type**: `boolean`  
**Default**: `false`

Enable the HiDPI display configuration module.

### `system.display.hidpi.displays`

**Type**: `list of display configurations`  
**Default**: `[]`

List of external displays to configure with HiDPI settings.

### `system.display.hidpi.backupPath`

**Type**: `string`  
**Default**: `"/var/backups/hidpi"`

Directory where backups of original display configurations are stored.

### `system.display.hidpi.enableDisplayResolution`

**Type**: `boolean`  
**Default**: `true`

Enable display resolution preferences in the window server. Should generally be left as `true`.

## Display Configuration

Each display in the `displays` list can have the following options:

### `enable`

**Type**: `boolean`  
**Default**: `true`

Enable HiDPI for this specific display. Set to `false` to temporarily disable without removing the configuration.

### `name`

**Type**: `string`  
**Required**: Yes

A descriptive name for the display. Used for documentation and logging purposes.

**Example**: `"LG UltraFine 5K"`, `"Dell U2720Q"`

### `vendorId`

**Type**: `string (4 hex digits)`  
**Required**: Yes

The display's vendor ID in hexadecimal format (4 digits).

**Example**: `"24a3"` (LG), `"10ac"` (Dell), `"05ac"` (Apple)

### `productId`

**Type**: `string (4 hex digits)`  
**Required**: Yes

The display's product ID in hexadecimal format (4 digits).

**Example**: `"5a45"`, `"41b5"`

### `resolutionPreset`

**Type**: `null or enum`  
**Default**: `null`

Use a predefined resolution preset. When set, this takes precedence over `resolutions`.

**Available Presets**:
- `"1080p"` - Standard 1920x1080 displays
- `"1080p-fix-sleep"` - 1080p with wake-up fix (uses 1424x802)
- `"1200p"` - 1920x1200 displays
- `"1440p"` - 2560x1440 displays
- `"3000x2000"` - High-resolution displays
- `"3440x1440"` - Ultrawide displays

### `resolutions`

**Type**: `list of strings`  
**Default**: `[]`

List of custom HiDPI resolutions to enable. Each resolution should be in the format `"WIDTHxHEIGHT"`.

**Example**: `[ "1920x1080" "1680x945" "1440x810" "1280x720" ]`

### `icon`

**Type**: `null or enum`  
**Default**: `null`

Optional display icon to show in System Preferences.

**Available Icons**:
- `"iMac"`
- `"MacBook"`
- `"MacBookPro"`
- `"LG"`
- `"ProDisplayXDR"`

### `edidPath`

**Type**: `null or path`  
**Default**: `null`

Path to a binary EDID file for injection. This enables EDID-based HiDPI configuration, which can help with wake-up issues on some displays.

**Example**: `./edid-data/lg-ultrafine-5k.bin`

### `patchEdid`

**Type**: `boolean`  
**Default**: `false`

Whether to patch the EDID to fix wake-up issues. Only works when `edidPath` is provided or on Intel Macs where EDID can be extracted.

### `dpi`

**Type**: `null or integer`  
**Default**: `null`

Target DPI for the display (optional, for documentation purposes).

**Example**: `218`

## Resolution Presets

Detailed breakdown of each resolution preset:

### 1080p

Optimized for 1920x1080 displays with comprehensive scaling options:

```
Primary: 1680x945, 1440x810, 1280x720, 1024x576
Secondary: 960x540, 840x472, 800x450, 640x360
```

### 1080p-fix-sleep

Same as 1080p but includes 1424x802 to fix wake-up issues:

```
Primary: 1680x945, 1424x802, 1280x720, 1024x576
Secondary: 960x540, 840x472, 800x450, 640x360
```

### 1200p

Optimized for 1920x1200 displays:

```
Primary: 1680x1050, 1440x900, 1280x800, 1024x640
Secondary: 960x540, 840x472, 800x450, 640x360
```

### 1440p

Comprehensive scaling for 2560x1440 displays:

```
Primary: 2560x1440, 2048x1152, 1920x1080, 1760x990, 1680x945, 1440x810, 1360x765, 1280x720
Secondary: 1024x576, 960x540, 840x472, 800x450, 640x360
```

### 3000x2000

For high-resolution displays like Surface Studio:

```
Primary: 3000x2000, 2880x1920, 2250x1500, 1920x1280, 1680x1050, 1440x900, 1280x800, 1024x640
Secondary: 960x540, 840x472, 800x450, 640x360
```

### 3440x1440

For ultrawide displays:

```
3440x1440, 2752x1152, 2580x1080, 2365x990, 1935x810, 1720x720, 1290x540
```

## Custom Resolutions

If presets don't meet your needs, specify custom resolutions:

```nix
{
  system.display.hidpi = {
    enable = true;
    displays = [
      {
        name = "Custom Display";
        vendorId = "1234";
        productId = "5678";
        resolutions = [
          "2560x1440"  # Native HiDPI 1280x720
          "1920x1080"  # Native HiDPI 960x540
          "1680x945"   # Balanced option
          "1440x810"   # Lower scaling
        ];
      }
    ];
  };
}
```

**Note**: The resolutions you specify are the "native" resolutions. macOS will render at 2x these resolutions internally for HiDPI scaling.

## Display Icons

Display icons appear in System Preferences > Displays. Configure them like this:

```nix
{
  displays = [
    {
      name = "My Display";
      vendorId = "1234";
      productId = "5678";
      resolutionPreset = "1080p";
      icon = "MacBookPro";  # Choose an icon
    }
  ];
}
```

## EDID Injection

EDID (Extended Display Identification Data) injection can help with display recognition and wake-up issues.

### Extracting EDID (Intel Macs Only)

```bash
nix run github:XXXM1R0XXX/one-key-hidpi#edid-extractor
```

This will save EDID data to a `.bin` file.

### Using EDID in Configuration

```nix
{
  displays = [
    {
      name = "My Display";
      vendorId = "1234";
      productId = "5678";
      resolutions = [ "1920x1080" "1680x945" ];
      edidPath = ./edid-1234-5678.bin;
      patchEdid = true;  # Fix wake-up issues
    }
  ];
}
```

### When to Use EDID Injection

- Display not recognized correctly
- Wake-up issues after sleep
- Display shows wrong capabilities
- Need to override display information

**Note**: Apple Silicon Macs don't expose EDID via ioreg, so EDID injection is primarily for Intel Macs.

## Multiple Displays

Configure multiple displays easily:

```nix
{
  system.display.hidpi = {
    enable = true;
    displays = [
      {
        name = "Left Monitor";
        vendorId = "10ac";
        productId = "41b5";
        resolutionPreset = "1440p";
        icon = "iMac";
      }
      {
        name = "Right Monitor";
        vendorId = "10ac";
        productId = "41bd";
        resolutionPreset = "1440p";
      }
      {
        name = "Laptop Display";
        enable = false;  # Don't configure built-in display
        vendorId = "0610";
        productId = "a030";
      }
    ];
  };
}
```

## Advanced Configuration

### Disabling Specific Displays Temporarily

```nix
{
  displays = [
    {
      name = "Temporary Display";
      enable = false;  # Disabled but configuration preserved
      vendorId = "1234";
      productId = "5678";
      resolutionPreset = "1080p";
    }
  ];
}
```

### Custom Backup Location

```nix
{
  system.display.hidpi = {
    enable = true;
    backupPath = "/Users/myuser/.hidpi-backups";
    displays = [ /* ... */ ];
  };
}
```

### Disable Display Resolution Preference

```nix
{
  system.display.hidpi = {
    enable = true;
    enableDisplayResolution = false;  # Don't modify window server preferences
    displays = [ /* ... */ ];
  };
}
```

## Complete Example

Here's a complete configuration example:

```nix
{ inputs, ... }:

{
  imports = [
    inputs.one-key-hidpi.darwinModules.hidpi
  ];

  system.display.hidpi = {
    enable = true;
    backupPath = "/var/backups/display-config";
    
    displays = [
      # Primary 4K monitor
      {
        name = "Dell UltraSharp U2720Q";
        vendorId = "10ac";
        productId = "41b5";
        resolutionPreset = "1440p";
        icon = "iMac";
      }
      
      # Secondary 1080p monitor with wake-up fix
      {
        name = "Generic 1080p";
        vendorId = "1234";
        productId = "5678";
        resolutionPreset = "1080p-fix-sleep";
      }
      
      # LG UltraFine with custom resolutions
      {
        name = "LG UltraFine 5K";
        vendorId = "05ac";
        productId = "9226";
        resolutions = [
          "2560x1440"
          "2048x1152"
          "1920x1080"
        ];
        icon = "LG";
      }
    ];
  };
}
```

## See Also

- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Example Configurations](../examples/README.md)
- [Development Guide](DEVELOPMENT.md)
