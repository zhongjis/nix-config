{...}: {
  programs.git = {
    enable = true;
    userName = "zhongjis";
    userEmail = "zhongjie.x.shen@gmail.com";

    aliases = {};

    attributes = [
      "push.default current"
    ];
  };
}
