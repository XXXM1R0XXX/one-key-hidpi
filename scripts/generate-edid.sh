#!/usr/bin/env bash
# EDID Extraction Tool for macOS
# Extracts EDID data from connected displays for use with one-key-hidpi

set -euo pipefail

echo "======================================"
echo "   EDID Extraction Tool for macOS    "
echo "======================================"
echo ""

# Detect architecture
IS_APPLE_SILICON=false
if [[ "$(uname -m)" == "arm64" ]]; then
    IS_APPLE_SILICON=true
fi

# Function to extract EDID on Intel Macs
extract_edid_intel() {
    local displays=($(ioreg -lw0 | grep -i "IODisplayEDID" | sed -e "/[^<]*</s///" -e "s/\>//"))
    
    if [[ ${#displays[@]} -eq 0 ]]; then
        echo "Error: No displays found with EDID data"
        exit 1
    fi
    
    echo "Found ${#displays[@]} display(s) with EDID data:"
    echo ""
    
    local index=0
    for display in "${displays[@]}"; do
        ((index++))
        
        # Extract vendor and product IDs
        VendorID=${display:16:4}
        ProductID=${display:22:2}${display:20:2}
        MonitorName=$(echo ${display:190:24} | xxd -p -r 2>/dev/null || echo "Unknown")
        
        echo "Display $index:"
        echo "  Vendor ID:  $VendorID"
        echo "  Product ID: $ProductID"
        echo "  Name:       $MonitorName"
        echo "  EDID (hex): ${display:0:60}..."
        echo ""
        
        # Offer to save EDID
        read -p "Save EDID data for this display? (y/n): " save
        if [[ "$save" == "y" || "$save" == "Y" ]]; then
            local filename="edid-${VendorID}-${ProductID}.bin"
            printf "%s" "$display" | xxd -r -p > "$filename"
            echo "  Saved to: $filename"
            echo "  Use in your nix config with: edidPath = ./$filename;"
            echo ""
        fi
    done
}

# Function to extract VID/PID on Apple Silicon
extract_vidpid_applesilicon() {
    echo "Note: Apple Silicon Macs don't expose EDID via ioreg."
    echo "Extracting Vendor ID and Product ID only..."
    echo ""
    
    local vends=($(ioreg -l | grep "DisplayAttributes" | sed -n 's/.*"LegacyManufacturerID"=\([0-9]*\).*/\1/p'))
    local prods=($(ioreg -l | grep "DisplayAttributes" | sed -n 's/.*"ProductID"=\([0-9]*\).*/\1/p'))
    
    set -o noglob
    IFS=$'\n' prodnames=($(ioreg -l | grep "DisplayAttributes" | sed -n 's/.*"ProductName"="\([^"]*\)".*/\1/p'))
    set +o noglob
    
    if [[ ${#prods[@]} -eq 0 ]]; then
        echo "Error: No displays found"
        exit 1
    fi
    
    echo "Found ${#prods[@]} display(s):"
    echo ""
    
    local index=0
    local prodnamesindex=0
    for prod in "${prods[@]}"; do
        MonitorName=${prodnames[$prodnamesindex]:-"Unknown"}
        VendorID=$(printf "%04x" ${vends[$index]})
        ProductID=$(printf "%04x" ${prods[$index]})
        
        ((index++))
        ((prodnamesindex++))
        
        if [[ ${VendorID} == "0610" ]]; then
            MonitorName="Apple Display (Internal)"
            ((prodnamesindex--))
        fi
        
        echo "Display $index:"
        echo "  Vendor ID:  $VendorID"
        echo "  Product ID: $ProductID"
        echo "  Name:       $MonitorName"
        echo ""
        echo "  Add to your nix config:"
        echo "  {"
        echo "    name = \"$MonitorName\";"
        echo "    vendorId = \"$VendorID\";"
        echo "    productId = \"$ProductID\";"
        echo "    resolutionPreset = \"1080p\";  # or \"1440p\", etc."
        echo "  }"
        echo ""
    done
}

# Main execution
echo "Detecting displays..."
echo ""

if [[ "$IS_APPLE_SILICON" == true ]]; then
    extract_vidpid_applesilicon
else
    extract_edid_intel
fi

echo "======================================"
echo "Extraction complete!"
echo ""
echo "Next steps:"
echo "1. Add the display configuration to your nix-darwin flake"
echo "2. Run: darwin-rebuild switch --flake .#your-hostname"
echo "3. Reboot your Mac"
echo ""
echo "For more help, see: https://github.com/XXXM1R0XXX/one-key-hidpi"
echo "======================================"
