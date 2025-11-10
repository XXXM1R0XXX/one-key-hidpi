# darwin-module.nix
{ config, lib, pkgs, ... }:

let
  # Сокращение для доступа к конфигурации вашего модуля
  cfg = config.programs.hidpi;

  # Вспомогательная функция для конвертации строки разрешения (например, "1920x1080")
  # в требуемый формат base64 для plist-файла.
  # Эта логика теперь выполняется на чистом Nix, а не в shell.
  resolutionToData = resolution:
    let
      parts = lib.splitString "x" resolution;
      width = lib.toInt (builtins.elemAt parts 0);
      height = lib.toInt (builtins.elemAt parts 1);
      # Формат: два 32-битных целых числа (по 8 hex-символов), big-endian.
      # pkgs.lib.toHexString форматирует числа в шестнадцатеричный вид с нужной длиной.
      hex = pkgs.lib.toHexString width 8 + pkgs.lib.toHexString height 8;
    in
    # pkgs.lib.fromHex преобразует hex-строку в бинарные данные,
    # а pkgs.lib.toBase64 кодирует их.
    pkgs.lib.toBase64 (pkgs.lib.fromHex hex);

in
{
  # Раздел опций остается таким же — он спроектирован отлично.
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

  # Раздел конфигурации полностью переписан.
  config = lib.mkIf cfg.enable {
    # Используем environment.etc для декларативного управления файлами.
    # Nix сам позаботится о создании файлов с правильным содержимым и правами.
    environment.etc = lib.foldl' (acc: display: acc // {
      # Путь к файлу внутри /etc (nix-darwin свяжет его с /Library/Displays/...).
      "Displays/Contents/Resources/Overrides/DisplayVendorID-${display.vendorId}/DisplayProductID-${display.productId}" = {
        # Генерируем корректный plist-файл с помощью встроенного генератора.
        source = (pkgs.formats.plist {}).generate "DisplayProductID-${display.productId}" {
          # lib.stringToPath.fromHex преобразует hex-строку в число, которое ожидает plist.
          DisplayProductID = lib.stringToPath.fromHex display.productId;
          DisplayVendorID = lib.stringToPath.fromHex display.vendorId;
          # Применяем нашу функцию к каждому разрешению.
          scale-resolutions = map resolutionToData display.resolutions;
        };
        # Nix автоматически установит правильные права доступа.
        user = "root";
        group = "wheel";
      };
    }) {} cfg.displays;
  };
}
