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
    # Мы будем динамически генерировать набор скриптов активации,
    # по одному для каждого дисплея.
    system.activationScripts = lib.foldl' (acc: display: acc // {
      # Генерируем уникальное имя для каждого скрипта
      "hidpi-override-${display.vendorId}-${display.productId}" = {
        # 'let' позволяет нам сгенерировать plist-файл и получить путь к нему
        let
          # 1. Декларативно создаем идеальный plist-файл.
          #    Результатом будет путь в /nix/store/...
          plistFile = (pkgs.formats.plist {}).generate "DisplayProductID-${display.productId}" {
            DisplayProductID = lib.stringToPath.fromHex display.productId;
            DisplayVendorID = lib.stringToPath.fromHex display.vendorId;
            scale-resolutions = map resolutionToData display.resolutions;
          };
        in
        # 2. Создаем простой и надежный скрипт для копирования этого файла.
        text = ''
          echo "Installing HiDPI override for display ${display.vendorId}-${display.productId}"
          TARGET_DIR="/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-${display.vendorId}"
          
          # Создаем целевую директорию
          mkdir -p "$TARGET_DIR"
          
          # Копируем наш сгенерированный файл из хранилища Nix
          # Переменная ${plistFile} будет заменена Nix на реальный путь в /nix/store
          cp "${plistFile}" "$TARGET_DIR/DisplayProductID-${display.productId}"
          
          # Устанавливаем права доступа (на всякий случай)
          chmod 644 "$TARGET_DIR/DisplayProductID-${display.productId}"
        '';
      };
    }) {} cfg.displays; # Начинаем с пустого набора атрибутов и добавляем по одному скрипту на каждый дисплей
  };
}
