{ lib }:

with lib;

rec {
  # Parse binary EDID data
  parseEdid = edidBinary:
    let
      # EDID is 128 or 256 bytes
      # First 8 bytes are header: 00 FF FF FF FF FF FF 00
      # Bytes 8-9: Manufacturer ID (big-endian)
      # Bytes 10-11: Product code (little-endian)
      # Bytes 12-15: Serial number
      # Byte 54-125: Detailed timing descriptors
      
      # Helper to extract bytes
      getByte = edid: offset: builtins.substring (offset * 2) 2 edid;
      getWord = edid: offset: (getByte edid offset) + (getByte edid (offset + 1));
      
      # Parse manufacturer ID (3 characters encoded in 2 bytes)
      parseManufacturerId = edid:
        let
          byte1 = hexToInt (getByte edid 8);
          byte2 = hexToInt (getByte edid 9);
          
          # Each letter is 5 bits (A=1, B=2, ... Z=26)
          char1 = ((byte1 / 4) % 32);
          char2 = (((byte1 % 4) * 8) + (byte2 / 32));
          char3 = (byte2 % 32);
          
          toChar = n: 
            if n >= 1 && n <= 26 
            then elemAt (stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZ") (n - 1)
            else "?";
        in
          (toChar char1) + (toChar char2) + (toChar char3);
    in
      {
        manufacturerId = parseManufacturerId edidBinary;
        productCode = getWord edidBinary 10;
        serialNumber = getWord edidBinary 12;
      };

  # Extract vendor ID from EDID
  getVendorId = edid:
    let
      # Vendor ID is at bytes 8-9 in EDID
      vendorBytes = builtins.substring 16 4 edid;  # Position 8 in pairs = 16 in string
    in
      vendorBytes;

  # Extract product ID from EDID  
  getProductId = edid:
    let
      # Product ID is at bytes 10-11 in EDID (little-endian)
      byte10 = builtins.substring 20 2 edid;
      byte11 = builtins.substring 22 2 edid;
    in
      byte11 + byte10;  # Swap bytes for little-endian

  # Patch EDID to fix wake-up issues
  # This replicates the logic from the original bash script
  patchEdidForWakeup = edidHex:
    let
      # Extract key bytes
      version = builtins.substring 38 2 edidHex;
      basicParams = builtins.substring 40 2 edidHex;
      checksum = builtins.substring 254 2 edidHex;
      
      # Parse as integers
      versionInt = hexToInt version;
      basicParamsInt = hexToInt basicParams;
      checksumInt = hexToInt checksum;
      
      # Calculate new checksum after patching
      # We're changing version to 04 and basicParams to 90
      newChecksumInt = checksumInt + versionInt + basicParamsInt - 0x04 - 0x90;
      newChecksum = intToHex (mod newChecksumInt 256) 2;
      
      # Build patched EDID
      # Change bytes at position 19 (0x13) to 04 and position 20 (0x14) to 90
      # Insert e6 at position 25 (0x19)
      part1 = builtins.substring 0 38 edidHex;   # Up to version
      part2 = builtins.substring 42 8 edidHex;   # After basicParams
      part3 = builtins.substring 50 204 edidHex; # Rest of EDID
      
      patchedEdid = part1 + "0490" + part2 + "e6" + part3 + newChecksum;
    in
      patchedEdid;

  # Convert EDID hex string to base64 for plist
  edidToBase64 = edidHex:
    let
      # This would need to shell out to xxd and base64
      # For now, return the hex string directly
      # In practice, this would be handled by a derivation
    in
      edidHex;

  # Validate EDID structure
  validateEdid = edidHex:
    let
      # Check minimum length (128 bytes = 256 hex chars)
      hasMinLength = stringLength edidHex >= 256;
      
      # Check EDID header (should start with 00 FF FF FF FF FF FF 00)
      header = builtins.substring 0 16 edidHex;
      hasValidHeader = header == "00ffffffffffff00" || header == "00FFFFFFFFFFFF00";
    in
      hasMinLength && hasValidHeader;

  # Helper functions from display-helpers
  hexToInt = hex:
    let
      cleanHex = toLower (replaceStrings [ " " "0x" ] [ "" "" ] hex);
      chars = stringToCharacters cleanHex;
      charToInt = c: 
        if c == "0" then 0 else if c == "1" then 1
        else if c == "2" then 2 else if c == "3" then 3
        else if c == "4" then 4 else if c == "5" then 5
        else if c == "6" then 6 else if c == "7" then 7
        else if c == "8" then 8 else if c == "9" then 9
        else if c == "a" then 10 else if c == "b" then 11
        else if c == "c" then 12 else if c == "d" then 13
        else if c == "e" then 14 else if c == "f" then 15
        else 0;
      values = map charToInt chars;
    in
      foldl' (acc: v: acc * 16 + v) 0 values;

  intToHex = n: length:
    let
      hex = [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f" ];
      toHexDigit = x: elemAt hex (mod x 16);
      go = n: if n == 0 then [] else go (n / 16) ++ [ (toHexDigit n) ];
      result = concatStrings (go n);
      padding = concatStrings (genList (_: "0") (length - (stringLength result)));
    in
      if n == 0 then concatStrings (genList (_: "0") length)
      else padding + result;
}
