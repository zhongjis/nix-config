vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- **diagnostic**
vim.keymap.set(
  "n",
  "[d",
  vim.diagnostic.goto_prev,
  { desc = "Go to previous [D]iagnostic message" }
)
vim.keymap.set(
  "n",
  "]d",
  vim.diagnostic.goto_next,
  { desc = "Go to next [D]iagnostic message" }
)
vim.keymap.set(
  "n",
  "<leader>e",
  vim.diagnostic.open_float,
  { desc = "Show diagnostic [E]rror messages" }
)

-- **oil**
vim.keymap.set(
  "n",
  "<leader>o",
  "<CMD>Oil<CR>",
  { desc = "[O]il: Open parent directory" }
)

-- **telescope**
local builtin = require("telescope.builtin")
vim.keymap.set(
  "n",
  "<leader>sh",
  builtin.help_tags,
  { desc = "[S]earch [H]elp" }
)
vim.keymap.set(
  "n",
  "<leader>sk",
  builtin.keymaps,
  { desc = "[S]earch [K]eymaps" }
)
vim.keymap.set(
  "n",
  "<leader>sf",
  builtin.find_files,
  { desc = "[S]earch [F]iles" }
)
vim.keymap.set(
  "n",
  "<leader>ss",
  builtin.builtin,
  { desc = "[S]earch [S]elect Telescope" }
)
vim.keymap.set(
  "n",
  "<leader>sw",
  builtin.grep_string,
  { desc = "[S]earch current [W]ord" }
)
vim.keymap.set(
  "n",
  "<leader>sg",
  builtin.live_grep,
  { desc = "[S]earch by [G]rep" }
)
vim.keymap.set(
  "n",
  "<leader>sd",
  builtin.diagnostics,
  { desc = "[S]earch [D]iagnostics" }
)
vim.keymap.set(
  "n",
  "<leader>sr",
  builtin.resume,
  { desc = "[S]earch [R]esume" }
)
vim.keymap.set(
  "n",
  "<leader>s.",
  builtin.oldfiles,
  { desc = '[S]earch Recent Files ("." for repeat)' }
)
vim.keymap.set(
  "n",
  "<leader><leader>",
  builtin.buffers,
  { desc = "[ ] Find existing buffers" }
)

vim.keymap.set("n", "<leader>/", function()
  -- You can pass additional configuration to Telescope to change the theme, layout, etc.
  builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
    winblend = 10,
    previewer = false,
  }))
end, { desc = "[/] Fuzzily search in current buffer" })

vim.keymap.set("n", "<leader>s/", function()
  builtin.live_grep({
    grep_open_files = true,
    prompt_title = "Live Grep in Open Files",
  })
end, { desc = "[S]earch [/] in Open Files" })

-- TODO: migrate this to use nix-config's
-- vim.keymap.set("n", "<leader>sn", function()
--   builtin.find_files({ cwd = vim.fn.stdpath("config") })
-- end, { desc = "[S]earch [N]eovim files" })

-- **harpoon**
local harpoon = require("harpoon")
vim.keymap.set("n", "<leader>a", function()
  harpoon:list():add()
end, { desc = "Harpoon: [a]dd file to list" })
vim.keymap.set("n", "<leader>h", function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "[H]arpoon: quick menu" })
vim.keymap.set("n", "<c-h>", function()
  harpoon:list():select(1)
end, { desc = "Harpoon: go to file 1" })
vim.keymap.set("n", "<c-j>", function()
  harpoon:list():select(2)
end, { desc = "Harpoon: go to file 2" })
vim.keymap.set("n", "<c-k>", function()
  harpoon:list():select(3)
end, { desc = "Harpoon: go to file 3" })
vim.keymap.set("n", "<c-l>", function()
  harpoon:list():select(4)
end, { desc = "Harpoon: go to file 4" })

-- **conform**
vim.keymap.set("n", "<leader>f", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "[F]ormat buffer" })

-- **lazygit.nvim**
vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "LazyGit" })

-- **undotree**
vim.keymap.set(
  "n",
  "<leader>u",
  "<cmd>UndotreeToggle<CR>",
  { desc = "[U]ndotree Toggle" }
)

-- **trouble.nvim**
vim.keymap.set(
  "n",
  "<leader>td",
  "<cmd>Trouble diagnostics toggle<cr>",
  { desc = "[T]rouble: [D]iagnostics" }
)
vim.keymap.set(
  "n",
  "<leader>tb",
  "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  { desc = "[T]rouble: [B]uffer Diagnostics" }
)
vim.keymap.set(
  "n",
  "<leader>tt",
  "<cmd>Trouble symbols toggle focus=false<cr>",
  { desc = "[T]rouble: [T]oggle Symbol)" }
)
vim.keymap.set(
  "n",
  "<leader>tl",
  "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  { desc = "[T]rouble: [L]SP Definitions / references / ..." }
)
vim.keymap.set(
  "n",
  "<leader>tl",
  "<cmd>Trouble loclist toggle<cr>",
  { desc = "[T]rouble: [L]ocation List" }
)
vim.keymap.set(
  "n",
  "<leader>tq",
  "<cmd>Trouble qflist toggle<cr>",
  { desc = "[T]rouble: [Q]uickfix List" }
)
