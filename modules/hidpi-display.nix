{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.display.hidpi;
  
  displayModule = types.submodule ({ config, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable HiDPI for this display";
      };

      name = mkOption {
        type = types.str;
        description = "Display name (for documentation purposes)";
        example = "LG UltraFine 5K";
      };

      vendorId = mkOption {
        type = types.str;
        description = "Display vendor ID in hexadecimal (4 digits)";
        example = "24a3";
      };

      productId = mkOption {
        type = types.str;
        description = "Display product ID in hexadecimal (4 digits)";
        example = "5a45";
      };

      resolutions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of HiDPI resolutions to enable (e.g., '1920x1080', '1680x945')";
        example = [ "1920x1080" "1680x945" "1440x810" "1280x720" ];
      };

      resolutionPreset = mkOption {
        type = types.nullOr (types.enum [
          "1080p"
          "1080p-fix-sleep"
          "1200p"
          "1440p"
          "3000x2000"
          "3440x1440"
        ]);
        default = null;
        description = ''
          Predefined resolution preset for common displays.
          When set, this takes precedence over manually specified resolutions.
          
          - 1080p: Standard 1920x1080 displays
          - 1080p-fix-sleep: 1920x1080 with 1424x802 to fix wake-up issues
          - 1200p: 1920x1200 displays
          - 1440p: 2560x1440 displays
          - 3000x2000: High-resolution displays like Surface Studio
          - 3440x1440: Ultrawide displays
        '';
      };

      icon = mkOption {
        type = types.nullOr (types.enum [
          "iMac"
          "MacBook"
          "MacBookPro"
          "LG"
          "ProDisplayXDR"
        ]);
        default = null;
        description = "Optional display icon to show in System Preferences";
      };

      edidPath = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Optional path to EDID binary file for injection.
          When provided, enables EDID-based HiDPI with patched display information.
          This can help with wake-up issues on some displays.
        '';
      };

      patchEdid = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to patch the EDID to fix wake-up issues.
          Only applicable when edidPath is provided or on Intel Macs where EDID can be extracted.
        '';
      };

      dpi = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Target DPI for the display (optional)";
        example = 218;
      };
    };
  });

in
{
  options.system.display.hidpi = {
    enable = mkEnableOption "HiDPI display configuration for external monitors";

    displays = mkOption {
      type = types.listOf displayModule;
      default = [];
      description = "List of external displays to configure with HiDPI";
      example = literalExpression ''
        [
          {
            name = "LG UltraFine 5K";
            vendorId = "24a3";
            productId = "5a45";
            resolutionPreset = "1440p";
            icon = "LG";
          }
        ]
      '';
    };

    backupPath = mkOption {
      type = types.str;
      default = "/var/backups/hidpi";
      description = "Path to store backups of original display configurations";
    };

    enableDisplayResolution = mkOption {
      type = types.bool;
      default = true;
      description = "Enable display resolution preferences in window server";
    };
  };

  config = mkIf cfg.enable {
    # Import sub-modules
    system.display.hidpi = {
      _edidInjection = import ./edid-injection.nix { inherit config lib pkgs; };
      _displayOverrides = import ./display-overrides.nix { inherit config lib pkgs; };
    };

    # Create backup directory
    system.activationScripts.hidpi.text = ''
      echo "Setting up HiDPI configuration..." >&2
      
      # Create backup directory
      mkdir -p "${cfg.backupPath}"
      chmod 755 "${cfg.backupPath}"
      
      # Backup existing configurations if they exist and we haven't backed up yet
      if [ -d "/Library/Displays/Contents/Resources/Overrides" ] && [ ! -f "${cfg.backupPath}/.backed-up" ]; then
        echo "Backing up existing display configurations..." >&2
        tar -czf "${cfg.backupPath}/display-overrides-$(date +%Y%m%d-%H%M%S).tar.gz" \
          -C "/Library/Displays/Contents/Resources" "Overrides" 2>/dev/null || true
        touch "${cfg.backupPath}/.backed-up"
      fi
    '';

    # Set window server preferences
    system.defaults = mkIf cfg.enableDisplayResolution {
      CustomSystemPreferences = {
        "/Library/Preferences/com.apple.windowserver" = {
          DisplayResolutionEnabled = true;
        };
      };
    };

    # Generate display overrides
    system.activationScripts.hidpiDisplays = {
      text = cfg._displayOverrides.activationScript;
    };
  };
}
