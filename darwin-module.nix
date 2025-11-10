# darwin-module.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.hidpi;
in
{
  # --- Опции модуля (без изменений) ---
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

  # --- Конфигурация системы (с исправлениями) ---
  config = lib.mkIf cfg.enable {
    system.activationScripts = lib.listToAttrs (map (display:
      let
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

        resToData = type: resolutions:
          let
            suffixMap = {
              type1 = "A"; type2 = "AAAABACAAAA=="; type3 = "AAAAB";
              type4 = "AAAAJAKAAAA=="; custom = "AAAAB";
            };
            applyFlags = addFlags (suffixMap.${type});
          #
          # !!! ВОТ ЗДЕСЬ БЫЛА ОШИБКА !!!
          # Мы убрали лишнее кодирование pkgs.lib.toBase64
          #
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
      {
        name = "hidpi-override-${display.vendorId}-${display.productId}";
        value = {
          text = ''
            # --- ОТЛАДКА ---
            # Эта строка будет меняться при каждой сборке, заставляя скрипт запускаться
            echo "--- HiDPI Activation Script running at $(date) ---"

            echo "Installing HiDPI override for display ${display.vendorId}-${display.productId}"
            TARGET_DIR="/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-${display.vendorId}"
            
            mkdir -p "$TARGET_DIR"
            
            # Копируем наш сгенерированный файл из хранилища Nix
            cp "${plistFile}" "$TARGET_DIR/DisplayProductID-${display.productId}"
            
            echo "HiDPI override file created at $TARGET_DIR/DisplayProductID-${display.productId}"
            echo "--- HiDPI Activation Script finished ---"
          '';
        };
      }) cfg.displays);
  };
}
