# darwin-module.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.hidpi;
  
  # Функция для преобразования hex-строки в число
  hexToInt = hexStr: 
    let
      hexDigits = {
        "0" = 0; "1" = 1; "2" = 2; "3" = 3;
        "4" = 4; "5" = 5; "6" = 6; "7" = 7;
        "8" = 8; "9" = 9; "a" = 10; "b" = 11;
        "c" = 12; "d" = 13; "e" = 14; "f" = 15;
      };
      chars = lib.stringToCharacters (lib.toLower hexStr);
      values = map (c: hexDigits.${c}) chars;
      fold = list: lib.foldl (acc: val: acc * 16 + val) 0 list;
    in fold values;

  # Функция для кодирования разрешения в base64 с нужным суффиксом
  encodeResolution = width: height: suffix:
    let
      w = width * 2;
      h = height * 2;
      
      # Преобразуем числа в hex (8 символов каждое)
      toHex8 = num: 
        let
          hex = lib.toHexString num;
          padded = lib.fixedWidthString 8 "0" hex;
        in padded;
      
      hexW = toHex8 w;
      hexH = toHex8 h;
      
      # Создаем команду для кодирования через bash
      encodeScript = pkgs.writeShellScript "encode-res" ''
        printf '%s' "${hexW}${hexH}" | ${pkgs.xxd}/bin/xxd -r -p | ${pkgs.coreutils}/bin/base64 | ${pkgs.coreutils}/bin/tr -d '\n'
      '';
      
      # Выполняем и получаем base64
      base64Result = builtins.readFile (pkgs.runCommand "encoded-res" {} ''
        ${encodeScript} > $out
      '');
      
      # Берем первые 11 символов и добавляем суффикс
      result = (lib.substring 0 11 base64Result) + suffix;
    in result;

  # Функция для парсинга разрешения "3440x1440"
  parseResolution = resStr:
    let
      parts = lib.splitString "x" resStr;
      width = lib.toInt (builtins.elemAt parts 0);
      height = lib.toInt (builtins.elemAt parts 1);
    in { inherit width height; };

  # Генерация массива разрешений для каждого типа
  generateResolutions = display:
    let
      suffixes = {
        type1 = "A";
        type2 = "AAAABACAAAA==";
        type3 = "AAAAB";
        type4 = "AAAAJAKAAAA==";
      };
      
      processType = typeName: resList:
        map (resStr: 
          let res = parseResolution resStr;
          in encodeResolution res.width res.height suffixes.${typeName}
        ) resList;
      
      allRes = 
        (processType "type1" display.resolutions.type1) ++
        (processType "type2" display.resolutions.type2) ++
        (processType "type3" display.resolutions.type3) ++
        (processType "type4" display.resolutions.type4);
    in allRes;

  # Генерация plist-файла для каждого дисплея
  generatePlistForDisplay = display:
    let
      vendorId = hexToInt display.vendorId;
      productId = hexToInt display.productId;
      resolutions = generateResolutions display;
      
      plistContent = {
        DisplayProductID = productId;
        DisplayVendorID = vendorId;
        scale-resolutions = resolutions;
        target-default-ppmm = 10.0699301;
      } // lib.optionalAttrs (display.edid != null) {
        IODisplayEDID = pkgs.lib.toBase64 (pkgs.lib.fromHex display.edid);
      };
      
      plistFile = (pkgs.formats.plist {}).generate 
        "DisplayProductID-${display.productId}" 
        plistContent;
    in plistFile;

in
{
  # --- Опции модуля (без изменений) ---
  options.programs.hidpi = {
    enable = lib.mkEnableOption "Enable declarative HiDPI settings";
    
    displays = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          vendorId = lib.mkOption { 
            type = lib.types.str;
            description = "Vendor ID in hex format (e.g., '61a9')";
          };
          
          productId = lib.mkOption { 
            type = lib.types.str;
            description = "Product ID in hex format (e.g., '3447')";
          };
          
          resolutions = lib.mkOption {
            type = lib.types.submodule {
              options = {
                type1 = lib.mkOption { 
                  type = lib.types.listOf lib.types.str; 
                  default = [];
                  description = "Type 1 resolutions (suffix 'A')";
                };
                type2 = lib.mkOption { 
                  type = lib.types.listOf lib.types.str; 
                  default = [];
                  description = "Type 2 resolutions (suffix 'AAAABACAAAA==')";
                };
                type3 = lib.mkOption { 
                  type = lib.types.listOf lib.types.str; 
                  default = [];
                  description = "Type 3 resolutions (suffix 'AAAAB')";
                };
                type4 = lib.mkOption { 
                  type = lib.types.listOf lib.types.str; 
                  default = [];
                  description = "Type 4 resolutions (suffix 'AAAAJAKAAAA==')";
                };
              };
            };
            default = {};
          };
          
          edid = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional EDID data in hex format";
          };
        };
      });
      default = [];
    };
  };

  # --- Конфигурация системы ---
  config = lib.mkIf cfg.enable {
    system.activationScripts.hidpi = lib.mkAfter (
      lib.concatStringsSep "\n" (map (display:
        let
          plistFile = generatePlistForDisplay display;
          targetDir = "/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-${display.vendorId}";
          targetFile = "${targetDir}/DisplayProductID-${display.productId}";
        in ''
          echo "=== HiDPI Activation for ${display.vendorId}:${display.productId} at $(date) ==="
          
          # Создаем директорию
          mkdir -p "${targetDir}"
          
          # Копируем файл из Nix store
          cp -f "${plistFile}" "${targetFile}"
          
          # Устанавливаем правильные права
          chown root:wheel "${targetFile}"
          chmod 644 "${targetFile}"
          
          echo "✓ HiDPI override installed: ${targetFile}"
          
          # Включаем поддержку HiDPI в системе
          defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES
          
          echo "=== HiDPI Activation complete ==="
        ''
      ) cfg.displays)
    );
  };
}
