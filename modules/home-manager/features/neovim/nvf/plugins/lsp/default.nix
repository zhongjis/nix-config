{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./formatter.nix
    ./lint.nix
  ];

  vim.lsp.enable = true;
  vim.lsp.lspkind.enable = true;

  # Additional treesitter grammars
  vim.treesitter.grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
    gitignore
    xml
    groovy # For Jenkinsfile support
  ];

  vim.languages = {
    enableTreesitter = true;
    enableExtraDiagnostics = true;

    # Nix
    nix = {
      enable = true;
      lsp.servers = ["nixd"];
    };

    # Markdown
    markdown.enable = true;

    # Bash/Shell
    bash.enable = true;

    # Lua
    lua = {
      enable = true;
      lsp.lazydev.enable = true;
    };

    # Java - for Spring Framework development
    java.enable = true;

    # Scala - works with both Scala 2.x and 3.x (Metals auto-detects)
    scala.enable = true;

    # Terraform
    terraform.enable = true;

    # YAML
    yaml.enable = true;

    # Python
    python.enable = true;

    # CSS
    css.enable = true;

    # Tailwind CSS
    tailwind.enable = true;

    # HTML
    html.enable = true;

    # SQL
    sql.enable = true;

    # TypeScript/JavaScript
    ts = {
      enable = true;
      extensions.ts-error-translator.enable = true;
      format.type = ["prettierd"];
    };
  };

  # Advanced LSP settings via Lua configuration
  # These settings are applied after LSP servers are attached
  vim.luaConfigRC.lsp-settings = lib.nvim.dag.entryAfter ["lsp"] ''
    -- Configure LSP servers with advanced settings
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then return end

        -- Java (jdtls) settings for Spring Framework
        if client.name == "jdtls" then
          client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
            java = {
              signatureHelp = { enabled = true },
              completion = {
                favoriteStaticMembers = {
                  "org.junit.jupiter.api.Assertions.*",
                  "org.junit.Assert.*",
                  "org.mockito.Mockito.*",
                  "org.mockito.ArgumentMatchers.*",
                  "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
                  "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
                  "java.util.Objects.requireNonNull",
                  "java.util.Objects.requireNonNullElse",
                },
                filteredTypes = {
                  "com.sun.*",
                  "io.micrometer.shaded.*",
                  "java.awt.*",
                  "jdk.*",
                  "sun.*",
                },
                importOrder = { "java", "javax", "org", "com", "" },
              },
              sources = {
                organizeImports = {
                  starThreshold = 5,
                  staticStarThreshold = 3,
                },
              },
              codeGeneration = {
                toString = {
                  template = "''${object.className}{''${member.name()}=''${member.value}, ''${otherMembers}}",
                },
                hashCodeEquals = {
                  useJava7Objects = true,
                  useInstanceof = true,
                },
                useBlocks = true,
              },
              inlayHints = {
                parameterNames = { enabled = "all" },
              },
              eclipse = { downloadSources = true },
              maven = { downloadSources = true },
              autobuild = { enabled = true },
            },
          })
          client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        end

        -- Scala (metals) settings for Scala 2.x/3.x compatibility
        if client.name == "metals" then
          client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
            metals = {
              showImplicitArguments = true,
              showImplicitConversionsAndClasses = true,
              showInferredType = true,
              superMethodLensesEnabled = true,
              enableSemanticHighlighting = true,
              inlayHints = {
                inferredTypes = { enable = true },
                implicitArguments = { enable = true },
                implicitConversions = { enable = true },
                typeParameters = { enable = true },
                hintsInPatternMatch = { enable = true },
              },
              excludedPackages = {
                "akka.actor.typed.javadsl",
                "com.github.swagger.akka.javadsl",
              },
            },
          })
          client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        end

        -- Python (pyright) settings
        if client.name == "pyright" then
          client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
            python = {
              analysis = {
                typeCheckingMode = "standard",
                autoImportCompletions = true,
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          })
          client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        end

        -- TypeScript/JavaScript settings
        if client.name == "ts_ls" or client.name == "tsserver" or client.name == "vtsls" then
          client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
              suggest = {
                includeCompletionsForModuleExports = true,
              },
              updateImportsOnFileMove = { enabled = "always" },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
              suggest = {
                includeCompletionsForModuleExports = true,
              },
              updateImportsOnFileMove = { enabled = "always" },
            },
          })
          client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        end

        -- Enable inlay hints if supported (Neovim 0.10+)
        if client.supports_method("textDocument/inlayHint") then
          vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end
      end,
    })
  '';
}
