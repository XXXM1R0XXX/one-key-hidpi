# one-key-hidpi - Nix Flake for macOS HiDPI

> Declarative macOS HiDPI configuration for external displays using nix-darwin, or as a standalone Nix package

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Nix](https://img.shields.io/badge/Nix-Flake-blue.svg)](https://nixos.org/)
[![macOS](https://img.shields.io/badge/macOS-Compatible-green.svg)](https://www.apple.com/macos/)

This project provides a native [Nix Flake](https://nixos.wiki/wiki/Flakes) solution for managing macOS external display HiDPI settings. Use it as a **standalone package** for quick setup, or integrate it with [nix-darwin](https://github.com/LnL7/nix-darwin) for declarative, version-controlled display configurations.

## Two Ways to Use

### 📦 Option 1: Standalone Package (Quick & Easy)

Perfect if you just want to enable HiDPI without nix-darwin:

```bash
# Run directly (no installation needed)
nix run github:XXXM1R0XXX/one-key-hidpi

# Or install to your profile
nix profile install github:XXXM1R0XXX/one-key-hidpi
one-key-hidpi  # Run the interactive script
```

This provides the familiar interactive menu from the original bash script, but packaged with Nix for reproducibility.

### ⚙️ Option 2: nix-darwin Module (Declarative)

For full declarative configuration with version control and rollback capabilities - see [Quick Start](#quick-start) below.

## Features

✨ **Declarative Configuration**: Define display settings in your nix-darwin config  
🔄 **Reproducible**: Same configuration produces identical results across systems  
📦 **Standalone Package**: Run as a Nix package without nix-darwin  
🎯 **Easy Rollback**: Use nix-darwin generations to revert changes  
🖥️ **Multi-Display**: Configure multiple external displays simultaneously  
🎨 **Display Icons**: Optional system preference icons (iMac, MacBook, LG, etc.)  
🔧 **Resolution Presets**: Common presets for 1080p, 1440p, 4K displays  
🛠️ **Custom Resolutions**: Define exactly the resolutions you need  
🍎 **Apple Silicon + Intel**: Works on both architectures  
💾 **Automatic Backups**: Original configurations backed up before changes  

## Quick Start (nix-darwin Module)

### 1. Add to Your Flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    one-key-hidpi = {
      url = "github:XXXM1R0XXX/one-key-hidpi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, darwin, one-key-hidpi }: {
    darwinConfigurations.my-mac = darwin.lib.darwinSystem {
      system = "aarch64-darwin";  # or "x86_64-darwin"
      modules = [
        one-key-hidpi.darwinModules.hidpi
        ./configuration.nix
      ];
    };
  };
}
```

### 2. Find Your Display IDs

```bash
# Use the built-in extraction tool
nix run github:XXXM1R0XXX/one-key-hidpi#edid-extractor

# Or manually:
# Intel Macs:
ioreg -lw0 | grep -i "IODisplayEDID"

# Apple Silicon:
ioreg -l | grep "DisplayAttributes" -A 10
```

### 3. Configure Your Display

Add to your `configuration.nix`:

```nix
{
  system.display.hidpi = {
    enable = true;
    
    displays = [
      {
        name = "Dell UltraSharp 4K";
        vendorId = "10ac";    # Your display's vendor ID
        productId = "41b5";   # Your display's product ID
        resolutionPreset = "1440p";  # Use preset resolutions
        icon = "iMac";        # Optional: system preference icon
      }
    ];
  };
}
```

### 4. Apply Configuration

```bash
# Rebuild nix-darwin
darwin-rebuild switch --flake .#my-mac

# Reboot for changes to take effect
sudo reboot
```

### 5. Verify

After rebooting, open **System Preferences > Displays**. You should see HiDPI resolutions available in the "Scaled" section with the "🎯" symbol indicating native rendering.

## Configuration Examples

### Generic 1080p Display

```nix
{
  system.display.hidpi = {
    enable = true;
    displays = [{
      name = "Generic 1080p Monitor";
      vendorId = "1234";
      productId = "5678";
      resolutionPreset = "1080p";
    }];
  };
}
```

### LG UltraFine 5K

```nix
{
  system.display.hidpi = {
    enable = true;
    displays = [{
      name = "LG UltraFine 5K";
      vendorId = "05ac";
      productId = "9226";
      resolutionPreset = "1440p";
      icon = "LG";
    }];
  };
}
```

### Multiple Displays

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
      }
      {
        name = "Right Monitor";
        vendorId = "10ac";
        productId = "41bd";
        resolutionPreset = "1440p";
      }
    ];
  };
}
```

### Custom Resolutions

```nix
{
  system.display.hidpi = {
    enable = true;
    displays = [{
      name = "Custom Display";
      vendorId = "1234";
      productId = "5678";
      resolutions = [
        "2560x1440"
        "1920x1080"
        "1680x945"
        "1440x810"
      ];
    }];
  };
}
```

### Wake-Up Fix (Intel Macs)

For displays with sleep/wake issues:

```nix
{
  system.display.hidpi = {
    enable = true;
    displays = [{
      name = "Problematic Display";
      vendorId = "1234";
      productId = "5678";
      resolutionPreset = "1080p-fix-sleep";
      # Or with EDID patching:
      # edidPath = ./my-display-edid.bin;
      # patchEdid = true;
    }];
  };
}
```

## Resolution Presets

| Preset | Description | Resolutions |
|--------|-------------|-------------|
| `1080p` | Standard 1920x1080 displays | 1680x945, 1440x810, 1280x720, etc. |
| `1080p-fix-sleep` | 1080p with wake-up fix | Includes 1424x802 |
| `1200p` | 1920x1200 displays | 1680x1050, 1440x900, 1280x800, etc. |
| `1440p` | 2560x1440 displays | 2560x1440, 2048x1152, 1920x1080, etc. |
| `3000x2000` | High-resolution displays | 3000x2000, 2880x1920, 2250x1500, etc. |
| `3440x1440` | Ultrawide displays | 3440x1440, 2752x1152, 2580x1080, etc. |

## Available Display Icons

- `"iMac"` - iMac style icon
- `"MacBook"` - MacBook style icon  
- `"MacBookPro"` - MacBook Pro style icon
- `"LG"` - LG display icon
- `"ProDisplayXDR"` - Pro Display XDR icon

## Documentation

- **[Configuration Guide](docs/CONFIGURATION.md)** - Detailed configuration options and examples
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and recovery procedures
- **[Examples](examples/README.md)** - Ready-to-use configuration examples
- **[Development](docs/DEVELOPMENT.md)** - Contributing and development guide

## How It Works

This flake configures macOS HiDPI by:

1. **Generating Display Configurations**: Creates plist files with HiDPI resolution data
2. **Placing Override Files**: Installs configurations to `/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-XXXX/`
3. **Setting System Preferences**: Enables display resolution settings in window server
4. **Managing Permissions**: Ensures proper ownership (root:wheel) and permissions
5. **Creating Backups**: Automatically backs up original configurations

Under the hood, resolutions are encoded at 2x the specified value. For example, a "1920x1080" HiDPI resolution renders at 3840x2160 internally but displays content as if at 1920x1080, providing crisp rendering.

## Requirements

- **Operating System**: macOS Monterey (12.0) or later
- **Architecture**: Apple Silicon (aarch64-darwin) or Intel (x86_64-darwin)
- **Nix**: Nix with flakes enabled
- **nix-darwin**: Installed and configured
- **Sudo Access**: Required for modifying `/Library/Displays/`

## Comparison with Original Script

This Nix flake version offers several advantages over the [original bash script](https://github.com/xzhih/one-key-hidpi):

| Feature | Bash Script | Nix Flake |
|---------|-------------|-----------|
| **Declarative** | ❌ Interactive | ✅ Configuration as code |
| **Reproducible** | ❌ Manual steps | ✅ Identical results |
| **Version Control** | ❌ No tracking | ✅ Git-based |
| **Rollback** | ⚠️ Manual backup | ✅ nix-darwin generations |
| **Multi-display** | ⚠️ Run multiple times | ✅ Single configuration |
| **CI/CD Ready** | ❌ Interactive only | ✅ Automated deployment |
| **Type Safety** | ❌ No validation | ✅ Nix type system |

## Recovery

### If Something Goes Wrong

**From Recovery Mode** (can't boot):
```bash
# Boot into Recovery Mode (Cmd+R or hold power button)
# Open Terminal and run:
rm -rf /Volumes/"Macintosh HD"/Library/Displays/Contents/Resources/Overrides
reboot
```

**From Normal Mode**:
```bash
# Disable the module
darwin-rebuild switch --flake .#my-mac  # with enable = false

# Or rollback to previous generation
darwin-rebuild switch --rollback
```

See [Troubleshooting Guide](docs/TROUBLESHOOTING.md) for detailed recovery procedures.

## Known Limitations

- **Apple Silicon**: Can't extract or inject EDID (vendor/product IDs only)
- **Reboot Required**: Changes require a full system reboot
- **System Updates**: May need to reapply after macOS updates
- **Built-in Displays**: Generally don't need HiDPI configuration

## Migrating from Bash Script

If you're currently using the original bash script:

1. **Extract your current settings**:
   ```bash
   ls /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-*/
   ```

2. **Note your vendor and product IDs** from the directory names

3. **Create equivalent nix configuration** using the IDs

4. **Test in a VM or be prepared to recover** (see Recovery section)

5. **Apply and reboot**

## Contributing

Contributions are welcome! See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for:

- Setting up development environment
- Code structure and conventions  
- Testing procedures
- Submitting pull requests

## Credits

This project is inspired by and based on:

- [xzhih/one-key-hidpi](https://github.com/xzhih/one-key-hidpi) - Original bash script implementation
- [syscl/Enable-HiDPI-OSX](https://github.com/syscl/Enable-HiDPI-OSX) - Early HiDPI enabling work
- [nix-darwin](https://github.com/LnL7/nix-darwin) - Darwin system configuration

## License

MIT License - see [LICENSE](LICENSE) file for details

## Related Projects

- [nix-darwin](https://github.com/LnL7/nix-darwin) - Nix modules for macOS
- [home-manager](https://github.com/nix-community/home-manager) - User environment management
- [BetterDisplay](https://github.com/waydabber/BetterDisplay) - Alternative GUI tool for display management

## Support

- 🐛 **Bug Reports**: [Open an issue](https://github.com/XXXM1R0XXX/one-key-hidpi/issues)
- 💬 **Questions**: [Start a discussion](https://github.com/XXXM1R0XXX/one-key-hidpi/discussions)
- 📖 **Documentation**: [Read the docs](docs/CONFIGURATION.md)

---

**Note**: This tool modifies system display configuration files. Always ensure you can boot into Recovery Mode before applying changes. Backups are created automatically, but it's recommended to have a recovery plan.
