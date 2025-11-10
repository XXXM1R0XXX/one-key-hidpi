# Example configuration for Dell UltraSharp Displays
# Common Dell UltraSharp models: U2720Q, U2723DE, U3219Q
{
  system.display.hidpi = {
    enable = true;
    
    displays = [
      {
        name = "Dell UltraSharp U2720Q";
        vendorId = "10ac";  # Dell vendor ID
        productId = "41b5";  # U2720Q product ID (check yours with ioreg)
        
        # 4K display - use 1440p preset for good scaling
        resolutionPreset = "1440p";
        
        # Optional: No icon specified, will use default
        # icon = null;
      }
      
      # You can configure multiple displays
      # {
      #   name = "Dell UltraSharp U3219Q";
      #   vendorId = "10ac";
      #   productId = "41bd";
      #   resolutionPreset = "1440p";
      # }
    ];
  };
}
