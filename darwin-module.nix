{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.hidpi;

  # Display configuration type
  displayConfigType = types.submodule {
    options = {
      vendorId = mkOption {
        type = types.str;
        description = "Display Vendor ID in hex format (e.g., '1e6d')";
      };

      productId = mkOption {
        type = types.str;
        description = "Display Product ID in hex format (e.g., '5b11')";
      };

      resolutions = mkOption {
        type = types.listOf types.str;
        default = [ "1920x1080" "1680x945" "1440x810" "1280x720" ];
        description = "List of resolutions to enable for HiDPI (e.g., ['1920x1080', '1680x945'])";
        example = [ "2560x1440" "1920x1080" "1680x945" ];
      };

      icon = mkOption {
        type = types.nullOr (types.enum [ "imac" "macbook" "macbook-pro" "lg" "pro-display-xdr" ]);
        default = null;
        description = "Optional display icon to use";
      };

      enableEDID = mkOption {
        type = types.bool;
        default = false;
        description = "Enable EDID patching (only for Intel Macs)";
      };

      edidData = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom EDID data in hex format (optional)";
      };
    };
  };

  # Convert decimal VendorID/ProductID to hex if needed
  toHex = id: 
    if builtins.match "[0-9]+" id != null
    then lib.toLower (lib.toHexString (lib.toInt id))
    else lib.toLower id;
  
  # For decimal conversion, we'll let the shell script handle it
  # Just pass through the values as-is since they can be in different formats

  # Generate activation script
  activationScript = if cfg.displays != [] then
    let
      displayCommands = map (display:
        let
          vendorHex = toHex display.vendorId;
          productHex = toHex display.productId;
          displayDir = "DisplayVendorID-${vendorHex}";
          plistFile = "DisplayProductID-${productHex}";
          resolutionsArg = concatStringsSep " " display.resolutions;
          edidSection = if display.enableEDID && display.edidData != null
            then ''
              echo "          <key>IODisplayEDID</key>" >> "$plistPath"
              echo "          <data>${display.edidData}</data>" >> "$plistPath"
            ''
            else "";
        in
        ''
          echo "Configuring HiDPI for display ${vendorHex}:${productHex}..."
          
          # Create override directory
          mkdir -p "$targetDir/${displayDir}"
          
          plistPath="$targetDir/${displayDir}/${plistFile}"
          
          # Convert hex to decimal for VendorID and ProductID
          vendorDec=$((0x${vendorHex}))
          productDec=$((0x${productHex}))
          
          # Write plist header
          cat > "$plistPath" <<PLIST_HEADER
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
            <dict>
              <key>DisplayProductID</key>
              <integer>$productDec</integer>
              <key>DisplayVendorID</key>
              <integer>$vendorDec</integer>
          PLIST_HEADER
          
          ${edidSection}
          
          # Add scale-resolutions array
          echo "      <key>scale-resolutions</key>" >> "$plistPath"
          echo "      <array>" >> "$plistPath"
          
          # Generate resolution entries
          for res in ${resolutionsArg}; do
            width=$(echo $res | cut -d x -f 1)
            height=$(echo $res | cut -d x -f 2)
            hidpi=$(printf '%08x %08x' $((width * 2)) $((height * 2)) | xxd -r -p | base64)
            base64_prefix=$(echo "$hidpi" | cut -c1-11)
            
            echo "        <data>''${base64_prefix}A</data>" >> "$plistPath"
            echo "        <data>''${base64_prefix}AAAABACAAAA==</data>" >> "$plistPath"
            echo "        <data>''${base64_prefix}AAAAB</data>" >> "$plistPath"
            echo "        <data>''${base64_prefix}AAAAJAKAAAA==</data>" >> "$plistPath"
          done
          
          # Write plist footer
          cat >> "$plistPath" <<'PLIST_FOOTER'
              </array>
              <key>target-default-ppmm</key>
              <real>10.0699301</real>
            </dict>
          </plist>
          PLIST_FOOTER
          
          chmod 644 "$plistPath"
        ''
      ) cfg.displays;
    in
    ''
      # HiDPI Configuration
      targetDir="/Library/Displays/Contents/Resources/Overrides"
      
      if [ ! -d "$targetDir" ]; then
        mkdir -p "$targetDir"
      fi
      
      ${concatStringsSep "\n      " displayCommands}
      
      # Enable HiDPI in system preferences
      defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES
      
      echo "HiDPI configuration complete. Reboot required for changes to take effect."
    ''
  else "";

in

{
  options.programs.hidpi = {
    enable = mkEnableOption "macOS HiDPI configuration";

    displays = mkOption {
      type = types.listOf displayConfigType;
      default = [];
      description = "List of displays to configure for HiDPI";
      example = literalExpression ''
        [
          {
            vendorId = "1e6d";
            productId = "5b11";
            resolutions = [ "1920x1080" "1680x945" "1440x810" ];
            icon = "lg";
          }
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.hidpi.text = activationScript;
  };
}
