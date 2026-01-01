# OpenCode formatters configuration module
# Defines code formatters for different programming languages
# from: https://github.com/khaneliman/khanelinix/blob/main/modules/home/programs/terminal/tools/opencode/formatters.nix
{
  lib,
  pkgs,
  ...
}: {
  programs.opencode.settings.formatter = {
    # nixfmt = {
    #   command = [
    #     (lib.getExe pkgs.nixfmt)
    #     "$FILE"
    #   ];
    #   extensions = [".nix"];
    # };

    # csharpier = {
    #   command = [
    #     (lib.getExe pkgs.csharpier)
    #     "$FILE"
    #   ];
    #   extensions = [
    #     ".cs"
    #   ];
    # };

    # rustfmt = {
    #   command = [
    #     (lib.getExe pkgs.rustfmt)
    #     "$FILE"
    #   ];
    #   extensions = [".rs"];
    # };
  };
}
