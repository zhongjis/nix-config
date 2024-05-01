local map = function(keys, func, desc)
  vim.keymap.set("n", keys, func, { desc = desc })
end

map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- **diagnostic**
map("[d", vim.diagnostic.goto_prev, "Go to previous [D]iagnostic message")
map("]d", vim.diagnostic.goto_next, "Go to next [D]iagnostic message")
map("<leader>e", vim.diagnostic.open_float, "Show diagnostic [E]rror messages")

-- **oil**
map("<leader>o", "<CMD>Oil<CR>", "[O]il: Open parent directory")

-- **telescope**
local builtin = require("telescope.builtin")
map("<leader>sh", builtin.help_tags, "[S]earch [H]elp")
map("<leader>sk", builtin.keymaps, "[S]earch [K]eymaps")
map("<leader>sf", builtin.find_files, "[S]earch [F]iles")
map("<leader>ss", builtin.builtin, "[S]earch [S]elect Telescope")
map("<leader>sw", builtin.grep_string, "[S]earch current [W]ord")
map("<leader>sg", builtin.live_grep, "[S]earch by [G]rep")
map("<leader>sd", builtin.diagnostics, "[S]earch [D]iagnostics")
map("<leader>sr", builtin.resume, "[S]earch [R]esume")
map("<leader>s.", builtin.oldfiles, '[S]earch Recent Files ("." for repeat)')
map("<leader><leader>", builtin.buffers, "[ ] Find existing buffers")
map(
  "<leader>/",
  builtin.current_buffer_fuzzy_find,
  "[/] Fuzzily search in current buffer"
)
map("<leader>s/", function()
  builtin.live_grep({
    grep_open_files = true,
    prompt_title = "Live Grep in Open Files",
  })
end, "[S]earch [/] in Open Files")

-- TODO: migrate this to use nix-config's
-- map("n", "<leader>sn", function()
--   builtin.find_files({ cwd = vim.fn.stdpath("config") )
-- end, "[S]earch [N]eovim files" )

-- **harpoon**
local harpoon = require("harpoon")
map("<leader>a", function()
  harpoon:list():add()
end, "Harpoon: [a]dd file to list")
map("<leader>h", function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, "[H]arpoon: quick menu")
map("<c-h>", function()
  harpoon:list():select(1)
end, "Harpoon: go to file 1")
map("<c-j>", function()
  harpoon:list():select(2)
end, "Harpoon: go to file 2")
map("<c-k>", function()
  harpoon:list():select(3)
end, "Harpoon: go to file 3")
map("<c-l>", function()
  harpoon:list():select(4)
end, "Harpoon: go to file 4")

-- **conform**
map("<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, "[F]ormat buffer")

-- **lazygit.nvim**
map("<leader>gg", "<cmd>LazyGit<CR>", "LazyGit")

-- **undotree**
map("<leader>u", "<cmd>UndotreeToggle<CR>", "[U]ndotree Toggle")

-- **trouble.nvim**
map("<leader>td", "<cmd>Trouble diagnostics toggle<cr>", "[T]rouble: [D]iagnostics")
map(
  "<leader>tb",
  "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  "[T]rouble: [B]uffer Diagnostics"
)
map(
  "<leader>tt",
  "<cmd>Trouble symbols toggle focus=false<cr>",
  "[T]rouble: [T]oggle Symbol)"
)
map(
  "<leader>tl",
  "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  "[T]rouble: [L]SP Definitions / references / ..."
)
map("<leader>tl", "<cmd>Trouble loclist toggle<cr>", "[T]rouble: [L]ocation List")
map("<leader>tq", "<cmd>Trouble qflist toggle<cr>", "[T]rouble: [Q]uickfix List")
map("[t", function()
  require("trouble").next({ skip_groups = true, jump = true })
end, "Go to previous [D]iagnostic message")
map("]t", function()
  require("trouble").next({ skip_groups = true, jump = true })
end, "Go to next [D]iagnostic message")

-- **zen-mode.nvim**
map("<leader>zz", function()
  require("zen-mode").toggle({ width = 0.85 })
end, "Toggle [Z]en Mode")
