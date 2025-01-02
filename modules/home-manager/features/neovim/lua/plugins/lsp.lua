return {
  -- Main LSP Configuration
  "neovim/nvim-lspconfig",
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    { "williamboman/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
    "williamboman/mason-lspconfig.nvim",

    { "j-hui/fidget.nvim", opts = {} },

    -- Allows extra capabilities provided by nvim-cmp
    "hrsh7th/cmp-nvim-lsp",
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
        map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
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
      yamlls = {},
      terraformls = {},
      tflint = {},
      ts_ls = {},
      jdtls = {},
      pyright = {},
      bashls = {},
      groovyls = {},
    }

    for server, config in pairs(servers) do
      config.capabilities =
        vim.tbl_deep_extend("force", config.capabilities or {}, capabilities)
      require("lspconfig")[server].setup(config)
    end
  end,
}