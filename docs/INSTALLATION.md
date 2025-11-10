# Installation & Setup

This document provides detailed installation instructions for the one-key-hidpi Nix Flake.

## Prerequisites

- **macOS**: Monterey (12.0) or later
- **Architecture**: Apple Silicon (aarch64-darwin) or Intel (x86_64-darwin)
- **Nix**: Installed with flakes enabled
- **nix-darwin**: Installed and configured
- **Sudo access**: Required for system modifications

## Installing Nix (if not already installed)

```bash
# Install Nix with flakes support
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Or use the official installer with flakes enabled
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Enable flakes in `~/.config/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

## Installing nix-darwin (if not already installed)

```bash
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```

## Quick Installation

### 1. Add to Your Flake

Add one-key-hidpi to your nix-darwin flake inputs:

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
    darwinConfigurations."my-hostname" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";  # or "x86_64-darwin"
      modules = [
        one-key-hidpi.darwinModules.hidpi
        ./configuration.nix
      ];
    };
  };
}
```

### 2. Update Flake Lock

**Important**: The included `flake.lock` is a placeholder. Update it to get the latest versions:

```bash
nix flake update
```

This will fetch the actual versions of nixpkgs and nix-darwin.

### 3. Configure Your Display

Find your display IDs:

```bash
# Use the extraction tool
nix run github:XXXM1R0XXX/one-key-hidpi#edid-extractor

# Or manually extract (see docs/CONFIGURATION.md for details)
```

Add configuration to your `configuration.nix`:

```nix
{ config, pkgs, ... }:

{
  system.display.hidpi = {
    enable = true;
    
    displays = [
      {
        name = "My External Display";
        vendorId = "1234";  # Replace with your actual vendor ID
        productId = "5678";  # Replace with your actual product ID
        resolutionPreset = "1080p";  # Choose appropriate preset
        icon = "iMac";  # Optional
      }
    ];
  };
}
```

### 4. Build and Test

Before applying, test the build:

```bash
darwin-rebuild build --flake .#my-hostname
```

Review the output for any errors.

### 5. Apply Configuration

```bash
darwin-rebuild switch --flake .#my-hostname
```

### 6. Reboot

Changes require a full reboot:

```bash
sudo reboot
```

## Verification

After rebooting:

1. Open **System Preferences > Displays**
2. Click **Scaled**
3. You should see new HiDPI resolutions with the 🎯 symbol

## Common Installation Issues

### "experimental-features" Error

If you see an error about experimental features:

```bash
# Add to ~/.config/nix/nix.conf
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### "attribute 'darwinModules' missing"

Make sure you've updated your flake lock:

```bash
nix flake update
```

### Permission Denied

The activation scripts need sudo. Make sure you have administrator access and can use sudo.

### No Display IDs Found

See the [Troubleshooting Guide](docs/TROUBLESHOOTING.md) for help extracting display information.

## Alternative Installation Methods

### Using Specific Version

Pin to a specific commit or tag:

```nix
{
  inputs.one-key-hidpi = {
    url = "github:XXXM1R0XXX/one-key-hidpi/v2.0.0";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

### Using Local Clone

For development or testing:

```nix
{
  inputs.one-key-hidpi = {
    url = "path:/path/to/local/one-key-hidpi";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

## Uninstallation

To remove HiDPI configuration:

### Temporary Disable

Set `enable = false` in your configuration:

```nix
{
  system.display.hidpi.enable = false;
}
```

Then rebuild:
```bash
darwin-rebuild switch --flake .#my-hostname
sudo reboot
```

### Complete Removal

1. Remove the module import from your nix-darwin configuration
2. Rebuild: `darwin-rebuild switch --flake .#my-hostname`
3. Manually clean up (if needed):
   ```bash
   sudo rm -rf /Library/Displays/Contents/Resources/Overrides
   ```
4. Reboot

### Rollback to Previous Generation

```bash
# List generations
darwin-rebuild --list-generations

# Rollback
darwin-rebuild switch --rollback

# Or switch to specific generation
darwin-rebuild switch --switch-generation 42

# Reboot
sudo reboot
```

## Upgrading

To upgrade to the latest version:

```bash
# Update flake
nix flake update one-key-hidpi

# Or update all inputs
nix flake update

# Rebuild
darwin-rebuild switch --flake .#my-hostname

# Reboot if there were changes to display configuration
sudo reboot
```

## Next Steps

- Read the [Configuration Guide](docs/CONFIGURATION.md) for detailed options
- Check out [Examples](examples/README.md) for ready-to-use configurations
- See [Troubleshooting](docs/TROUBLESHOOTING.md) if you encounter issues

## Getting Help

- 📖 [Documentation](docs/CONFIGURATION.md)
- 🔧 [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- 🐛 [Report Issues](https://github.com/XXXM1R0XXX/one-key-hidpi/issues)
- 💬 [Ask Questions](https://github.com/XXXM1R0XXX/one-key-hidpi/discussions)
