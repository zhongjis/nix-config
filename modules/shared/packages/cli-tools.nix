{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Cross-platform CLI tools
    jc
    ast-grep
    yt-dlp
  ];
}
