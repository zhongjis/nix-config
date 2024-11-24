{
  lib,
  config,
  ...
}: {
  options = {
    git.enable =
      lib.mkEnableOption "enables git";
  };

  config = lib.mkIf config.git.enable {
    programs.git = {
      enable = true;
      userName = "zhongjis";
      userEmail = "zhongjie.x.shen@gmail.com";

      aliases = {};

      attributes = [
        "push.default current"
      ];
    };
  };
}
