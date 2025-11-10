# Example Configurations

This directory contains example configurations for common display setups.

## Available Examples

### LG UltraFine 5K
- **File**: `ultrafine-5k-example.nix`
- **Description**: Configuration for LG UltraFine 5K displays
- **Resolution Preset**: 1440p
- **Icon**: LG

### Dell UltraSharp
- **File**: `dell-ultrasharp-example.nix`
- **Description**: Configuration for Dell UltraSharp 4K displays (U2720Q, U3219Q, etc.)
- **Resolution Preset**: 1440p

### Generic 1080p
- **File**: `generic-1080p-example.nix`
- **Description**: Configuration for standard 1920x1080 displays
- **Resolution Presets**: 1080p or 1080p-fix-sleep

### Generic 1440p
- **File**: `generic-1440p-example.nix`
- **Description**: Configuration for standard 2560x1440 displays
- **Resolution Preset**: 1440p

## How to Use

1. Find your display's Vendor ID and Product ID:
   ```bash
   # On Intel Macs:
   ioreg -lw0 | grep -i "IODisplayEDID"
   
   # On Apple Silicon Macs:
   ioreg -l | grep "DisplayAttributes" -A 10
   ```

2. Copy the relevant example to your nix-darwin configuration:
   ```nix
   { inputs, ... }:
   {
     imports = [
       inputs.one-key-hidpi.darwinModules.hidpi
     ];
     
     # Include example configuration
     system.display.hidpi = {
       enable = true;
       displays = [
         {
           name = "My Display";
           vendorId = "1234";  # Your actual vendor ID
           productId = "5678";  # Your actual product ID
           resolutionPreset = "1080p";
         }
       ];
     };
   }
   ```

3. Rebuild your nix-darwin configuration:
   ```bash
   darwin-rebuild switch --flake .#your-hostname
   ```

4. Reboot for changes to take effect

## Custom Resolutions

If the presets don't meet your needs, you can specify custom resolutions:

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
          "1920x1080"
          "1680x945"
          "1440x810"
          "1280x720"
        ];
      }
    ];
  };
}
```

## Available Resolution Presets

- **1080p**: Standard scaling for 1920x1080 displays
- **1080p-fix-sleep**: For 1080p displays with wake-up issues (uses 1424x802)
- **1200p**: For 1920x1200 displays
- **1440p**: For 2560x1440 displays
- **3000x2000**: For high-resolution displays (Surface Studio, etc.)
- **3440x1440**: For ultrawide displays

## Display Icons

You can optionally set a display icon:

```nix
{
  icon = "iMac";  # Options: "iMac", "MacBook", "MacBookPro", "LG", "ProDisplayXDR"
}
```

## Troubleshooting

If you experience issues:

1. Verify your vendor/product IDs are correct
2. Try the "fix-sleep" preset if you have wake-up issues
3. Check `/var/log/system.log` for activation errors
4. See `../docs/TROUBLESHOOTING.md` for recovery procedures
