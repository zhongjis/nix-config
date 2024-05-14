local cmp = require("cmp")
local luasnip = require("luasnip")
luasnip.config.setup()

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = "menu,menuone,noinsert",
  },

  mapping = cmp.mapping.preset.insert({
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-y>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete({}),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
    { name = "path" },
  }, {
    { name = "buffer" },
  }),
  formatting = {
    format = function(entry, vim_item)
      if vim.tbl_contains({ "path" }, entry.source.name) then
        local icon, hl_group =
          require("nvim-web-devicons").get_icon(entry:get_completion_item().label)
        if icon then
          vim_item.kind = icon
          vim_item.kind_hl_group = hl_group
          return vim_item
        end
      end
      return require("lspkind").cmp_format({ with_text = false })(entry, vim_item)
    end,
  },
})

-- `/` cmdline setup.
cmp.setup.cmdline("/", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "buffer" },
  },
})

-- `:` cmdline setup.
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = "path" },
  }, {
    {
      name = "cmdline",
      option = {
        ignore_cmds = { "Man", "!" },
      },
    },
  }),
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
  callback = function(event)
    -- stylua: ignore start
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
    end

    -- NOTE: goto actions
    map("gd", "<cmd>Trouble lsp_definitions<cr>", "[G]oto [D]efinition")
    map("gD", "<cmd>Trouble lsp_declarations<cr>", "[G]oto [D]eclaration")
    map("gr", "<cmd>Trouble lsp_references<cr>", "[G]oto [R]eferences")
    map("gi", "<cmd>Trouble lsp_implementations<cr>", "[G]oto [I]mplementation")
    map("gtd", "<cmd>Trouble lsp_type_definitions<cr>", "[G]oto [T]ype [D]efinition")

    -- NOTE: document actions
    map("<leader>ds", "<cmd>Trouble lsp_document_symbols<cr>", "[D]ocument [S]ymbols")
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
    end
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
  callback = function(event)
    vim.lsp.buf.clear_references()
    vim.api.nvim_clear_autocmds({
      group = "kickstart-lsp-highlight",
      buffer = event.buf,
    })
  end,
})

require("fidget").setup()
require("neodev").setup()

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "nil_ls",
    "jsonls",
    "yamlls",
    "terraformls",
    "tflint",
    "bashls",
    "tsserver",
  },

  handlers = {
    function(server_name)
      require("lspconfig")[server_name].setup({})
    end,

    lua_ls = function()
      require("lspconfig").lua_ls.setup({
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
      })
    end,
  },
})
