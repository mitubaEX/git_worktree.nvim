-- Minimal init file for running tests
-- This sets up the minimal environment needed for testing

local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"

-- Clone plenary if it doesn't exist
vim.fn.system({
  "git",
  "clone",
  "--depth=1",
  "https://github.com/nvim-lua/plenary.nvim",
  plenary_dir,
})

-- Add to runtime path
vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)

-- Load plenary
vim.cmd("runtime! plugin/plenary.vim")

-- Ensure git is configured
vim.fn.system({ "git", "config", "--global", "user.name", "Test User" })
vim.fn.system({ "git", "config", "--global", "user.email", "test@example.com" })
