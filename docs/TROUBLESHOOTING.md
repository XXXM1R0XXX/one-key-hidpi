# Troubleshooting Guide

This guide helps you diagnose and fix common issues with HiDPI configuration on macOS using one-key-hidpi.

## Table of Contents

1. [Common Issues](#common-issues)
2. [Recovery Procedures](#recovery-procedures)
3. [Debugging](#debugging)
4. [Known Limitations](#known-limitations)
5. [Getting Help](#getting-help)

## Common Issues

### Display Not Showing HiDPI Resolutions

**Symptoms**: After rebuilding and rebooting, the display doesn't show the expected HiDPI resolutions in System Preferences.

**Solutions**:

1. **Verify Vendor and Product IDs**:
   ```bash
   # Intel Macs:
   ioreg -lw0 | grep -i "IODisplayEDID"
   
   # Apple Silicon:
   ioreg -l | grep "DisplayAttributes" -A 10
   
   # Or use the extraction tool:
   nix run github:XXXM1R0XXX/one-key-hidpi#edid-extractor
   ```
   
   Make sure the IDs in your configuration match exactly.

2. **Check if files were created**:
   ```bash
   ls -la /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-*/
   ```
   
   You should see files like `DisplayProductID-xxxx` for your display.

3. **Verify file permissions**:
   ```bash
   ls -la /Library/Displays/Contents/Resources/Overrides/
   ```
   
   Directories should be owned by `root:wheel` with `755` permissions.
   Files should have `644` permissions.

4. **Check activation logs**:
   ```bash
   log show --predicate 'eventMessage contains "HiDPI"' --last 1h
   ```

5. **Force reboot** (not just restart):
   ```bash
   sudo shutdown -r now
   ```

### Wake-Up Issues

**Symptoms**: Display doesn't wake up correctly after sleep, shows wrong resolution, or goes black.

**Solutions**:

1. **Use the fix-sleep preset**:
   ```nix
   resolutionPreset = "1080p-fix-sleep";
   ```

2. **Enable EDID patching** (Intel Macs only):
   ```nix
   {
     edidPath = ./my-edid.bin;
     patchEdid = true;
   }
   ```

3. **Try a lower resolution temporarily**:
   Before sleep, switch to a lower resolution in System Preferences, then back after wake.

4. **Disable Power Nap**:
   System Preferences > Energy Saver > Disable Power Nap

### Configuration Changes Not Taking Effect

**Symptoms**: Made changes to nix configuration but display settings haven't changed.

**Solutions**:

1. **Rebuild nix-darwin**:
   ```bash
   darwin-rebuild switch --flake .#your-hostname
   ```

2. **Check for errors during rebuild**:
   Look for activation script errors in the output.

3. **Verify the module is imported**:
   ```nix
   {
     imports = [
       inputs.one-key-hidpi.darwinModules.hidpi
     ];
   }
   ```

4. **Reboot after rebuild**:
   Display changes require a full reboot.

### Nix Build Errors

**Symptoms**: Errors during `darwin-rebuild` related to the HiDPI module.

**Common errors and fixes**:

1. **"attribute 'darwinModules' missing"**:
   - Update your flake lock: `nix flake update`
   - Check your input configuration

2. **"cannot coerce ... to a string"**:
   - Check that vendorId and productId are strings: `"1234"` not `1234`
   - Verify all required options are set

3. **"infinite recursion encountered"**:
   - Check for circular dependencies in module imports
   - Try simplifying your configuration temporarily

### Display Icon Not Showing

**Symptoms**: Configured a display icon but it doesn't appear in System Preferences.

**Solutions**:

1. **Verify icon exists**:
   Check that the icon file is present in the nix store.

2. **Only certain icons work**:
   Use one of: `"iMac"`, `"MacBook"`, `"MacBookPro"`, `"LG"`, `"ProDisplayXDR"`

3. **Try without icon first**:
   Set `icon = null;` to ensure basic functionality works.

## Recovery Procedures

### Recovery Mode (Cannot Boot)

If you can't boot into macOS after applying HiDPI configuration:

1. **Boot into Recovery Mode**:
   - Intel Mac: Restart and hold `Cmd + R`
   - Apple Silicon: Shutdown, then press and hold the power button until "Loading startup options" appears

2. **Open Terminal** from the Utilities menu

3. **Mount your system volume**:
   ```bash
   # List volumes
   ls /Volumes/
   
   # Your system volume should be named "Macintosh HD" or similar
   cd /Volumes/"Macintosh HD"
   ```

4. **Remove HiDPI configuration**:
   ```bash
   # Option 1: Remove all display overrides
   rm -rf /Volumes/"Macintosh HD"/Library/Displays/Contents/Resources/Overrides
   
   # Option 2: Remove just your display
   rm -rf /Volumes/"Macintosh HD"/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-XXXX
   ```

5. **Reboot**:
   ```bash
   reboot
   ```

### Normal Mode Recovery

If you can boot but want to revert changes:

1. **Disable HiDPI module temporarily**:
   ```nix
   {
     system.display.hidpi.enable = false;
   }
   ```
   
   Then rebuild:
   ```bash
   darwin-rebuild switch --flake .#your-hostname
   ```

2. **Restore from backup**:
   ```bash
   # Check backup location (default: /var/backups/hidpi)
   ls -la /var/backups/hidpi/
   
   # Restore (find the most recent backup)
   cd /Library/Displays/Contents/Resources
   sudo rm -rf Overrides
   sudo tar -xzf /var/backups/hidpi/display-overrides-YYYYMMDD-HHMMSS.tar.gz
   
   # Reboot
   sudo reboot
   ```

3. **Manual cleanup**:
   ```bash
   # Remove display configurations
   sudo rm -rf /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-*
   
   # Reset window server preferences
   sudo defaults delete /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled
   
   # Reboot
   sudo reboot
   ```

### Rollback with nix-darwin

One advantage of using nix-darwin is easy rollback:

```bash
# List previous generations
darwin-rebuild --list-generations

# Rollback to previous generation
darwin-rebuild switch --rollback

# Or switch to specific generation
darwin-rebuild switch --switch-generation 42

# Reboot
sudo reboot
```

## Debugging

### Check Current Configuration

```bash
# View applied display overrides
sudo find /Library/Displays/Contents/Resources/Overrides -type f -exec echo {} \; -exec cat {} \;

# Check window server preferences
defaults read /Library/Preferences/com.apple.windowserver

# View system logs for display-related messages
log show --predicate 'subsystem == "com.apple.windowserver"' --last 1h
```

### Test EDID Extraction

```bash
# Intel Macs - extract EDID
ioreg -lw0 | grep -i "IODisplayEDID"

# Apple Silicon - extract VID/PID
ioreg -l | grep "DisplayAttributes" -A 20

# Use the extraction tool
nix run github:XXXM1R0XXX/one-key-hidpi#edid-extractor
```

### Verify Nix Configuration

```bash
# Check if module is properly loaded
nix eval .#darwinConfigurations.your-hostname.config.system.display.hidpi.enable

# View effective configuration
nix eval .#darwinConfigurations.your-hostname.config.system.display.hidpi.displays --json

# Test build without applying
darwin-rebuild build --flake .#your-hostname
```

### Activation Script Logging

Enable verbose logging to see what's happening during activation:

```nix
{
  system.activationScripts.preActivation.text = ''
    echo "Starting HiDPI activation..."
    set -x  # Enable verbose mode
  '';
}
```

Then rebuild and check logs:
```bash
darwin-rebuild switch --flake .#your-hostname 2>&1 | tee rebuild.log
```

## Known Limitations

### Apple Silicon Limitations

- **No EDID extraction**: Apple Silicon Macs don't expose EDID via `ioreg`
- **No EDID injection**: Can't use `edidPath` on Apple Silicon
- **No wake-up patching**: `patchEdid` option doesn't work

**Workaround**: Use vendor/product IDs only and rely on resolution presets.

### System Integrity Protection (SIP)

If SIP is enabled (default), some system files may be protected:

- `/System/Library/Displays/` is read-only
- We use `/Library/Displays/` instead (which works)

### File Persistence

After macOS updates, you may need to:

1. Rebuild nix-darwin: `darwin-rebuild switch --flake .`
2. Reboot

### Resolution Limitations

- Can't exceed native display capabilities
- Some displays may not support all HiDPI resolutions
- Very high resolutions may cause performance issues

## Getting Help

### Before Asking for Help

1. Check this troubleshooting guide
2. Review the [Configuration Guide](CONFIGURATION.md)
3. Look at [example configurations](../examples/README.md)
4. Search existing GitHub issues

### When Asking for Help

Provide this information:

1. **macOS version**: `sw_vers`
2. **Mac model**: `system_profiler SPHardwareDataType | grep "Model"`
3. **Architecture**: `uname -m`
4. **Display info**:
   ```bash
   # Intel:
   ioreg -lw0 | grep -i "IODisplayEDID"
   
   # Apple Silicon:
   ioreg -l | grep "DisplayAttributes" -A 10
   ```
5. **Your configuration** (sanitized, without secrets)
6. **Error messages** from rebuild or logs
7. **What you've already tried**

### Where to Get Help

- **GitHub Issues**: https://github.com/XXXM1R0XXX/one-key-hidpi/issues
- **Discussions**: For questions and community support
- **Original project**: https://github.com/xzhih/one-key-hidpi (for underlying concepts)

## Related Resources

- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [macOS EDID information](https://www.tonymacx86.com/threads/solved-black-screen-with-gtx-1070-lg-ultrafine-5k-sierra-10-12-4.219872/)
- [Apple Display Manager documentation](https://developer.apple.com/documentation/coregraphics/quartz_display_services)
