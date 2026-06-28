# Common LSP source of truth for AI tools.
{
  lib,
  pkgs,
  ...
}: let
  commonLsp = {
    nixd = {
      command = [(lib.getExe pkgs.nixd)];
      extensions = [".nix"];
      initialization = {
        formatting = {
          command = [(lib.getExe pkgs.alejandra)];
        };
      };
    };

    emmylua-ls = {
      command = [(lib.getExe pkgs.emmylua-ls)];
      extensions = [".lua"];
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

    pyright = {
      command = [
        (lib.getExe' pkgs.basedpyright "basedpyright-langserver")
        "--stdio"
      ];
      extensions = [
        ".py"
        ".pyi"
      ];
    };

    bashls = {
      command = [
        (lib.getExe pkgs.bash-language-server)
        "start"
      ];
      extensions = [
        ".sh"
        ".bash"
      ];
    };

    typescript = {
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
    };

    yamlls = {
      command = [
        (lib.getExe pkgs.yaml-language-server)
        "--stdio"
      ];
      extensions = [
        ".yaml"
        ".yml"
      ];
    };

    jsonls = {
      command = [
        (lib.getExe' pkgs.vscode-langservers-extracted "vscode-json-language-server")
        "--stdio"
      ];
      extensions = [
        ".json"
        ".jsonc"
      ];
    };

    taplo = {
      command = [
        (lib.getExe pkgs.taplo)
        "lsp"
        "stdio"
      ];
      extensions = [".toml"];
    };

    jdtls = {
      command = [(lib.getExe pkgs.jdt-language-server)];
      extensions = [".java"];
    };

    metals = {
      command = [(lib.getExe pkgs.metals)];
      extensions = [
        ".scala"
        ".sbt"
        ".sc"
      ];
    };
  };
in {
  config._module.args.commonLsp = commonLsp;
}
