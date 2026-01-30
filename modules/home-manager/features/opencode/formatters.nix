# OpenCode formatters configuration module
# Defines code formatters for different programming languages
# from: https://github.com/khaneliman/khanelinix/blob/main/modules/home/programs/terminal/tools/opencode/formatters.nix
{
  lib,
  pkgs,
  ...
}: {
  programs.opencode.settings.formatter = {
    alejandra = {
      command = [
        (lib.getExe pkgs.alejandra)
        "$FILE"
      ];
      extensions = [".nix"];
    };

    black = {
      command = [
        (lib.getExe pkgs.black)
        "--line-length"
        "85"
        "$FILE"
      ];
      extensions = [".py"];
    };

    prettierd = {
      command = [
        (lib.getExe pkgs.prettierd)
        "$FILE"
      ];
      extensions = [
        ".js"
        ".jsx"
        ".ts"
        ".tsx"
        ".mjs"
        ".cjs"
        ".mts"
        ".cts"
        ".json"
        ".yaml"
        ".yml"
        ".md"
        ".css"
      ];
    };

    google-java-format = {
      command = [
        (lib.getExe pkgs.google-java-format)
        "--replace"
        "$FILE"
      ];
      extensions = [".java"];
    };

    scalafmt = {
      command = [
        (lib.getExe pkgs.scalafmt)
        "--non-interactive"
        "$FILE"
      ];
      extensions = [
        ".scala"
        ".sbt"
        ".sc"
      ];
    };
  };
}
