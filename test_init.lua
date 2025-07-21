-- Test configuration for git_worktree.nvim
-- Run with: nvim -u test_init.lua

-- Add current directory to runtime path
vim.opt.runtimepath:prepend('.')

-- Load the plugin
require('git_worktree').setup()

print("git_worktree.nvim test environment loaded!")
print("Available commands:")
print("  :GitWorktreeList")
print("  :GitWorktreeCurrent")
print("  :GitWorktreeCreate <branch>")
print("  :GitWorktreeSwitch <branch>")
print("  :GitWorktreeDelete <branch>")