local servers = {
  lua_ls = {
    settings = {
      Lua = {
        completion = {
          callSnippet = "Replace",
        },
        runtime = {
          version = "LuaJIT",
        },
        diagnostics = {
          globals = {
            "vim",
          },
        },
        telemetry = {
          enable = false,
        },
      },
    },
  },
  jsonls = {},
  yamlls = {
    settings = {
      yaml = {
        schemas = {
          kubernetes = "*.yaml",
          ["https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/refs/heads/main/all.json"] = "*.yaml",
          ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
          ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
          ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
          ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
          ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
          ["http://json.schemastore.org/ansible-playbook"] = "*play*.{yml,yaml}",
          ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
          ["https://json.schemastore.org/dependabot-v2"] = ".github/dependabot.{yml,yaml}",
          ["https://json.schemastore.org/gitlab-ci"] = "*gitlab-ci*.{yml,yaml}",
          ["https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json"] = "*api*.{yml,yaml}",
          ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "*docker-compose*.{yml,yaml}",
          ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = "*flow*.{yml,yaml}",
        },
      },
    },
  },
  terraformls = {},
  ts_ls = {},
  jdtls = {},
  pyright = {},
  bashls = {},
  cssls = {},
  nixd = {
    settings = {
      nixd = {
        formatting = {},
        options = {
          nixos = {
            expr = '(builtins.getFlake "~/personal/nix-config").nixosConfigurations.framework-16.options',
          },
          nix_darwin = {
            expr = '(builtins.getFlake "~/personal/nix-config").darwinConfigurations.Zhongjies-MacBook-Pro.options',
          },
          home_manager = {
            expr = '(builtins.getFlake "~/personal/nix-config").homeConfigurations."zshen@framework-16".options',
          },
        },
      },
    },
  },
}

return {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "j-hui/fidget.nvim", opts = {} },
    "hrsh7th/cmp-nvim-lsp",
    {
      "Chaitanyabsprip/fastaction.nvim",
      ---@type FastActionConfig
      opts = {},
    },
  },
  config = function()
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
      callback = function(event)

        -- stylua: ignore start
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
        end

        -- NOTE: goto actions
        map("gd", "<cmd>Trouble lsp_definitions toggle<cr>", "[G]oto [D]efinition")
        map("gD", "<cmd>Trouble lsp_declarations toggle<cr>", "[G]oto [D]eclaration")
        map("gr", "<cmd>Trouble lsp_references toggle<cr>", "[G]oto [R]eferences")
        map("gi", "<cmd>Trouble lsp_implementations toggle<cr>", "[G]oto [I]mplementation")
        map("gtd", "<cmd>Trouble lsp_type_definitions toggle<cr>", "[G]oto [T]ype [D]efinition")

        -- NOTE: document actions
        map("<leader>ds", "<cmd>Trouble lsp_document_symbols toggle<cr>", "[D]ocument [S]ymbols")
        map("<leader>dd","<cmd>Trouble diagnostics toggle<cr>","[D]ocument [D]iagnostics List")

        map("[d", "<cmd>Trouble diagnostics prev<cr>", "Go to previous [D]iagnostic message")
        map("]d", "<cmd>Trouble diagnostics next<cr>", "Go to next [D]iagnostic message")

        map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        map("<leader>ca", "<cmd> lua require(\"fastaction\").code_action()<cr>", "[C]ode [A]ction")
        map("K", vim.lsp.buf.hover, "Hover Documentation")
        -- stylua: ignore end

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          local highlight_augroup =
            vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup(
              "kickstart-lsp-detach",
              { clear = true }
            ),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({
                group = "kickstart-lsp-highlight",
                buffer = event2.buf,
              })
            end,
          })
        end

        if
          client
          and client.server_capabilities.inlayHintProvider
          and vim.lsp.inlay_hint
        then
          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, "[T]oggle Inlay [H]ints")
        end
      end,
    })

    local signs = { ERROR = "", WARN = "", INFO = "", HINT = "" }
    local diagnostic_signs = {}
    for type, icon in pairs(signs) do
      diagnostic_signs[vim.diagnostic.severity[type]] = icon
    end
    vim.diagnostic.config({ signs = { text = diagnostic_signs } })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend(
      "force",
      capabilities,
      require("cmp_nvim_lsp").default_capabilities()
    )

    for server, config in pairs(servers) do
      config.capabilities =
        vim.tbl_deep_extend("force", config.capabilities or {}, capabilities)
      require("lspconfig")[server].setup(config)
    end
  end,
}
