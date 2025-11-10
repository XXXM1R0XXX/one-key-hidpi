# darwin-module.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.hidpi;
in
{
  # --- ОПЦИИ МОДУЛЯ ---
  # (Эта часть остается без изменений, она спроектирована правильно)
  options.programs.hidpi = {
    enable = lib.mkEnableOption "Enable declarative HiDPI settings";
    displays = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          vendorId = lib.mkOption { type = lib.types.str; };
          productId = lib.mkOption { type = lib.types.str; };
          resolutions = lib.mkOption {
            type = lib.types.submodule {
              options = {
                type1 = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
                type2 = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
                type3 = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
                type4 = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
                custom = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
              };
            };
            default = {};
          };
          edid = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
        };
      });
      default = [];
    };
  };

  # --- КОНФИГУРАЦИЯ СИСТЕМЫ ---
  config = lib.mkIf cfg.enable {
    # Используем lib.listToAttrs - правильную функцию для преобразования списка в сет.
    system.activationScripts = lib.listToAttrs (map (display:
      let
        # --- ВСЯ ЛОГИКА ГЕНЕРАЦИИ ПЕРЕНЕСЕНА ВНУТРЬ `let` ---

        parseRes = res: {
          width = lib.toInt (builtins.elemAt (lib.splitString "x" res) 0);
          height = lib.toInt (builtins.elemAt (lib.splitString "x" res) 1);
        };

        encodeResolution = width: height:
          let
            w = width * 2;
            h = height * 2;
            hexW = pkgs.lib.toHexString w 8;
            hexH = pkgs.lib.toHexString h 8;
          in pkgs.lib.toBase64 (pkgs.lib.fromHex (hexW + hexH));

        addFlags = suffix: res: (lib.substring 0 11 (encodeResolution res.width res.height)) + suffix;

        # Эта функция теперь возвращает список готовых base64-строк для plist
        resToData = type: resolutions:
          let
            suffixMap = {
              type1 = "A";
              type2 = "AAAABACAAAA==";
              type3 = "AAAAB";
              type4 = "AAAAJAKAAAA==";
              custom = "AAAAB";
            };
            applyFlags = addFlags (suffixMap.${type});
          in map (res: applyFlags (parseRes res)) resolutions;

        allResolutions =
          (resToData "type1" display.resolutions.type1) ++
          (resToData "type2" display.resolutions.type2) ++
          (resToData "type3" display.resolutions.type3) ++
          (resToData "type4" display.resolutions.type4) ++
          (resToData "custom" display.resolutions.custom);

        plistFile = (pkgs.formats.plist {}).generate "DisplayProductID-${display.productId}" ({
          DisplayProductID = lib.stringToPath.fromHex display.productId;
          DisplayVendorID = lib.stringToPath.fromHex display.vendorId;
          "scale-resolutions" = allResolutions;
        } // lib.optionalAttrs (display.edid != null) {
          IODisplayEDID = pkgs.lib.toBase64 (pkgs.lib.fromHex display.edid);
        });

      in
      # listToAttrs ожидает на выходе сет с атрибутами 'name' и 'value'
      {
        name = "hidpi-override-${display.vendorId}-${display.productId}";
        value = {
          text = ''
            echo "Installing HiDPI override for display ${display.vendorId}-${display.productId}"
            TARGET_DIR="/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-${display.vendorId}"
            
            mkdir -p "$TARGET_DIR"
            
            cp "${plistFile}" "$TARGET_DIR/DisplayProductID-${display.productId}"
            
            echo "HiDPI override for ${display.vendorId}-${display.productId} installed."
          '';
        };
      }) cfg.displays);
  };
}
