{
  lib,
  pkgs,
  ...
}: let
  mkServer = {
    command,
    extensions,
    rootMarkers,
    initialization ? null,
  }:
    {
      command = builtins.head command;
      fileTypes = extensions;
      inherit rootMarkers;
    }
    // lib.optionalAttrs (builtins.length command > 1) {
      args = builtins.tail command;
    }
    // lib.optionalAttrs (initialization != null) {
      initOptions = initialization;
    };

  lspConfig = {
    servers = {
      nixd = mkServer {
        command = [(lib.getExe pkgs.nixd)];
        extensions = [".nix"];
        rootMarkers = [
          "flake.nix"
          "default.nix"
          "shell.nix"
        ];
        initialization = {
          formatting = {
            command = [(lib.getExe pkgs.alejandra)];
          };
        };
      };

      emmylua-ls = mkServer {
        command = [(lib.getExe pkgs.emmylua-ls)];
        extensions = [".lua"];
        rootMarkers = [
          ".luarc.json"
          ".luarc.jsonc"
          ".luacheckrc"
          ".stylua.toml"
          "stylua.toml"
        ];
        initialization = {
          Lua = {
            diagnostics = {
              globals = [
                "vim"
                "Sbar"
                "spoon"
              ];
            };
            workspace = {
              library = [
                "/nix/store/*/share/lua/5.1"
                "/etc/profiles/per-user/khaneliman/share/lua/5.1"
              ];
            };
          };
        };
      };

      pyright = mkServer {
        command = [
          (lib.getExe' pkgs.basedpyright "basedpyright-langserver")
          "--stdio"
        ];
        extensions = [
          ".py"
          ".pyi"
        ];
        rootMarkers = [
          "pyproject.toml"
          "pyrightconfig.json"
          "setup.py"
          "requirements.txt"
        ];
      };

      bashls = mkServer {
        command = [
          (lib.getExe pkgs.bash-language-server)
          "start"
        ];
        extensions = [
          ".sh"
          ".bash"
        ];
        rootMarkers = [".git"];
      };

      typescript = mkServer {
        command = [
          (lib.getExe pkgs.typescript-language-server)
          "--stdio"
        ];
        extensions = [
          ".ts"
          ".tsx"
          ".js"
          ".jsx"
          ".mjs"
          ".cjs"
          ".mts"
          ".cts"
        ];
        rootMarkers = [
          "package.json"
          "tsconfig.json"
          "jsconfig.json"
        ];
      };

      yamlls = mkServer {
        command = [
          (lib.getExe pkgs.yaml-language-server)
          "--stdio"
        ];
        extensions = [
          ".yaml"
          ".yml"
        ];
        rootMarkers = [".git"];
      };

      jsonls = mkServer {
        command = [
          (lib.getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server")
          "--stdio"
        ];
        extensions = [
          ".json"
          ".jsonc"
        ];
        rootMarkers = [
          "package.json"
          ".git"
        ];
      };

      taplo = mkServer {
        command = [
          (lib.getExe pkgs.taplo)
          "lsp"
          "stdio"
        ];
        extensions = [".toml"];
        rootMarkers = [
          ".taplo.toml"
          "taplo.toml"
          ".git"
        ];
      };

      jdtls = mkServer {
        command = [(lib.getExe pkgs.jdt-language-server)];
        extensions = [".java"];
        rootMarkers = [
          "pom.xml"
          "build.gradle"
          "build.gradle.kts"
          "settings.gradle"
          ".project"
        ];
      };

      metals = mkServer {
        command = [(lib.getExe pkgs.metals)];
        extensions = [
          ".scala"
          ".sbt"
          ".sc"
        ];
        rootMarkers = [
          "build.sbt"
          "build.sc"
          "build.gradle"
          "pom.xml"
        ];
      };
    };
  };
in {
  programs."oh-my-pi".lsp = lspConfig;
}
