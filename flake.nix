{
  description = "Declarative macOS HiDPI configuration for nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Определяем поддерживаемые системы один раз, чтобы избежать повторений
      supportedSystems = [ "x86_64-darwin" "aarch64-darwin" ];

      # Создаем pkgs для каждой системы
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    in
    {
      # Модуль для nix-darwin остается без изменений
      darwinModules.default = import ./darwin-module.nix;

      # Пакеты для каждой поддерживаемой системы
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Используем writeShellScriptBin для простой упаковки скрипта.
          # Это намного проще и эффективнее, чем mkDerivation.
          display-info = pkgs.writeShellScriptBin "display-info" (
            # Встраиваем содержимое файла display-info.sh прямо в пакет.
            # Nix будет автоматически отслеживать изменения в этом файле.
            builtins.readFile ./display-info.sh
          );
        });

      # Определяем пакет по умолчанию для каждой системы отдельно,
      # чтобы избежать ошибки бесконечной рекурсии.
      defaultPackage = forAllSystems (system: self.packages.${system}.display-info);
    };
}
