# darwin-module.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.hidpi;
in
{
  # --- ОПЦИИ МОДУЛЯ ---
  # Пользователь будет настраивать их в своем flake.nix
  options.programs.hidpi = {
    enable = lib.mkEnableOption "Enable declarative HiDPI settings";

    displays = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          vendorId = lib.mkOption {
            type = lib.types.str;
            description = "Vendor ID вашего монитора (в hex, например '61a9').";
          };
          productId = lib.mkOption {
            type = lib.types.str;
            description = "Product ID вашего монитора (в hex, например '3447').";
          };
          # Прямой перевод опций из скрипта hidpi.sh
          resolutions = lib.mkOption {
            type = lib.types.submodule {
              options = {
                # Аналог create_res_1
                type1 = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
                # Аналог create_res_2
                type2 = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
                # Аналог create_res_3
                type3 = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
                # Аналог create_res_4
                type4 = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
                # Аналог custom_res
                custom = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
              };
            };
            default = {};
            description = "Набор разрешений, сгруппированных по типам из оригинального скрипта.";
          };
          # Опция для EDID
          edid = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Полный EDID монитора в виде hex-строки (если нужна инъекция EDID).";
          };
        };
      });
      default = [];
    };
  };

  # --- КОНФИГУРАЦИЯ СИСТЕМЫ ---
  # Эта часть будет выполняться, если `programs.hidpi.enable = true;`
  config = lib.mkIf cfg.enable {
    system.activationScripts =
      # Используем mapAttrs' для создания скрипта для каждого дисплея
      lib.mapAttrs' (index: display:
        let
          # --- ПЕРЕВОД ЛОГИКИ BASH НА NIX ---

          # Вспомогательная функция для преобразования "1920x1080" в пару чисел
          parseRes = res: {
            width = lib.toInt (builtins.elemAt (lib.splitString "x" res) 0);
            height = lib.toInt (builtins.elemAt (lib.splitString "x" res) 1);
          };

          # Главная функция кодирования. Точно повторяет:
          # `printf '%08x %08x' $((width * 2)) $((height * 2)) | xxd -r -p | base64`
          encodeResolution = width: height:
            let
              # Умножаем на 2, как в скрипте
              w = width * 2;
              h = height * 2;
              # Преобразуем в 8-символьную hex-строку (32-bit, big-endian)
              hexW = pkgs.lib.toHexString w 8;
              hexH = pkgs.lib.toHexString h 8;
              # Конвертируем hex в бинарные данные и кодируем в base64
            in pkgs.lib.toBase64 (pkgs.lib.fromHex (hexW + hexH));

          # Функции, которые добавляют нужные флаги к base64-строке, как в hidpi.sh
          # Они обрезают строку до 11 символов и добавляют суффикс
          addFlags = suffix: res: (lib.substring 0 11 (encodeResolution res.width res.height)) + suffix;

          resToData = type: resolutions:
            let
              # Суффиксы, взятые прямо из скрипта hidpi.sh
              suffixMap = {
                type1 = "A";                           # create_res_1
                type2 = "AAAABACAAAA==";                 # create_res_2
                type3 = "AAAAB";                         # create_res_3
                type4 = "AAAAJAKAAAA==";                 # create_res_4
                custom = "AAAAB";                        # create_res (использует два варианта, берем основной)
              };
              applyFlags = addFlags (suffixMap.${type});
            in map (res: pkgs.lib.toBase64 (applyFlags (parseRes res))) resolutions;


          # Собираем все разрешения в один список для plist
          allResolutions =
            (resToData "type1" display.resolutions.type1) ++
            (resToData "type2" display.resolutions.type2) ++
            (resToData "type3" display.resolutions.type3) ++
            (resToData "type4" display.resolutions.type4) ++
            (resToData "custom" display.resolutions.custom);

          # --- Генерация Plist и Скрипта Активации ---
          
          # Генерируем plist декларативно. Это надежно.
          plistFile = (pkgs.formats.plist {}).generate "DisplayProductID-${display.productId}" ({
            DisplayProductID = lib.stringToPath.fromHex display.productId;
            DisplayVendorID = lib.stringToPath.fromHex display.vendorId;
            "scale-resolutions" = allResolutions;
          } // lib.optionalAttrs (display.edid != null) {
            # Добавляем EDID только если он указан
            IODisplayEDID = pkgs.lib.toBase64 (pkgs.lib.fromHex display.edid);
          });

        in {
          # Имя для скрипта активации
          name = "hidpi-override-${display.vendorId}-${display.productId}";
          # Код скрипта
          value.text = ''
            echo "Installing HiDPI override for display ${display.vendorId}-${display.productId}"
            TARGET_DIR="/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-${display.vendorId}"
            
            # Создаем целевую директорию
            mkdir -p "$TARGET_DIR"
            
            # Копируем наш сгенерированный файл из хранилища Nix
            cp "${plistFile}" "$TARGET_DIR/DisplayProductID-${display.productId}"
            
            echo "HiDPI override for ${display.vendorId}-${display.productId} installed."
          '';
        })
      (lib.range 0 (builtins.length cfg.displays - 1)) # Итерируем по индексам списка displays
      cfg.displays;
  };
}
