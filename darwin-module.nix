{ config, lib, pkgs, ... }:

let
  cfg = config.programs.hidpi;

  resolutionToData = resolution:
    let
      parts = lib.splitString "x" resolution;
      width = lib.toInt (builtins.elemAt parts 0);
      height = lib.toInt (builtins.elemAt parts 1);
      hex = pkgs.lib.toHexString width 8 + pkgs.lib.toHexString height 8;
    in
    pkgs.lib.toBase64 (pkgs.lib.fromHex hex);

in
{
  options.programs.hidpi = {
    enable = lib.mkEnableOption "Enable declarative HiDPI settings";
    displays = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          vendorId = lib.mkOption { type = lib.types.str; };
          productId = lib.mkOption { type = lib.types.str; };
          resolutions = lib.mkOption { type = lib.types.listOf lib.types.str; };
        };
      });
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc = lib.foldl' (acc: display: acc // {
      "Displays/Contents/Resources/Overrides/DisplayVendorID-${display.vendorId}/DisplayProductID-${display.productId}" = {
        source = (pkgs.formats.plist {}).generate "DisplayProductID-${display.productId}" {
          DisplayProductID = lib.stringToPath.fromHex display.productId;
          DisplayVendorID = lib.stringToPath.fromHex display.vendorId;
          scale-resolutions = map resolutionToData display.resolutions;
        };
        # ----- ИЗМЕНЕНИЯ ЗДЕСЬ -----
        # Удаляем строки user и group, так как они вызывают ошибку.
        # Nix-darwin по умолчанию установит правильного владельца (root:wheel).
        # Добавляем права доступа для большей надежности.
        mode = "0644";
      };
    }) {} cfg.displays;
  };
}
