# Technical Implementation Details

## Overview
This document describes how the original `hidpi.sh` script was converted to a declarative Nix flake for nix-darwin.

## Architecture

### Original Script (hidpi.sh)
The original script was an interactive shell script that:
1. Detected connected displays using `ioreg`
2. Asked users to select displays and configurations interactively
3. Generated plist files and placed them in `/Library/Displays/Contents/Resources/Overrides`
4. Created EDID patches when needed

### New Flake Architecture
The new implementation consists of:

```
flake.nix                 # Main flake definition
├── darwinModules.default # nix-darwin module
│   └── darwin-module.nix # Module implementation
└── packages              # Standalone utilities
    └── display-info      # Display detection script
```

## Core Components

### 1. flake.nix
- Exports a `darwinModules.default` for integration with nix-darwin
- Provides a `packages.display-info` utility for discovering display information
- Supports both Apple Silicon (aarch64-darwin) and Intel (x86_64-darwin) Macs

### 2. darwin-module.nix
The module provides declarative options under `programs.hidpi`:

```nix
programs.hidpi = {
  enable = true;
  displays = [
    {
      vendorId = "1e6d";      # Display vendor ID (hex)
      productId = "5b11";      # Display product ID (hex)
      resolutions = [ ... ];   # List of HiDPI resolutions
      enableEDID = false;      # Optional EDID patching
      edidData = null;         # Optional custom EDID data
    }
  ];
};
```

The module generates a system activation script that:
1. Creates the necessary directory structure in `/Library/Displays/Contents/Resources/Overrides`
2. Generates plist files for each configured display
3. Enables HiDPI in macOS system preferences

### 3. display-info.sh
A standalone script that detects and lists connected displays:
- Supports both Intel and Apple Silicon Macs
- Uses `ioreg` to query display information
- Outputs in the format: `index | VendorID | ProductID | MonitorName`

## Resolution Generation

The module generates HiDPI resolution data by:
1. Taking the desired resolution (e.g., `1920x1080`)
2. Doubling the width and height (e.g., `3840x2160`)
3. Converting to hex format
4. Base64 encoding the result
5. Appending scale flags (`A`, `AAAABACAAAA==`, `AAAAB`, `AAAAJAKAAAA==`)

This matches the original script's behavior in the `create_res_*` functions.

## Key Differences from Original

### What Changed
1. **Declarative vs. Interactive**: Configuration is now in Nix files, not interactive prompts
2. **Integration**: Native nix-darwin integration vs. standalone script
3. **Reproducibility**: Configuration is version-controlled and reproducible
4. **Simplified**: Removed icon selection (can be added later if needed)

### What Stayed the Same
1. **Core Logic**: Resolution generation algorithm unchanged
2. **File Locations**: Still uses `/Library/Displays/Contents/Resources/Overrides`
3. **EDID Support**: EDID patching still supported (though requires manual data input)
4. **Compatibility**: Works on both Intel and Apple Silicon Macs

## Migration from Original Script

To migrate from the original script:

1. Run `display-info` to get your display IDs:
   ```bash
   nix run github:XXXM1R0XXX/one-key-hidpi#display-info
   ```

2. Add to your `flake.nix`:
   ```nix
   {
     inputs.one-key-hidpi.url = "github:XXXM1R0XXX/one-key-hidpi";
     
     outputs = { darwin, one-key-hidpi, ... }: {
       darwinConfigurations.hostname = darwin.lib.darwinSystem {
         modules = [
           one-key-hidpi.darwinModules.default
           {
             programs.hidpi = {
               enable = true;
               displays = [ /* your displays */ ];
             };
           }
         ];
       };
     };
   }
   ```

3. Run `darwin-rebuild switch`

4. Reboot your system

## Future Enhancements

Possible future improvements:
- Icon selection support (copy icons from displayIcons/)
- Automatic display detection (non-declarative mode)
- EDID auto-generation for Intel Macs
- Integration with nix-darwin's display management
- Validation of resolution values
- Better error messages

## Testing

The implementation has been tested with:
- ✅ Bash syntax validation
- ✅ Shellcheck linting
- ✅ Resolution generation logic validation
- ✅ Hex/decimal conversion testing
- ✅ Security scanning (no vulnerabilities)

## References
- Original script: `hidpi.sh`
- nix-darwin documentation: https://github.com/LnL7/nix-darwin
- macOS HiDPI guide: https://comsysto.github.io/Display-Override-PropertyList-File-Parser-and-Generator-with-HiDPI-Support-For-Scaled-Resolutions/
