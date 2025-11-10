# Development Guide

This guide is for contributors and developers working on the one-key-hidpi nix-darwin module.

## Table of Contents

1. [Development Setup](#development-setup)
2. [Project Structure](#project-structure)
3. [Code Conventions](#code-conventions)
4. [Testing](#testing)
5. [Adding New Features](#adding-new-features)
6. [Contributing](#contributing)

## Development Setup

### Prerequisites

- macOS (Monterey or later)
- Nix with flakes enabled
- nix-darwin installed
- Git
- Text editor with Nix support (VS Code + Nix IDE, or similar)

### Setting Up Development Environment

1. **Clone the repository**:
   ```bash
   git clone https://github.com/XXXM1R0XXX/one-key-hidpi.git
   cd one-key-hidpi
   ```

2. **Enter development shell**:
   ```bash
   nix develop
   ```
   
   This provides:
   - `nixpkgs-fmt` for formatting
   - `nil` for Nix language server
   - Other development tools

3. **Test the flake**:
   ```bash
   nix flake check
   nix flake show
   ```

## Project Structure

```
one-key-hidpi/
├── flake.nix                    # Main flake definition
├── flake.lock                   # Locked dependencies
├── modules/
│   ├── hidpi-display.nix        # Main nix-darwin module
│   ├── edid-injection.nix       # EDID handling
│   └── display-overrides.nix    # Display configuration generation
├── lib/
│   ├── default.nix              # Library exports
│   ├── display-helpers.nix      # Resolution encoding, validation
│   └── edid.nix                 # EDID parsing utilities
├── examples/
│   ├── README.md
│   ├── ultrafine-5k-example.nix
│   ├── dell-ultrasharp-example.nix
│   ├── generic-1080p-example.nix
│   └── generic-1440p-example.nix
├── scripts/
│   └── generate-edid.sh         # EDID extraction tool
├── docs/
│   ├── CONFIGURATION.md         # User configuration guide
│   ├── TROUBLESHOOTING.md       # Troubleshooting guide
│   └── DEVELOPMENT.md           # This file
├── displayIcons/                # Display icon resources
│   ├── iMac.icns
│   ├── MacBook.icns
│   ├── MacBookPro.icns
│   └── ProDisplayXDR.icns
├── README-FLAKE.md              # Main README for flake version
├── README.md                    # Original README (preserved)
└── hidpi.sh                     # Original bash script (preserved)
```

### Key Files

- **`flake.nix`**: Entry point, defines inputs, outputs, and module exports
- **`modules/hidpi-display.nix`**: Main module defining configuration options
- **`modules/display-overrides.nix`**: Generates actual display configuration files
- **`lib/display-helpers.nix`**: Resolution encoding and display utilities
- **`lib/edid.nix`**: EDID parsing and manipulation functions

## Code Conventions

### Nix Style

Follow these conventions for consistency:

1. **Formatting**: Use `nixpkgs-fmt` for consistent formatting
   ```bash
   nixpkgs-fmt flake.nix modules/*.nix lib/*.nix
   ```

2. **Naming**:
   - Options: camelCase (`vendorId`, `productId`, `resolutionPreset`)
   - Internal functions: camelCase (`parseResolution`, `encodeResolution`)
   - File names: kebab-case (`display-helpers.nix`, `edid-injection.nix`)

3. **Module Structure**:
   ```nix
   { config, lib, pkgs, ... }:
   
   with lib;
   
   let
     cfg = config.system.display.hidpi;
     # ... local bindings
   in
   {
     options = { /* ... */ };
     config = mkIf cfg.enable { /* ... */ };
   }
   ```

4. **Documentation**:
   - All options must have `description`
   - Include `example` for non-obvious options
   - Use `literalExpression` for complex examples

### Shell Scripts

For bash scripts (like `generate-edid.sh`):

1. Use strict mode: `set -euo pipefail`
2. Quote all variables: `"$variable"`
3. Use `local` for function-local variables
4. Add comments explaining non-obvious logic

## Testing

### Local Testing

1. **Test flake evaluation**:
   ```bash
   nix flake check
   nix eval .#darwinModules.hidpi
   ```

2. **Test in a separate branch**:
   ```bash
   git checkout -b test-feature
   # Make changes
   nix flake check
   ```

3. **Test with a VM** (if possible):
   Create a test nix-darwin configuration and apply it in a VM.

4. **Test on your system** (be careful):
   ```nix
   # In your nix-darwin config:
   {
     inputs.one-key-hidpi.url = "path:/path/to/your/dev/one-key-hidpi";
   }
   ```
   
   Then rebuild:
   ```bash
   darwin-rebuild build --flake .#your-hostname
   # Review the build output before switching
   darwin-rebuild switch --flake .#your-hostname
   ```

### Test Cases

Key scenarios to test:

- [ ] Single display configuration
- [ ] Multiple display configuration  
- [ ] Each resolution preset (1080p, 1440p, etc.)
- [ ] Custom resolutions
- [ ] Display icons
- [ ] Enable/disable individual displays
- [ ] Module disable (`enable = false`)
- [ ] Backup creation
- [ ] Recovery procedures

### Manual Testing Checklist

Before submitting changes:

- [ ] `nix flake check` passes
- [ ] No evaluation errors
- [ ] Documentation is updated
- [ ] Examples work correctly
- [ ] Changes tested on at least one system
- [ ] Backward compatibility maintained
- [ ] No secrets or personal info in commits

## Adding New Features

### Adding a New Resolution Preset

1. **Add to presets in `modules/display-overrides.nix`**:
   ```nix
   resolutionPresets = {
     # ... existing presets
     "new-preset" = [
       "2880x1620"
       "2560x1440"
       # ... more resolutions
     ];
   };
   ```

2. **Update option enum in `modules/hidpi-display.nix`**:
   ```nix
   resolutionPreset = mkOption {
     type = types.nullOr (types.enum [
       # ... existing options
       "new-preset"
     ]);
   };
   ```

3. **Document in `docs/CONFIGURATION.md`**

4. **Add example in `examples/`**

### Adding a New Display Icon

1. **Add icon file to `displayIcons/`**:
   ```bash
   cp new-icon.icns displayIcons/
   ```

2. **Update icon mappings in `modules/display-overrides.nix`**:
   ```nix
   iconPaths = {
     # ... existing icons
     "NewIcon" = "new-icon.icns";
   };
   ```

3. **Add to option enum in `modules/hidpi-display.nix`**:
   ```nix
   icon = mkOption {
     type = types.nullOr (types.enum [
       # ... existing options
       "NewIcon"
     ]);
   };
   ```

4. **Update documentation**

### Adding EDID Processing Features

Edit `lib/edid.nix` to add new EDID parsing or manipulation functions:

```nix
{
  # New function
  extractFeature = edidHex:
    let
      # Extract relevant bytes
      feature = builtins.substring X Y edidHex;
    in
      feature;
}
```

### Adding Configuration Options

1. **Define option in `modules/hidpi-display.nix`**:
   ```nix
   newOption = mkOption {
     type = types.bool;
     default = false;
     description = "Enable new feature";
   };
   ```

2. **Implement in appropriate module**

3. **Add tests**

4. **Update documentation**

## Contributing

### Pull Request Process

1. **Fork the repository**

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**:
   - Follow code conventions
   - Update documentation
   - Add/update examples as needed

4. **Test thoroughly**:
   ```bash
   nix flake check
   nixpkgs-fmt flake.nix modules/*.nix lib/*.nix
   ```

5. **Commit with clear messages**:
   ```bash
   git commit -m "Add support for X feature"
   ```

6. **Push and create pull request**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **PR description should include**:
   - What changed and why
   - Any breaking changes
   - Testing performed
   - Related issues

### Commit Message Guidelines

Use conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, no code change
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

Examples:
```
feat(modules): add support for custom EDID files

docs(examples): add LG UltraFine 4K example

fix(lib): correct resolution encoding for ultrawide displays
```

## Debugging Tips

### Inspecting Nix Values

```bash
# Evaluate specific attributes
nix eval .#darwinModules.hidpi
nix eval .#lib --json

# Check configuration for a specific system
nix eval .#darwinConfigurations.my-mac.config.system.display.hidpi --json
```

### Testing Activation Scripts

Extract the activation script to review:

```bash
nix build .#darwinConfigurations.my-mac.config.system.build.toplevel
cat result/activate
```

### Verbose Logging

Add debug output in activation scripts:

```nix
system.activationScripts.hidpiDisplays.text = ''
  echo "DEBUG: Starting HiDPI configuration" >&2
  set -x  # Enable command tracing
  # ... rest of script
'';
```

## Architecture Notes

### Why Separate Modules?

- **`hidpi-display.nix`**: User-facing options and high-level logic
- **`display-overrides.nix`**: File generation and activation
- **`edid-injection.nix`**: EDID-specific operations (Intel only)

This separation allows for:
- Clearer code organization
- Easier testing of individual components
- Potential reuse of EDID logic elsewhere

### Resolution Encoding

Resolutions are encoded as base64 data for plist files. The encoding:

1. Takes a resolution like "1920x1080"
2. Doubles it (3840x2160 for HiDPI)
3. Encodes as hexadecimal (8 bytes each for width and height)
4. Converts to base64
5. Appends suffix for resolution type

### Activation Script Design

Activation scripts run as root during `darwin-rebuild switch`:

1. Create backup (if first time)
2. Create directory structure
3. Copy configuration files
4. Set permissions
5. Update window server preferences

Changes take effect after reboot.

## Release Process

1. Update version in documentation
2. Update CHANGELOG.md
3. Test on multiple systems if possible
4. Create git tag: `git tag v1.0.0`
5. Push tag: `git push origin v1.0.0`
6. Create GitHub release with notes

## Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/)
- [NixOS Module System](https://nixos.org/manual/nixos/stable/index.html#sec-writing-modules)
- [macOS Display Documentation](https://developer.apple.com/documentation/coregraphics/quartz_display_services)

## Questions?

If you have questions about development:

1. Check existing issues and discussions
2. Ask in a GitHub discussion
3. Join the Nix community channels

Thank you for contributing!
