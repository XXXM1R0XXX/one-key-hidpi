# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-11-10

### Added - Nix Flake Version

This is a major update introducing a complete Nix Flake-based solution alongside the original bash script.

#### Core Features
- **Nix Flake Integration**: Full nix-darwin module for declarative HiDPI configuration
- **Declarative Configuration**: Define display settings in nix configuration files
- **Version Control**: All display configurations tracked via git/nix
- **Reproducible Builds**: Same configuration produces identical results
- **Easy Rollback**: Use nix-darwin generations to revert changes
- **Multi-Display Support**: Configure multiple displays in a single configuration

#### Modules
- `modules/hidpi-display.nix`: Main nix-darwin module with user-facing options
- `modules/display-overrides.nix`: Display configuration file generation and activation
- `modules/edid-injection.nix`: EDID parsing and patching utilities

#### Helper Libraries
- `lib/display-helpers.nix`: Resolution encoding, validation, plist generation
- `lib/edid.nix`: EDID parsing, patching, and manipulation functions

#### Examples
- LG UltraFine 5K configuration example
- Dell UltraSharp configuration example
- Generic 1080p display configuration
- Generic 1440p display configuration
- Multiple display setup examples

#### Documentation
- **README-FLAKE.md**: Comprehensive Nix Flake documentation
- **docs/CONFIGURATION.md**: Detailed configuration guide with all options
- **docs/TROUBLESHOOTING.md**: Troubleshooting guide and recovery procedures
- **docs/DEVELOPMENT.md**: Contributing and development guidelines
- **examples/README.md**: Example usage instructions

#### Utilities
- **scripts/generate-edid.sh**: EDID extraction tool for both Intel and Apple Silicon Macs
- Display icon resources packaged for nix store

#### Configuration Options
- Resolution presets: `1080p`, `1080p-fix-sleep`, `1200p`, `1440p`, `3000x2000`, `3440x1440`
- Custom resolution support
- Display icon selection: iMac, MacBook, MacBookPro, LG, Pro Display XDR
- EDID injection and patching (Intel Macs)
- Automatic backup of original configurations
- Granular enable/disable per display

### Changed
- **README.md**: Updated to explain both versions (Nix Flake and bash script)
- Repository now supports two installation methods: Nix Flake (recommended) and bash script (original)

### Preserved
- Original bash script (`hidpi.sh`) maintained for backward compatibility
- Original README preserved as `README-bash-original.md`
- Chinese README (`README-zh.md`) preserved
- All display icons and resources maintained

### Technical Details

#### Architecture
The Nix Flake version uses a modular architecture:
- User configuration → nix-darwin options
- Options validation → Nix type system
- Configuration generation → plist files with resolution data
- System activation → Files placed in `/Library/Displays/Contents/Resources/Overrides/`
- Automatic backups before any changes

#### Compatibility
- Works on both Apple Silicon (aarch64-darwin) and Intel (x86_64-darwin) Macs
- Compatible with macOS Monterey (12.0) and later
- Integrates with existing nix-darwin configurations
- No conflicts with original bash script approach

#### Benefits Over Bash Script
- Declarative vs imperative configuration
- Version control and reproducibility
- Type-safe configuration
- Automatic backup and recovery
- No manual intervention required
- CI/CD ready

## [1.0.0] - Previous

### Original Bash Script Version
- Interactive bash script for HiDPI configuration
- EDID injection support
- Wake-up issue fixes
- Display icon customization
- Multiple resolution presets
- Recovery mode support

---

## Migration Guide

### From Bash Script to Nix Flake

If you're currently using the bash script and want to migrate to the Nix Flake version:

1. **Extract your current configuration**:
   ```bash
   ls /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-*/
   ```

2. **Note your display IDs** from the directory names

3. **Set up nix-darwin** if not already installed

4. **Add one-key-hidpi flake** to your inputs

5. **Create equivalent configuration** using the noted IDs

6. **Test and apply**:
   ```bash
   darwin-rebuild build --flake .#hostname  # test first
   darwin-rebuild switch --flake .#hostname  # then apply
   ```

7. **Reboot**

Both versions can coexist, but the Nix Flake version is recommended for new installations.

## Version Numbering

- **1.x.x**: Original bash script versions
- **2.x.x**: Nix Flake versions (includes bash script for compatibility)

## Links

- [Nix Flake Documentation](README-FLAKE.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Examples](examples/README.md)
