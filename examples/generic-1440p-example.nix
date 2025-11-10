# Example configuration for generic 2560x1440 displays
{
  system.display.hidpi = {
    enable = true;
    
    displays = [
      {
        name = "Generic 1440p Monitor";
        
        # Replace with your monitor's actual VID/PID
        # Find these using: ioreg -lw0 | grep -i "IODisplayEDID"
        vendorId = "1234";  # Example vendor ID
        productId = "abcd";  # Example product ID
        
        # 1440p preset with comprehensive scaling options
        resolutionPreset = "1440p";
        
        # Or specify custom resolutions:
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
