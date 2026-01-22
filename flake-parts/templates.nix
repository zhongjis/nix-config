{ ... }:
{
  flake.templates = {
    java8 = {
      path = ../templates/java8;
      description = "nix flake new -t github:zhongjis/nix-config#java8 .";
    };
    nodejs22 = {
      path = ../templates/nodejs22;
      description = "nix flake new -t github:zhongjis/nix-config#nodejs22 .";
    };
  };
}
