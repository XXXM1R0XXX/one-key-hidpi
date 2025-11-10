# Enable macOS HiDPI

> **Two versions available**: [Interactive Shell Script](#shell-script-version-original) | [Nix Flake (Recommended)](#nix-flake-version-new)

## Overview

[English](README.md) | [中文](README-zh.md) | [Nix Flake Docs](README-FLAKE.md)

This project enables HiDPI mode on non-retina external displays connected to macOS, providing crisp text and UI rendering with "Native" scaled resolutions in System Preferences.

**Choose your version**:
- 🎯 **[Nix Flake](#nix-flake-version-new)** (NEW): Declarative, version-controlled configuration via nix-darwin - **Recommended for nix-darwin users**
- 🖱️ **[Shell Script](#shell-script-version-original)**: Interactive bash script - Original implementation

System Preferences Preview:

![Preferences](./img/preferences.jpg)

![HiDPI Demo](./img/hidpi.gif)

---

## Nix Flake Version (NEW)

### ✨ Why Use the Nix Flake Version?

- **Declarative**: Define display settings in code, not through interactive menus
- **Reproducible**: Same configuration produces identical results every time
- **Version Controlled**: Track all changes in git
- **Easy Rollback**: Revert to previous generations with one command
- **Multi-Display**: Configure all displays at once
- **CI/CD Ready**: Automate deployment
- **Type Safe**: Nix validates your configuration

### Quick Start

**Full documentation**: [README-FLAKE.md](README-FLAKE.md)

1. **Add to your flake.nix**:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    one-key-hidpi.url = "github:XXXM1R0XXX/one-key-hidpi";
  };

  outputs = { nixpkgs, darwin, one-key-hidpi, ... }: {
    darwinConfigurations.my-mac = darwin.lib.darwinSystem {
      modules = [
        one-key-hidpi.darwinModules.hidpi
        {
          system.display.hidpi = {
            enable = true;
            displays = [{
              name = "My Display";
              vendorId = "1234";  # Find with: ioreg -lw0 | grep IODisplayEDID
              productId = "5678";
              resolutionPreset = "1080p";  # or "1440p", "3440x1440", etc.
            }];
          };
        }
      ];
    };
  };
}
```

2. **Find your display's VID/PID**:

```bash
# Use the extraction tool
nix run github:XXXM1R0XXX/one-key-hidpi#edid-extractor

# Or manually:
# Intel Macs:
ioreg -lw0 | grep -i "IODisplayEDID"

# Apple Silicon:
ioreg -l | grep "DisplayAttributes" -A 10
```

3. **Apply and reboot**:

```bash
darwin-rebuild switch --flake .#my-mac
sudo reboot
```

### Examples

See [examples/](examples/) for ready-to-use configurations:

- [LG UltraFine 5K](examples/ultrafine-5k-example.nix)
- [Dell UltraSharp](examples/dell-ultrasharp-example.nix)
- [Generic 1080p](examples/generic-1080p-example.nix)
- [Generic 1440p](examples/generic-1440p-example.nix)

### Resolution Presets

- `"1080p"` - Standard 1920x1080 displays
- `"1080p-fix-sleep"` - For displays with wake-up issues
- `"1200p"` - 1920x1200 displays
- `"1440p"` - 2560x1440 displays
- `"3000x2000"` - High-res displays (Surface Studio, etc.)
- `"3440x1440"` - Ultrawide displays

### Documentation

- 📖 [Complete Nix Flake README](README-FLAKE.md)
- ⚙️ [Configuration Guide](docs/CONFIGURATION.md) - Detailed options reference
- 🔧 [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and recovery
- 🛠️ [Development Guide](docs/DEVELOPMENT.md) - Contributing guidelines
- 📝 [Examples](examples/README.md) - Ready-to-use configurations

### Recovery

If something goes wrong:

```bash
# Disable temporarily
darwin-rebuild switch --flake .  # with enable = false

# Or rollback
darwin-rebuild switch --rollback

# In Recovery Mode (if can't boot)
rm -rf /Volumes/"Macintosh HD"/Library/Displays/Contents/Resources/Overrides
```

---

## Shell Script Version (Original)

### Explanation

This interactive bash script enables HiDPI on external displays by injecting display configuration files into macOS.

**Note**: Some devices have wake-up issues. The script's second option may help by injecting a patched EDID, though this may introduce other issues.

Logo scaling may not be fully resolved since the higher resolution is simulated.

### Usage

**Option 1 - Remote Mode**: Run this script in Terminal

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/xzhih/one-key-hidpi/master/hidpi.sh)"
```

**Option 2 - Local Mode**: Download ZIP, decompress, and double-click `hidpi.command`

![Run Script](./img/run.jpg)

### Recovery

#### Normal Recovery

Run the script again and choose option 3 to disable.

#### Recovery Mode

If you can't boot into the system, boot into macOS Recovery mode and use Terminal.app.

There are two ways to disable it (option 1 is recommended):

**Method 1**: Use the recovery script

```bash
ls /Volumes/
cd /Volumes/"Your System Disk Part"/Users/
ls
cd "user name"
./.hidpi-disable
```

**Method 2**: Remove display override folders manually

```bash
ls /Volumes/
rm -rf /Volumes/"Your System Disk Part"/Library/Displays/Contents/Resources/Overrides
```

### Limitations

- Requires user interaction
- No version control
- Manual recovery needed
- Must re-run for each display
- Changes not tracked
- No automated deployment

**Consider using the [Nix Flake version](#nix-flake-version-new) for a more robust solution.**

---

## Comparison

| Feature | Nix Flake | Shell Script |
|---------|-----------|--------------|
| **Setup** | Configuration file | Interactive menu |
| **Reproducible** | ✅ Yes | ❌ No |
| **Version Control** | ✅ Git-based | ❌ Manual |
| **Rollback** | ✅ One command | ⚠️ Manual restore |
| **Multi-display** | ✅ Single config | ⚠️ Run multiple times |
| **Automation** | ✅ CI/CD ready | ❌ Interactive only |
| **Documentation** | ✅ Comprehensive | ⚠️ Basic |
| **Recovery** | ✅ Built-in | ⚠️ Manual |

## Requirements

### For Nix Flake Version
- macOS Monterey (12.0) or later
- Nix with flakes enabled
- nix-darwin installed

### For Shell Script Version
- macOS (any recent version)
- Bash
- Sudo access

## Credits

This project builds upon:

- [xzhih/one-key-hidpi](https://github.com/xzhih/one-key-hidpi) - Original bash script
- [syscl/Enable-HiDPI-OSX](https://github.com/syscl/Enable-HiDPI-OSX) - Early HiDPI work
- [nix-darwin](https://github.com/LnL7/nix-darwin) - macOS system configuration with Nix

## Inspired By

- [TonyMacX86 Forums](https://www.tonymacx86.com/threads/solved-black-screen-with-gtx-1070-lg-ultrafine-5k-sierra-10-12-4.219872/page-4#post-1644805)
- [syscl's Enable-HiDPI-OSX](https://github.com/syscl/Enable-HiDPI-OSX)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- 🐛 **Bug Reports**: [Open an issue](https://github.com/XXXM1R0XXX/one-key-hidpi/issues)
- 💬 **Questions**: [GitHub Discussions](https://github.com/XXXM1R0XXX/one-key-hidpi/discussions)
- 📖 **Documentation**: 
  - [Nix Flake Documentation](README-FLAKE.md)
  - [Configuration Guide](docs/CONFIGURATION.md)
  - [Troubleshooting Guide](docs/TROUBLESHOOTING.md)

---

**⚠️ Important**: This tool modifies system display configuration files. Always ensure you can boot into Recovery Mode before applying changes. The Nix Flake version creates automatic backups, but having a recovery plan is still recommended.
