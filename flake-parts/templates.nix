{...}: {
  flake.templates = {
    java8 = {
      path = ../templates/java8;
      description = "nix flake new -t github:zhongjis/nix-config#java8 .";
    };
    nodejs26 = {
      path = ../templates/nodejs26;
      description = "nix flake new -t github:zhongjis/nix-config#nodejs26 .";
    };
  };
}
