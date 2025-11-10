{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.display.hidpi;

  # EDID patching function (replicates the bash script logic)
  patchEdid = edidHex:
    let
      # Extract relevant parts of EDID
      version = builtins.substring 19 2 edidHex;  # Position 38 in pairs -> 19 in string
      basicparams = builtins.substring 20 2 edidHex;  # Position 40 in pairs -> 20 in string
      checksum = builtins.substring 127 2 edidHex;  # Position 254 in pairs -> 127 in string
      
      # Calculate new checksum
      versionInt = helpers.hexToInt version;
      basicparamsInt = helpers.hexToInt basicparams;
      checksumInt = helpers.hexToInt checksum;
      
      newChecksumInt = checksumInt + versionInt + basicparamsInt - 4 - 144;
      newChecksum = helpers.intToHex (newChecksumInt % 256);
      
      # Construct new EDID with patches
      # Change version and basic params, update checksum
      part1 = builtins.substring 0 19 edidHex;
      part2 = builtins.substring 21 3 edidHex;  # Skip version, keep 3 chars
      part3 = builtins.substring 25 102 edidHex;  # To position where we inject e6
      part4 = builtins.substring 127 126 edidHex;  # Rest before checksum
      
      newEdid = part1 + "0490" + part2 + "e6" + part3 + part4 + newChecksum;
    in
      newEdid;

  helpers = {
    # Convert hex string to integer
    hexToInt = hex:
      let
        chars = stringToCharacters hex;
        values = map (c: 
          if c == "0" then 0 else if c == "1" then 1
          else if c == "2" then 2 else if c == "3" then 3
          else if c == "4" then 4 else if c == "5" then 5
          else if c == "6" then 6 else if c == "7" then 7
          else if c == "8" then 8 else if c == "9" then 9
          else if c == "a" || c == "A" then 10
          else if c == "b" || c == "B" then 11
          else if c == "c" || c == "C" then 12
          else if c == "d" || c == "D" then 13
          else if c == "e" || c == "E" then 14
          else if c == "f" || c == "F" then 15
          else 0
        ) chars;
        multiply = foldl' (acc: v: acc * 16 + v) 0 values;
      in
        multiply;
    
    # Convert integer to hex string (2 digits)
    intToHex = n:
      let
        hex = [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f" ];
        hi = elemAt hex (n / 16);
        lo = elemAt hex (mod n 16);
      in
        hi + lo;
  };

  # EDID extraction script for Intel Macs
  edidExtractScript = pkgs.writeShellScript "extract-edid" ''
    # Extract EDID from ioreg
    ioreg -lw0 | grep -i "IODisplayEDID" | sed -e "/[^<]*</s///" -e "s/>//"
  '';

in
{
  inherit patchEdid edidExtractScript;
}
