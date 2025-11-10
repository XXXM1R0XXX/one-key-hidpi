{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.display.hidpi;
  helpers = import ../lib/display-helpers.nix { inherit lib pkgs; };
  
  # Resolution presets matching the original script
  resolutionPresets = {
    "1080p" = [
      "1680x945" "1440x810" "1280x720" "1024x576"
      "960x540" "840x472" "800x450" "640x360"
    ];
    
    "1080p-fix-sleep" = [
      "1680x945" "1424x802" "1280x720" "1024x576"
      "960x540" "840x472" "800x450" "640x360"
    ];
    
    "1200p" = [
      "1680x1050" "1440x900" "1280x800" "1024x640"
      "960x540" "840x472" "800x450" "640x360"
    ];
    
    "1440p" = [
      "2560x1440" "2048x1152" "1920x1080" "1760x990"
      "1680x945" "1440x810" "1360x765" "1280x720"
      "1024x576" "960x540" "840x472" "800x450" "640x360"
    ];
    
    "3000x2000" = [
      "3000x2000" "2880x1920" "2250x1500" "1920x1280"
      "1680x1050" "1440x900" "1280x800" "1024x640"
      "960x540" "840x472" "800x450" "640x360"
    ];
    
    "3440x1440" = [
      "3440x1440" "2752x1152" "2580x1080" "2365x990"
      "1935x810" "1720x720" "1290x540"
    ];
  };

  # Icon resource mappings
  iconPaths = {
    "iMac" = "iMac.icns";
    "MacBook" = "MacBook.icns";
    "MacBookPro" = "MacBookPro.icns";
    "LG" = null; # Uses system LG icon
    "ProDisplayXDR" = "ProDisplayXDR.icns";
  };

  # Generate display configuration for a single display
  generateDisplayConfig = display:
    let
      vendorIdInt = helpers.hexToInt display.vendorId;
      productIdInt = helpers.hexToInt display.productId;
      
      # Determine which resolutions to use
      resolutions = if display.resolutionPreset != null
        then resolutionPresets.${display.resolutionPreset}
        else display.resolutions;
      
      # Generate resolution data entries
      resolutionData = map (res: helpers.encodeResolution res) resolutions;
      
      # Base plist configuration
      plistData = {
        DisplayProductID = productIdInt;
        DisplayVendorID = vendorIdInt;
        "scale-resolutions" = resolutionData;
        "target-default-ppmm" = 10.0699301;
      };
      
      # Add EDID if provided
      plistWithEdid = if display.edidPath != null
        then plistData // {
          IODisplayEDID = builtins.readFile display.edidPath;
        }
        else plistData;
      
    in {
      inherit display vendorIdInt productIdInt resolutions;
      plist = pkgs.writeText "DisplayProductID-${display.productId}" 
        (lib.generators.toPlist {} plistWithEdid);
    };

  # Generate all display configurations
  displayConfigs = map generateDisplayConfig (filter (d: d.enable) cfg.displays);

  # Generate activation script
  activationScript = ''
    # Ensure target directory exists
    TARGET_DIR="/Library/Displays/Contents/Resources/Overrides"
    mkdir -p "$TARGET_DIR"
    
    ${concatMapStringsSep "\n" (dc: ''
      # Configure display: ${dc.display.name}
      VENDOR_DIR="$TARGET_DIR/DisplayVendorID-${dc.display.vendorId}"
      mkdir -p "$VENDOR_DIR"
      
      # Copy display configuration plist
      cp "${dc.plist}" "$VENDOR_DIR/DisplayProductID-${dc.display.productId}"
      chmod 644 "$VENDOR_DIR/DisplayProductID-${dc.display.productId}"
      
      ${optionalString (dc.display.icon != null && iconPaths.${dc.display.icon} != null) ''
        # Copy display icon
        ICON_SOURCE="${pkgs.callPackage ../flake.nix {}}"/packages/${pkgs.system}/display-icons/${iconPaths.${dc.display.icon}}
        if [ -f "$ICON_SOURCE" ]; then
          cp "$ICON_SOURCE" "$VENDOR_DIR/DisplayProductID-${dc.display.productId}.icns"
          chmod 644 "$VENDOR_DIR/DisplayProductID-${dc.display.productId}.icns"
        fi
      ''}
      
      # Set proper ownership
      chown -R root:wheel "$VENDOR_DIR"
      chmod 755 "$VENDOR_DIR"
      
      echo "  ✓ Configured ${dc.display.name} (${dc.display.vendorId}:${dc.display.productId})" >&2
    '') displayConfigs}
    
    echo "HiDPI configuration complete. Reboot required for changes to take effect." >&2
  '';

in
{
  inherit activationScript displayConfigs;
}
