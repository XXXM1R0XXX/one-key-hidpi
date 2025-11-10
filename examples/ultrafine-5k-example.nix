# Example configuration for LG UltraFine 5K Display
# Add this to your nix-darwin configuration
{
  system.display.hidpi = {
    enable = true;
    
    displays = [
      {
        name = "LG UltraFine 5K";
        vendorId = "05ac";  # Apple vendor ID (LG UltraFine uses Apple's ID)
        productId = "9226";  # LG UltraFine 5K product ID
        
        # Use 1440p preset which provides good scaling options
        resolutionPreset = "1440p";
        
        # Optional: Use LG display icon
        icon = "LG";
        
        # Optional: Specify custom resolutions instead of preset
        # resolutions = [
        #   "2560x1440"
        #   "2048x1152" 
        #   "1920x1080"
        #   "1680x945"
        #   "1440x810"
        # ];
      }
    ];
  };
}
