{ lib, pkgs }:

with lib;

rec {
  # Convert hex string to integer
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

  # Convert integer to hex string (padded to specified length)
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

  # Parse resolution string (e.g., "1920x1080") to { width, height }
  parseResolution = res:
    let
      parts = splitString "x" res;
      width = toInt (elemAt parts 0);
      height = toInt (elemAt parts 1);
    in
      { inherit width height; };

  # Encode resolution for HiDPI (doubles the resolution and encodes as base64)
  encodeResolution = res:
    let
      parsed = parseResolution res;
      doubleWidth = parsed.width * 2;
      doubleHeight = parsed.height * 2;
      
      # Create hex representation (8 bytes for width, 8 bytes for height)
      widthHex = intToHex doubleWidth 8;
      heightHex = intToHex doubleHeight 8;
      
      # The original script uses: printf '%08x %08x' width height | xxd -r -p | base64
      # We'll create the data structure that macOS expects
      # Format: 00 00 XX XX 00 00 YY YY (where XXXX is width, YYYY is height in big-endian)
      
      # For HiDPI we need to encode as base64 data
      # The pattern from the script shows different suffixes:
      # Type 1: base64(width height) + "A"
      # Type 2: base64(width height) + "AAAABACAAAA=="
      # Type 3: base64(width height) + "AAAAB"
      # Type 4: base64(width height) + "AAAAJAKAAAA=="
      
      # We'll use type 1 (most common) for primary resolutions
    in
      {
        _raw = pkgs.runCommand "encode-resolution-${res}" {} ''
          printf '%08x %08x' ${toString doubleWidth} ${toString doubleHeight} | \
            ${pkgs.xxd}/bin/xxd -r -p | \
            ${pkgs.coreutils}/bin/base64 > $out
        '';
        # Use the raw data from the command
        data = readFile (pkgs.runCommand "encode-resolution-${res}" {} ''
          printf '%08x %08x' ${toString doubleWidth} ${toString doubleHeight} | \
            ${pkgs.xxd}/bin/xxd -r -p | \
            ${pkgs.coreutils}/bin/base64 | \
            ${pkgs.coreutils}/bin/head -c 11 > $out
          echo "AAAAB" >> $out
        '');
      };

  # Calculate DPI from resolution and physical dimensions
  calculateDpi = { width, height, widthMm, heightMm }:
    let
      widthInches = widthMm / 25.4;
      heightInches = heightMm / 25.4;
      widthDpi = width / widthInches;
      heightDpi = height / heightInches;
    in
      {
        horizontal = widthDpi;
        vertical = heightDpi;
        average = (widthDpi + heightDpi) / 2.0;
      };

  # Validate display configuration
  validateDisplay = display:
    let
      hasValidVendorId = stringLength display.vendorId == 4;
      hasValidProductId = stringLength display.productId == 4;
      hasResolutionsOrPreset = 
        (display.resolutions != [] && display.resolutions != null) ||
        (display.resolutionPreset != null);
    in
      hasValidVendorId && hasValidProductId && hasResolutionsOrPreset;

  # Generate plist-compatible resolution entries
  generateResolutionEntries = resolutions:
    let
      encodeOne = res:
        let
          parsed = parseResolution res;
          width = parsed.width * 2;
          height = parsed.height * 2;
        in
          pkgs.runCommand "res-${res}" {} ''
            printf '%08x%08x' ${toString width} ${toString height} | \
              ${pkgs.xxd}/bin/xxd -r -p | \
              ${pkgs.coreutils}/bin/base64 -w0 > $out
          '';
    in
      map (res: 
        let encoded = readFile (encodeOne res);
            # Trim whitespace and add suffix
            trimmed = replaceStrings ["\n" " "] ["" ""] encoded;
        in
          builtins.substring 0 11 trimmed + "AAAAB"
      ) resolutions;
}
