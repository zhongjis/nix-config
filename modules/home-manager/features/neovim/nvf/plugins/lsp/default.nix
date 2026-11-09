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
    gotmpl # For Go template support (.yaml.gotmpl, helm charts, etc.)
  ];

  vim.languages = {
    enableTreesitter = true;
    enableExtraDiagnostics = true;

    # Nix
    nix = {
      enable = true;
      lsp.servers = ["nixd"];
    };

    # Json
    json.enable = true;

    # Markdown
    markdown.enable = true;

    # Bash/Shell
    bash.enable = true;

    # Lua
    lua = {
      enable = true;
      extensions.lazydev.enable = true;
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
    python = {
      enable = true;
      lsp.servers = ["basedpyright" "ruff"];
      extraDiagnostics.enable = false;
    };

    # CSS
    css.enable = true;

    # Tailwind CSS

    # HTML
    html.enable = true;

    # SQL
    sql.enable = true;

    # TypeScript/JavaScript
    typescript = {
      enable = true;
      extraDiagnostics.enable = false;
      extensions.ts-error-translator.enable = true;
      format.type = ["prettier"];
    };
    tsx = {
      enable = true;
      extraDiagnostics.enable = false;
    };
  };

  # Tailwind CSS
  vim.lsp.presets.tailwindcss-language-server.enable = true;

  vim.lsp.servers = {
    basedpyright.settings.basedpyright = {
      analysis = {
        typeCheckingMode = "standard";
        autoImportCompletions = true;
      };
      disableOrganizeImports = true;
    };
    ruff.on_attach = lib.generators.mkLuaInline ''
      function(client)
        client.server_capabilities.hoverProvider = false
      end
    '';
    # Per-project -data dir; nvf's preset shares one workspace across all projects.
    jdt-language-server.cmd = lib.mkForce (lib.generators.mkLuaInline ''
      function(dispatchers, config)
        local root = config.root_dir or vim.fn.getcwd()
        local id = vim.fn.fnamemodify(root, ":t") .. "-" .. vim.fn.sha256(root):sub(1, 8)
        return vim.lsp.rpc.start({
          "${lib.getExe pkgs.jdt-language-server}",
          "-configuration",
          get_jdtls_config_dir(),
          "-data",
          get_jdtls_cache_dir() .. "/workspace/" .. id,
          get_jdtls_jvm_args(),
        }, dispatchers, {
          cwd = config.cmd_cwd,
          env = config.cmd_env,
          detached = config.detached,
        })
      end
    '');
    # Java settings for Spring Framework
    jdt-language-server.settings.java = {
      signatureHelp.enabled = true;
      completion = {
        favoriteStaticMembers = [
          "org.junit.jupiter.api.Assertions.*"
          "org.junit.Assert.*"
          "org.mockito.Mockito.*"
          "org.mockito.ArgumentMatchers.*"
          "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*"
          "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*"
          "java.util.Objects.requireNonNull"
          "java.util.Objects.requireNonNullElse"
        ];
        filteredTypes = [
          "com.sun.*"
          "io.micrometer.shaded.*"
          "java.awt.*"
          "jdk.*"
          "sun.*"
        ];
        importOrder = ["java" "javax" "org" "com" ""];
      };
      codeGeneration = {
        toString.template = "\${object.className}{\${member.name()}=\${member.value}, \${otherMembers}}";
        hashCodeEquals = {
          useJava7Objects = true;
          useInstanceof = true;
        };
        useBlocks = true;
      };
      inlayHints.parameterNames.enabled = "all";
      eclipse.downloadSources = true;
      maven.downloadSources = true;
      autobuild.enabled = true;
    };
    typescript-language-server.init_options.preferences = {
      includeCompletionsForModuleExports = true;
      includeCompletionsForImportStatements = true;
      includePackageJsonAutoImports = "auto";
      includeInlayParameterNameHints = "all";
      includeInlayParameterNameHintsWhenArgumentMatchesName = false;
      includeInlayFunctionParameterTypeHints = true;
      includeInlayVariableTypeHints = true;
      includeInlayPropertyDeclarationTypeHints = true;
      includeInlayFunctionLikeReturnTypeHints = true;
      includeInlayEnumMemberValueHints = true;
    };
  };

  # Advanced LSP settings via Lua configuration
  # These settings are applied after LSP servers are attached
  vim.luaConfigRC.lsp-settings = lib.nvim.dag.entryAfter ["lsp"] ''
    -- nvf's nvim-metals module also attaches Metals to java buffers; replace its
    -- FileType autocmd so Java gets jdtls only.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("lsp", { clear = true }),
      pattern = { "scala", "sbt" },
      callback = function()
        require("metals").initialize_or_attach(metals_config)
      end,
    })

    -- Configure LSP servers with advanced settings
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then return end

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

        -- Enable inlay hints if supported (Neovim 0.10+)
        if client:supports_method("textDocument/inlayHint") then
          vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
        end
      end,
    })
  '';
}
