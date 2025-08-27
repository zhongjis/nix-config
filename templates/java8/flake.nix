{
  description = "Java 8 Dev Env";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    javaVersion = 8;
  in
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        overlays.default = final: prev: let
        in rec {
          jdk = prev."jdk${toString javaVersion}";
          maven = prev.maven.override {jdk_headless = jdk;};
          lombok = prev.lombok.override {inherit jdk;};
        };

        devShells.default = pkgs.mkShell {
          shell = "/bin/zsh";
          shellHook = let
            loadLombok = "-javaagent:${pkgs.lombok}/share/java/lombok.jar";
            prev = "\${JAVA_TOOL_OPTIONS:+ $JAVA_TOOL_OPTIONS}";
          in ''
            export JAVA_TOOL_OPTIONS="${loadLombok}${prev}"
            echo "[[java_8]] shell activated!!!"
          '';
          packages = with pkgs; [
            gcc
            jdk
            maven
            ncurses
            patchelf
            zlib
          ];
        };
      }
    );
}
