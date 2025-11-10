# Example configuration for generic 1920x1080 displays
{
  system.display.hidpi = {
    enable = true;
    
    displays = [
      {
        name = "Generic 1080p Monitor";
        
        # Replace with your monitor's actual VID/PID
        # Find these using: ioreg -lw0 | grep -i "IODisplayEDID"
        vendorId = "1234";  # Example vendor ID
        productId = "5678";  # Example product ID
        
        # Standard 1080p preset
        resolutionPreset = "1080p";
        
        # If you have wake-up issues, use this instead:
        # resolutionPreset = "1080p-fix-sleep";
        
        # Or specify custom resolutions:
        # resolutions = [
        #   "1920x1080"
        #   "1680x945"
        #   "1440x810"
        #   "1280x720"
        # ];
      }
    ];
  };
}
